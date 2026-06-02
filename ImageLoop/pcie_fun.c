#ifdef __cplusplus
 extern "C" {
 #endif
#include <Windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <strsafe.h>
#include <string.h>
#include <SetupAPI.h>
#include <INITGUID.H>
#include <WinIoCtl.h>
#include "pcie_fun.h"
#include <io.h>
#include "xdma_public.h"
#include "rwif.h"
#pragma comment(lib, "setupapi.lib")

#define MAX_BYTES_PER_TRANSFER 0x800000

static HANDLE h_c2h0;
static HANDLE h_h2c0;
static HANDLE h_user;

unsigned char *c2h_align_mem_tmp;

unsigned int image_h;
unsigned int image_v;

static BYTE* allocate_buffer(size_t size, size_t alignment) {
    if (alignment == 0) {
        SYSTEM_INFO sys_info;
        GetSystemInfo(&sys_info);
        alignment = sys_info.dwPageSize;
    }
    return (BYTE*)_aligned_malloc(size, alignment);
}

static int get_devices(GUID guid, char* devpath, size_t len_devpath) {
    SP_DEVICE_INTERFACE_DATA device_interface;
    PSP_DEVICE_INTERFACE_DETAIL_DATA dev_detail;
    DWORD index;
    HDEVINFO device_info;
    wchar_t tmp[256];
    device_info = SetupDiGetClassDevs((LPGUID)&guid, NULL, NULL, DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (device_info == INVALID_HANDLE_VALUE) {
        exit(-1);
        return 0;
    }
    device_interface.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);
    for (index = 0; SetupDiEnumDeviceInterfaces(device_info, NULL, &guid, index, &device_interface); ++index) {
        ULONG detailLength = 0;
        if (!SetupDiGetDeviceInterfaceDetail(device_info, &device_interface, NULL, 0, &detailLength, NULL) && GetLastError() != ERROR_INSUFFICIENT_BUFFER)
            break;

        dev_detail = (PSP_DEVICE_INTERFACE_DETAIL_DATA)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, detailLength);
        if (!dev_detail)
            break;
        dev_detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);

        if (!SetupDiGetDeviceInterfaceDetail(device_info, &device_interface, dev_detail, detailLength, NULL, NULL)) {
            HeapFree(GetProcessHeap(), 0, dev_detail);
            break;
        }

        StringCchCopy(tmp, len_devpath, dev_detail->DevicePath);
        wcstombs(devpath, tmp, 256);
        HeapFree(GetProcessHeap(), 0, dev_detail);
    }
    SetupDiDestroyDeviceInfoList(device_info);
    return index;
}

HANDLE open_devices(char* device_base_path, char* device_name, DWORD accessFlags)
{
    char device_path[MAX_PATH + 1] = "";
    wchar_t device_path_w[MAX_PATH + 1];
    strcpy_s(device_path, sizeof device_path, device_base_path);
    strcat_s(device_path, sizeof device_path, device_name);
    mbstowcs(device_path_w, device_path, sizeof(device_path));
    return CreateFile(device_path_w, accessFlags, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
}

static void read_device(HANDLE device, long address, DWORD size, BYTE *buffer)
{
    DWORD rd_size = 0;
    if (INVALID_SET_FILE_POINTER == SetFilePointer(device, address, NULL, FILE_BEGIN))
        return;
    if (!ReadFile(device, (void *)buffer, (DWORD)size, &rd_size, NULL))
        return;
}

static int write_device(HANDLE device, long address, DWORD size, BYTE *buffer)
{
    DWORD wr_size = 0;
    if (INVALID_SET_FILE_POINTER == SetFilePointer(device, address, NULL, FILE_BEGIN))
        return 0;
    if (!WriteFile(device, (void *)buffer, (DWORD)size, &wr_size, NULL))
        return 0;
    return (wr_size == size);
}

int pcie_init()
{
    char user_name[50] = "\\user";
    char c2h0_name[50] = "\\c2h_0";
    char h2c0_name[50] = "\\h2c_0";
    char base_path[MAX_PATH + 1] = "";

    DWORD num_devices = get_devices(GUID_DEVINTERFACE_XDMA, base_path, sizeof(base_path));
    if (num_devices < 1)
        return 0;

    h_user = open_devices(base_path, user_name, GENERIC_READ | GENERIC_WRITE);
    if (h_user == INVALID_HANDLE_VALUE)
        return 0;
    h_h2c0 = open_devices(base_path, h2c0_name, GENERIC_READ | GENERIC_WRITE);
    if (h_h2c0 == INVALID_HANDLE_VALUE)
        return 0;
    h_c2h0 = open_devices(base_path, c2h0_name, GENERIC_READ | GENERIC_WRITE);
    if (h_c2h0 == INVALID_HANDLE_VALUE)
        return 0;

    c2h_align_mem_tmp = allocate_buffer(0x8000000,4096);

    if(NULL == c2h_align_mem_tmp)
        return 0;

    pcie_start();
    return 1;
}

void pcie_deinit()
{
    pcie_close();
    CloseHandle(h_user);
    CloseHandle(h_c2h0);
    CloseHandle(h_h2c0);
}

void c2h_transfer(unsigned int address,unsigned int size,unsigned char *buffer)
{
    read_device(h_c2h0, address, size, buffer);
}

static int h2c_transfer(unsigned int address,unsigned int size,unsigned char *buffer)
{
    unsigned int offset = 0;
    while (offset < size) {
        unsigned int chunk = size - offset;
        if (chunk > MAX_BYTES_PER_TRANSFER)
            chunk = MAX_BYTES_PER_TRANSFER;
        if (!write_device(h_h2c0, address + offset, chunk, buffer + offset))
            return 0;
        offset += chunk;
    }
    return 1;
}

void pcie_start(){
    DWORD xdma_start_open = 0x0000000f;
    write_device(h_user, 0x04, 4, (BYTE *)&xdma_start_open);
}

void pcie_close(){
    DWORD xdma_start_open = 0x00000000;
    write_device(h_user, 0x04, 4, (BYTE *)&xdma_start_open);
}

static void pcie_download_done(){
    static DWORD done = 0;
    done = (done % 10) + 1;
    write_device(h_user, 0, 4, (BYTE *)&done);
}

void download_image_data(char *name)
{
    const char *ext = strrchr(name, '.');

    if (ext && 0 == _stricmp(ext, ".bin"))
    {
        FILE *f = fopen(name, "rb");
        unsigned int size;
        unsigned char *data;

        if (!f) return;

        fseek(f, 0, SEEK_END);
        size = ftell(f);
        fseek(f, 0, SEEK_SET);

        data = (unsigned char*)malloc(size);
        if (!data) { fclose(f); return; }

        if (fread(data, 1, size, f) != size)
        {
            free(data);
            fclose(f);
            return;
        }
        fclose(f);

        if (h2c_transfer(0x30000000, size, data))
            pcie_download_done();
        free(data);
    }
    else
    {
        /* BMP / other formats via rwif */
        ImageData imageData;
        read_image_file(name, &imageData);
        image_v = imageData.height;
        image_h = imageData.width;
        if (h2c_transfer(0x30000000, image_h * image_v * 4, imageData.pixelArray))
            pcie_download_done();
        clear_image_data(&imageData);
    }
}

#ifdef __cplusplus
}
#endif

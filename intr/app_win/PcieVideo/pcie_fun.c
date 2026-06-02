#ifdef __cplusplus
 extern "C" {
 #endif
#include <Windows.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <strsafe.h>
#include <stdint.h>
#include <SetupAPI.h>
#include <INITGUID.H>
#include <WinIoCtl.h>
#include "pcie_fun.h"
//#include <AtlBase.h>
#include <io.h>
#include "xdma_public.h"

#pragma comment(lib, "setupapi.lib")

static HANDLE h_c2h0;
static HANDLE h_h2c0;
static HANDLE h_user;
static HANDLE h_event[4];

static unsigned int c2h_ddr_addr[8];
unsigned char *c2h_align_mem_tmp;

unsigned int image_h;
unsigned int image_v;

LARGE_INTEGER start;
LARGE_INTEGER stop;
LARGE_INTEGER freq;

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

 static void write_device(HANDLE device, long address, DWORD size, BYTE *buffer)
 {
     DWORD wr_size = 0;
     if (INVALID_SET_FILE_POINTER == SetFilePointer(device, address, NULL, FILE_BEGIN))
         return;
     if (!WriteFile(device, (void *)buffer, (DWORD)size, &wr_size, NULL))
         return;
 }

int pcie_init()
{
    char user_name[50] = "\\user";
    char c2h0_name[50] = "\\c2h_0";
    char h2c0_name[50] = "\\h2c_0";
    char event_name[50] = "\\event_";
    char base_path[MAX_PATH + 1] = "";

    c2h_ddr_addr[0] = 0;
    c2h_ddr_addr[1] = 16777216;
    c2h_ddr_addr[2] = 16777216 * 2;
    c2h_ddr_addr[3] = 16777216 * 3;

    DWORD num_devices = get_devices(GUID_DEVINTERFACE_XDMA, base_path, sizeof(base_path));
    if (num_devices < 1)
        return 0;

    h_user = open_devices(base_path, user_name, GENERIC_READ | GENERIC_WRITE);
    if (h_user == INVALID_HANDLE_VALUE)
        return 0;
    h_h2c0 = open_devices(base_path, h2c0_name, GENERIC_READ | GENERIC_WRITE);
    if (h_c2h0 == INVALID_HANDLE_VALUE)
        return 0;
    h_c2h0 = open_devices(base_path, c2h0_name, GENERIC_READ | GENERIC_WRITE);
    if (h_c2h0 == INVALID_HANDLE_VALUE)
        return 0;

    c2h_align_mem_tmp = allocate_buffer(0x800000,4096);

    if(NULL == c2h_align_mem_tmp)
        return 0;

    for(int i=0;i<LEN(h_event);i++){
        char tmp[50];
        char index=(char)i+'0';
        strcpy_s(tmp, LEN(tmp), event_name);
        strncat_s(tmp, LEN(tmp), &index,1);
        h_event[i]=open_devices(base_path, tmp, GENERIC_READ);
        if (h_event[i] == INVALID_HANDLE_VALUE)
            return 0;
    }
    return 1;
}

void pcie_deinit()
{
    CloseHandle(h_user);
    CloseHandle(h_c2h0);
    CloseHandle(h_h2c0);
    for(int i=0;i<LEN(h_event);i++){
        CloseHandle(h_event[i]);
    }
}

void wait_event(int index)
{
    BYTE val;
    fprintf(stderr,"wait_event：%d,%p\n", index, h_event[index]);
    read_device(h_event[index], 0, 1, (BYTE *)&val);//waite irq
    fprintf(stderr,"wait_event_ok：%d\n", index);
    Sleep(1);
}

unsigned int c2h_transfer(unsigned int size, int id)
{
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&stop);
    unsigned int bd = (unsigned int)(1.0/((unsigned long long)(stop.QuadPart - start.QuadPart) / (double)freq.QuadPart));
    QueryPerformanceCounter(&start);
    fprintf(stderr,"c2h_transfer_%d_%d\n", id, size);
    read_device(h_c2h0,c2h_ddr_addr[id],size,c2h_align_mem_tmp);
    fprintf(stderr,"c2h_transfer_ok\n");
    return bd;
}

void pcie_start(){
    DWORD xdma_start_open = 0x0000000f;
    write_device(h_user, 0x04, 4, (BYTE *)&xdma_start_open);
}

void pcie_close(){
    DWORD xdma_start_open = 0x00000000;
    write_device(h_user, 0x04, 4, (BYTE *)&xdma_start_open);
}

#ifdef __cplusplus
}
#endif

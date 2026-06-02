
#ifndef PCIE_FUNC_H
#define PCIE_FUNC_H
#ifdef __cplusplus
 extern "C" {
 #endif

#define LEN(addr) sizeof(addr)/sizeof(addr[0])

extern unsigned char *c2h_align_mem_tmp;
extern unsigned int image_h;
extern unsigned int image_v;

void download_image_data(char *pic_name);
void c2h_transfer(unsigned int address,unsigned int size,unsigned char *buffer);
void pcie_deinit();
int pcie_init();
void pcie_start();
void pcie_close();
#ifdef __cplusplus
}
#endif
#endif


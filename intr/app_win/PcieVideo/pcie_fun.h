
#ifndef PCIE_FUNC_H
#define PCIE_FUNC_H
#ifdef __cplusplus
 extern "C" {
 #endif

#define LEN(addr) sizeof(addr)/sizeof(addr[0])

extern unsigned char *h2c_align_mem_tmp;
extern unsigned char *c2h_align_mem_tmp;
extern unsigned int image_h;
extern unsigned int image_v;

int pcie_init();
void pcie_deinit();
void pcie_start();
void pcie_close();
void wait_event(int index);
unsigned int c2h_transfer(unsigned int size, int id);
#ifdef __cplusplus
}
#endif
#endif



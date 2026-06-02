/*
 * dma_pl.c
 *
 *  Created on: 2018年7月9日
 *      Author: Administrator
 */


#include "xmcdma.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xgpiops.h"
#include "xil_mmu.h"
#include "xgpio.h"
#include "sleep.h"

#define MCDMA_DEV_ID	XPAR_MCDMA_0_DEVICE_ID
/*
 * BD buffer
 */
#define BLOCK_SIZE_1MB 		0x100000U
#define DDR_BASE_ADDR		XPAR_PSU_DDR_0_S_AXI_BASEADDR
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x10000000)
#define TX_BD_SPACE_BASE	(MEM_BASE_ADDR)								//发送端BD所占的空间
#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x20000000)				//发送缓存的首地址



#define NUMBER_OF_BDS_PER_PKT		5
#define NUMBER_OF_PKTS_TO_TRANSFER 	873
#define NUMBER_OF_BDS_TO_TRANSFER	(NUMBER_OF_PKTS_TO_TRANSFER * NUMBER_OF_BDS_PER_PKT)  //BD总数量，每个通道需要的总BD数
//#define NUMBER_OF_BDS_TO_TRANSFER	1188

//#define MAX_PKT_LEN		1024
#define MAX_PKT_LEN		1024

#define NUM_MAX_CHANNELS	16

#define AXIGPIO_CHANNEL_1    1U
#define AXIGPIO_CHANNEL_2    2U

#define AXIGPIO_IRQ_TYPE_HIGH   1U
#define AXIGPIO_IRQ_TYPE_PEDGE  3U

#define AXIGPIO_IRQ_PRIORITY  128U

// IMAGE_COUNT_ADDR 已废弃: XDMA AXI-Lite 接入自定义 h2c_intr IP, 由 GPIO 中断通知

//#define TEST_START_VALUE	0xC
/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */
XMcdma AxiMcdma;

XGpio axiGpio0;
XScuGic scuGic;

volatile int TxDone;
//volatile int RxDone;
int num_channels;

//int TxPattern[NUM_MAX_CHANNELS + 1];
//int TestStartValue[] = {0xC, 0xB, 0x3, 0x55, 0x33, 0x20, 0x80, 0x66, 0x88};

/*
 * Buffer for transmit packet. Must be 32-bit aligned to be used by DMA.
 */
UINTPTR *Packet = (UINTPTR *) TX_BUFFER_BASE;


/*
 * Function definitions
 */
static int TxSetup(XMcdma *McDmaInstPtr);
static int SendPacket(XMcdma *McDmaInstPtr);
static int clear_Senden(XMcdma *McDmaInstPtr);

static int gpio_conf(XGpio *GpioInstPtr);
void axiGpio0_Handler(void *CallbackRef);

int main()
{
	int Status, i;

	Status = gpio_conf(&axiGpio0);
	if (Status != XST_SUCCESS) {
		xil_printf("gpio_conf failed %d\r\n", Status);
		return XST_FAILURE;
	}

	TxDone = 0;

	XMcdma_Config *Mcdma_Config;
	xil_printf("\r\n--- Entering main() --- \r\n");

	/* 0x20000000 - 0x3FFFFFFF 图像存储/读取区域，强制 Non-Cacheable */
	for (i = 0; i < 512; i++) {
		Xil_SetTlbAttributes(0x20000000 + (i * BLOCK_SIZE_1MB), NORM_NONCACHE);
	}
	/* TX_BD_SPACE_BASE 区域 (0x10000000 起) 也需 Non-Cacheable, 否则 MCDMA 写 BD 冲突 */
	for (i = 0; i < 10; i++) {
		Xil_SetTlbAttributes(TX_BD_SPACE_BASE + (i * BLOCK_SIZE_1MB), NORM_NONCACHE);
	}

	Mcdma_Config = XMcdma_LookupConfig(MCDMA_DEV_ID);
	if (!Mcdma_Config) {
			xil_printf("No config found for %d\r\n", MCDMA_DEV_ID);

			return XST_FAILURE;
	}

	Status = XMcDma_CfgInitialize(&AxiMcdma, Mcdma_Config);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}
	//TX->MM2S
	num_channels = Mcdma_Config->TxNumChannels;
	Xil_DCacheInvalidateRange(0x1000000, 1000000);
	Status = TxSetup(&AxiMcdma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = SendPacket(&AxiMcdma);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed send packet\r\n");
		return XST_FAILURE;
	}

	/* 等待 h2c_intr IP → GPIO 中断触发 MCDMA 传输 */
	while (1) {
		usleep(100000);
	}
	return XST_SUCCESS;
}



static int gpio_conf(XGpio *GpioInstPtr)
{
	int Status;

	/* Initialize the GPIO driver. If an error occurs then exit */
	Status = XGpio_Initialize(GpioInstPtr, XPAR_GPIO_0_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_Config *IntcConfig;

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(&scuGic, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_SetPriorityTriggerType(&scuGic, XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR,
					0xA0, 0x3);

	/*
	 * Connect the interrupt handler that will be called when an
	 * interrupt occurs for the device.
	 */
	Status = XScuGic_Connect(&scuGic, XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR,
				 (Xil_ExceptionHandler)axiGpio0_Handler, GpioInstPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Enable the interrupt for the GPIO device.*/
	XScuGic_Enable(&scuGic, XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR);

	/*
	 * Enable the GPIO channel interrupts so that push button can be
	 * detected and enable interrupts for the GPIO device
	 */
	XGpio_InterruptEnable(GpioInstPtr, AXIGPIO_CHANNEL_1);
	XGpio_InterruptGlobalEnable(GpioInstPtr);

	/*
	 * Initialize the exception table and register the interrupt
	 * controller handler with the exception table
	 */
	Xil_ExceptionInit();

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			 (Xil_ExceptionHandler)XScuGic_InterruptHandler, &scuGic);

	/* Enable non-critical exceptions */
	Xil_ExceptionEnable();

	XGpio_DiscreteWrite(GpioInstPtr, AXIGPIO_CHANNEL_2, 0x0); // 向axiGpio0通道1的第0位和第1位写
	return	XST_SUCCESS;
}



/*****************************************************************************/
/**
*
* This function sets up the TX channel of a DMA engine to be ready for packet
* transmission
*
* @param	McDmaInstPtr is the instance pointer to the AXI MCDMA engine.
*
* @return	XST_SUCCESS if the setup is successful, XST_FAILURE otherwise.
*
* @note		None.
*
******************************************************************************/
static int TxSetup(XMcdma *McDmaInstPtr)
{
	XMcdma_ChanCtrl *Tx_Chan;
	int ChanId;
	int BdCount = NUMBER_OF_BDS_TO_TRANSFER;
	UINTPTR TxBufferPtr;
	UINTPTR TxBdSpacePtr;
	int Status;
	u32 i, j;
	u32 buf_align;

	TxBufferPtr = TX_BUFFER_BASE;
	TxBdSpacePtr = TX_BD_SPACE_BASE;

	for (ChanId = 1; ChanId <= num_channels; ChanId++) {
		Tx_Chan = XMcdma_GetMcdmaTxChan(McDmaInstPtr, ChanId);   // Gets the TX Channel Pointer

		/* Disable all interrupts */
		XMcdma_IntrDisable(Tx_Chan, XMCDMA_IRQ_ALL_MASK);

		Status = XMcDma_ChanBdCreate(Tx_Chan, TxBdSpacePtr, BdCount);  	//创建BD链表，每个链表在内存中的地址不同
		if (Status != XST_SUCCESS) {
			xil_printf("Rx bd create failed with %d\r\n", Status);
			return XST_FAILURE;
		}

		for (j = 0 ; j < NUMBER_OF_PKTS_TO_TRANSFER; j++) {
			for (i = 0 ; i < NUMBER_OF_BDS_PER_PKT; i++) {
				Status = XMcDma_ChanSubmit(Tx_Chan, TxBufferPtr, MAX_PKT_LEN); 			//*此函数使用提供的缓冲区地址和长度字段填写 BD 条目
				if (Status != XST_SUCCESS) {
					xil_printf("ChanSubmit failed\n\r");
					return XST_FAILURE;
				}

				TxBufferPtr += MAX_PKT_LEN;
				if (!Tx_Chan->Has_Txdre) {
					buf_align = TxBufferPtr % 64;
					if (buf_align > 0)
						buf_align = 64 - buf_align;
				    TxBufferPtr += buf_align;
				}

				/* Clear the receive buffer, so we can verify data */
				//memset((void *)TxBufferPtr, 0, MAX_PKT_LEN);

			}
		}
		TxBdSpacePtr += BdCount * Tx_Chan->Separation;   //Separation 参数存储在内存中，表示连续两个缓冲区起始地址之间的字节偏移量
		XMcdma_IntrEnable(Tx_Chan, XMCDMA_IRQ_ALL_MASK);
	 }
	return XST_SUCCESS;
}

static int SendPacket(XMcdma *McDmaInstPtr)
{
	XMcdma_ChanCtrl *Tx_Chan = NULL;
	u32 Index, Pkts, Index1;
	XMcdma_Bd *BdCurPtr;
	u32 Status;
	u8 *TxPacket;
	u8 Value;
	u32 ChanId;

	for (ChanId = 1; ChanId <= num_channels; ChanId++) {
		Tx_Chan = XMcdma_GetMcdmaTxChan(McDmaInstPtr, ChanId);

		BdCurPtr = XMcdma_GetChanCurBd(Tx_Chan);						//获取起始BD指针
		for(Index = 0; Index < NUMBER_OF_PKTS_TO_TRANSFER; Index++) {
			for(Pkts = 0; Pkts < NUMBER_OF_BDS_PER_PKT; Pkts++) {
				u32 CrBits = 0;
				/*
				Value = TestStartValue[ChanId] + TxPattern[ChanId]++;				//确定数据值
				TxPacket = (u8 *)XMcdma_BdRead64(BdCurPtr, XMCDMA_BD_BUFA_OFFSET);  //得到当前BD的数据地址
				for(Index1 = 0; Index1 < MAX_PKT_LEN; Index1++) {
					TxPacket[Index1] = Value;									    //按数据地址设定一些值进行校验

					Value = (Value + 1) & 0xFF;
				}
				*/
				//Xil_DCacheFlushRange((UINTPTR)TxPacket, MAX_PKT_LEN);

				if (Pkts == 0) {
					CrBits |= XMCDMA_BD_CTRL_SOF_MASK;
				}

				if (Pkts == (NUMBER_OF_BDS_PER_PKT - 1)) {
					CrBits |= XMCDMA_BD_CTRL_EOF_MASK;
				}

				XMcDma_BdSetCtrl(BdCurPtr, CrBits);									//每个通道Control 信息
				XMCDMA_CACHE_FLUSH((UINTPTR)(BdCurPtr));
				BdCurPtr = (XMcdma_Bd *)XMcdma_BdChainNextBd(Tx_Chan, BdCurPtr);
			}
		}

	}

	for (ChanId = 1; ChanId <= num_channels; ChanId++) {
		Tx_Chan = XMcdma_GetMcdmaTxChan(McDmaInstPtr, ChanId);
		Status = XMcDma_ChanToHw(Tx_Chan);											//每个通道往register写入值，向MM2S Channel Enable/Disable Register 每个Channel Enable
		if (Status != XST_SUCCESS) {
			xil_printf("XMcDma_ChanToHw failed for Channel %d\n\r", ChanId);
			xil_printf("%d\n\r", XMcdma_ReadReg(Tx_Chan->ChanBase,XMCDMA_ERR_OFFSET));
			return XST_FAILURE;
		}
	}
	return XST_SUCCESS;
}

static int clear_Senden(XMcdma *McDmaInstPtr)
{
	XMcdma_ChanCtrl *Tx_Chan = NULL;
	u32 Status;
	u32 ChanId;


	int BdCount = NUMBER_OF_BDS_TO_TRANSFER;
	UINTPTR TxBufferPtr;
	UINTPTR TxBdSpacePtr;
	u32 i, j;
	u32 buf_align;

	TxBufferPtr = TX_BUFFER_BASE;
	TxBdSpacePtr = TX_BD_SPACE_BASE;



	for (ChanId = 1; ChanId <= num_channels; ChanId++) {
		Tx_Chan = XMcdma_GetMcdmaTxChan(McDmaInstPtr, ChanId);   // Gets the TX Channel Pointer

		/* Disable all interrupts */
		XMcdma_IntrDisable(Tx_Chan, XMCDMA_IRQ_ALL_MASK);

		for (j = 0 ; j < NUMBER_OF_PKTS_TO_TRANSFER; j++) {
			for (i = 0 ; i < NUMBER_OF_BDS_PER_PKT; i++) {
				XMcdma_BdWrite(TxBdSpacePtr, 0x1C,0x00000000);
			}
		}
		TxBdSpacePtr += BdCount * Tx_Chan->Separation;   //Separation 参数存储在内存中，表示连续两个缓冲区起始地址之间的字节偏移量
		XMcdma_IntrEnable(Tx_Chan, XMCDMA_IRQ_ALL_MASK);
	 }
	XGpio_DiscreteWrite(&axiGpio0, AXIGPIO_CHANNEL_2, 0x0);

	for (ChanId = 1; ChanId <= num_channels; ChanId++) {
		Tx_Chan = XMcdma_GetMcdmaTxChan(McDmaInstPtr, ChanId);
		Status = XMcDma_ChanToHw(Tx_Chan);											//每个通道往register写入值，向MM2S Channel Enable/Disable Register 每个Channel Enable
		if (Status != XST_SUCCESS) {
			xil_printf("XMcDma_ChanToHw failed for Channel %d\n\r", ChanId);
			xil_printf("%d\n\r", XMcdma_ReadReg(Tx_Chan->ChanBase,XMCDMA_ERR_OFFSET));
			xil_printf("%d\n\r", XMcdma_ReadReg(Tx_Chan->ChanBase,XMCDMA_CSR_OFFSET));
			xil_printf("%d\n\r", XMcdma_ReadReg(Tx_Chan->ChanBase,XMCDMA_TXCH_SERV_OFFSET));
			xil_printf("%d\n\r", XMcdma_ReadReg(Tx_Chan->ChanBase,XMCDMA_TXINT_SER_OFFSET));
			xil_printf("%d\n\r", XMcdma_ReadReg(0x40,0x00));
			xil_printf("%d\n\r", XMcdma_ReadReg(0x40,0x04));
			return XST_FAILURE;
		}
	}
	return XST_SUCCESS;
}

void axiGpio0_Handler(void *CallbackRef)
{
	u32 Status;
	XGpio *axiGpioPtr = (XGpio *)CallbackRef;

	print("frame end!!\n\n");
	XGpio_DiscreteWrite(&axiGpio0, AXIGPIO_CHANNEL_2, 0x1);
	Status = TxSetup(&AxiMcdma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = SendPacket(&AxiMcdma);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed send packet\r\n");
		return XST_FAILURE;
	}
	XGpio_DiscreteWrite(&axiGpio0, AXIGPIO_CHANNEL_2, 0x0);
	// 清除中断寄存器标志，否则无法再次进入中断
	XGpio_InterruptClear(axiGpioPtr, AXIGPIO_CHANNEL_1);

}

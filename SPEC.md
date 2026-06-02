# PCIe 图像传输环回系统 — 设计规格说明书

## 版本信息
- 日期：2026-05-06
- 目标器件：XCZU4EV-SFVC784-2-I (Zynq UltraScale+ MPSoC)
- Vivado 版本：2020.2
- Vitis 版本：2020.2
- Qt 版本：6.9.3 MSVC2022 64bit
- XDMA IP：v4.1 (PCIe Gen3 x2)

---

## 1. 目标器件资源概述

| 类别 | 资源项 | 数量 | 本设计占用 | 利用率 |
|---|---|---|---|---|
| **片上处理器** | Cortex-A53 (APU) | 4 核 @ 1.33 GHz | 1 核 (bare-metal) | 25% |
| | Cortex-R5 (RPU) | 2 核 @ 533 MHz | 未使用 | 0% |
| | Mali-400 MP2 GPU | 1 个 | 未使用 | 0% |
| | VCU (H.264/H.265) | 1 个 | 未使用 | 0% |
| **逻辑资源** | Logic Cells | 192,150 | — | — |
| | CLB LUTs | 87,840 | — | — |
| | CLB Flip-Flops | 175,680 | — | — |
| **存储资源** | Block RAM | 5.3 Mb (128 × 36 Kb) | — | — |
| | UltraRAM | 13.5 Mb (48 × 288 Kb) | — | — |
| | Distributed RAM | 1.3 Mb | — | — |
| **DSP** | DSP48E2 | 728 | — | — |
| **高速收发器** | GTH (16.375 Gb/s) | 4 个 | 2 个 (PCIe Gen3 x2) | 50% |
| | GTY (32.75 Gb/s) | 16 个 | 未使用 | 0% |
| **外部存储器** | DDR4-2400 | 64-bit 接口 | 配置中 | — |
| **I/O** | MIO | 78 个 | UART0 (MIO 42-43) | — |
| | HD I/O | 96 个 | — | — |
| | PL I/O | 256 个 | 少量 (LED, 复位) | — |

**关键约束：**
- GTH 仅有 4 个，PCIe x4 已占满全部 GTH，无法支撑 x8 lane 扩展
- 如需更高 PCIe 带宽（x8 / Gen4），须迁移至 ZU7EV/ZU9EG 或 Kintex UltraScale+ 平台
- DDR4 带宽 19.2 GB/s (理论)，是 MCDMA 10 通道并行读取的瓶颈所在

---

## 2. PS PLL 时钟配置

### 2.1 问题背景

Zynq US+ PS 端有 5 个 PLL：APLL、DPLL、VPLL、RPLL、IOPLL。Vivado 自动化默认将 PL 时钟 (pl_clk0/pl_clk1) 挂在 **RPLL** 上。RPLL VCO 被优化为 2133.312 MHz (33.333 × 64)，同时为 ADMA/GPU/TOPSW 等模块输出 533.333 MHz。此 VCO 值下：
- pl_clk0 (请求 200 MHz): 2133.312 / 12 = 177.776 MHz (偏差 -11%)
- pl_clk1 (请求 300 MHz): 2133.312 / 8 = 266.664 MHz (偏差 -11%)

PL0 和 PL1 共享 RPLL 且与多组外设时钟竞争同一 VCO，无法精确命中目标频率。

### 2.2 解决方案：切换至 IOPLL

将 PL0 和 PL1 的时钟源从 RPLL 改为 **IOPLL**。IOPLL 默认服务于 QSPI/NAND 等 I/O 外设，本设计中未用到这些外设，IOPLL 输出通道空闲。IOPLL VCO 配置为 1800 MHz (33.333 × 60)：

| 时钟 | 计算式 | 频率 | 偏差 |
|---|---|---|---|
| pl_clk0 | 1800 / 9 | **200.0 MHz** | 0% |
| pl_clk1 | 1800 / 6 | **300 MHz** | 0% |

两个 PL 时钟均为精确整数分频，完全命中。处理流水线的理论吞吐因此提升 (vs 旧方案 177.8/266.7 MHz)。

### 2.3 最终时钟架构

| 时钟 | 频率 | 来源 PLL | VCO | 用途 |
|---|---|---|---|---|
| pl_clk0 | 200 MHz | IOPLL | 1800 MHz | MCDMA / Frame_Arbiter / lsp_debug / result_tranfer |
| pl_clk1 | 300 MHz | IOPLL | 1800 MHz | HP0/HP1 AXI 互联 |
| axi_aclk | 250 MHz | XDMA 内部 | — | XDMA / HP2 / HPC0 互联 |

---

## 3. 系统架构总览

```
┌──────────────────────────────┐      PCIe Gen3 x2       ┌───────────────────────────────────────┐
│         PC (Windows)          │◄──────────────────────►│             FPGA (ZU4EV)                │
│                               │                        │                                        │
│  ┌─────────────────────┐     │    XDMA Driver          │  ┌─────────────────────────────────┐  │
│  │  ImageLoop / App     │     │  ┌────────┬────────┐   │  │  XDMA IP (v4.1, 250MHz)        │  │
│  │  ├─ pcie_fun.c       │     │  │ h_user │ c2h_0  │   │  │  ├─ m_axil (user, AXI-Lite)    │  │
│  │  ├─ rwif_bmp.c       │     │  │(AXI-L) │(AXI-MM)│   │  │  ├─ h2c_0 (AXI-MM, 64bit)      │  │
│  │  └─ mainwindow       │     │  ├┴───────┴┴───────┤   │  │  ├─ c2h_0 (AXI-MM, 64bit)      │  │
│  └──────────┬───────────┘     │  │     h2c_0       │   │  │  └─ usr_irq_req[3:0] (4路)     │  │
│             │                 │  │    (AXI-MM)     │   │  └──────────┬──────────────────────┘  │
│  ┌──────────┴───────────┐     │  └─────────────────┘   │             │                         │
│  │   event_0 (阻塞读)    │     │                        │  ┌──────────┴──────────────────────┐  │
│  └──────────────────────┘     │  MSI ←─────────────────│  │  Zynq PS (ARM A53)              │  │
└───────────────────────────────┘                        │  │  pl_clk0=200MHz(IOPLL)               │  │
                                                         │  │  pl_clk1=300MHz(IOPLL)               │  │
                                                         │  │  ├─ MCDMA (10ch MM2S)           │  │
                                                         │  │  ├─ dma_da.c (TLB/BDS/IRQ)      │  │
                                                         │  │  ├─ GIC (pl_ps_irq0)            │  │
                                                         │  │  └─ DDR4-2400 (4GB)             │  │
                                                         │  └─────────────────────────────────┘  │
                                                         │                                        │
                           ┌─────────────────────────────────────────────────────────────────┐   │
                           │              处理流水线 (pl_clk0, 200MHz)                     │   │
                           │                                                                 │   │
                           │  DDR@0x30000000 ──MM2S──> [MCDMA 10ch] ──10×AXI-Stream──>      │   │
                           │  (原始图像)           256b×burst32    582行/ch                  │   │
                           │                                                                 │   │
                           │  ┌──────────────────────────────────────────────────────┐      │   │
                           │  │ [Frame_Arbiter] ──data_n──> [lsp_debug] ──data_o──>  │      │   │
                           │  │   10→1汇聚                    光斑位置提取  80bit     │      │   │
                           │  │                              W=7680 H=582           │      │   │
                           │  └──────────────────────────────────────────────────────┘      │   │
                           │         │                                │                     │   │
                           │         │ CCLC_ready (反压)              │ end_flag            │   │
                           │         │                                v                     │   │
                           │         │              ┌─────────────────────────────────┐     │   │
                           │         │              │       result_tranfer            │     │   │
                           │         │              │  [FIFO 80b×128] → [fifo2axis]  │     │   │
                           │         │              │      128b AXI-Stream            │     │   │
                           │         │              │  [dma_s2mm_cmd] → [DataMover]  │     │   │
                           │         │              │      S2MM, burst=32            │     │   │
                           │         │              │  [monitor] 统计计数             │     │   │
                           │         │              └──────────────┬──────────────────┘     │   │
                           │         │                             │ M_AXI_S2MM (128b)     │   │
                           └─────────┼─────────────────────────────┼───────────────────────┘   │
                                     │                             │                            │
                                     v                             v                            │
                              ┌─────────────────────────────────────────────────────────────┐   │
                              │                       DDR4 内存映射                          │   │
                              │  0x30000000: 原始图像 (PC写入, MCDMA读取)                    │   │
                              │  0x1000000:  光斑结果 (DataMover写入, PC C2H读回)             │   │
                              │                                                                               │   │
                              └─────────────────────────────────────────────────────────────┘   │
                                                                                               │
  ┌──────────────────────┐                                 ┌──────────────────────┐            │
  │  h2c_intr IP (ip.v)  │  trigger_out → GPIO ch1         │  AXI GPIO (v2.0)     │            │
  │  ├─ slv_reg0 (PC写)  │────────────────────────────────→│  ch1=in  (end_flag)  │            │
  │  ├─ slv_reg2 (结果数) │  xdma_irq_req → usr_irq_req[0] │  ch2=out (clear)     │            │
  │  └─ data_en + data   │─→(外部结果计数)                 │  ip2intc → pl_ps_irq0│            │
  └──────────────────────┘                                 └──────────────────────┘            │
                                                                                               │
                                                                                               │
                                           ┌──────────────────────┐                            │
                                           │ 时钟域汇总            │                            │
                                           │ pl_clk0  = 200   MHz │ (IOPLL, MCDMA/Arbiter/lsp) │
                                           │ pl_clk1  = 300 MHz│ (IOPLL, HP0/HP1 互联)      │
                                           │ axi_aclk = 250   MHz │ (XDMA, HP2/HPC0 互联)      │
                                           └──────────────────────┘                            │
                                           PL0/PL1 均使用 IOPLL (VCO=1800 MHz):               │
                                           pl_clk0 = 1800/9 = 200.0 MHz 精准命中              │
                                           pl_clk1 = 1800/6  = 300 MHz 精准命中             │
                                                                                               │
                                           └───────────────────────────────────────────────────┘
```

---

## 4. 数据流

### 4.1 PC → FPGA 图像下载（H2C）→ MCDMA 传输

```
PC ImageLoop
  │
  ├─ 选择 BMP/BIN 文件
  ├─ rwif_bmp.c: 24/32-bit BMP → BGRA 像素数组 (image_h × image_v × 4 bytes)
  └─ pcie_fun.c: h2c_transfer(0x30000000, size, pixelArray)
        │
        │ WriteFile(h_h2c0, address=0x30000000, data)
        v
  XDMA h2c_0 (AXI-MM) ──→ axi_smc ──→ HP2_FPD ──→ DDR @ 0x30000000
        │
        │ 传输完成后，通知 FPGA 有新图像
        v
  WriteFile(h_user, addr=0x00, data)  ──→ XDMA m_axil ──→ h2c_intr IP S_AXI
        │                                                  │
        │                                                  │ slv_reg0 被写入
        │                                                  │ (写入值 ≠ tracked_val, 内部自动跟踪)
        │                                                  v
        │                                          trigger_out 脉冲 (10cycle)
        │                                                  │
        │                                                  v
        │                                    AXI GPIO ch1 输入 → ip2intc_irpt
        │                                                  │
        │                                                  v
        │                                    ARM axiGpio0_Handler:
        │                                      TxSetup + SendPacket
        │                                      MCDMA 开始从 0x30000000 搬运
        v
  等待 event_0 中断 → PC 收到结果通知
```

**说明：** 不再使用 DDR 地址 `0x7FFFF000` 轮询计数。PC 写完图像数据后通过 XDMA user 通道写 h2c_intr IP 的寄存器，IP 检测变化后直接触发 AXI GPIO 中断通知 ARM 启动 MCDMA 传输。

### 4.2 FPGA 处理流水线：MCDMA 切片 → 光斑提取 → DataMover 回写 DDR

图像经 H2C 写入 DDR @ 0x30000000 后，FPGA 内部通过 MCDMA 将数据切片读出，
经 Frame_Arbiter 汇聚后送入 lsp_debug 进行光斑位置提取，结果通过 result_tranfer
(DataMover S2MM) 回写 DDR，最终由 PC 通过 C2H 读回。

**图像切分参数：**
- 图像总尺寸：7680 (宽) × 5820 (高)，每像素 4 bytes (BGRA)
- MCDMA 10 通道 MM2S，每通道负责 582 行 × 7680 列
- 582 × 10 = 5820 行（完整图像高度）

```
                          ┌──────────────────────────────────────────┐
                          │         FPGA 处理流水线                   │
                          │                                          │
  DDR @ 0x30000000        │  ┌─────────────┐                        │
  (PC写入的原始图像)       │  │   MCDMA      │  10ch MM2S            │
      │                   │  │   (10通道)    │  256-bit @ 200MHz   │
      │                   │  │   burst=32   │                        │
      │                   │  └──┬──┬──┬──┬──┘                        │
      │                   │     │  │  │..│  每通道 582行             │
      │                   │     v  v  v  v                           │
      │                   │  ┌─────────────────┐                     │
      │                   │  │ Frame_Arbiter   │  10→1 通道汇聚      │
      │                   │  │ (channel_num=10)│                     │
      │                   │  └────────┬────────┘                     │
      │                   │           │ data_n, data_valid_n         │
      │                   │           │ CCLC_ready (反压)            │
      │                   │           v                              │
      │                   │  ┌─────────────────┐                     │
      │                   │  │   lsp_debug     │  光斑位置提取        │
      │                   │  │ W=7680 H=582    │                     │
      │                   │  │ merge_num=10    │                     │
      │                   │  └────────┬────────┘                     │
      │                   │           │                              │
      │                   │           │ data_o (80bit 光斑结果)      │
      │                   │           │ data_valid_o                 │
      │                   │           │ end_flag (帧处理完成)        │
      │                   │           v                              │
      │                   │  ┌─────────────────────────────────┐    │
      │                   │  │       result_tranfer             │    │
      │                   │  │  ┌──────────┐  ┌─────────────┐  │    │
      │                   │  │  │ FIFO     │  │dma_s2mm_cmd  │  │    │
      │                   │  │  │ 80b×128  │  │  (命令生成)  │  │    │
      │                   │  │  │ BRAM     │  └──────┬──────┘  │    │
      │                   │  │  └────┬─────┘         │         │    │
      │                   │  │       │               │         │    │
      │                   │  │       v               v         │    │
      │                   │  │  ┌─────────────────────────┐   │    │
      │                   │  │  │     fifo2axis           │   │    │
      │                   │  │  │  FIFO → AXI-Stream      │   │    │
      │                   │  │  │  128-bit TDATA+TKEEP    │   │    │
      │                   │  │  └───────────┬─────────────┘   │    │
      │                   │  │              │ S_AXIS_S2MM     │    │
      │                   │  │              v                  │    │
      │                   │  │  ┌─────────────────────────┐   │    │
      │                   │  │  │   AXI DataMover (S2MM)  │   │    │
      │                   │  │  │   128-bit, burst=32     │   │    │
      │                   │  │  │   BTT=23bit             │   │    │
      │                   │  │  └───────────┬─────────────┘   │    │
      │                   │  │              │ M_AXI_S2MM       │    │
      │                   │  └──────────────┼─────────────────┘    │
      │                   │                 │                      │
      │                   │  ┌──────────────┼─────────────────┐    │
      │                   │  │   monitor_0  │                  │    │
      │                   │  │  count_1~5   │ 统计各通道结果数  │    │
      │                   │  │  result_cnt  │ 结果计数          │    │
      │                   │  └──────────────┘                  │    │
      │                   │                                    │    │
      └───────────────────┼────────────────────────────────────┘    │
                          │                                         │
                          │ M_AXI_S2MM (128-bit AXI-MM)             │
                          │ 经 axi_interconnect_1 → HP1_FPD         │
                          v                                         │
                    DDR (结果数据区)                                 │
                          │                                         │
                          │ PC C2H 读回                              │
                          v                                         │
                    PC ImageLoop                                    │
```

### 4.3 FPGA → PC 结果回读（C2H）

```
PC ImageLoop
  │
  └─ pcie_fun.c: c2h_transfer(结果地址, size, buffer)
        │
        │ ReadFile(h_c2h0, address, buffer)
        v
  XDMA c2h_0 (AXI-MM) ←─ axi_smc ←─ HP2_FPD ←─ DDR (光斑结果数据)
        │
        v
  PC 端解析光斑位置 / 统计信息

### 4.4 FPGA → PC 中断通知

```
外部 FPGA 逻辑
  │
  ├─ data_en + data[31:0] (结果计数)
  │
  v
h2c_intr IP (ip.v)
  ├─ 2级同步 data_en 到 S_AXI_ACLK 域
  ├─ 上升沿检测: data_en_sync1 && !data_en_d1
  ├─ captured_data <= data (内部捕获)
  └─ xdma_irq_req 脉冲 (10cycle)
        │
        v
XDMA usr_irq_req[0] ──MSI──> PC
        │
        v
PC event_0 ReadFile 阻塞返回 → 读 captured_data 获取结果计数
```

### 4.5 工业相机直连采集（待集成）

当前图像源为 PC 本地 BMP/BIN 文件。计划将 IKapLibrary 工业相机 SDK 集成至 ImageLoop，实现相机实时采集 → PCIe DMA 直传 FPGA，消除文件 I/O 环节。

**目标架构：**

```
工业相机                   Qt ImageLoop (改造后)
   │                           │
   │  SDK 回调                  │
   └──→ cbOnEndOfFrame() ──→ g_bufferData 就绪
                                   │
                                   ├─→ WriteFile(h_h2c0, 0x30000000, g_bufferData, size)
                                   └─→ WriteFile(h_user, 0x00, frameCount)
```

**图像格式匹配：**

| 相机输出格式 | FPGA CCLC 输入 | 转换需求 |
|---|---|---|
| **Mono8** (推荐) | 8-bit 灰度 | 零转换，直传 |
| BayerRG8 | 需 debayer → BGRA | `ItkBufferConvert` 或 CPU 侧处理 |
| RGB8/BGR8 | 32-bit BGRA | SDK 内转换或软件转 |

推荐相机设为 **Mono8** 模式，数据格式与 CCLC 输入天然对齐，带宽效率最高。

**关键技术点：**

| 项目 | 说明 |
|---|---|
| SDK 初始化 | `ItkManInitialize()` → `ItkManGetDeviceCount()` → `ConfigureCamera()` |
| 数据获取 | 注册 `cbOnEndOfFrame` 回调，`ItkBufferRead()` 读到 `g_bufferData` |
| Qt 集成 | 回调线程直接调 `h2c_transfer()` + `write_device(h_user)`，替代文件对话框 |
| 线程安全 | 回调线程与 Qt 主线程共享 PCIe 设备句柄需加锁 |
| 格式转换 | 去掉 `rwif_bmp.c` 的 BMP 解析逻辑，改为 SDK 原生格式 |

**吞吐量匹配：**

| 环节 | 速率 | 说明 |
|---|---|---|
| 相机输出 | 取决于型号 (如 25MP@30fps ≈ 750 MB/s) | 选型需匹配 |
| H2C 传输 (x2) | ~1.5 GB/s | 50MB/帧 ≈ 33 ms |
| CCLC 处理 | 500M 像素/s ≈ 500 MB/s (Mono8) | 50MP ≈ 100 ms |
| DDR 带宽 | 19.2 GB/s | 非瓶颈 |

相机 50MP Mono8 ≈ 50 MB/帧，全链路帧率由 CCLC 处理端决定（~10 FPS），非传输端。

---

## 5. 模块规格

### 5.1 Vivado Block Design — 关键 IP

| IP 名称 | 类型 | 功能 |
|---|---|---|
| `design_1_xdma_0_0` | XDMA v4.1 | PCIe DMA 引擎，m_axil (user通道), H2C/C2H AXI-MM |
| `design_1_axi_mcdma_0_0` | AXI MCDMA v1.1 | 10通道 MM2S，256-bit 数据宽度，burst=32 |
| `design_1_zynq_ultra_ps_e_0_0` | Zynq US+ PS v3.3 | ARM Cortex-A53, GIC, DDR4-2400, UART0 |
| `design_1_axi_gpio_0_0` | AXI GPIO v2.0 | 双通道，ch1=1bit输入(end_flag), ch2=1bit输出(clear) |
| `design_1_Frame_Arbiter_0_0` | 自定义 v1.0 | 10通道 MCDMA 流汇聚 (channel_num=10) |
| `design_1_lsp_debug_0_0` | 自定义 v1.0 | 光斑位置提取，W=7680, H=582, merge_num=10 |
| `design_1_result_tranfer_0_0` | 子模块组 | 结果数据回写 DDR（见下方子模块表） |
| `h2c_intr IP` | 自定义 AXI-Lite | PC 写计数检测 + 外部 data 捕获 (ip.v) |

**result_tranfer 子模块：**

| 子模块 | 类型 | 功能 |
|---|---|---|
| `fifo_generator_0` | FIFO Gen v13.2 | 80bit×128深度 BRAM FIFO (First-Word-Fall-Through) |
| `fifo2axis_0` | 自定义 | FIFO 读控制 → AXI-Stream，128-bit TDATA+TKEEP+TLAST |
| `dma_s2mm_cmd_0` | 自定义 | DataMover S2MM 命令生成 (TAG=0x0001) |
| `axi_datamover_0` | DataMover v5.1 | S2MM 方向，128-bit 数据宽度，burst=32，BTT=23bit |
| `monitor_0` | 自定义 | 结果统计：count_1~5 (28bit), result_cnt1~2 (16bit) |
| `util_vector_logic_0` | Util Vector Logic | NOT 门，rst_n 反相后驱动 FIFO srst |

**处理流水线关键参数：**

| 参数 | 值 | 说明 |
|---|---|---|
| 图像尺寸 | 7680×5820 px | 每像素 4 bytes (BGRA)，约 171 MB/帧 |
| MCDMA 通道数 | 10 | 每通道 582 行，并行切片读取 |
| MCDMA 数据宽度 | 256-bit | 每拍 8 像素 |
| MCDMA burst | 32 | 单次 burst 传输 32×256bit = 1KB |
| lsp_debug 输入 | 80-bit 并行数据 | 从 Frame_Arbiter 接收 |
| lsp_debug 输出 | 80-bit 光斑坐标 | 写入 result_tranfer FIFO |
| FIFO 位宽 | 80-bit | 匹配 lsp_debug 输出 |
| DataMover 位宽 | 128-bit | S2MM AXI-Stream → AXI-MM 写 DDR |
| 处理时钟 | 200 MHz | pl_clk0，全流水线同步 |

### 5.2 Frame_Arbiter IP — 数据流通道分路

**端口：**

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `MM2S_tdata` | input | 256 | MCDMA 输入数据 |
| `MM2S_tvalid` | input | 1 | 输入有效 |
| `MM2S_tdest` | input | 4 | 通道标识 (0~9)，MCDMA 输出时携带 |
| `MM2S_tready` | output | 1 | 反压信号，对应通道 FIFO 满时拉低 |
| `CCLC_ready` | input | 10 | lsp_debug 各 CCLC 实例的接收就绪 |
| `data_valid_n` | output | 10 | 各通道输出有效 |
| `data_n` | output | 10×8 | 各通道 8-bit 灰度像素 |
| `data_count` | output | 10×11 | 各通道 FIFO 数据量 (调试用) |

**参数：**

| 参数 | 值 | 说明 |
|---|---|---|
| `channel_num` | 10 | 通道数，匹配 MCDMA 通道数 |
| `data_W` | 256 | 输入数据宽度 |
| `tdest_W` | 4 | TDEST 位宽 |
| `output_W` | 8 | 输出像素位宽 (8-bit 灰度) |
| `Thres` | 16 | 噪声阈值，低于此值的像素清零 |

**工作原理：**

```
MCDMA AXIS (256b, TDEST=0~9)
       │
       v
  TDEST 解码 → dest_decode[TDEST] = 1
       │
       ├─→ FIFO_0 (TDEST=0) ─→ 256→8bit 位宽转换 ─→ [阈值过滤: <16→0] ─→ data_n[0]
       ├─→ FIFO_1 (TDEST=1) ─→ 256→8bit 位宽转换 ─→ [阈值过滤]        ─→ data_n[1]
       ├─→ ...
       └─→ FIFO_9 (TDEST=9) ─→ 256→8bit 位宽转换 ─→ [阈值过滤]        ─→ data_n[9]
                                                                         │
                                                                         v
                                                                   lsp_debug
                                                                  (10 CCLC 实例)
```

每个通道内部：FIFO 缓冲 MCDMA 的 256-bit 突发数据 → `axis_dwidth_converter` 将 256-bit 转换为 8-bit 逐像素输出 → 阈值比较器将低于 16 的暗像素清零 → 10 路 8-bit 像素并行送入 lsp_debug。

### 5.3 lsp_debug IP — 光斑定位 (Connected Component Labeling & Characterization)

**顶层模块：** `light_spot_positioning`  
**核心算法：** CCLC2_0 (Connected Component Labeling and Characterization)

**端口：**

| 端口 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| `data_valid_i` | input | 10 | 10 通道输入有效 (来自 Frame_Arbiter) |
| `data_i` | input | 10×8 | 10 通道 8-bit 灰度像素 |
| `ready_o` | output | 10 | 反压信号，连 Frame_Arbiter CCLC_ready |
| `data_valid_o` | output | 1 | 结果输出有效 |
| `data_o` | output | 80 | 光斑结果 |
| `end_flag` | output | 1 | 帧处理完成标志 → AXI GPIO → ARM 中断 |

**参数：**

| 参数 | 值 | 说明 |
|---|---|---|
| `Width` | 7680 | 图像宽度 (列) |
| `Height` | 582 | 每个 CCLC 处理的行数 (×10=5820) |
| `merge_num` | 10 | CCLC 实例数 |
| `Data_W` | 8 | 输入像素位宽 |
| `X_weight_W` | 28 | X 方向灰度加权累加器位宽 |
| `Y_weight_W` | 28 | Y 方向灰度加权累加器位宽 |
| `Gray_W` | 14 | 灰度累加器位宽 |
| `count_W` | 10 | 像素计数位宽 |
| `Output_data_W` | 80 | 输出结果位宽 |

**模块层次：**

```
light_spot_positioning (top)
├── CCLC2_0 × 10         ← 每通道一个 CCLC 实例, ROW_start = i×582
├── merge_output          ← 跨通道拼接: 缝合 split blob
└── point_output          ← 11路 FIFO 优先级仲裁输出
```

**CCLC2_0 核心算法 — 4 并行状态机 (全流水线, 1 像素/周期):**

| 状态机 | 状态数 | 功能 |
|---|---|---|
| `state_cell` | 2 | 游程检测: 3 级数据打拍, 判断亮像素段的 start/middle/end |
| `state_merge` | 6 | 连通域合并: 通过 FIFO 读取上一行段信息, 判断上下行连通性 |
| `state_cell_process` | 4 | FIFO 写入: 合并后的段质心累加值写入 FIFO |
| `state_blk` | 5 | BRAM 管理: 跨切片 blob 数据存储/更新/读取 |

**数据通路 (单 CCLC):**

```
pixel_in(8b) ─┬─→ DSP48(mult_x): data × col → x_weight(28b)
               └─→ DSP48(mult_y): data × row → y_weight(28b)

游程检测: (data_3, data_2) → 起点/中间/终点判断
  ├─ 起点: 初始化 cell_x_weight, cell_y_weight, cell_weight, cell_count, cell_length, start_x
  ├─ 中间: 累加 Σx_weight, Σy_weight, Σgray, count++
  └─ 终点: cells_end_pulse → 段结束, 数据送入 cell_process

cell_process:
  ├─ 段长度 ≤ 1 → 丢弃
  ├─ 连续段之间间距 ≤ 2 → 合并累加值
  └─ 写入 FIFO → state_merge 读取

state_merge (FIFO 读出端):
  ├─ 当前列 == 上一行段结束列 → cells_merge 判断连通性
  ├─ 连通 → 累加合并, 更新 temp_summary
  ├─ 不连通且 count > 3 → 输出结果 (80-bit)
  ├─ 跨切片拼接 → BRAM 暂存 bit 含 merge_cnt 标记
  └─ 帧末 → last_fifo 清空剩余数据
```

**80-bit 输出格式：**

| 字段 | 位宽 | 说明 |
|---|---|---|
| X_weight | 28 | Σ(x × gray)，所有亮像素的列加权和 |
| Y_weight | 28 | Σ(y × gray)，行加权和 |
| Gray | 14 | Σ(gray)，灰度总和 |
| count | 10 | 像素计数 |

PC 端计算质心：`x_center = X_weight / Gray`, `y_center = Y_weight / Gray`

**merge_output — 跨切片拼接：**

10 个图像切片边界处的光斑被截断，需跨通道拼接。merge_output 通过 BRAM 存储各 CCLC 的 split blob 信息，逐对上/下切片比对：
- 上切片 blob: x1 = start_x, x2 = start_x + length
- 下切片 blob: x3 = start_x, x4 = start_x + length
- `x1 < x4 且 x3 < x2` → 重叠 → 累加值合并
- 无重叠的 blob → 直接输出

**point_output — 优先级仲裁输出：**

11 个 FIFO (10 CCLC + 1 merge)，带优先级编码器。索引越小的 CCLC 优先级越高。`end_flag` = 所有 FIFO 空 且 frame_end_flag 传播完成 → 拉高通知 ARM 帧处理完成。

### 5.4 h2c_intr IP (ip.v) — 寄存器映射

**端口：**

| 端口 | 方向 | 说明 |
|---|---|---|
| `S_AXI_*` | 标准 AXI4-Lite Slave | 连接 XDMA m_axil (通过 Interconnect) + PS M_AXI_HPM |
| `trigger_out` | output | PC 写 slv_reg0 写入值 ≠ tracked_val → 10cycle 脉冲 → AXI GPIO ch1 输入 |
| `data_en` | input | 外部数据有效标志 |
| `data[31:0]` | input | 外部结果计数 |
| `xdma_irq_req` | output | 数据捕获 → 10cycle 脉冲 → XDMA usr_irq_req[0] → MSI → PC |

**寄存器：**

| 寄存器 | 偏移 | 方向 | 描述 |
|---|---|---|---|
| `slv_reg0` | 0x00 | PC 写 | 图像计数 (0-6 循环)，变化时触发 trigger_out |
| `slv_reg1` | 0x04 | R/W | 标准 AXI 可写寄存器 |
| `slv_reg2` | 0x08 | R/W | 标准 AXI 可写寄存器 |
| `slv_reg3` | 0x0C | R/W | 备用 |

### 5.5 Vitis 裸机程序 (dma_da.c)

**内存映射：**
- `0x20000000` - `0x3FFFFFFF`：Non-Cacheable，MCDMA 图像源数据区域
- `TX_BUFFER_BASE = DDR_BASE + 0x30000000`：MCDMA 发送缓存（指向原始图像）
- ~~`IMAGE_COUNT_ADDR = 0x7FFFF000`~~（已废弃，由 h2c_intr IP + AXI GPIO 中断替代）

**初始化流程：**
1. GPIO 配置 + 中断注册 (`gpio_conf`) —— 接收 h2c_intr IP 的 trigger_out
2. DDR 区域 TLB 属性设置 (Non-Cacheable)
3. MCDMA 初始化 + BD 链表创建 (`TxSetup`)
4. 等待 GPIO 中断触发首次 DMA 传输

**中断处理 (`axiGpio0_Handler`)：**
- h2c_intr 触发（图像就绪）→ TxSetup + SendPacket 启动 MCDMA
- lsp_debug end_flag（帧处理完成）→ 重新 TxSetup + Invalidate + SendPacket

**与旧方案的区别：** 不再使用 `CheckImageWritten()` 轮询 `0x7FFFF000`，改为中断驱动——PC 写 h2c_intr 寄存器直接触发 GPIO 中断，ARM 收到后立即启动 MCDMA。

### 5.6 PC 驱动接口

**XDMA 驱动设备节点：**

| 节点 | 访问方式 | 用途 |
|---|---|---|
| `\user` | ReadFile/WriteFile | AXI-Lite 总线访问，控制 h2c_intr IP 寄存器 |
| `\h2c_0` | WriteFile | H2C DMA，PC→FPGA 数据传输 |
| `\c2h_0` | ReadFile | C2H DMA，FPGA→PC 数据回读 |
| `\event_0` | ReadFile (阻塞) | FPGA→PC 中断接收 (#0) |
| `\event_1` - `\event_15` | ReadFile (阻塞) | 备用中断 |

**user 通道寄存器操作（通过 h2c_intr IP）：**

| 偏移 | 操作 | 说明 |
|---|---|---|
| 0x00 | Write | 写 slv_reg0 (任意变化值)，触发 trigger_out → GPIO 中断 → ARM 启动 MCDMA |
| 0x04 | Write | 写 XDMA 中断使能 (0x00010000 = 使能 event_0) |
| 0x08 | Read | 读 user 通道对应偏移 (结果计数需另定义路径) |
|

### 5.7 Qt 上位机 (ImageLoop)

**文件：**
- `mainwindow.cpp/h/ui`：主界面，发送区 + 接收区
- `pcie_fun.c/h`：XDMA 驱动接口封装
- `rwif_bmp.c/h`：BMP/BIN 文件读写
- `xdma_public.h`：XDMA 驱动 GUID 和设备路径定义

**按钮：**
- "图片下载"：选择 BMP/BIN → h2c_transfer(0x30000000) → write_device(h_user, 0x00, count)
- "图片读取"：c2h_transfer(0x30000000) → QImage 显示
- "清除画面" ×2：清空 label1/label2

---

## 6. 中断通路汇总

```
中断方向 1: PC 写 h2c_intr → GPIO → ARM (启动 MCDMA)
========================================================
PC: WriteFile(h_user, 0x00, data)
    │
    v
XDMA: m_axil 写事务 → h2c_intr IP S_AXI
    │
    v
ip.v: slv_reg0 变化 → trigger_out (10cycle 脉冲)
    │
    v
AXI GPIO ch1 输入 → ip2intc_irpt → pl_ps_irq0 → GIC → ARM axiGpio0_Handler
    │
    v
ARM: TxSetup + SendPacket (MCDMA 从 0x30000000 开始搬运)

中断方向 2: lsp_debug 帧结束 → GPIO → ARM (处理完成)
=======================================================
lsp_debug: end_flag 拉高
    │
    v
AXI GPIO ch1 输入 → ip2intc_irpt → pl_ps_irq0 → GIC → ARM axiGpio0_Handler
    │
    v
ARM: 重新 TxSetup + Invalidate + SendPacket (准备下一帧)

中断方向 3: FPGA 结果计数 → PC (新增，待集成)
=============================================
FPGA: data_en + data → ip.v 捕获 → xdma_irq_req 脉冲
    │
    v
XDMA: usr_irq_req[0] → MSI → Windows Kernel
    │
    v
PC: event_0 ReadFile 阻塞返回 → 读 user 0x08 (slv_reg2) 获取结果计数
```

**注：** 方向 1 和方向 2 共享 AXI GPIO ch1（均为 1-bit 输入），当前 GPIO_WIDTH=1。若两个中断源同时存在需扩展 GPIO 宽度为 2 或使用独立 GPIO IP。

---

## 7. 未来发展规划

### 7.1 架构升级：相机直连 + 多级流水线

**目标架构：**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PC 端 (Qt ImageLoop)                            │
│                                                                         │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐  │
│  │  相机采集模块      │    │  PCIe 传输控制     │    │  结果处理模块      │  │
│  │  ├─ IKapLibrary   │    │  ├─ H2C 下发      │    │  ├─ C2H 读回      │  │
│  │  ├─ 帧就绪回调     │───→│  ├─ h2c_intr 通知  │    │  ├─ 光斑数校验     │  │
│  │  └─ 帧缓存池(3帧)  │    │  └─ event_0 等待   │←───│  └─ 质心叠加显示   │  │
│  └──────────────────┘    └────────┬───────────┘    └──────────────────┘  │
│                                   │                                      │
│                     Qt 主线程      │      工作线程                        │
│                     (UI 控制)      │      (DMA 传输)                      │
│                     启动/停止      │      收发双向                        │
└───────────────────────────────────┼──────────────────────────────────────┘
                                    │  PCIe Gen3
┌───────────────────────────────────┼──────────────────────────────────────┐
│                         FPGA 端 (ZU4EV)                                  │
│                                   │                                      │
│  ┌────────────────────────────────┼──────────────────────────────────┐  │
│  │                          DDR4 多级缓冲                             │  │
│  │                                                                    │  │
│  │   图像缓冲池                      结果缓冲池                        │  │
│  │  ┌─────────┬─────────┐          ┌─────────┬─────────┐             │  │
│  │  │ Buf_0   │ Buf_1   │          │ Res_0   │ Res_1   │             │  │
│  │  │ (写入中) │ (处理中) │          │ (处理中) │ (读出中) │             │  │
│  │  └─────────┴─────────┘          └─────────┴─────────┘             │  │
│  │       ↑         │                     ↑         │                  │  │
│  │    H2C DMA    MCDMA              DataMover   C2H DMA              │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  处理流水线: MCDMA → Frame_Arbiter → lsp_debug → result_tranfer         │
│                                                                         │
│  ARM (dma_da.c): 帧序号追踪, 缓冲管理, 中断路由                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Qt 端功能模块

| 模块 | 功能 | 说明 |
|---|---|---|
| **相机采集** | IKapLibrary SDK 集成 | 枚举/打开/配置/启停相机，回调接收帧数据 |
| **帧缓存池** | 3 帧环形缓冲 (Qt 侧) | 一帧采集、一帧 H2C 传输中、一帧等待覆盖，避免丢帧 |
| **传输控制** | H2C 下发 + 中断通知 | 帧就绪 → H2C DMA → write_device(h_user) 触发 ARM |
| **中断接收** | event_0 阻塞监听 | 独立线程等待 FPGA → PC 中断 |
| **结果回读** | C2H DMA | 中断到达 → 自动 c2h_transfer 读取光斑结果 |
| **结果校验** | 基础检测 | 光斑数量范围校验、质心坐标合法性检查、处理超时告警 |
| **结果显示** | 叠加显示 | 原始图像叠加光斑标记、统计信息面板 |
| **启停控制** | UI 按钮 | 一键启动采集→传输→处理流水线，一键停止 |

### 7.3 FPGA 端多级缓冲流水线

**乒乓缓冲策略（图像端）：**

```
帧 N:    PC H2C → Buffer_0 → MCDMA 读 Buffer_0 → 处理 → 结果写 Res_0
         ARM 收到 h2c_intr → 启动 Buffer_0 的 MCDMA 传输
         
帧 N+1:  PC H2C → Buffer_1 → MCDMA 读 Buffer_1 → 处理 → 结果写 Res_1
         (Buffer_0 正在处理中, Buffer_1 接收新帧)

帧 N+2:  Buffer_0 已处理完毕, Res_0 已回读 → Buffer_0 可接收
```

**乒乓缓冲策略（结果端）：**

```
帧 N:    DataMover → Res_0 → PC C2H 读 Res_0
         同时 DataMover → Res_1 → (下一帧结果写入)
```

**DDR 地址规划：**

| 地址区间 | 大小 | 用途 |
|---|---|---|
| `0x3000_0000` - `0x30FF_FFFF` | 16 MB | 图像 Buffer_0 |
| `0x3100_0000` - `0x31FF_FFFF` | 16 MB | 图像 Buffer_1 |
| `0x0100_0000` - `0x01FF_FFFF` | 16 MB | 结果 Res_0 |
| `0x0200_0000` - `0x02FF_FFFF` | 16 MB | 结果 Res_1 |

**ARM 缓冲管理逻辑（dma_da.c 升级）：**

```
中断处理流程:
  axiGpio0_Handler:
    ├─ 读取 h2c_intr 寄存器 → 确认新帧就绪
    ├─ 判断当前活跃 Buffer (乒乓切换)
    ├─ TxSetup 指向活跃 Buffer 的 MCDMA BD
    ├─ SendPacket 启动 DMA
    ├─ 帧序号写入 slv_reg3 (供 PC 对账)
    └─ 等待 end_flag → 结果写入对应 Res Buffer → 触发 xdma_irq_req
```

### 7.4 带宽演进路线

```
当前:   PCIe Gen3 x2  ── 1.5 GB/s ── 2 通道 DMA ── 文件→H2C
        (XCZU4EV, 单帧串行)

Phase1: PCIe Gen3 x2  ── 1.5 GB/s ── 相机→H2C ── 乒乓 Buffer
        (零文件 I/O, 采集与传输重叠, 帧率提升 30%)

Phase2: PCIe Gen3 x4  ── 3.2 GB/s ── 4+4 通道 DMA ── 全流水线
        (XCZU4EV 满带宽, 采集/传输/处理/回读 4 阶段流水, 帧率翻倍)

Phase3: PCIe Gen3 x8  ── 6.3 GB/s ── 需更换更大器件
  或    PCIe Gen4 x4  ── 6.5 GB/s ── (ZU7EV / Kintex US+)
        (多路视频流并行, 实时处理)
```

### 7.5 其他优化

- [ ] **中断聚合**：多帧完成后统一通知 PC，减少 MSI 次数
- [ ] **帧序号追踪**：H2C 携带 frame_id，结果带 frame_id 回传，PC 端校验匹配
- [ ] **错误恢复**：超时未收到 end_flag → ARM 复位 MCDMA → 丢弃当前帧 → 通知 PC 重传
- [ ] **ILA 调试**：关键路径插入 ILA 核，板级信号验证
- [ ] **Linux 主机支持**：移植驱动到 Linux XDMA 驱动框架 + IKapLibrary Linux SDK
- [ ] **HLS 加速**：后续算法迭代用 Vitis HLS 实现，直接替换 lsp_debug 模块
- [ ] **持续集成**：Vivado 脚本化构建，自动化仿真验证

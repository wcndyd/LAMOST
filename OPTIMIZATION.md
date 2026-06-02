# 面试技术分析：STA / PPA 优化 / 低功耗设计

---

## 1. 静态时序分析 (STA)

### 1.0 前置概念

**什么是 STA：** 不做功能仿真，仅分析电路中所有寄存器到寄存器路径的延迟是否满足时钟约束。对于同步电路，只需确保每条路径的传播延迟 < 时钟周期，电路就能正确工作。

**两个核心检查：**

```
Setup (建立时间): 数据必须在时钟有效沿"之前"稳定
  data_arrival = T_clk_launch + T_clk2q + T_logic + T_routing
  data_required = T_clk_capture + T_period - T_setup - T_skew
  条件: data_arrival < data_required
  违反后果: 寄存器采样到错误值

Hold (保持时间): 数据在时钟有效沿"之后"必须维持足够久
  data_removal = T_clk_launch + T_clk2q + T_logic_min
  data_required = T_clk_capture + T_hold + T_skew
  条件: data_removal > data_required
  违反后果: 新数据太快覆盖旧数据，寄存器采样不确定
```

**Slack (时序余量):** `Slack = data_required - data_arrival`，正值 = 通过，负值 = 违规。

---

### 1.0a 补充：LUT 内部结构 & "LUT 级数" 含义

FPGA 的组合逻辑由 LUT（Look-Up Table，查找表）实现。理解 LUT 结构是分析时序路径延迟的基础。

**LUT 本质上是一块微型 SRAM + 多路选择器：**

```
UltraScale+ LUT6 内部结构:

        6 个输入信号 (A0~A5) 作为地址线
        ───────────────────────→
                                │
  SRAM 阵列 (2^6 = 64 bit)     │
  ┌──┐                         │
  │0 │                         │
  │1 │                         │
  │..│──→ 64选1 多路选择器 ←──┘
  │62│           │
  │63│           v
  └──┘         输出 F(A0..A5)
```

真值表预写入 64 位 SRAM，6 个输入信号组合作为地址去查表，查到的值就是逻辑输出。例如 `F = A & B & C`：
```
A B C | F      SRAM地址 | SRAM值
0 0 0 | 0        0    |   0
0 0 1 | 0        1    |   0
0 1 0 | 0        2    |   0
0 1 1 | 0        ...  |  ...
1 0 0 | 0        6    |   0
1 1 0 | 0        7    |   1  ← 只有 ABC 全为 1 时输出 1
1 1 1 | 1
```
任意 6 输入布尔函数都能通过预填这 64 个 SRAM 值实现，延迟固定（与功能复杂度无关）。

**什么是 "LUT X 级"（组合逻辑深度）：**

指信号从一个寄存器 Q 端出发，**串联经过多少个 LUT** 才到达下一个寄存器 D 端。每穿过一个 LUT 就是"1 级组合逻辑"。

```
1 级 LUT (最浅):
  ┌──────┐         ┌─────┐         ┌──────┐
  │ reg_A│────────→│LUT1 │────────→│ reg_B│
  │  Q   │  ───    │     │   ───   │  D   │
  └──────┘ routing  └─────┘ routing └──────┘
  延迟: T_clk2q + T_LUT + T_routing + T_setup
       ≈ 0.3 + 0.8 + 0.3 + 0.2 = 1.6 ns  ✓ 任意频率都能过

3 级 LUT (中等):
  ┌──────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌──────┐
  │ reg_A│───→│LUT1 │───→│LUT2 │───→│LUT3 │───→│ reg_B│
  │  Q   │    │     │    │     │    │     │    │  D   │
  └──────┘    └─────┘    └─────┘    └─────┘    └──────┘
  延迟: 0.3 + 3×0.8 + 3×0.3 + 0.2 = 3.8 ns
  在 200 MHz (5 ns) 下 Slack = 1.2 ns ✓
  在 300 MHz (3.33 ns) 下 Slack = 3.33 - 3.8 = -0.47 ns ✗ 违规!

5 级 LUT (深):
  延迟: 0.3 + 5×0.8 + 5×0.3 + 0.2 = 5.8 ns
  在 200 MHz 下已经违规! 必须插入流水寄存器打断。
```

**关键理解：** LUT 级数 ≠ 逻辑复杂度。100 个输入的 AND 和 6 个输入的 AND，如果都用同一个 LUT6 实现，延迟一样。LUT 级数只取决于"必须串联几个 LUT 才能算出结果"。设计中要避免的是一直串联下去（一个 LUT 的输出做另一个 LUT 的输入……），而不是避免用很多 LUT 做并行计算。

**本项目中的具体体现：**

```
Frame_Arbiter TDEST 解码路径 (3 级 LUT):
  TDEST[3:0] ─→ LUT1(4-10译码) ─→ LUT2(多路选择tready) ─→ LUT3(wr_en门控) ─→ FIFO

merge_output 比较器路径 (最深 ~5 级 LUT + CARRY8):
  blk_in_n ─→ LUT1(计算x2) ─→ LUT2+LUT3(13b比较x1<x4) ─→ LUT4(AND重叠) ─→ CARRY8(80b加法)
  5 级是 200 MHz 下的边界线，再深就必须流水化。
```

**面试话术：** "FPGA 的 LUT6 本质上是一块 64 位 SRAM 查表器，无论实现多复杂的 6 输入函数延迟都一样—约 0.8 ns。我评估时序时关注的是'组合逻辑级数'即寄存器之间串联了多少个 LUT。在本项目的 200 MHz 域 (5 ns)，经验法则是组合逻辑不超过 5 级 LUT；在 300 MHz 域 (3.33 ns)，不超过 2~3 级。merge_output 的比较器链是我最关注的路径——x2 计算 + 重叠判断 + 合并加法，刚好卡在 5 级边界。若布局后 net delay 偏大，首选修法是拆成两级流水。"

---

### 1.1 本项目 3 个时钟域

| 时钟域 | 频率 | 周期 | 来源 | 覆盖模块 |
|---|---|---|---|---|
| pl_clk0 | 200 MHz | **5.0 ns** | IOPLL (1800/9) | MCDMA, Frame_Arbiter, CCLC ×10, result_tranfer |
| pl_clk1 | 300 MHz | **3.33 ns** | IOPLL (1800/6) | HP0/HP1 AXI Interconnect |
| axi_aclk | 250 MHz | **4.0 ns** | XDMA 内部 | XDMA DMA 通道, HP2, HPC0 |

**异步域边界：** pl_clk0 ↔ pl_clk1、axi_aclk ↔ pl_clk1、外部 data_en ↔ pl_clk0。异步域之间的路径需要特殊处理（CDC），不能用普通 STA 约束。

---

### 1.2 时序路径拆解

**路径本质：** 每一条时序路径 = 一个寄存器输出(Q端) → 经过组合逻辑 → 到达另一个寄存器输入(D端)。STA 检查这段旅程能不能在时钟周期内完成。

#### 路径 A：MCDMA → Frame_Arbiter TDEST 解码 (pl_clk0, 5 ns)

这条路径从 MCDMA 的 AXIS 输出寄存器出发，经过 Frame_Arbiter 的组合逻辑，到达 FIFO 的写使能寄存器。

```
Timing Diagram (pl_clk0, 200 MHz):

  Clock    ──┬──────┬──────┬──  (周期 5 ns, 上升沿触发)
             │  T0  │  T1  │
  
  MCDMA 输出:  [tdata/tdest/tvalid 在 T0 沿之后变化]
             ←──T_clk2q──→  (寄存器时钟→输出延迟, 约 0.3 ns 对于 FF)
  
  组合逻辑链:
  ├─ dest_decode[9:0]:  4b→10b 译码       LUT 1 级  ≈ 0.8 ns
  ├─ tready 选择:       tready[tdest] 多路复用 LUT 2 级  ≈ 0.9 ns  
  ├─ wr_en 门控:        tready & tvalid & decode  LUT 3 级  ≈ 1.0 ns
  └─ FIFO wr_en D pin:  ───────── 总组合逻辑延迟 ≈ 2.7 ns ────────→
  
  到达时间: T_clk2q + T_logic = 0.3 + 2.7 = 3.33 ns
  
  FIFO wr_en 端:
  T_setup = 0.2 ns (FIFO 内部寄存器建立时间)
  
  到达要求: T_period - T_setup = 5.0 - 0.2 = 4.8 ns
  Slack = 4.8 - 3.0 = +1.8 ns  ✓  宽裕
  
  但若 MCDMA 和 Frame_Arbiter 物理距离远:
  布线延迟可能额外增加 1-2 ns → Slack 可能缩至 0 ns
```

**面试话术：** "TDEST 译码路径的关键是 4-10 译码器 + 门控逻辑共 3 级 LUT，总逻辑延迟约 2.7 ns。考虑到 UltraScale+ 的 LUT 延迟约 0.5-1.0 ns/级，在 5 ns 周期下余量约 1.8 ns。但若布局布线后 MCDMA 到 Frame_Arbiter 的 net delay 超过 1 ns，需要将译码逻辑流水线化——用一级寄存器将 dest_decode 结果打拍后再驱动 wr_en。"

---

#### 路径 B：CCLC2_0 乘加链 (pl_clk0, 5 ns)

这是最核心的数据处理路径：像素灰度和 X/Y 坐标送入 DSP48 乘法器，乘积累加后写入段信息寄存器。

```
数据流 (每像素一个时钟周期):

  pixel(8b) ─→ [data_0] ─→ [data_1] ─→ [data_2]
                    打拍1        打拍2        打拍3
                                          (与 DSP48 输出对齐)
  坐标:
  col_cnt(13b) ──────────────────────→ DSP48 mult_x
  row_cnt(13b) ──────────────────────→ DSP48 mult_y

每个 DSP48E2 内部流水:
  Stage 0: 输入寄存器  (A/B 锁存)
  Stage 1: 乘法阵列    (8b × 13b → 21b 部分积)
  Stage 2: 累加寄存器  (P = A*B, 28b 输出)
  
  DSP48 内部延迟: 约 3 个时钟周期 (已由 data_0/1/2 打拍匹配)

DSP48 输出后的组合路径:
  x_weight_accum <= x_weight + mult_x_P   (28b 加法)
  cell_x_weight  <= cell_x_weight + x_weight  (28b 加法, 可合并)
  
  28b 进位链加法器: 约 7 级 CARRY8, 每级 ≈ 0.1 ns = 0.7 ns  (UltraScale+ CARRY8 很快)

  总路径延迟: T_clk2q(0.2) + 0.7 + T_setup(0.2) = 1.1 ns
  Slack = 5.0 - 1.1 = +3.9 ns  ✓  非常宽裕 (因为 DSP48 吸收了所有重计算)
```

**面试话术：** "CCLC2_0 的乘法用 DSP48E2 硬核完成，DSP 内部自带 3 级流水，延迟约 3 个周期。RTL 中 data_0/1/2 三级打拍就是为了和 DSP 流水线对齐——当像素数据到达 state_cell 状态机时，对应的 x_weight 和 y_weight 正好从 DSP48 输出，可直接用于段累加。后续的 28b 加法器用了 UltraScale+ CARRY8 进位链，仅 0.7 ns，在 5 ns 周期下余量很大。"

---

#### 路径 C：merge_output 跨切片比较器 (pl_clk0, 5 ns)

这是整个设计组合逻辑最深的路径：从 BRAM 读出上下两个切片的 blob 数据，比较 x1, x2, x3, x4 四个 13-bit 坐标值，判断重叠关系。

```
单次合并判断的数据通路:

  BRAM 读出 (从 blk_in_n 端口):
  ├─ blk_in_n[BLK_W*(i-1)+:COL_W]           → x1 (上切片 blob 起始列, 13b)
  ├─ blk_in_n[BLK_W*(i-1)+COL_W+:length_W]   → x2_len (上切片 blob 长度, 6b)
  ├─ blk_in_n[BLK_W*i+:COL_W]                → x4 (下切片 blob 起始列, 13b)
  └─ blk_in_n[BLK_W*i+COL_W+:length_W]       → x4_len (下切片 blob 长度, 6b)
  
  x2 = x1 + x2_len  (13b+6b 加法)            ≈ 0.5 ns
  x4_range = x4 + x4_len  (同)              ≈ 0.5 ns
  
  重叠判断 (3 级逻辑):
  cond1 = x1 < x4_range  (13b 数值比较)      LUT 2级 ≈ 1.0 ns
  cond2 = x4 < x2        (13b 数值比较)      LUT 2级 ≈ 1.0 ns
  overlap = cond1 && cond2                   LUT 1级 ≈ 0.5 ns
  
  若重叠 → 合并累加值: result = blk_up[80b] + blk_down[80b]
  80b 加法 (CARRY8 链)                       ≈ 1.5 ns
  
  最坏路径: 加法 + 比较 + 加法
  T_total = 0.5 + 1.0 + 1.5 = 3.33 ns
  + T_clk2q(0.2) + T_routing(0.3) = 3.5 ns
  Slack = 5.0 - 3.5 = +1.5 ns  ✓
```

**面试话术：** "merge_output 的最深组合路径经过一级加法(计算 x2)、两级比较(判断 x1<x4 && x3<x2)、再一级 80b 加法(合并累加值)，总计约 5 级 LUT + 1 条 CARRY8。在 5 ns 周期下余量约 1.5 ns。若布局后 net delay 过大，可插入一级流水打拍——将比较结果寄存后再驱动加法器，代价是 merge_output 延迟增加 1 周期，不影响吞吐。"

---

#### 路径 D：pl_clk1 域 AXI Interconnect (300 MHz, 3.33 ns — 约束最紧)

```
pl_clk1 = 300 MHz, 周期仅 3.33 ns → 这是整个设计约束最紧的域

AXI Interconnect 内部最大组合路径:
  XBar 地址译码: S_AXI_AWADDR → 从设备选择 → M_AXI_AWADDR 转发
  约 2-3 级 LUT + net delay = 1.5-2.5 ns
  
  T_clk2q(0.15) + T_logic(2.0) + T_routing(0.3) + T_setup(0.15) = 2.6 ns
  Slack = 3.0 - 2.6 = +0.4 ns  ← 紧张
  
  优化策略:
  ├─ 在 Address Editor 中减少互联层数 (减少 XBar 级联)
  ├─ 用 SmartConnect 替代 AXI Interconnect (自带流水寄存器)
  └─ Pblock 约束互联逻辑在单个 SLR 内
```

**面试话术：** "300 MHz 域是整个设计时序最紧的——3 ns 周期下仅有约 5 级 LUT 的延迟预算。好在这个域主要是 AXI Interconnect 的标准 IP，Xilinx 已经做过时序优化。我的策略是：(1) 用 SmartConnect 替代普通 Interconnect，因为 SM 内部自动插了流水寄存器；(2) 不做额外的用户逻辑挂在 pl_clk1 上；(3) 物理约束确保互联逻辑不跨 SLR。"

---

### 1.3 CDC (跨时钟域) 的 STA 处理

普通 STA 工具假设所有寄存器在同一个时钟域——对跨异步时钟域的路径，这个假设不成立，必须特殊处理。

#### 为什么 CDC 不能用普通 STA？

```
场景: 信号从 200 MHz 域 (pl_clk0) 跨到 300 MHz 域 (pl_clk1)

  pl_clk0 的 T0 沿: 信号变化
  pl_clk1 的采样沿: 时间点不确定 (两个时钟相位关系不固定)
  
  如果信号正好在 pl_clk1 采样沿附近变化 → 亚稳态
  STA 工具不知道两个时钟的相位关系 → 报告的 Slack 无意义
```

#### 本项目 CDC 处理方案：

| 跨域路径 | 信号类型 | 处理方案 | XDC 约束 |
|---|---|---|---|
| h2c_intr data_en → pl_clk0 | 单 bit | 2 级同步器 (ip.v 已实现) | `set_false_path` 告知工具跳过此路径 |
| result_tranfer → axi_interconnect_1 | 多 bit AXI 总线 | AXI Clock Converter IP (内置异步 FIFO) | `set_clock_groups -asynchronous` 声明两个域异步 |
| lsp_debug end_flag → AXI GPIO | 单 bit | GPIO IP 内部同步器 | `set_max_delay` 仅约束到 GPIO 输入 pin |
| XDMA axi_aclk → PS | AXI 总线 | PS 内部 AXI FIFO | 无需用户约束 |

#### AXI Clock Converter 详解

本项目最关键的一条 CDC 路径是 `result_tranfer` (200 MHz) → `axi_interconnect_1` (300 MHz)，需要用 Vivado 的 **AXI Clock Converter** IP 处理。

**为什么不能直连：**

```
result_tranfer                    axi_interconnect_1
  M_AXI_S2MM ─────────────────→ S01_AXI
   (pl_clk0, 200 MHz)            (pl_clk1, 300 MHz)

  直连后果:
  ├─ AXI 是同步协议 (VALID/READY 握手依赖同一时钟沿)
  ├─ 两个时钟没有固定相位关系 → 握手可能丢失
  ├─ 多 bit 数据总线 (AWADDR/WDATA/ARADDR 等) 若不经同步直接跨域
  │    → 各 bit 到达时间不同 (skew) → 目的域采样到错误值
  └─ GT 收发器也存在同样问题
```

**AXI Clock Converter 的工作原理：**

本质上是一个封装好的 **异步多 bit CDC 方案**，内部对 AXI 的 5 个通道分别处理：

```
AXI Clock Converter 内部结构 (以写地址通道 AW 为例):

   写域 (pl_clk0, 200 MHz)         读域 (pl_clk1, 300 MHz)
   ════════════════════            ════════════════════
   
   AWVALID ──────────┐
   AWADDR  ──────┐   │
   AWPROT  ───┐  │   │
              │  │   │
              v  v   v
          ┌──────────────┐      ┌──────────────────┐
          │   输入寄存器   │      │     输出寄存器     │
          │  (pl_clk0域)  │      │   (pl_clk1域)    │
          └──────┬───────┘      └────────┬─────────┘
                 │                       │
                 │     ┌───────────┐     │
                 └────→│ 异步 FIFO  │────→│
                       │ (格雷码指针) │     │
                       └───────────┘     │
                                         v
                                   AWVALID (同步后)
                                   AWADDR  (同步后)
                                   AWPROT  (同步后)
```

核心机制：

1. **写侧**：AXI 通道信号（VALID + DATA + ADDR 等）先寄存，再写入异步 FIFO
2. **跨域**：FIFO 的读/写指针用**格雷码**编码跨时钟域传递，格雷码每次只变 1 bit，即使同步器采样到旧值，也最多差 1 个位置，不会出现"读指针采样为全 0（FIFO 判空错误）"这类致命故障
3. **读侧**：从 FIFO 读出数据后驱动目的域的 AXI 信号，READY 握手通过反向通道回传

```
时序示意:

  pl_clk0 ─┬──┬──┬──┬──┬──┬──┬──  (200 MHz)
           │  │  │  │  │  │  │  │
  AWVALID  ──┐     ┌──────────      (写域有效)
             │     │
             v     v
  [FIFO写]  ──X─────X─────────      (每个有效周期写一次)
  
  pl_clk1 ─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─  (300 MHz, 周期更短)
           │ │ │ │ │ │ │ │ │ │ │
  [FIFO读] X─X─X─X─X─X─X─X─X─X─    (有空就往外读)
           │     │     │
  AWVALID  ──┐   ┌──   ┌──          (读域重建)
  (同步后)
```

**关键理解：** Clock Converter 引入 2-3 个目的时钟周期的延迟（FIFO 读写 + 同步器）。在本项目中，300 MHz 侧每周期 3.33 ns，额外延迟约 7-10 ns，对 AXI 总线吞吐影响极小。

**什么时候不需要 Clock Converter：** 如果两个域是同步整数倍关系（如 200 MHz → 400 MHz），且同源 PLL、相位对齐，Vivado 会自动识别为同步域，直连即可——工具自己会算 timing。

#### 面试演示：约束语法与含义

```tcl
# 1. 声明异步时钟组 (最重要)
set_clock_groups -asynchronous \
  -group [get_clocks pl_clk0] \
  -group [get_clocks pl_clk1] \
  -group [get_clocks axi_aclk]
# 含义: 这三组时钟之间没有固定相位关系，STA 不分析跨组路径

# 2. 对已做同步处理的单 bit 信号
set_false_path -from [get_ports data_en] -to [get_cells *data_en_sync0*]
# 含义: data_en 到第一级同步器的路径不用检查 setup/hold
#       (亚稳态概率已由同步器链控制在可接受范围)

# 3. 对慢速控制信号放宽约束
set_max_delay 10.0 -from [get_pins lsp_debug_0/end_flag_reg/Q] \
                   -to   [get_pins axi_gpio_0/gpio_io_i[*]]
# 含义: end_flag 不需要在一个周期内到达 GPIO，给 10 ns 窗口足够
```

---

### 1.4 时序收敛实战流程

```
Vivado 时序收敛步骤:

1. synth_design → report_timing_summary
   检查: 综合后 WNS (Worst Negative Slack) 是否 > -0.3 ns
   若 WNS < -0.5 ns → RTL 级别改流水

2. opt_design → place_design → phys_opt_design
   phys_opt: 自动做寄存器复制、扇出优化、LUT 等价变换

3. route_design → report_timing_summary -delay_type min_max
   检查: setup WNS > 0, hold WNS > 0

4. 若仍有违规:
   ├─ report_timing -max_paths 10 -slack_lesser_than 0
   │   (定位最差的 10 条路径)
   ├─ 在 Schematic 中 trace 物理路径, 看是否跨 SLR/跨 die
   ├─ Pblock 约束: 将起点和终点寄存器锁在同一矩形区域
   └─ 若组合逻辑太长 → 回到 RTL 插入流水寄存器

5. 最终验收标准:
   ├─ Setup WNS > 0 ns (零违规)
   ├─ Hold WNS > 0 ns (零违规)
   └─ Pulse Width WNS > 0 ns (时钟占空比检查)
```

### 1.5 面试常见追问

**Q: 为什么要用 IOPLL 而不是 RPLL？对时序有什么影响？**

A: RPLL VCO 为 2133.312 MHz 时，pl_clk0 只能用 2133.312/12=177.8 MHz，比预期的 200 MHz 慢 11%。IOPLL VCO=1800 MHz 可以精确分频：1800/9=200 MHz、1800/6=300 MHz。时钟频率的提升直接影响吞吐——200 MHz vs 177.8 MHz 有 12.5% 的性能收益。同时 200 MHz 是整数分频，PLL 输出 jitter 更小，对 setup 余量有利。

**Q: 如果 200 MHz 域 setup 违规，怎么修？**

A: 第一步看违规路径的 logic delay vs net delay 占比。如果 net delay > 50%，做 Pblock 物理约束。如果 logic delay > 50%，查组合逻辑级数——超过 15 级 LUT 就插入流水寄存器。本项目最有可能违规的是 merge_output 的比较器链，因为 80b 加法 + 13b 比较 + 再 80b 加法约 5 级 LUT+2 级 CARRY。修法是拆成两级流水：先算 x2/x4_range 并寄存，再判断重叠并寄存，最后做合并加法。

**Q: CDC 亚稳态概率怎么算？**

A: MTBF = T_w / (f_in × f_clk × T_ce)，其中 T_w(决断窗) ≈ 20 fs for UltraScale+ FF, T_ce(指数衰减常数) ≈ 50 ps。对于 2 级同步器，每级的 MTBF ≈ 10^7 年，两级串联后 > 宇宙年龄，实际可认为零概率。

---

## 2. PPA 优化 (Performance / Power / Area)

### 2.1 Performance 分析

**当前性能瓶颈：**

```
帧处理总延迟 = T_h2c + T_mcdma_setup + T_proc + T_s2mm + T_c2h

  T_h2c:    171 MB / 1.5 GB/s       ≈ 114 ms   (PCIe Gen3 x2 传输)
  T_setup:  10 ch × BD 链表配置      ≈ 0.5 ms   (ARM 写寄存器)
  T_proc:   582 行 / ch, 7680 列/ch  @ 200 MHz = 582×7680/200M ≈ 22.3 ms  (纯像素处理)
  T_s2mm:   结果数据量小              ≈ <1 ms
  T_c2h:    结果读回                  ≈ <1 ms
  ─────────────────────────────────────────────
  总延迟 ≈ 138 ms  →  最高帧率 ≈ 7.2 FPS
```

**性能优化空间：**

| 优化项 | 当前 | 优化后 | 收益 |
|---|---|---|---|
| PCIe lane 扩展 | x2: 1.5 GB/s | x4: 3.2 GB/s | T_h2c 115→54 ms, FPS 7→14 |
| pl_clk0 超频 | 200 MHz | 250 MHz (尝试) | T_proc 22→18 ms |
| 双缓冲 BD 链表 | 帧间重新 TxSetup | 预配置两套 BD, 切换 | T_setup 0.5→0.05 ms |
| MCDMA burst 优化 | burst=32 | burst=64/128 | DDR 效率提升 15-20% |
| 多帧流水线 | 串行 | 乒乓 buffer | 吞吐翻倍 (H2C 与 C2H 重叠) |

### 2.2 Area 优化

**当前资源估算 (10 CCLC 实例):**

| 资源 | 单 CCLC | ×10 | 合计 |
|---|---|---|---|
| LUT | ~3000 | 30000 | 34% of 87,840 |
| FF | ~4500 | 45000 | 26% of 175,680 |
| BRAM (FIFO+ROM) | 3×18Kb + 1×36Kb | 90×18Kb + 10×36Kb | ~14% of 5.3 Mb |
| DSP48 | 2 (mult_x, mult_y) | 20 | 2.7% of 728 |

**面积优化策略：**

- DSP48 分时复用: 10 CCLC 按列交错处理, 共享 4 个 DSP48 → 节省 16 个 DSP (仅学术探讨, 控制逻辑复杂度会抵消收益)
- 注意：BRAM 是离散资源（36 Kb/块），对于深度 128→64 这种小幅缩减，只要不跨 BRAM 级联边界，块数不变。本项目中 CCLC FIFO 宽度 99 位，128 深度已占 1 块 18 Kb BRAM，深度降至 64 不省 BRAM。真正省 BRAM 的空间在于：若数据宽度可对齐到 36 Kb 原语，可将 2 块 18 Kb 合并为 1 块 36 Kb 减少一半块数
- Frame_Arbiter FIFO (255b×128depth): 已使用多块 BRAM 级联以实现宽端口。若 MCDMA burst 间隔有冗余，可评估将深度从 128 跨到 512（增加块数但提高缓冲抗反压能力）的利弊取舍
- 若面积紧张: CCLC 实例数从 10 降为 5, 每通道处理 1164 行 (吞吐减半, 面积减半)

### 2.3 Power 分析

**功耗分布估算 (ZU4EV, 典型工况):**

| 功耗域 | 占比 | 主要消耗 |
|---|---|---|
| PS (ARM + DDR + 外设) | ~45% | DDR4 刷新 + A53 活跃 + PLL |
| PL 静态 (漏电流) | ~15% | 器件固有, 与温度正相关 |
| PL 动态 (逻辑翻转) | ~25% | CCLC ×10 持续数据处理 |
| PL 动态 (DSP+BRAM) | ~10% | 乘法器 + FIFO 读写 |
| GT 收发器 | ~5% | PCIe 链路活跃 |

**功耗优化空间：**

- 帧间时钟门控: 非处理时段关闭 pl_clk0 到 CCLC + Frame_Arbiter 的时钟 (节省约 30% PL 动态功耗)
- Operand Isolation: CCLC 空闲时乘法器输入强制为 0, 停止 DSP 翻转
- DDR 低功耗模式: 帧间将 DDR 置为 Self-Refresh (节省 ~200 mW)
- PS 外设关断: GPU/VCU/RPU/USB/GEM 全部 disable (已在 PS 配置中)
- 阈值过滤前置: Frame_Arbiter 将暗像素清零后, 下游 CCLC 大部分路径不翻转 (已在设计中)

---

## 3. 低功耗设计策略

### 3.1 系统级低功耗

```
运行剖面:
  ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ 图像传输  │ → │ 处理中   │ → │ 等待结果  │ → (循环)
  │ ~115 ms  │    │ ~22 ms  │    │ ~10 ms   │
  └──────────┘    └──────────┘    └──────────┘

  占空比: 处理仅占 15%, 剩余 85% 时间可降功耗

  优化方案:
  ├─ 传输阶段: ARM WFI (Wait For Interrupt), PL 仅 XDMA 活跃
  ├─ 处理阶段: 全速运行
  └─ 等待阶段: PL 时钟门控, ARM 降频, DDR Self-Refresh
```

### 3.2 Vivado 低功耗实现手段

| 手段 | XDC/工具命令 | 预期节电 |
|---|---|---|
| 时钟门控 (自动) | `set_property CLOCK_GATING true` (power_opt_design) | 15-25% PL 动态 |
| 操作数隔离 | RTL 插入使能门控: `if (valid) result <= a*b; else result <= 0;` | 10-15% DSP 动态 |
| BRAM 使能控制 | `set_property BRAM_SLEEP_MODE true` | 5-10% BRAM 静态 |
| 多电压 (不支持) | ZU4EV PL 仅有单一 Vccint | — |
| PS 电源域管理 | FSBL 中关闭未用外设时钟 | 100-200 mW |

### 3.3 面试话术要点

**STA:** "项目涉及 3 个异步时钟域 (200/333/250 MHz)，对 AXI 跨域路径使用 Clock Converter 自动处理，对自定义信号使用 2 级同步器。关键时序路径在 300 MHz 域 (3.33 ns)，需关注组合逻辑不超过 4 级 LUT。DSP48 内部流水已吸收乘法延迟。"

**PPA 权衡:** "10 通道并行 CCLC 用面积换吞吐——单个 CCLC 仅处理 582 行，但 10 个实例消耗约 30K LUT。若面积紧张可降为 5 通道。DDR 带宽是最终瓶颈 (19.2 GB/s)，PCIe 扩展到 x4 后 H2C 延迟减半，帧率可达 14 FPS。"

**低功耗:** "利用处理占空比低的特点 (仅 15%)，帧间将 PL 时钟门控、ARM 置 WFI、DDR 进入 Self-Refresh。Frame_Arbiter 的阈值过滤在源头清零暗像素，下游 CCLC 大部分路径无翻转，天然节省动态功耗。"

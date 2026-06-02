# 优化需求清单

## 1. Vivado Block Design

### 1.1 PS PLL 时钟配置
- [ ] PL0/PL1 时钟源从 RPLL 切换至 **IOPLL** (VCO=2000 MHz)
- [ ] pl_clk0 = 200 MHz, pl_clk1 = 333.33 MHz
- [ ] 重新综合、检查所有 IP 的 FREQ_HZ 是否自动更新

### 1.2 时钟域交叉修复
- [ ] `result_tranfer/M_AXI_S2MM` (pl_clk0, 200 MHz) → `axi_interconnect_1/S01_AXI` (pl_clk1, 333 MHz) 存在 FREQ_HZ 不匹配
- [ ] 插入 AXI Clock Converter 或让 Vivado Connection Automation 自动处理

### 1.3 h2c_intr IP 集成
- [ ] 将 `ip.v` 封装为 Vivado IP 并加入 Block Design
- [ ] `S_AXI` 挂接到合适的 AXI Interconnect (XDMA m_axil + PS M_AXI_HPM 双 master 访问)
- [ ] `trigger_out` → AXI GPIO ch1 输入 (当前 ch1 已被 lsp_debug/end_flag 占用，需扩展 GPIO_WIDTH 为 2)
- [ ] `xdma_irq_req` → XDMA `usr_irq_req[0]`
- [ ] `data_en`, `data[31:0]` → 外部 FPGA 逻辑 (待确认信号来源)

### 1.4 GPIO 扩展
- [ ] AXI GPIO ch1 GPIO_WIDTH 从 1 扩展为 ≥2
- [ ] bit0: lsp_debug end_flag
- [ ] bit1: h2c_intr trigger_out
- [ ] 或使用独立 GPIO IP 隔离两组中断

---

## 2. Vitis 固件 (dma_da.c)

### 2.1 中断处理优化
- [ ] `axiGpio0_Handler` 当前仅处理 end_flag，需区分中断来源
- [ ] 读取 GPIO 输入寄存器判断是 `lsp_debug/end_flag` 还是 `h2c_intr/trigger_out`
- [ ] h2c_intr 触发：启动 TxSetup + SendPacket (首次 MCDMA 传输)
- [ ] end_flag 触发：重新 TxSetup + Invalidate + SendPacket (准备下一帧)

### 2.2 移除轮询残留
- [ ] 确认 `IMAGE_COUNT_ADDR` 相关代码已清理
- [ ] 确认 `CheckImageWritten()` 已删除 ∨
- [ ] DDR 内存映射确认：仅需 Non-Cacheable 区域 (0x20000000-0x3FFFFFFF) + BD 空间

---

## 3. PC 上位机 (ImageLoop)

### 3.1 XDMA 中断接收
- [ ] 集成 `event_0` 阻塞读取线程 (参考 `intr/xdma_driver/exe/user_event/user_event.cpp`)
- [ ] H2C 传输完成后：`WriteFile(h_user, 0x00, img_count)` 触发 h2c_intr → ARM 中断
- [ ] `event_0` 收到 FPGA 中断 → 自动 `c2h_transfer(0x1000000)` 读取光斑结果
- [ ] 结果解析：80-bit 数据 = {X_weight(28), Y_weight(28), Gray(14), count(10)}

### 3.2 界面优化
- [ ] 接收区改名为 "光斑结果区"
- [ ] 结果显示形式 (坐标列表 / 叠加标记 / 质心统计)

---

## 4. 测试验证

### 4.1 硬件测试
- [ ] PLL 切换后时序收敛检查 (report_timing_summary)
- [ ] h2c_intr IP trigger_out 脉冲波形 ILA 观察
- [ ] MCDMA BD 链表 Non-Cacheable 后传输正确性
- [ ] 端到端：PC 发图 → ARM 中断 → MCDMA → lsp → DataMover → PC 读结果

### 4.2 软件测试
- [ ] event_0 阻塞读取超时处理
- [ ] 多帧连续传输不丢中断

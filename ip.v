
`timescale 1 ns / 1 ps

module h2c_intr_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH  = 32,
    parameter integer C_S_AXI_ADDR_WIDTH  = 4
)
(
    // Users to add ports here
    output wire  trigger_out,       // PC写slv_reg0有变化→10cycle脉冲→AXI GPIO
    input  wire  data_en,           // 外部输入: 数据有效标志
    input  wire [C_S_AXI_DATA_WIDTH-1:0] data,  // 外部输入: 结果计数
    output wire  xdma_irq_req,      // 收到data→10cycle脉冲→XDMA usr_irq_req
    // User ports ends

    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
    reg       axi_awready;
    reg       axi_wready;
    reg [1 : 0]   axi_bresp;
    reg       axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg       axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata;
    reg [1 : 0]   axi_rresp;
    reg       axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg0;   // PC写入: 图片计数 (0-6循环)
    reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0]  slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0]  tracked_val;   // 内部: 硬件跟踪 slv_reg0 上次值
    reg [C_S_AXI_DATA_WIDTH-1:0]  captured_data;  // 内部: data_en 上升沿捕获的 data
    wire     slv_reg_rden;
    wire     slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0]   reg_data_out;
    integer  byte_index;
    reg  aw_en;

    //===== 路径1: PC写slv_reg0变化检测 → trigger_out (接AXI GPIO) =====
    wire reg0_write;
    wire value_changed;
    reg [3:0] pulse_cnt0;
    reg       pulse_active0;

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    assign reg0_write   = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0);
    assign value_changed = reg0_write && (S_AXI_WDATA != tracked_val);

    assign trigger_out = pulse_active0;

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            pulse_active0 <= 1'b0;
            pulse_cnt0    <= 4'd0;
        end
        else if (value_changed)
        begin
            pulse_active0 <= 1'b1;
            pulse_cnt0    <= 4'd0;
        end
        else if (pulse_active0)
        begin
            if (pulse_cnt0 == 4'd9)
                pulse_active0 <= 1'b0;
            else
                pulse_cnt0    <= pulse_cnt0 + 4'd1;
        end
    end

    // tracked_val 跟踪 slv_reg0
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            tracked_val <= 0;
        else if (value_changed)
            tracked_val <= S_AXI_WDATA;
    end

    //===== 路径2: 外部data_en上升沿 → 捕获data → slv_reg2 → xdma_irq_req =====
    reg data_en_sync0, data_en_sync1;   // 2级同步器
    reg data_en_d1;                     // 打拍用于边沿检测
    reg [3:0] pulse_cnt1;
    reg       pulse_active1;

    assign xdma_irq_req = pulse_active1;

    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            data_en_sync0 <= 1'b0;
            data_en_sync1 <= 1'b0;
            data_en_d1    <= 1'b0;
            pulse_active1 <= 1'b0;
            pulse_cnt1    <= 4'd0;
            captured_data <= 0;
        end
        else
        begin
            // 2级同步 + 打拍
            data_en_sync0 <= data_en;
            data_en_sync1 <= data_en_sync0;
            data_en_d1    <= data_en_sync1;

            // 上升沿检测: 同步后的data_en 0→1
            if (data_en_sync1 && !data_en_d1)
            begin
                captured_data <= data;
                pulse_active1 <= 1'b1;
                pulse_cnt1    <= 4'd0;
            end
            else if (pulse_active1)
            begin
                if (pulse_cnt1 == 4'd9)
                    pulse_active1 <= 1'b0;
                else
                    pulse_cnt1    <= pulse_cnt1 + 4'd1;
            end
        end
    end

    //===== AXI 标准信号 =====
    assign S_AXI_AWREADY  = axi_awready;
    assign S_AXI_WREADY   = axi_wready;
    assign S_AXI_BRESP    = axi_bresp;
    assign S_AXI_BVALID   = axi_bvalid;
    assign S_AXI_ARREADY  = axi_arready;
    assign S_AXI_RDATA    = axi_rdata;
    assign S_AXI_RRESP    = axi_rresp;
    assign S_AXI_RVALID   = axi_rvalid;

    //----- axi_awready -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else
        begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if (S_AXI_BREADY && axi_bvalid)
            begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end
            else
                axi_awready <= 1'b0;
        end
    end

    //----- axi_awaddr latching -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    //----- axi_wready -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    //----- register write -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            slv_reg0 <= 0;
        else if (slv_reg_wren)
        begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                2'h0:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                2'h1:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                2'h2:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                2'h3:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                default : ;
            endcase
        end
    end

    //----- write response -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            axi_bvalid  <= 0;
            axi_bresp   <= 2'b0;
        end
        else if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            axi_bvalid <= 1'b0;
    end

    //----- axi_arready -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end
        else if (~axi_arready && S_AXI_ARVALID)
        begin
            axi_arready <= 1'b1;
            axi_araddr  <= S_AXI_ARADDR;
        end
        else
            axi_arready <= 1'b0;
    end

    //----- axi_rvalid -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end
        else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b0;
        end
        else if (axi_rvalid && S_AXI_RREADY)
            axi_rvalid <= 1'b0;
    end

    //----- register read -----
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*)
    begin
        case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            2'h0   : reg_data_out <= slv_reg0;
            2'h1   : reg_data_out <= slv_reg1;
            2'h2   : reg_data_out <= slv_reg2;
            2'h3   : reg_data_out <= slv_reg3;
            default : reg_data_out <= 0;
        endcase
    end

    //----- read data output -----
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_rdata <= 0;
        else if (slv_reg_rden)
            axi_rdata <= reg_data_out;
    end

endmodule

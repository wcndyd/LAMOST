`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/08 14:26:39
// Design Name: 
// Module Name: Frame_Arbiter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Frame_Arbiter#(
    parameter   channel_num = 5     ,    
    parameter   data_W      = 256   ,
    parameter   tdest_W     = 4     ,
    parameter   output_W    = 8     ,
    parameter   Thres       = 16
)
(
    input                               clk             ,
    input                               rst_n           ,
    input   [data_W-1:0]                MM2S_tdata      ,
    input                               MM2S_tvalid     ,
    input   [tdest_W-1:0]               MM2S_tdest      ,
    output                              MM2S_tready     ,
    input   [channel_num-1:0]           CCLC_ready      ,
    output  [channel_num-1:0]           data_valid_n    ,
    output  [channel_num*output_W-1:0]  data_n          ,
    output  [channel_num*11-1:0]        data_count      
);


localparam  convert_cnt = data_W/output_W;

wire    [channel_num-1:0]       wr_en                           ;
wire    [channel_num-1:0]       tready                          ;
wire                            convert_ready[channel_num-1:0]  ;
wire                            rd_en[channel_num-1:0]          ;
wire    [data_W-1:0]            dout[channel_num-1:0]           ;      
wire                            full[channel_num-1:0]           ;
wire                            empty[channel_num-1:0]          ;

wire    [channel_num*output_W-1:0]  data_n_1                    ;

generate
    genvar i;
    for(i=0;i<channel_num;i=i+1) begin:fifo_gen
        fifo_MM2S fifo_u (
            .clk            (clk            ),              // input wire clk
            .srst           (~rst_n         ),              // input wire srst
            .din            (MM2S_tdata     ),              // input wire [255 : 0] din
            .wr_en          (wr_en[i]       ),              // input wire wr_en
            .rd_en          (rd_en[i]       ),              // input wire rd_en
            .dout           (dout[i]        ),              // output wire [255 : 0] dout
            .full           (               ),              // output wire full
            .empty          (empty[i]       ),              // output wire empty
            .data_count     (data_count[i*11 +: 11]  ),              // output wire [10 : 0] data_count
            .prog_full      (full[i]        ),                  // output wire prog_full
            .wr_rst_busy    (               ),              // output wire wr_rst_busy
            .rd_rst_busy    (               )               // output wire rd_rst_busy
        );
    end
endgenerate

wire [channel_num-1:0] dest_decode;
genvar e;
generate
    for (e = 0; e < channel_num; e = e + 1) begin:dest_gen
        assign dest_decode[e] = (MM2S_tdest == e);
    end
endgenerate
    
generate
    genvar j;
        for(j=0;j<channel_num;j=j+1) begin:tready_gen
            assign  tready[j] = !full[j];            
        end
endgenerate


assign MM2S_tready = tready[MM2S_tdest];

assign wr_en = MM2S_tready&&MM2S_tvalid ? dest_decode : {channel_num{1'b0}};

generate
    genvar k;
    for(k=0;k<channel_num;k=k+1) begin:convert_gen
        axis_dwidth_converter_0 u (
            .aclk           (clk                                ),                    // input wire aclk
            .aresetn        (rst_n                              ),              // input wire aresetn
            .s_axis_tvalid  (rd_en[k]                           ),  // input wire s_axis_tvalid
            .s_axis_tready  (convert_ready[k]                   ),  // output wire s_axis_tready
            .s_axis_tdata   (dout[k]                            ),    // input wire [255 : 0] s_axis_tdata
            .m_axis_tvalid  (data_valid_n[k]                    ),  // output wire m_axis_tvalid
            .m_axis_tready  (CCLC_ready[k]                      ),  // input wire m_axis_tready
            .m_axis_tdata   (data_n_1[k*output_W +: output_W]   )    // output wire [7 : 0] m_axis_tdata
        );
        assign rd_en[k] =  convert_ready[k]&& ~empty[k];
        assign data_n[k*output_W +: output_W] = data_n_1[k*output_W +: output_W]>=Thres ? data_n_1[k*output_W +: output_W] : 'd0;
    end
endgenerate



endmodule

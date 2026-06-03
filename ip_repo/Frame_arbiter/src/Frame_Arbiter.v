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
    output  [channel_num-1:0]           data_valid_n    ,
    output  [channel_num*output_W-1:0]  data_n          
);


localparam  convert_cnt = data_W/output_W;

wire                            wr_en[channel_num-1:0]  ;
wire                            rd_en[channel_num-1:0]  ;
wire    [data_W-1:0]            dout[channel_num-1:0]   ;      
wire                            full[channel_num-1:0]   ;
wire                            empty[channel_num-1:0]  ;
reg                             tready                  ;
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
            .prog_full      (full[i]        ),      // output wire prog_full
            .wr_rst_busy    (               ),              // output wire wr_rst_busy
            .rd_rst_busy    (               )               // output wire rd_rst_busy
        );
    end
endgenerate

integer j;

always@(*)begin
    tready = 1'b1;
    for(j=0;j<channel_num;j=j+1) begin
        assign  wr_en[j] = (MM2S_tdest==j)&&MM2S_tvalid&&MM2S_tready ? 1'b1:1'b0;  
        assign  tready = tready&~full[j];
    end
end 

assign MM2S_tready = tready;

generate
    genvar k;
    for(k=0;k<channel_num;k=k+1) begin:convert_gen
        width_convert#(
            .Width_i        (data_W         ),
            .Width_o        (output_W       ),
            .Convert_cnt    (convert_cnt    ),
            .Thres          (Thres          )
        )
        convert_u(
            .clk                    (clk                                ),
            .rst_n                  (rst_n                              ),                
            .empty                  (empty[k]                           ),
            .data_i                 (dout[k]                            ),
            .data_rd                (rd_en[k]                           ),
            .data_o                 (data_n[k*output_W +: output_W]     ),
            .data_en                (data_valid_n[k]                    )
        );
    end
endgenerate



endmodule

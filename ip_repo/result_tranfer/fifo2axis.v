`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/14 16:56:01
// Design Name: 
// Module Name: fifo2axis
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


module fifo2axis#(
    parameter   data_W = 80 
)
(
    input                   clk             ,
    input                   rst_n           ,
    input                   empty           ,
    input   [data_W-1:0]    dout            ,
    output                  rd_en           ,
                                        
    input                   axis_tready     ,
    output                  axis_tvalid     ,
    output  [127:0]         axis_tdata      ,
    output  [15:0]          axis_tkeep      ,
    output                  axis_tlast          
);

reg     tvalid;

assign rd_en = axis_tvalid&axis_tready;
assign axis_tdata = dout|128'd0;
assign axis_tvalid = !empty&tvalid;
assign axis_tlast = 1'b0;
assign axis_tkeep = 16'hffff;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tvalid <= 1'b0;
    end
    else if(!empty) begin
        tvalid <= 1'b1;
    end
    else begin
        tvalid <= 1'b0;   
    end
end

endmodule

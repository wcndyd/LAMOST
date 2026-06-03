`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/04 10:27:41
// Design Name: 
// Module Name: point_output
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


module point_output#(
    parameter   input_data_W    = 80    ,
    parameter   blk_num         = 4     
)
(
    input                                       clk                 ,
    input                                       rst_n               ,
    input       [blk_num*input_data_W-1:0]      input_data          ,
    input       [blk_num-1:0]                   input_data_valid    ,
    output      [input_data_W-1:0]              output_data         ,
    output                                      output_en           ,
    input                                       frame_end_flag_i    ,
    output                                      frame_end_flag_o          
);



wire    [input_data_W-1:0]                  dout[blk_num-1:0]           ;
wire    [blk_num-1:0]                       empty                       ;
reg                                         dout_en[blk_num-1:0]        ;                                                                       
reg                                         not_empty[blk_num-1:0]      ;

reg     [9:0]                               frame_end_flag              ;
//生成一些缓冲FIFO
generate
    genvar i;
    for(i = 0; i<blk_num;i=i+1) begin:fifo_gen
        fifo_generator_1 ui (
        .clk                (clk                                                ),                         // input wire clk
        .srst               (~rst_n                                             ),                         // input wire srst
        .din                (input_data[input_data_W*(i+1)-1:input_data_W*i]    ),                         // input wire [79 : 0] din
        .wr_en              (input_data_valid[i]                                ),                         // input wire wr_en
        .rd_en              (dout_en[i]                                         ),                         // input wire rd_en
        .dout               (dout[i]                                            ),                         // output wire [79 : 0] dout
        .full               (                                                   ),                         // output wire full
        .empty              (empty[i]                                           ),                         // output wire empty
        .wr_rst_busy        (                                                   ),                         // output wire wr_rst_busy
        .rd_rst_busy        (                                                   )                          // output wire rd_rst_busy
        );        
    end
endgenerate

//生成优先级标志位，not_empty有效是表示自身或前面非空
integer j;
always @(*) begin
    not_empty[0] = ~empty[0];
    for (j = 1; j < blk_num; j = j + 1) begin       
        not_empty[j] = not_empty[j-1] | ~empty[j];
    end
end

//数据链路仲裁部分
// 每一路数据与自己的有效信号相与，无效则全 0
wire    [input_data_W-1:0]          masked_data[blk_num-1:0]            ;
reg                                 output_valid[blk_num-1:0]           ;
reg     [input_data_W-1:0]          output_data_temp[blk_num-1:0]       ;
generate
    genvar g;
    for (g = 0; g < blk_num; g = g + 1) begin : gen_mask
        assign masked_data[g] = output_valid[g] ? output_data_temp[g] : {input_data_W{1'b0}};
    end
endgenerate
// 最后将所有 masked_data 进行“或”缩减
integer h;
reg [input_data_W-1:0] final_data;
reg output_data_valid_temp          ;

always @(*) begin
    final_data = {input_data_W{1'b0}};
    output_data_valid_temp = 1'b0;
    for (h = 0; h < blk_num; h = h + 1) begin
        final_data = final_data | masked_data[h];
        output_data_valid_temp = output_data_valid_temp|output_valid[h];
    end
end
assign output_data       = final_data;
assign output_en         = output_data_valid_temp; // 只要有一个为1，总有效位就为1

//第一个最高优先级，会特殊一点
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dout_en[0] <= 1'b0;
        output_data_temp[0] <= 'd0;
        output_valid[0] <= 1'b0;
    end
    else if(~empty[0] && ~dout_en[0]) begin
        dout_en[0] <= 1'b1;
        output_data_temp[0] <= dout[0];
        output_valid[0] <= 1'b1;                
    end
    else begin
        dout_en[0] <= 1'b0;
        output_data_temp[0] <= 'd0;
        output_valid[0] <= 1'b0;             
    end
end

//剩余的优先级设置，基本就是越前面优先级越高
generate
    genvar k;
    for(k=1;k<blk_num;k=k+1) begin:Arbiter
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                dout_en[k] <= 1'b0;
                output_data_temp[k] <= 'd0;
                output_valid[k] <= 1'b0;
            end
            else if(~not_empty[k-1] &&not_empty[k]&& ~dout_en[k]) begin
                dout_en[k] <= 1'b1;
                output_data_temp[k] <= dout[k];
                output_valid[k] <= 1'b1;                
            end
            else begin
                dout_en[k] <= 1'b0;
                output_data_temp[k] <= 'd0;
                output_valid[k] <= 1'b0;             
            end
        end
    end
endgenerate


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        frame_end_flag <= 'd0;
    else 
        frame_end_flag <= {frame_end_flag[8:0],frame_end_flag_i};
end

assign frame_end_flag_o = (|frame_end_flag[9:5])&&(&empty) ? 1'b1 : 1'b0;

endmodule

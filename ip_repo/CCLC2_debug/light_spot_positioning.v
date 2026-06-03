`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/06 20:06:15
// Design Name: 
// Module Name: light_spot_positioning
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

module light_spot_positioning#(
    parameter Width             = 7920  ,                       //图像宽度    parameter 
    parameter Height            = 1000  ,                       //图像高度
    parameter merge_num         = 4     , 
    parameter Data_W            = 8     ,                       //图像位宽
    parameter COL_W             = 13    ,                       //宽度数据位宽
    parameter ROW_W             = 13    ,                       //高度数据位宽
    parameter X_weight_W        = 28    ,                       //X权重位宽
    parameter Y_weight_W        = 28    ,                       //Y权重位宽
    parameter Gray_W            = 14    ,                       //灰度值位宽
    parameter M_flag_W          = 5     ,                       //拼接标识符计数位宽
    parameter count_W           = 10    ,                       //灰度点数总点数位宽
    parameter length_W          = 6     ,                       //每一个游程长度
    parameter Output_data_W     = 80    ,                       //输出数据位宽
    parameter BLK_W             = 99                            //储存拼接数据所需的ROM位宽 

)
(
    input                                   clk                 ,
    input                                   rst_n               ,
    input   [merge_num-1:0]                 data_valid_i        ,
    input   [merge_num*Data_W-1:0]          data_i              ,
    output  [merge_num-1:0]                 ready_o             ,
    output                                  data_valid_o        ,
    output  [Output_data_W-1:0]             data_o              ,
    output                                  end_flag            ,
    output  [merge_num:0]                           Output_En_d     ,
    output  [(merge_num+1)*Output_data_W-1:0]       Output_data_d   ,     
    output  [merge_num-1:0]                         frame_flag_d    ,     
    output  [merge_num*M_flag_W-1:0]                merge_blk_num_d ,     
    output  [merge_num*M_flag_W-1:0]                blk_down_addr_d ,     
    output  [merge_num*BLK_W-1:0]                   blk_out_d       ,     
    output  [merge_num-1:0]                         blk_data_en_d   ,     
    output                                          merge_end_d             
);



wire    [merge_num:0]                           Output_En       ;
wire    [(merge_num+1)*Output_data_W-1:0]       Output_data     ;                                                                
wire    [merge_num-1:0]                         frame_flag      ;
wire    [merge_num*M_flag_W-1:0]                merge_blk_num   ;
wire    [merge_num*BLK_W-1:0]                   blk_out         ;
wire    [merge_num*M_flag_W-1:0]                blk_down_addr   ;
wire    [merge_num-1:0]                         blk_data_en     ;
wire    [merge_num-1:0]                         ready           ;
wire                                            merge_end       ;
reg     [1:0]                                   merge_end_edge  ;
reg     [9:0]                                   rst_1         ;
wire                                            rst_user      ;

assign  Output_En_d     = Output_En     ;                           
assign  Output_data_d   = Output_data   ;    
assign  frame_flag_d    = frame_flag    ;    
assign  merge_blk_num_d = merge_blk_num ;
assign  blk_down_addr_d = blk_down_addr ;
assign  blk_out_d       = blk_out       ;
assign  blk_data_en_d   = blk_data_en   ;
assign  merge_end_d     = merge_end     ;

assign  ready_o = ready;
assign  rst_user = |rst_1;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        merge_end_edge <= 'd0;
    else 
        merge_end_edge <= {merge_end_edge[0],merge_end};
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rst_1 <= 'd0;
    else if(!merge_end_edge[1] && merge_end_edge[0])
        rst_1[0] <= 1'b1;
    else 
        rst_1 <= {rst_1[8:0],1'b0};
end



generate
    genvar i;
    for(i=0;i<merge_num;i=i+1) begin:CCLC_gen
        CCLC2_0 #(                                          //Connected Component Labeling Calculate
            .Width           (Width             ),                  //图像宽度
            .Height          (Height            ),                  //图像高度
            .ROW_start       (i*Height          ),                  //图像在原图中的起点
            .Data_W          (Data_W            ),                  //图像位宽
            .COL_W           (COL_W             ),                  //宽度数据位宽
            .ROW_W           (ROW_W             ),                  //高度数据位宽
            .X_weight_W      (X_weight_W        ),                  //X权重位宽
            .Y_weight_W      (Y_weight_W        ),                  //Y权重位宽
            .Gray_W          (Gray_W            ),                  //灰度值位宽
            .M_flag_W        (M_flag_W          ),                  //拼接标识符计数位宽
            .count_W         (count_W           ),                  //灰度点数总点数位宽
            .length_W        (length_W          ),                  //每一个游程长度
            .Output_data_W   (Output_data_W     ),                  //输出数据位宽
            .BLK_W           (BLK_W             )                   //储存拼接数据所需的ROM位宽
        )
        CCLC(
            .clk                         (clk                                               ),                 //时钟
            .rst_n                       ( !rst_user && rst_n                               ),                 //复位
            .data_valid                  (data_valid_i[i]                                   ),                 //输入数据有效
            .data                        (data_i[Data_W*i +: Data_W]                        ),                 //输入数据
            .Output_En                   (Output_En[i]                                      ),                 //输出数据有效
            .Output_data                 (Output_data[Output_data_W*i +: Output_data_W]     ),                 //输出数据
            .frame_flag                  (frame_flag[i]                                     ),                 //这部分图像数据结束标识符
            .merge_num                   (merge_blk_num[M_flag_W*i +: M_flag_W]             ),                 //所储存的所有的可以拼接的数量
            .blk_out                     (blk_out[BLK_W*i +: BLK_W]                         ),                 //ROM数据输出
            .blk_down_addr               (blk_down_addr[M_flag_W*i +: M_flag_W]             ),                 //图像底部拼接的起始地址
            .blk_data_en                 (blk_data_en[i]                                    ),                 //读出ROM输出使能信号
            .ready                       (ready[i]                                          )                  //由于使用复位对模块进行初始化，ready是为了判断相关FIFO ROM等是否能够使用
        );    
    end
endgenerate

merge_output #(
    .blk_num        (merge_num          ),     
    .M_flag_W       (M_flag_W           ),    
    .BLK_W          (BLK_W              ),    
    .Output_data_W  (Output_data_W      ),        
    .COL_W          (COL_W              ),
    .length_W       (length_W           )
    
)
merge_u1(
    .clk                (clk                                                    ),
    .rst_n              ( !rst_user && rst_n                                    ),
    .frame_flag_n       (frame_flag                                             ),
    .merge_num_n        (merge_blk_num                                          ),
    .blk_down_addr      (blk_down_addr                                          ),
    .blk_in_n           (blk_out                                                ),
    .blk_data_en_n      (blk_data_en                                            ),
    .output_data_valid  (Output_En[merge_num]                                   ),
    .output_data        (Output_data[Output_data_W*merge_num +: Output_data_W]  ),      
    .end_flag           (merge_end                                              )
);  

point_output #(
    .input_data_W       (Output_data_W      ), 
    .blk_num            (merge_num+1        )
)
point_o_u1(
    .clk                    (clk            ),        
    .rst_n                  (rst_n          ),  
    .input_data             (Output_data    ),        
    .input_data_valid       (Output_En      ),      
    .output_data            (data_o         ),            
    .output_en              (data_valid_o   ),
    .frame_end_flag_i       (merge_end      ),
    .frame_end_flag_o       (end_flag       )
);
endmodule

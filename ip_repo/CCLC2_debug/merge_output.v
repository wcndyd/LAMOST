`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/28 18:55:01
// Design Name: 
// Module Name: merge_output
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

module merge_output #(
    parameter blk_num       = 4     ,
    parameter M_flag_W      = 5     ,
    parameter BLK_W         = 99    ,  
    parameter Output_data_W = 80    ,
    parameter COL_W         = 13    ,
    parameter length_W      = 6
    
)
(
    input                                       clk                     ,
    input                                       rst_n                   ,
    input           [blk_num-1:0]               frame_flag_n            ,
    input           [M_flag_W*blk_num-1:0]      merge_num_n             ,
    input           [M_flag_W*blk_num-1:0]      blk_down_addr           ,    
    input           [BLK_W*blk_num-1:0]         blk_in_n                ,
    output          [blk_num-1:0]               blk_data_en_n           ,
    output                                      output_data_valid       ,
    output          [Output_data_W-1:0]         output_data             ,
    output  reg                                 end_flag
);

localparam  merge_IDLE          = 4'b0001;
localparam  up_data_rd          = 4'b0010;
localparam  merge_state_cheak   = 4'b0010;
localparam  merge_process       = 4'b0100;
localparam  merge_end           = 4'b1000;
                      
reg     [3:0]                   state_merge[blk_num-1:0]        ;

reg                             blk_data_en[(blk_num-1)*2:0]    ;

//取各个图像片段结束标志的交集，所有都结束才能进行拼接
wire                            frame_flag_end                  ;
assign  frame_flag_end = &frame_flag_n;

//每个部分拼接结束才输出拼接结束标识符，
reg                             merge_end_flag[blk_num-1:0]     ;
integer e;
always @(*) begin
    end_flag = 1'b1; // 初始值为 1
    for (e = 0; e < blk_num; e = e + 1) begin
        end_flag = end_flag & merge_end_flag[e];
    end
end

//第一部分的上半部分读出但不使用，直接舍弃
reg     [BLK_W-1:0]     blk_temp_up_data;
reg     [M_flag_W-1:0]  down_addr;
reg     [M_flag_W-1:0]  addr_cnt;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state_merge[0] <= merge_IDLE;
        down_addr <= 'd1;
        merge_end_flag[0] <= 1'b0;
        addr_cnt <= 'd1;
        blk_data_en[0] <= 1'b0;
        blk_temp_up_data <= 'd0;
    end
    else begin
        case(state_merge[0])
            merge_IDLE:begin
                if(frame_flag_end) begin 
                    if(down_addr > 1) begin
                        state_merge[0] <= up_data_rd;
                    end
                    else begin
                        state_merge[0] <= merge_end;
                        merge_end_flag[0] <= 1'b1;
                    end
                end
                else begin
                    state_merge[0] <= merge_IDLE;
                    down_addr <= blk_down_addr[M_flag_W-1:0];                                
                end
            end
            up_data_rd:begin
                if(addr_cnt == down_addr) begin
                    blk_data_en[0] <= 1'b0;
                    state_merge[0] <= merge_end;                
                end
                else if(!blk_data_en[0]) begin
                    blk_data_en[0] <= 1'b1;
                    state_merge[0] <= up_data_rd;
                end
                else if(blk_data_en[0]) begin
                    blk_temp_up_data <= blk_in_n[BLK_W-1:0];
                    blk_data_en[0] <= 1'b0;
                    addr_cnt <= addr_cnt + 1'b1;
                    state_merge[0] <= up_data_rd;
                end
            end
            merge_end:begin
                state_merge[0] <= merge_end;
                merge_end_flag[0] <= 1'b1;
            end
        endcase
    end
end

reg                             blk_output_valid[blk_num-1:0]   ;                                   //所有路径的输出有效信号
reg     [Output_data_W-1:0]     blk_output_data[blk_num-1:0]    ;                                   //所有路径的输数据
//数据仲裁，哪一路的输出有效输出哪一路的数据
always @(*) begin                                           //第一路初始化为0不输出，就是第一行上半部分，无法拼接舍去
    blk_output_valid[0] = 1'b0;   
    blk_output_data[0] = {Output_data_W{1'b0}};
end

// 每一路数据与自己的有效信号相与，无效则全 0
wire    [Output_data_W-1:0]     masked_data [blk_num-1:0];
generate
    genvar g;
    for (g = 1; g < blk_num; g = g + 1) begin : gen_mask
        assign masked_data[g] = blk_output_valid[g] ? blk_output_data[g] : {Output_data_W{1'b0}};
    end
endgenerate

// 最后将所有 masked_data 进行“或”缩减
integer k;
reg     [Output_data_W-1:0]     final_data                      ;                                   //最终输出 
reg                             output_data_valid_temp          ;                                   //最终输出有效信号

always @(*) begin
    //初始化赋值
    final_data = {Output_data_W{1'b0}};
    output_data_valid_temp = 1'b0;
    for (k = 1; k < blk_num; k = k + 1) begin
        final_data = final_data | masked_data[k];
        output_data_valid_temp = output_data_valid_temp|blk_output_valid[k];
    end
end
assign output_data       = final_data;
assign output_data_valid = output_data_valid_temp; // 只要有一个为1，总有效位就为1

//因为前后两次拼接都会使能同一个ROM，故做一次数据拼接
integer j;
reg [blk_num-1:0] data_en_n;
always @(*) begin
    data_en_n = {blk_num{1'b0}};
    for (j = 0; j < blk_num; j = j + 1) begin
        if(j == blk_num - 1)
            data_en_n[j] = data_en_n[j] | blk_data_en[j*2];        
        else
            data_en_n[j] = data_en_n[j] | blk_data_en[j*2] | blk_data_en[j*2+1];
    end
end
assign blk_data_en_n  =  data_en_n;


//数据拼接部分 假设上半部分分别是x1,x2,下半部分是x3,x4.
generate
    genvar i;
    for (i = 1; i < blk_num; i = i + 1) begin : merge_gen    //i从1开始       
        reg     [M_flag_W-1:0]  up_addr_num;                    //拼接时上面部分的待拼接总数，用来判断，免得读出是超出所存数据区限
        reg     [M_flag_W-1:0]  down_addr;                      //拼接时下面部分的待拼接结束地址
        reg     [M_flag_W-1:0]  addr_cnt_up;                    //拼接时上面部分的待拼接的起始地址，用于累加计数
        reg     [M_flag_W-1:0]  addr_cnt_down;                  //拼接时上面部分的待拼接的起始地址，因为读取的是下面图像的上边部分，自然从头计数
        reg                     up_flag;                        //上面部分读取数据标识符
        reg                     down_flag;                      //下面部分读取数据标识符
        reg     [2:0]           delay_cnt;                      //延时计数，因为发去读取信号到接收到数据需要几个延迟节拍
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                state_merge[i] <= merge_IDLE;
                up_addr_num <= 'd0;
                down_addr <= 'd0;
                addr_cnt_up <= 'd0;
                addr_cnt_down <= 'd0;
                merge_end_flag[i] <= 1'b0;
                blk_data_en[i*2-1] <= 1'b0;
                blk_data_en[i*2] <= 1'b0;
                up_flag <= 1'b0;
                down_flag <= 1'b0;
                blk_output_valid[i] <= 1'b0;
                delay_cnt <= 'd0;
            end
            else begin
                case(state_merge[i])
                    merge_IDLE:begin
                        if(frame_flag_end && merge_end_flag[i-1]) begin                            //所有图片检测完才行拼接
                            //如果     上面图片的 待拼接的总数等于图片下面待拼接部分起始地址 表示上面图片的下面没有可待拼接的      并且  下半图片的下面带拼接的起始地址等于1，表示上面待拼接部分没有，也就是没得拼接，直接结束 
                            if((merge_num_n[i*M_flag_W-1:(i-1)*M_flag_W]==blk_down_addr[i*M_flag_W-1:(i-1)*M_flag_W]) && (blk_down_addr[(i+1)*M_flag_W-1:i*M_flag_W]==1)) begin   
                                state_merge[i] <= merge_end;                          
                            end
                            else if(merge_end_flag[i-1])begin               //前一部分拼接结束，才能进行后面的拼接
                                state_merge[i] <= merge_state_cheak;
                                up_addr_num <= merge_num_n[i*M_flag_W-1:(i-1)*M_flag_W];               
                                addr_cnt_up <= blk_down_addr[i*M_flag_W-1:(i-1)*M_flag_W];              
                                addr_cnt_down <= 'd1;                                                   
                                down_addr <= blk_down_addr[(i+1)*M_flag_W-1:i*M_flag_W];               
                                up_flag <= 1'b1;                                                       
                                down_flag <= 1'b1;                                                     
                            end
                        end
                        else begin
                            state_merge[i] <= merge_IDLE;        
                        end
                    end
                    merge_state_cheak:begin
                        //数据清零
                        blk_output_valid[i] <= 1'b0;        
                        delay_cnt <= 'd0;
                        if(up_addr_num > addr_cnt_up && up_flag) begin              //上面部分还有待拼接片段，读出使能
                            blk_data_en[i*2-1] <= 1'b1;                            
                        end
                        if(addr_cnt_down < down_addr && down_flag) begin            //下面部分还有待拼接片段，读出使能
                            blk_data_en[i*2] <= 1'b1;                              
                        end
                        if(up_addr_num == addr_cnt_up && addr_cnt_down == down_addr) begin  //如果都没有待拼接片段，结束拼接
                            state_merge[i] <= merge_end;
                        end
                        else begin
                            state_merge[i] <= merge_process;                        //否则进入拼接处理
                        end
                    end
                    merge_process:begin
                        blk_data_en[i*2-1] <= 1'b0;                                 //仅使能一个节拍
                        blk_data_en[i*2] <= 1'b0;
                        if(delay_cnt == 2) begin
                            if(up_addr_num > addr_cnt_up && addr_cnt_down < down_addr) begin          //上下都有待拼接数据
                                if(blk_in_n[BLK_W*(i-1) +: COL_W]<blk_in_n[BLK_W*i +: COL_W] + blk_in_n[BLK_W*i+COL_W +: length_W])begin                   //x1<x4
                                    if(blk_in_n[BLK_W*i +: COL_W]<=blk_in_n[BLK_W*(i-1) +: COL_W] + blk_in_n[BLK_W*(i-1)+COL_W +: length_W]) begin          //x3<=x2    肯定连通，合并
                                        up_flag <= 1'b1;
                                        down_flag <= 1'b1;
                                        addr_cnt_up <= addr_cnt_up + 1'b1;
                                        addr_cnt_down <= addr_cnt_down + 1'b1;
                                        state_merge[i] <= merge_state_cheak;
                                        blk_output_valid[i] <= 1'b1;
                                        blk_output_data[i] <= blk_in_n[BLK_W*i-1 -: Output_data_W]+ blk_in_n[BLK_W*(i+1)-1 -: Output_data_W];                                    
                                    end
                                    else begin                                                                                                      //x3>x2 不连通，读出上面部分的
                                        up_flag <= 1'b1;
                                        down_flag <= 1'b0;
                                        addr_cnt_up <= addr_cnt_up + 1'b1;
                                        state_merge[i] <= merge_state_cheak;
                                        blk_output_valid[i] <= 1'b1;
                                        blk_output_data[i] <= blk_in_n[BLK_W*i-1 -: Output_data_W];                                  
                                    end
                                end
                                else if(blk_in_n[BLK_W*(i-1) +: COL_W]==blk_in_n[BLK_W*i +: COL_W] + blk_in_n[BLK_W*i+COL_W +: length_W]) begin      //x1=x4 合并
                                    up_flag <= 1'b1;
                                    down_flag <= 1'b1;
                                    addr_cnt_up <= addr_cnt_up + 1'b1;
                                    addr_cnt_down <= addr_cnt_down + 1'b1;
                                    state_merge[i] <= merge_state_cheak;
                                    blk_output_valid[i] <= 1'b1;
                                    blk_output_data[i] <= blk_in_n[BLK_W*i-1 -: Output_data_W]+ blk_in_n[BLK_W*(i+1)-1 -: Output_data_W];                                                                  
                                end
                                else begin                                                                                                              //x1>x4
                                    up_flag <= 1'b0;
                                    down_flag <= 1'b1;
                                    addr_cnt_down <= addr_cnt_down + 1'b1;
                                    state_merge[i] <= merge_state_cheak;
                                    blk_output_valid[i] <= 1'b1;
                                    blk_output_data[i] <= blk_in_n[BLK_W*(i+1)-1 -: Output_data_W];                                  
                                end
                            end
                            else if(up_addr_num > addr_cnt_up) begin            //上面图像还有剩余数据，下面合并完毕
                                up_flag <= 1'b1;
                                down_flag <= 1'b0;
                                addr_cnt_up <= addr_cnt_up + 1'b1;
                                state_merge[i] <= merge_state_cheak;
                                blk_output_valid[i] <= 1'b1;
                                blk_output_data[i] <= blk_in_n[BLK_W*i-1 -: Output_data_W];                         
                            end
                            else begin                                          //下面图像还有剩余数据，上面合并完毕
                                up_flag <= 1'b0;
                                down_flag <= 1'b1;
                                addr_cnt_down <= addr_cnt_down + 1'b1;
                                state_merge[i] <= merge_state_cheak;
                                blk_output_valid[i] <= 1'b1;
                                blk_output_data[i] <= blk_in_n[BLK_W*(i+1)-1 -: Output_data_W];                         
                            end
                        end
                        else begin
                            delay_cnt <= delay_cnt + 1'b1;
                            state_merge[i] <= merge_process;
                        end                            
                    end
                    merge_end:begin
                        merge_end_flag[i] <= 1'b1;                    
                    end
                endcase
            end
        end  
    end
endgenerate

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/15 13:53:44
// Design Name: 
// Module Name: monitor
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


module monitor(
    input               clk             ,
    input               rst_n           ,
    input               clear           ,
    
    input               rd_en           ,
    input   [9:0]       data_valid_i    ,                                        
    input               result_i        ,    
    
    output  reg [27:0]  count_1         ,
    output  reg [27:0]  count_2         ,
    output  reg [27:0]  count_3         ,
    output  reg [27:0]  count_4         ,
    output  reg [27:0]  count_5         ,
    output  reg [15:0]  result_cnt1     ,
    
    output  reg [15:0]  result_cnt2    
);



always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_1 <= 'd0;
    else if(data_valid_i[5])
        count_1 <= count_1+1'b1;
    else if(clear)
        count_1 <= 'd0;        
    else 
        count_1 <= count_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_2 <= 'd0;
    else if(data_valid_i[6])
        count_2 <= count_2+1'b1;
    else if(clear)
        count_2 <= 'd0;  
    else 
        count_2 <= count_2;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_3 <= 'd0;
    else if(data_valid_i[7])
        count_3 <= count_3+1'b1;
    else if(clear)
        count_3 <= 'd0;  
    else 
        count_3 <= count_3;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_4 <= 'd0;
    else if(data_valid_i[3])
        count_4 <= count_4+1'b1;
    else if(clear)
        count_4 <= 'd0;  
    else 
        count_4 <= count_4;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_5 <= 'd0;
    else if(data_valid_i[4])
        count_5 <= count_5+1'b1;
    else if(clear)
        count_5 <= 'd0;  
    else 
        count_5 <= count_5;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        result_cnt1 <= 'd0;
    else if(result_i)
        result_cnt1 <= result_cnt1+1'b1;
    else if(clear)
        result_cnt1 <= 'd0;  
    else 
        result_cnt1 <= result_cnt1;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_cnt2 <= 'd0;
    end
    else if(rd_en) 
        result_cnt2 <= result_cnt2 + 1'b1;
    else if(clear)
        result_cnt2 <= 'd0; 
    else 
        result_cnt2 <= result_cnt2 ;   
end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/14 16:44:06
// Design Name: 
// Module Name: dma_s2mm_cmd
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


module dma_s2mm_cmd#(
    parameter   DSA         = 6'd0      ,
    parameter   EOF         = 1'b0      ,
    parameter   DRR         = 1'b0      ,
    parameter   TYPE        = 1'b1      ,
    parameter   TAG         = 4'd1      ,
    parameter   RSVD        = 4'd0      ,
    parameter   thres       = 10'd32    ,       
    parameter   burst_length= 23'd512   ,
    parameter   start_addr  = 32'h1000000  
)
(
    input                   clk             ,
    input                   rst_n           ,

    
    input                   s2mm_cmd_tready   ,
    output                  s2mm_cmd_tvalid   ,
    output  [71:0]          s2mm_cmd_tdata    ,
                                            
    input   [7:0]           sts_tdata       ,
    input                   sts_tvalid      ,
    output                  sts_tready      ,
    
    input   [7:0]           data_count      ,                                        
    
    input                   end_flag        ,

    output  [31:0]          cnt             ,
    output                  flag            

);

parameter IDLE   = 3'd0;
parameter WR_CMD = 3'd1;
parameter WAIT   = 3'd2;
parameter LAST   = 3'd3;
parameter END    = 3'd4;

parameter base_addr = 20'h10000;

reg [31:0]          s2mm_addr           ;
reg                 s2mm_tvalid         ;
reg [22:0]          s2mm_burst_len      ;
    
    
reg [2:0]           state               ;
reg [1:0]           end_flag_d          ;
reg                 end_flag_1          ;
    
reg [3:0]           frame_cnt           ;

reg [31:0]          start_addr1         ;
  
reg [3:0]           tag                 ;

reg [31:0]          total_cnt           ;
reg                 total_cnt_flag      ;

assign  cnt = total_cnt;
assign  flag = total_cnt_flag;

assign  s2mm_cmd_tvalid = s2mm_tvalid;
assign  s2mm_cmd_tdata = {RSVD,tag,s2mm_addr,DRR,EOF,DSA,TYPE,s2mm_burst_len};
assign  sts_tready = 1'b1;


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        end_flag_d <= 'd0;
    else begin
        end_flag_d[0] <= end_flag;
        end_flag_d[1] <= end_flag_d[0];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        end_flag_1 <= 1'b0;
    else if(!end_flag_d[1] && end_flag_d[0])
        end_flag_1 <= 1'b1;
    else if(state == END)
        end_flag_1 <= 1'b0;
    else 
        end_flag_1 <= end_flag_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        s2mm_addr <= start_addr;
        start_addr1 <= start_addr + base_addr;
        s2mm_burst_len <= burst_length;
        s2mm_tvalid <= 1'b0;
        tag <= 4'd0;
        total_cnt <= 'd0;
        total_cnt_flag <= 1'b0;
    end
    else begin
        case(state)
            IDLE:begin
                if(end_flag_1)
                    state <= END;                    
                else if(data_count >= thres)
                    state <= WR_CMD;
                else  
                    state <= IDLE;
            end
            WR_CMD:begin
                if(s2mm_cmd_tready) begin
                    s2mm_tvalid <= 1'b1;
                    state <= WAIT;
                    s2mm_burst_len <= burst_length;
                    total_cnt <= total_cnt + burst_length/16;
                    tag <= 4'd1;
                end
                else begin
                    s2mm_tvalid <= s2mm_tvalid;
                    state <= WR_CMD;
                    s2mm_burst_len <= s2mm_burst_len;
                    tag <= tag;
                end                    
            end
            WAIT:begin
                s2mm_tvalid <= 1'b0;                
                if(sts_tvalid) begin   
                    if(sts_tdata == 8'b10000001) begin
                        state <= IDLE;
                        s2mm_addr <= s2mm_addr + s2mm_burst_len;
                    end
                    else if(sts_tdata == 8'b10000010) begin
                        state <= IDLE;
                        total_cnt <= 'd0;
                        total_cnt_flag <= 1'b0;
                        if(start_addr1 == start_addr + 8*base_addr) begin
                            s2mm_addr <= start_addr1;
                            start_addr1 <= start_addr;
                        end
                        else begin
                            s2mm_addr <= start_addr1;
                            start_addr1 <= start_addr1 + base_addr;
                        end
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                else begin
                    s2mm_addr <= s2mm_addr;
                    state <= WAIT;
                end                    
            end
            END:begin
                if(s2mm_cmd_tready) begin 
                    s2mm_tvalid <= 1'b1;
                    state <= WAIT;
                    s2mm_burst_len <= (data_count + 4) * 16;
                    total_cnt <= total_cnt + data_count + 4;
                    total_cnt_flag <= 1'b1;
                    tag <= 4'd2;
                end
                else begin
                    s2mm_tvalid <= s2mm_tvalid;
                    state <= END;
                    s2mm_burst_len <= s2mm_burst_len;
                    tag <= tag;
                end 
            end
            default:begin
                state <= IDLE;
                s2mm_addr <= start_addr ;
                s2mm_burst_len <= s2mm_burst_len;
                s2mm_tvalid <= s2mm_tvalid;            
            end
        endcase
    end
end

endmodule

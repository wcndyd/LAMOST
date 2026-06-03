`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/08 16:44:54
// Design Name: 
// Module Name: width_convert
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


module width_convert#(
    parameter       Width_i     =   256         ,
    parameter       Width_o     =   8           ,
    parameter       Convert_cnt =   32          ,
    parameter       Thres       =   16
)
(
    input                       clk         ,
    input                       rst_n       ,
    input                       empty       ,
    input   [Width_i-1:0]       data_i      ,
    output  reg                 data_rd     ,            
    output  [Width_o-1:0]       data_o      ,
    output                      data_en     
);

 parameter      IDLE    =   2'd1;
 parameter      Convert =   2'd2;
 
reg     [7 :0]                  Conv_cnt    ; 
reg     [Width_i-1:0]           data_temp   ;
reg     [1 :0]                  state       ;

 
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        data_rd <= 1'b0;
    else if((!empty)&&(Conv_cnt == 'd0))
        data_rd <= 1'b1;
    else 
        data_rd <= 1'b0;
end

assign data_o = ((state == Convert) && (data_temp[Width_o-1:0] >= Thres))?data_temp[Width_o-1:0]:'d0;    //ãÐÖµ·Ö¸î
assign data_en = (state == Convert)?'d1:'d0;
 
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_temp <= 'd0;
        state <= IDLE;
        Conv_cnt <= 'd0;
    end
    else begin
        case(state)
            IDLE: begin
                if(!empty) begin
                    data_temp <= data_i;
                    state <= Convert;
                    Conv_cnt <= Convert_cnt - 1'b1;
                end
                else begin
                    data_temp <= 'd0;
                    state <= IDLE; 
                    Conv_cnt <= 'd0;                    
                end
            end
            
            Convert: begin
                if(Conv_cnt == 'd0) begin
                    if(!empty) begin
                        data_temp <= data_i;
                        Conv_cnt <= Convert_cnt - 1'b1;
                        state <= Convert;
                    end
                    else begin
                        data_temp <= 'd0;
                        Conv_cnt <= 'd0;
                        state <= IDLE;                    
                    end
                end
                else begin
                    data_temp <= {{Width_o{1'b0}},data_temp[Width_i-1:Width_o]};
                    Conv_cnt <= Conv_cnt - 1'b1;
                    state <= Convert;
                end
            end
            
            default: begin
                data_temp <= 'd0;
                state <= IDLE;
                Conv_cnt <= 1'b0;
            end
        endcase
    end
end 
 
 

endmodule

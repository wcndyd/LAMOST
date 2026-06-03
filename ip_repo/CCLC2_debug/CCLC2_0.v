`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/16 21:38:02
// Design Name: 
// Module Name: CCLC2_0
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


module CCLC2_0  #(                                          //Connected Component Labeling Calculate
  parameter Width           = 7920  ,                       //图像宽度
  parameter Height          = 6000  ,                       //图像高度
  parameter ROW_start       = 0     ,                       //图像在原图中的起点
  parameter Data_W          = 8     ,                       //图像位宽
  parameter COL_W           = 13    ,                       //宽度数据位宽
  parameter ROW_W           = 13    ,                       //高度数据位宽
  parameter X_weight_W      = 28    ,                       //X权重位宽
  parameter Y_weight_W      = 28    ,                       //Y权重位宽
  parameter Gray_W          = 14    ,                       //灰度值位宽
  parameter M_flag_W        = 5     ,                       //拼接标识符计数位宽
  parameter count_W         = 10    ,                       //灰度点数总点数位宽
  parameter length_W        = 6     ,                       //每一个游程长度
  parameter Output_data_W   = 80    ,                       //输出数据位宽
  parameter BLK_W           = 99                            //储存拼接数据所需的ROM位宽
  )
  (
  input                                 clk                         ,           //时钟
  input                                 rst_n                       ,           //复位
  input                                 data_valid                  ,           //输入数据有效
  input             [Data_W-1:0]        data                        ,           //输入数据
  output    reg                         Output_En                   ,           //输出数据有效
  output    reg     [Output_data_W-1:0] Output_data                 ,           //输出数据
  output    reg                         frame_flag                  ,           //这部分图像数据结束标识符
  output            [M_flag_W-1:0]      merge_num                   ,           //所储存的所有的可以拼接的数量
  output            [BLK_W-1:0]         blk_out                     ,           //ROM数据输出
  output    reg     [M_flag_W-1:0]      blk_down_addr               ,           //图像底部拼接的起始地址
  input                                 blk_data_en                 ,           //读出ROM输出使能信号
  output                                ready                                   //由于使用复位对模块进行初始化，ready是为了判断相关FIFO ROM等是否能够使用
 );

localparam FIFO_w = M_flag_W+X_weight_W+Y_weight_W+Gray_W+count_W+length_W+COL_W;           //FIFO所存入的结构组成，规定FIFO宽度
//localparam BLK_W = X_weight_W+Y_weight_W+Gray_W+count_W+length_W+COL_W;                   //ROM存入的结构组成


//指明每个结构的高位和低位，便于引用和数据拼接
localparam length_LSB = COL_W;
localparam length_MSB = COL_W + length_W -1;
localparam count_LSB = COL_W + length_W;
localparam count_MSB = COL_W+ length_W + count_W  -1;
localparam Gray_LSB = COL_W + length_W + count_W;
localparam Gray_MSB = COL_W + length_W + count_W + Gray_W -1;
localparam Y_LSB = COL_W + length_W + count_W + Gray_W;
localparam Y_MSB = COL_W+ length_W + count_W  + Gray_W + Y_weight_W -1;
localparam X_LSB = COL_W + length_W + count_W + Gray_W + Y_weight_W;
localparam X_MSB = COL_W+ length_W + count_W  + Gray_W + Y_weight_W + X_weight_W-1;


//游程拼接阶段，负责读出本行位置之前的游程记录，与连通域拼接和输出有关
localparam  merge_IDLE              = 6'b000001;
localparam  first_row               = 6'b000010;
localparam  follow_row              = 6'b000100;
localparam  cells_merge             = 6'b001000;
localparam  last_fifo               = 6'b010000;
localparam  END                     = 6'b100000;

//游程检测阶段，负责识别相关的游程数据，和游程数据写入有关
localparam  cell_IDLE               = 2'b01;
localparam  row_detection           = 2'b10; 

//FIFO写入，负责写入游程数据
localparam  process_IDLE            = 4'b0001;  
localparam  cell_detection          = 4'b0010;
localparam  wait_next_cell          = 4'b0100;
localparam  cell_wr                 = 4'b1000;

//ROM控制，负责记录拼接部分的数据
localparam  blk_IDLE                = 5'b00001;
localparam  blk_up_x                = 5'b00010;
localparam  blk_up_data             = 5'b00100;
localparam  blk_down_data           = 5'b01000;
localparam  blk_clear               = 5'b10000;

reg     [5:0]                   state_merge         ;//游程拼接阶段
reg     [1:0]                   state_cell          ;//游程检测阶段 
reg     [3:0]                   state_cell_process  ;//FIFO写入
reg     [4:0]                   state_blk           ;//ROM控制 
    
reg                             FIFO_wren           ;//FIFO写使能
reg     [FIFO_w-1:0]            Data_in             ;//FIFO输入数据

//一个是原本的行列计数，供乘法器使用，一个是打拍后的行列计数器，供全局使用
reg     [COL_W-1:0]             col_cnt_2           ;
reg                             col_cnt_2_valid     ;
reg     [ROW_W-1:0]             row_cnt_2           ;
reg     [COL_W-1:0]             col_cnt             ;
reg     [ROW_W-1:0]             row_cnt             ;

//打拍是为了使用乘法器，乘法器输出有3段延迟，打三拍能够直接使用乘法器结果
reg     [Data_W-1 : 0]          data_0              ;//打一拍
reg     [Data_W-1 : 0]          data_1              ;//打两拍
reg     [Data_W-1 : 0]          data_2              ;//打三拍
reg     [Data_W-1 : 0]          data_3              ;//保存前一个数据，找到区域的开头
reg                             data_valid_0        ;//打一拍
reg                             data_valid_1        ;//打两拍
reg                             data_valid_2        ;//打三拍

reg                             FIFO_rden           ;//FIFO读使能
reg     [FIFO_w-1:0]            temp_summary        ;//暂时存入本行特定位置上一行所对应的连通域信息
reg     [length_W-1:0]          length              ;//暂时存入本行特定位置上一行对应的连通域长度，用来遍历判断上一行连通域下方是否有有效连通域，以判断是否将结束的连通域读出
reg     [length_W-1:0]          cells_length        ;//用以给length计数，用作遍历使用
reg                             frame_end           ;//这一部分数据处理结束，遍历完所有数据，输出结束标识符
reg                             blk_temp_flag_up    ;//上部分拼接标识符，提供给ROM处理状态机，提示其存入ROM
reg                             blk_temp_flag_down  ;//下部分拼接标识符，提供给ROM处理状态机，提示其存入ROM
reg     [M_flag_W+BLK_W-1:0]    blk_temp_data       ;//拼接数据暂存寄存器，暂时将拼接数据存入其中供ROM使用
reg                             abandon_flag        ;//舍弃标识符，表示这部分游程数据既不存入也不输出，舍弃，也提供给temp_summary_2使用，将其清零，免得污染数据

reg     [9:0]                   res_cnt             ;

reg     [length_W-1:0]          cell_length         ;//计算连通域长度  
reg     [X_weight_W-1:0]        cell_x_weight       ;//计算连通域x权重
reg     [Y_weight_W-1:0]        cell_y_weight       ;//计算连通域y权重
reg     [count_W-1:0]           cell_count          ;//计算连通域数量
reg     [Gray_W-1:0]            cell_weight         ;//计算连通域灰度权重
reg     [COL_W-1:0]             start_x             ;//起始点x坐标
reg                             merge_flag          ;//合并标识符

wire    [FIFO_w-1:0]            summary_cells       ; 
assign summary_cells = {{M_flag_W{1'b0}},cell_x_weight,cell_y_weight,cell_weight,cell_count,cell_length,start_x};  

reg     [length_W-1:0]          cell_length_2       ;//给cell_length打拍，供last_cell_vaild使用

reg     [FIFO_w-1:0]            temp_summary_2      ;//temp_summary的副本，保存其信息，判断是否说舍弃还是合并
reg     [FIFO_w-1:0]            summary_cells_2     ;//summary_cells的副本，保存其信息，因为summary_cell使wire类型，变化比较快，保存其信息能够流出很多操作空间

//产生游程结束边沿信号
reg                             cells_end           ;           //游程结束标识符兼打拍，使用其上升沿
reg                             cells_end_1         ;
wire                            cells_end_pulse     ;
assign  cells_end_pulse = ~cells_end_1 & cells_end;         //检测结束信号上升沿，提供FIFO写信号

reg     [BLK_W-1:0]             blk_data_in         ;       //ROM数据输入
wire    [BLK_W-1:0]             blk_data_out        ;       //ROM数据输出
reg                             blk_wea             ;       //ROM读写选择
reg                             blk_en              ;       //ROM读写使能
reg     [M_flag_W-1:0]          blk_addr            ;       //ROM读写地址
reg     [M_flag_W-1:0]          blk_addr_1          ;       //给供给拼接模块使用的读出地址
assign blk_out = blk_data_out;  
 
reg     [M_flag_W-1:0]          merge_cnt           ;//记录rom中已经存入多少待拼接数据，但其显示会多加一个
assign merge_num = merge_cnt;    

    
wire                            empty               ;
                 
wire    [COL_W-1:0]             x                   ;
wire    [ROW_W-1:0]             y                   ;
// 微调坐标数据，纠正乘法计算
assign x = col_cnt + 1'b1;
assign y = row_cnt + 1'b1;

wire    [20:0]                  x_weight            ;
wire    [20:0]                  y_weight            ;
wire    [FIFO_w-1:0]            Data_out            ;
  
wire                            rsta_busy           ;
wire                            wr_rst_busy         ;
wire                            rd_rst_busy         ;
assign ready = ~(rd_rst_busy|wr_rst_busy|rsta_busy);


wire                            last_cell_vaild     ;//判断此位置是否是有效的游程
assign last_cell_vaild = ((cell_length!=cell_length_2)&&cell_length>=2)? 1'b1:1'b0;//判断cell_length是否在变动，在变动表示此位置数据有游程，还要要求是否长度大于2，免得是噪点







always@(posedge clk or negedge rst_n) begin //给数据打拍，使乘法数据出来的结果能够被直接使用
    if(!rst_n)  
        begin
            data_0 <= {Data_W{1'b0}};
            data_1 <= {Data_W{1'b0}};
            data_2 <= {Data_W{1'b0}};
            data_valid_0 <= 1'b0;       
            data_valid_1 <= 1'b0;
            data_valid_2 <= 1'b0; 
        end
    else 
        begin
            data_0 <= data;
            data_1 <= data_0;
            data_2 <= data_1;
            data_valid_0 <= data_valid&ready   ;            
            data_valid_1 <= data_valid_0 ;              
            data_valid_2 <= data_valid_1 ;
        end
end

always@(posedge clk or negedge rst_n) begin     //data3是为了判断连通区域的开头，对上一次数据进行一次打拍
    if(!rst_n)  
        data_3 <= {Data_W{1'b0}};          
    else if(data_valid_2)
        data_3 <= data_2;
end


always@(posedge clk or negedge rst_n) begin     //列计数，提供给乘法器做计算
    if(!rst_n)
        col_cnt <= 'd0;
    else if(data_valid&ready)
        begin
            if(col_cnt == Width - 1)
                col_cnt <= 'd0;
            else 
                col_cnt <= col_cnt + 1'b1;
        end
    else
        col_cnt <= col_cnt;
end

always@(posedge clk or negedge rst_n) begin     //列计数2，提供给状态机做判断
    if(!rst_n) begin
        col_cnt_2 <= 'd0;
        col_cnt_2_valid <= 1'b0;            //提供判断，避免数据有效中断
    end
    else if(data_valid_2) begin
        col_cnt_2_valid <= 1'b1;
        if(col_cnt_2 == Width - 1)
            col_cnt_2 <= 'd0;
        else 
            col_cnt_2 <= col_cnt_2 + 1'b1;
    end
    else begin
        col_cnt_2 <= col_cnt_2;
        col_cnt_2_valid <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n) begin     //行计数，提供给乘法器
    if(!rst_n)
        row_cnt <= ROW_start;
    else if(data_valid&ready)
        begin
            if(col_cnt == Width - 1)
                begin
                    if(row_cnt == ROW_start + Height - 1)
                        row_cnt <= ROW_start;
                    else
                        row_cnt <= row_cnt + 1'b1;
                end
            else 
                row_cnt <= row_cnt;
        end
    else
        row_cnt <= row_cnt;
end

always@(posedge clk or negedge rst_n) begin //行计数2，提供给状态机做判断
    if(!rst_n)
        row_cnt_2 <= ROW_start;
    else if(data_valid_2) begin
        if(col_cnt_2 == Width - 1)
            begin
                if(row_cnt_2 == ROW_start + Height - 1)
                    row_cnt_2 <= ROW_start;
                else
                    row_cnt_2 <= row_cnt_2 + 1'b1;
            end
        else 
            row_cnt_2 <= row_cnt_2;
    end
    else
        row_cnt_2 <= row_cnt_2;
end

//控制FIFO读出
//具体思路是，先等第一行所有区域存入，进入后续行以后，按照当前列进行检测，若当前列数正好是FIFO中存的连通域的起始坐标，则将其读出存入temp
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        FIFO_rden               <= 1'b0         ;       
        temp_summary            <= 'd0          ;       
        length                  <= 'd0          ;       
        cells_length            <= 'd0          ;       
        Output_En               <= 1'b0         ;       //模块输出使能。将已经闭合的连通域的数据输出
        Output_data             <= 'd0          ;       //数据输出    
        state_merge             <= merge_IDLE   ;
        frame_end               <= 1'b0         ;       
        blk_temp_flag_down      <= 1'b0         ;
        blk_temp_flag_up        <= 1'b0         ;
        blk_temp_data           <= 'd0          ;
        abandon_flag            <= 1'b0         ;
    end
    else begin
        case(state_merge)
            merge_IDLE:begin                 
                FIFO_rden <= 1'b0;                                              //数据初始化
                temp_summary <= 'd0;
                if(row_cnt_2 == ROW_start && data_valid_2)                      //进入第一行检测
                    state_merge <= first_row;      
                else 
                    state_merge <= merge_IDLE;
            end
            first_row:begin                     //第一行不读出FIFO，故特设第一行状态
                FIFO_rden <= 1'b0;
                if(row_cnt_2 == ROW_start && col_cnt_2 == Width - 1)            //第一行结束，进入后续行
                    state_merge <= follow_row;
                else
                    state_merge <= first_row;
            end
            follow_row:begin                            //利用FIFO的first word fall through,在没有读出的时候就能在信号线上知道之前存入的连通域信息
                Output_En <= 1'b0;                      //以下数据仅使能一个时钟，在此将其归零
                blk_temp_flag_down <= 1'b0;
                abandon_flag <= 1'b0;
                blk_temp_flag_up <= 1'b0;
                if(col_cnt_2 == Width - 1 && data_valid_2) begin   //特殊情况，已经检测一行，位于行末
                    if(row_cnt_2 == ROW_start + Height - 1) begin               //位于帧末，结束行检测
                        state_merge <= last_fifo;
                        FIFO_rden <= 1'b0;
                    end
                    else if(Data_out[COL_W-1:0] == Width - 1 && !empty)begin       //位于行末，且行末有一个像素有效，读取此连通域，太偏僻，直接舍弃，temp清零
                        temp_summary <= 'd0;
                        FIFO_rden <= 1'b1;
                        state_merge <= follow_row;                            
                    end
                    else begin                                      //一般情况，行末的temp清零
                        temp_summary <= 'd0;
                        FIFO_rden <= 1'b0;
                        state_merge <= follow_row;                        
                    end
                end
                else if(col_cnt_2 == Data_out[COL_W-1:0] && data_valid_2 && !empty) begin  //不在行末的情况
                    if(cells_end_pulse) begin
                        FIFO_rden <= 1'b1;
                        temp_summary <= Data_out;       
                        length <= Data_out[length_MSB:length_LSB];
                        cells_length <= 'd0;
                        state_merge <= cells_merge;     //因为此时为上一个区域刚写入，所以此时的点位必定为零，直接进入合并判断                    
                    end
                    else begin
                        FIFO_rden <= 1'b1;
                        temp_summary <= Data_out;       
                        length <= Data_out[length_MSB:length_LSB];
                        cells_length <= 'd0;
                        if(last_cell_vaild)               //如果当前有有效游程，就直接不用再去判断
                            state_merge <= follow_row;
                        else
                            state_merge <= cells_merge;                        
                    end
                end  
                else begin                      
                    if(cells_end_pulse)
                        temp_summary <= 'd0;                           
                    FIFO_rden <= 1'b0;
                    cells_length <= 'd0;
                end
            end
            cells_merge:begin
                FIFO_rden <= 1'b0;                  //数据仅使能一个时钟，在此将其归零
                if(data_valid_2) begin              //数据有效才进行合并，
                    if(cells_length == length - 1) begin                //到了上一行连通域的结尾部分
                        if(last_cell_vaild) begin                       //如果下方游程有效，继续检测，进入检测状态follow_row
                            temp_summary <= temp_summary;
                            state_merge <= follow_row;
                            cells_length <= 'd0;
                        end
                        else begin                                                  //如果下方没有找到有效游程
                            if(temp_summary[count_MSB:count_LSB] <= 3) begin        //如果连通域大小小于一定值舍弃，避免误识噪点
                                temp_summary <= 'd0;        
                                Output_En <= 1'b0;
                                state_merge <= follow_row;  
                                abandon_flag <= 1'b1;
                            end
                            else begin                                              //如果符合输出条件
                                if(temp_summary[X_MSB+1 +:M_flag_W]!= 0) begin      //判断是否是上面可拼接部分，如是，使能相关标志位，提供给ROM状态机处理
                                    blk_temp_data <= temp_summary;
                                    blk_temp_flag_up <= 1'b1;
                                    state_merge <= follow_row;
                                    temp_summary <= 'd0;
                                end
                                else begin                                          //如不是直接输出
                                    Output_data <= temp_summary[X_MSB:count_LSB];
                                    Output_En <= 1'b1;
                                    temp_summary <= 'd0;                                 
                                    state_merge <= follow_row;
                                end
                            end
                        end
                    end
                    else if(cells_length < length - 1) begin                        //在遍历范围之内，仍在寻找
                        if(last_cell_vaild) begin                                   //找到连通，继续检测，进入检测状态follow_row
                            temp_summary <= temp_summary;
                            state_merge <= follow_row;
                            cells_length <= 'd0;
                        end
                        else begin                                                  //还没找到，长度继续累加，继续寻找
                            cells_length <= cells_length + 1'b1;
                            state_merge <= cells_merge;
                        end     
                    end
                end
                else
                    state_merge <= cells_merge;
            end
            last_fifo:begin                                     //每一行都检测了，最后处理FIFO部分是否有剩余
                if(!empty) begin
                    FIFO_rden <= 1'b1;                    
                    if(FIFO_rden && Data_out[count_MSB:count_LSB] > 12'd2) begin                    //因为FIFO最后储存的一定是下面的拼接部分，使能相关标识符，给ROM状态机处理
                        blk_temp_data <= Data_out;
                        blk_temp_flag_down <= 1'b1;
                        state_merge <= last_fifo;
                    end
                    else begin      //如果连通域大小小于一定值舍弃                        
                        state_merge <= last_fifo;
                        blk_temp_flag_down <= 1'b0;                        
                    end
                end
                else begin
                    FIFO_rden <= 1'b0;
                    Output_data <= {Output_data_W{1'b0}} | res_cnt;
                    Output_En <= 1'b0;
                    state_merge <= END;
                    blk_temp_flag_down <= 1'b0;                    
                end

            end
            END:begin
                    state_merge  <= END;
                    frame_end <= 1'b1;
            end
            default:begin
                state_merge     <= merge_IDLE;
                FIFO_rden       <= 1'b0;
                Output_En       <= 1'b0 ;
            end
        endcase
    end
end
//将frame_flag赋值
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        frame_flag <= 1'b0;
    else if(frame_end)
        frame_flag <= 1'b1;
    else 
        frame_flag <= frame_flag;
end

//给cell_length打拍，供last_cell_vaild使用
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cell_length_2 <= 'd0;
    else if(col_cnt_2_valid)
        cell_length_2 <= cell_length;
    else 
        cell_length_2 <= cell_length_2;
end


//对输出计数
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        res_cnt <= 'd0;
    else if(Output_En)
        res_cnt <= res_cnt + 1'b1;
    else if(frame_end)
        res_cnt <= 'd0;
    else 
        res_cnt <= res_cnt;
end

always@(posedge clk or negedge rst_n) begin                 //产生结束边沿信号 因为行信号比边沿信号快一拍，所以将行信号打一拍，避免将行最后一个像素才输出结束忽略识别
    if(!rst_n)  begin
        cells_end_1 <= 1'b0;
    end
    else 
        cells_end_1 <= cells_end;
end


//游程识别阶段
//通过判断相邻两个的像素点信息判断游程的起点，中间，终点，并进行权重累加
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state_cell      <=  cell_IDLE   ;
        cell_length     <=  'd0         ; 
        cell_x_weight   <=  'd0         ;
        cell_y_weight   <=  'd0         ;
        cell_count      <=  'd0         ;
        cell_weight     <=  'd0         ;
        start_x         <=  'd0         ;
        cells_end       <=  'b0         ;//连通域结束标志
        merge_flag      <=  'd0         ;
    end
    else begin
        case(state_cell)
            cell_IDLE:begin
                if(data_valid && ready && (row_cnt == ROW_start))
                    state_cell <= row_detection;                        //进入行检测
                else
                    state_cell <= cell_IDLE;
            end
            row_detection: begin
                if(col_cnt_2_valid) begin
                    if(row_cnt_2 == ROW_start + Height - 1) begin       //最后一行                
                        if(col_cnt_2 == Width - 1) begin                //行末像素 
                            state_cell <= cell_IDLE;    //最后一个像素，结束行检测
                            if((data_3 != 'd0)&&(data_2 == 'd0)) begin  //此像素为连通域结束像素，标志位置一
                                cells_end <= 1'b1;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0))begin  //此像素为连通域中间像素，进行信息收集，数据累加，以为是行末像素，直接结束，标志位置一
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;
                                cells_end <= 1'b1; 
                            end
                            else begin
                                cells_end <= 1'b0;
                            end
                        end
                        else if(col_cnt_2 != 'd0) begin
                            if((data_3 == 'd0)&&(data_2 != 'd0)) begin //区域起始像素，数据初始化
                                cells_end <= 1'b0;
                                start_x <= col_cnt_2;
                                cell_count <= 1'b1;
                                cell_length <= 1'b1;
                                cell_x_weight <= x_weight;
                                cell_y_weight <= y_weight;
                                cell_weight <= data_2;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0)) begin //区域中间像素，数据累加
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;                
                            end 
                            else if((data_3 != 'd0)&&(data_2 == 'd0)) begin //区域结束像素，输出标志位
                                cells_end <= 1'b1;
                            end                    
                        end 
                        else begin              //行首像素，数据赋初值，无论行首像素是否有效，都适用
                            state_cell <= state_cell;
                            cells_end <= 1'b0;
                            start_x <= 13'd0;
                            cell_count <= 1'b1;
                            cell_length <= 1'b1;
                            cell_x_weight <= x_weight;
                            cell_y_weight <= y_weight;
                            cell_weight <= data_2;
                        end
                    end
                    else if(row_cnt_2 == ROW_start) begin           //首行
                        merge_flag <= 1'b1;                         //在首行的时候使能合并标识符，能够使表示首行存入的游程，其与上半部分的拼接部分相关
                        if(col_cnt_2 == Width - 1) begin            //行末像素                           
                            if((data_3 != 'd0)&&(data_2 == 'd0)) begin  //此像素为连通域结束像素，标志位置一
                                cells_end <= 1'b1;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0))begin  //此像素为连通域中间像素，进行信息收集，数据累加，以为是行末像素，直接结束，标志位置一
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;
                                cells_end <= 1'b1; 
                            end
                            else begin
                                cells_end <= 1'b0;
                            end
                        end
                        else if(col_cnt_2 != 'd0) begin
                            if((data_3 == 'd0)&&(data_2 != 'd0)) begin //区域起始像素，数据初始化
                                cells_end <= 1'b0;
                                start_x <= col_cnt_2;
                                cell_count <= 1'b1;
                                cell_length <= 1'b1;
                                cell_x_weight <= x_weight;
                                cell_y_weight <= y_weight;
                                cell_weight <= data_2;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0)) begin //区域中间像素，数据累加
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;                
                            end 
                            else if((data_3 != 'd0)&&(data_2 == 'd0)) begin //区域结束像素，输出标志位
                                cells_end <= 1'b1;
                            end                    
                        end 
                        else begin              //行首像素，数据赋初值，无论行首像素是否有效，都适用
                            state_cell <= state_cell;
                            cells_end <= 1'b0;
                            start_x <= 13'd0;
                            cell_count <= 1'b1;
                            cell_length <= 1'b1;
                            cell_x_weight <= x_weight;
                            cell_y_weight <= y_weight;
                            cell_weight <= data_2;
                        end
                    end 
                    else begin                                      //中间部分，如果检测到游程顺便把合并标识符关掉
                        if(col_cnt_2 == Width - 1) begin            //行末像素 
                            if((data_3 != 'd0)&&(data_2 == 'd0)) begin  //此像素为连通域结束像素，标志位置一
                                cells_end <= 1'b1;
                                merge_flag <= 1'b0;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0))begin  //此像素为连通域中间像素，进行信息收集，数据累加，以为是行末像素，直接结束，标志位置一
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;
                                cells_end <= 1'b1;
                                merge_flag <= 1'b0;
                            end
                            else begin
                                cells_end <= 1'b0;
                            end
                        end
                        else if(col_cnt_2 != 'd0) begin
                            if((data_3 == 'd0)&&(data_2 != 'd0)) begin //区域起始像素，数据初始化
                                cells_end <= 1'b0;
                                start_x <= col_cnt_2;
                                cell_count <= 1'b1;
                                cell_length <= 1'b1;
                                cell_x_weight <= x_weight;
                                cell_y_weight <= y_weight;
                                cell_weight <= data_2;
                            end
                            else if((data_3 != 'd0)&&(data_2 != 'd0)) begin //区域中间像素，数据累加
                                cell_count <= cell_count + 1'b1;
                                cell_length <= cell_length + 1'b1;
                                cell_x_weight <= cell_x_weight + x_weight;
                                cell_y_weight <= cell_y_weight + y_weight;
                                cell_weight <= cell_weight + data_2;                
                            end 
                            else if((data_3 != 'd0)&&(data_2 == 'd0)) begin //区域结束像素，输出标志位
                                cells_end <= 1'b1;
                                merge_flag <= 1'b0;
                            end                    
                        end 
                        else begin              //行首像素，数据赋初值，无论行首像素是否有效，都适用
                            state_cell <= state_cell;
                            cells_end <= 1'b0;
                            start_x <= 13'd0;
                            cell_count <= 1'b1;
                            cell_length <= 1'b1;
                            cell_x_weight <= x_weight;
                            cell_y_weight <= y_weight;
                            cell_weight <= data_2;
                        end
                    end
                end
                else begin      //若数据有效位中断
                    state_cell <= state_cell;
                    cells_end <= cells_end;
                    start_x <= start_x;
                    cell_count <= cell_count;
                    cell_length <= cell_length;
                    cell_x_weight <= cell_x_weight;
                    cell_y_weight <= cell_y_weight;
                    cell_weight <= cell_weight;
                end
            end
            default:begin
                state_cell <= cell_IDLE;
            end
        endcase
    end
end




//temp_summary的副本，保存其信息，对其进行是否清零或合并的操作
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        temp_summary_2 <= 'd0;
    end
    else if(FIFO_rden && FIFO_wren)             //读写在同一时间，说明temp是更新的不要合并
        temp_summary_2 <= temp_summary;
    else if(FIFO_rden && !FIFO_wren)            //此时可以视为和前面游程连续，对M_flag ,length,start_x区别对待
        temp_summary_2 <= {temp_summary[FIFO_w-1 -: M_flag_W],temp_summary_2[X_MSB:X_LSB]+temp_summary[X_MSB:X_LSB],temp_summary_2[Y_MSB:Y_LSB]+temp_summary[Y_MSB:Y_LSB],temp_summary_2[Gray_MSB:Gray_LSB]+temp_summary[Gray_MSB:Gray_LSB],temp_summary_2[count_MSB:count_LSB]+temp_summary[count_MSB:count_LSB],{length_W{1'b0}},temp_summary_2[COL_W-1: 0]};
    else if(FIFO_wren || blk_temp_flag_down || blk_temp_flag_up || Output_En || abandon_flag)//这几个标志为都能对其进行清零更新
        temp_summary_2 <= 'd0;
    else 
        temp_summary_2 <= temp_summary_2;
end


//FIFO写使能，负责游程的判断检测和有效写入，对上半部拼接部分进行标定
reg     [2:0]                   end_cnt             ;//主要是为了衔接特殊点，有些游程中间之隔了一两个点，计数判断是否他们能够被连接
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        FIFO_wren <= 1'b0;
        summary_cells_2 <= 'd0;
        end_cnt <= 'd0;
        state_cell_process <= process_IDLE;
        Data_in <= 'd0;
    end
    else begin
        case(state_cell_process)
            process_IDLE:begin
                FIFO_wren <= 1'b0;                  //仅使能一个时钟
                if(cells_end_pulse) begin
                    if(summary_cells[length_MSB:length_LSB] > 1) begin      //判断游程长度，不要单一的点
                        summary_cells_2 <= summary_cells;
                        if(data_2 != 'd0) begin                             
                            state_cell_process <= wait_next_cell;
                            end_cnt <= 'd0;
                        end
                        else begin 
                            state_cell_process <= cell_detection;    //进入行检测
                            end_cnt <= 'd1;
                        end
                    end
                    else begin
                        summary_cells_2 <= 'd0;
                        state_cell_process <= process_IDLE;
                        end_cnt <= 'd0;
                    end
                end
                else
                    state_cell_process <= process_IDLE;
            end
            cell_detection:begin                    //检测是否间隔一定长度后有游程
                if(data_2 != 'd0) begin
                    state_cell_process <= wait_next_cell;
                    end_cnt <= 'd0;
                end
                else if(end_cnt == 3'd1) begin
                    state_cell_process <= cell_wr;
                end
                else if(col_cnt_2_valid) begin
                    end_cnt <= end_cnt + 1'b1;
                end
            end
            wait_next_cell:begin                   //检测到游程还要检测是否是有效游程，是有效游程则合并
                if(cells_end_pulse) begin
                    if(summary_cells[length_MSB:length_LSB] > 1) begin
                        state_cell_process <= cell_detection;    //进入行检测
                        summary_cells_2 <= {{M_flag_W{1'b0}},summary_cells_2[X_MSB:X_LSB]+summary_cells[X_MSB:X_LSB],summary_cells_2[Y_MSB:Y_LSB]+summary_cells[Y_MSB:Y_LSB],summary_cells_2[Gray_MSB:Gray_LSB]+summary_cells[Gray_MSB:Gray_LSB],summary_cells_2[count_MSB:count_LSB]+summary_cells[count_MSB:count_LSB],{summary_cells_2[length_MSB:length_LSB]+summary_cells[length_MSB:length_LSB]+end_cnt+1'b1},summary_cells_2[COL_W-1: 0]};
                        end_cnt <= 3'd0;
                    end
                    else begin
                        state_cell_process <= cell_wr;
                        end_cnt <= 'd0;
                    end                
                end
                else if(data_3 == 'd0) begin                            //感觉是冗余操作
                    state_cell_process <= cell_wr;
                    end_cnt <= 'd0;                
                end
            end
            cell_wr:begin                           //写入有效游程
                if(merge_flag) begin                //如果还在第一行判断时，检测到的基本都是上半部分的，将其merge_flag部分进行标志位计数，供ROM状态机使用
                    Data_in <= {merge_cnt,summary_cells_2[X_MSB:X_LSB],summary_cells_2[Y_MSB:Y_LSB],summary_cells_2[Gray_MSB:Gray_LSB],summary_cells_2[count_MSB:count_LSB],summary_cells_2[length_MSB:length_LSB],summary_cells_2[COL_W-1:0]};
                    FIFO_wren <= 1'b1;
                    state_cell_process <= process_IDLE;
                    summary_cells_2 <= 'd0;
                end
                else begin                          //不在第一行时，merge_cnt继承，length,start_x更新，其他的进行合并
                    Data_in <= {temp_summary_2[FIFO_w-1 -: M_flag_W],summary_cells_2[X_MSB:X_LSB]+temp_summary_2[X_MSB:X_LSB],summary_cells_2[Y_MSB:Y_LSB]+temp_summary_2[Y_MSB:Y_LSB],summary_cells_2[Gray_MSB:Gray_LSB]+temp_summary_2[Gray_MSB:Gray_LSB],summary_cells_2[count_MSB:count_LSB]+temp_summary_2[count_MSB:count_LSB],summary_cells_2[length_MSB:length_LSB],summary_cells_2[COL_W-1:0]};
                    FIFO_wren <= 1'b1;
                    state_cell_process <= process_IDLE;
                    summary_cells_2 <= 'd0;
                end    
            end
            default:begin
                summary_cells_2 <= 'd0;
                state_cell_process <= process_IDLE;
                FIFO_wren <= 1'b0;
            end
        endcase
    end
end


//ROM读写状态机
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        blk_addr <= 'd0;                    //ROMaddr
        blk_data_in <= 'd0;                 //ROM数据输入
        blk_wea <= 1'b0;                    //读写选择
        blk_en <= 1'b0;                     //读写使能
        merge_cnt <= 'd1;                   //带拼接部分标志位
        blk_addr_1 <= 'd1;                  //结束后提供给拼接模块所使用的读地址
        state_blk <= blk_IDLE;              //
        blk_down_addr <= 'd1;               //记录下半拼接部分起始地址
    end
    else begin
        case(state_blk)
            blk_IDLE:begin
                if(state_cell_process == cell_wr && merge_flag) begin               //在第一行检测时存入部分信息并通过拼接标志位排序，包括length，start_x
                    blk_data_in <= {{X_weight_W{1'b0}},{Y_weight_W{1'b0}},{Gray_W{1'b0}},{count_W{1'b0}},summary_cells_2[length_MSB:length_LSB],summary_cells_2[COL_W-1:0]};
                    blk_addr <= merge_cnt;
                    state_blk <= blk_up_x;
                    merge_cnt <= merge_cnt + 1'b1;
                    blk_en <= 1'b0;
                end
                else if(blk_temp_flag_up) begin                                    //上半带拼接部分的连通域完全检测结束，将剩余信息存入
                    state_blk <= blk_up_data;
                    blk_en <= 1'b1;
                    blk_wea <= 1'b0;                                                //先读取先前存入数据
                    blk_addr <= blk_temp_data[FIFO_w-1 -: M_flag_W];                //地址为之前设置的标识符
                    blk_down_addr <= merge_cnt;                                     //进入这个状态时merger_cnt不会变动了，所以存入的就是起始的下半部分地址
                end
                else if(blk_temp_flag_down) begin                                   //下半部分数据存入，必须谨慎判断其节拍，防止数据错位
                    state_blk <= blk_down_data;
                    blk_en <= 1'b1;
                    blk_wea <= 1'b1;
                    blk_addr <= merge_cnt;
                    blk_data_in <= {blk_temp_data[X_MSB:0]};
                    merge_cnt <= merge_cnt + 1'b1;
                end 
                else if(frame_flag) begin                                           //结束检测，提供接口供拼接部分读取
                    blk_en <= 1'b0;
                    state_blk <= blk_clear;
                    blk_addr_1 <= 'd1;
                    blk_wea <= 1'b0;
                end
                else begin
                    state_blk <= blk_IDLE;
                    blk_en <= 1'b0;
                    blk_wea <= 1'b0;
                end
            end
            blk_up_x:begin              //写入部分起始信息
                blk_en <= 1'b1;
                blk_wea <= 1'b1;
                state_blk <= blk_IDLE;
            end
            blk_up_data:begin           
                if(blk_en && !blk_wea) begin //先等待读出结束
                    blk_en <= 1'b0;
                    blk_wea <= 1'b1; 
                    state_blk <= blk_up_data;                
                end
                else begin                  //合并数据并存入
                    blk_data_in <= {blk_temp_data[X_MSB:X_LSB],blk_temp_data[Y_MSB:Y_LSB],blk_temp_data[Gray_MSB:Gray_LSB],blk_temp_data[count_MSB:count_LSB],blk_data_out[length_MSB:length_LSB],blk_data_out[COL_W-1:0]};  
                    blk_en <= 1'b1;
                    blk_wea <= 1'b1; 
                    state_blk <= blk_IDLE; 
                end
            end
            blk_down_data:begin             //下半部分数据存入，必须谨慎判断其节拍，防止数据错位
                if(state_merge == last_fifo) begin
                    if(blk_temp_flag_down) begin
                        blk_en <= 1'b1;
                        blk_wea <= 1'b1;
                        blk_addr <= merge_cnt;
                        blk_data_in <= {blk_temp_data[X_MSB:0]};
                        state_blk <= blk_down_data;
                        merge_cnt <= merge_cnt + 1'b1;
                    end 
                    else begin 
                        blk_en <= 1'b0;
                        blk_wea <= 1'b1;
                        blk_addr <= merge_cnt;
                        blk_data_in <= {blk_temp_data[X_MSB:0]};
                        state_blk <= blk_down_data;                    
                    end
                end
                else begin
                    blk_en <= 1'b0;
                    state_blk <= blk_IDLE;               
                end
            end
            blk_clear:begin
                if(blk_data_en) begin           //每使能一次读出一次数据
                    blk_en <= 1'b1;
                    blk_wea <= 1'b0;
                    blk_addr <= blk_addr_1;                   
                    blk_addr_1 <= blk_addr_1 + 1'b1;  
                    state_blk <= blk_clear; 
                end
                else if(blk_addr_1 == merge_cnt) begin
                    blk_en <= 1'b0;
                    state_blk <= blk_clear;
                end
                else begin
                    blk_en <= 1'b0;
                    state_blk <= blk_clear;                
                end
            end
            default:begin
                    blk_en <= 1'b0;
                    state_blk <= blk_IDLE; 
            end            
        endcase
    end
end

mult_gen_0 mult_x (
  .CLK          (clk)               ,       // input wire CLK
  .A            (data)              ,       // input wire [15 : 0] A
  .B            (x)                 ,       // input wire [12 : 0] B
  .P            (x_weight)                  // output wire [28 : 0] P
);

mult_gen_0 mult_y (
  .CLK          (clk)               ,       // input wire CLK
  .A            (data)              ,      // input wire [15 : 0] A
  .B            (y)                 ,      // input wire [12 : 0] B
  .P            (y_weight)                  // output wire [28 : 0] P
);



wire    [7:0]               data_count;
fifo_generator_0 FIFO1 (
  .clk                      (clk        )               ,                         // input wire clk
  .srst                     (~rst_n     )               ,                         // input wire srst
  .din                      (Data_in    )               ,                         // input wire [0 : 0] din
  .wr_en                    (FIFO_wren  )               ,                         // input wire wr_en
  .rd_en                    (FIFO_rden  )               ,                         // input wire rd_en
  .dout                     (Data_out   )               ,                         // output wire [0 : 0] dout
  .full                     (           )               ,                         // output wire full
  .empty                    (empty      )               ,                         // output wire empty
  .data_count               (data_count )               ,                         // output wire [8 : 0] data_count
  .wr_rst_busy              (wr_rst_busy)               ,                         // output wire wr_rst_busy
  .rd_rst_busy              (rd_rst_busy)                                         // output wire rd_rst_busy
);

blk_mem_gen_0 bram1 (
  .clka         (clk            ),            // input wire clka
  .rsta         (~rst_n         ),            // input wire rsta
  .ena          (blk_en         ),            // input wire ena
  .wea          (blk_wea        ),            // input wire [14 : 0] wea
  .addra        (blk_addr       ),            // input wire [5 : 0] addra
  .dina         (blk_data_in    ),            // input wire [119 : 0] dina
  .douta        (blk_data_out   ),            // output wire [119 : 0] douta
  .rsta_busy    (rsta_busy      )             // output wire rsta_busy
);               

endmodule






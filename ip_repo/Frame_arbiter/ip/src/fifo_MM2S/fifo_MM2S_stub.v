// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Sun Jan 11 10:35:14 2026
// Host        : DESKTOP-NG3G9C3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub d:/FPGA_prj/ip_repo/Frame_arbiter/ip/src/fifo_MM2S/fifo_MM2S_stub.v
// Design      : fifo_MM2S
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu4ev-sfvc784-1-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2020.2" *)
module fifo_MM2S(clk, srst, din, wr_en, rd_en, dout, full, almost_full, 
  empty, wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[255:0],wr_en,rd_en,dout[255:0],full,almost_full,empty,wr_rst_busy,rd_rst_busy" */;
  input clk;
  input srst;
  input [255:0]din;
  input wr_en;
  input rd_en;
  output [255:0]dout;
  output full;
  output almost_full;
  output empty;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule

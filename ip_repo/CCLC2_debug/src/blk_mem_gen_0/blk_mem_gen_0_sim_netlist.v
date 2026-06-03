// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Mon Jan 19 19:51:20 2026
// Host        : DESKTOP-NG3G9C3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/FPGA_prj/ip_repo/CCLC2_debug/src/blk_mem_gen_0/blk_mem_gen_0_sim_netlist.v
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu4ev-sfvc784-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_0
   (clka,
    rsta,
    ena,
    wea,
    addra,
    dina,
    douta,
    rsta_busy);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA RST" *) input rsta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [4:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [98:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [98:0]douta;
  output rsta_busy;

  wire [4:0]addra;
  wire clka;
  wire [98:0]dina;
  wire [98:0]douta;
  wire ena;
  wire rsta;
  wire rsta_busy;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [98:0]NLW_U0_doutb_UNCONNECTED;
  wire [4:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [4:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [98:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "5" *) 
  (* C_ADDRB_WIDTH = "5" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "1" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "1" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     9.81116 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "1" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_0.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "0" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "32" *) 
  (* C_READ_DEPTH_B = "32" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "99" *) 
  (* C_READ_WIDTH_B = "99" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "32" *) 
  (* C_WRITE_DEPTH_B = "32" *) 
  (* C_WRITE_MODE_A = "READ_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "99" *) 
  (* C_WRITE_WIDTH_B = "99" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_0_blk_mem_gen_v8_4_4 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[98:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[4:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(rsta),
        .rsta_busy(rsta_busy),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[4:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[98:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
QGLtnqZzRetDH6gCWT4Js6wuLlZfrNx/VJp3sfR2NF+cxypO5AxN0oDKLJJtmdrtE/ueNDg+Qf7Z
TqBNRojORA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
B6Ger3hRvfjHkaJ+W8639Kl3TzC9TogLuklOXEiMNdc4Im+DjEUzxb3DKlzu0VW3zxZqjJ3+wsW/
LnRmPCESi5Y9eRJaLFXg79EMfoj4X+nTdHAP6yCfltBADKegZ12gpnB/8ey5yn2KA74LUtPC7jna
iyjqSfsWLGnz6UdXzwk=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BX+DxgMPRyZbYojCUR9Sk8Lq+3ZigBz4yMFHQkmurfdfDzyTPJCE827eGiPyTenK1QPVhEtf9g06
0BFXq/0COPuU1BWJwdkz1c4dE6/exDwhvEh+hPx3vRY6z8fDEf6aGVIXrHDvrmddehe7yMSIpo+k
aXHR06EEdfHCFY4TggYwhcJVXjkE+ApsVuyfmEfPmYjo8hCWyQyBsUWIOY03q1+MvUjjsmTwgs9g
fh5MY9ToaLfoJxPKdCpsqrBX4LJ+VDGFlAqIcqHTE2jCmPiToZAFXB7fzf1wDjFCBlJyFVDBGi0i
m+CouLSb7X1mvVhdDZgNrZDJMV688Bu3o54vew==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DaIU/Ddc8USbZ2mURzujJDWDH1JbHl5tFVOOQ2aVaUPIA71yyE38OXVLEtF8rNmujYH30nEeQ+FV
LVJ16aaHw+iiuaqorTM3K5KLohVlN+WlcEtSXHuPNHjw8ddqtzpaX7pH1zqZH+YmfCL5oaNLqDH4
rkBnUl0/Gm/hzSwKjYhXGQFYQ+gGP99OjXakzrAqZzp/Iq4gt+Z5902/JV9thd/isHQImJ0QyK8M
EKM579iPAfXGes2mbiNYHcvDmSPYmW1zlhOE++N1EKeea7j/msnKeyhlC+hGE4Xfn4TVvqgQexCT
rp/wS/MosY6WH1aKFQlFH2hEppA7KXUaQlvG+w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
XmWoAt4X8hrCJ5yTyug4ajJW5UhfkLNibzjihWzZ4Cr9hQSvWZoTc8rjGsLPbz6Le+/9iI5KxecS
eR0wiAO+G2IkwhZgVBeZdKoFnlnTVAyLjk9wMAFXNyJZM6b1NDbfXlPcUsC6JePvPlwwdWknkSsC
r3KvgkWAS+O3xvRmaNw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hw3Y+rShKrXiUViyNU1/O2qv6TgheLHBnFMj1i9MUGrHYqh9pLfLYUgWR7S2vj4jv4S+Ks0BpP4p
dKEqVAFmTCfQNEUHaVcFPkOHgig6L4mhLY6HUUKJoRgiQepgLi/W3V+ZZPQSQFkB3CU4MsJzhXvR
yLcpDriZy8cnAHD87Zi5DrNGBzj3kigJeM0du6lCQbxtF5aEdoaNP+YTnIFtcqYhoYnswQlYt0sV
HKgFA8VzqzL5WYnpH7+1IKmFkJBHkyqHCa9wPK0qCKnxkuDj70YzPVqQ+cocdKU+/gNdpCOdZlci
F2HTxrgfrXndJru3TiDqu4UavqAe0MNuFp3t0w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XPVggoWL6aXz+MpODTOZhEUQDa0vfEnUDaYeEHXm2vGyqKJujN2c/FFAFBeBYdJATLsIsQ+BqoPc
pBbcFYXDBfOtFIW2dH6Y1OoD65KyJ/hAq8coa21kFgq4hFat5vzZ2iIfkCpTUr4vDZO7Xne8cZO9
WsHffoTCt5rS59wWm2b8I5R8Eh2TUbQg3RCyrcnD66cvcEnlXe1CNMQ4/loVJpA4IBinBf820Wjc
vw2fZbGI0jXC+ACSHOviH63Xwmn+aRV5Ppkup7IYoon/ieKapRQeASu3TTY37xSBXiInSdtMTzJ6
+4GfO4eSHVriCk/sWbuTBzfRzoSShrnHjzz5LA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
L78XuiswVcgO2gtebzL7SA9BC/jJGAM0v6S9pzmyqL+QYzRneiYeGyDmsW33jEVVSTuNjTXkBLY7
yTOKQruatwe4V0OLi6174saSAmPgerSV1GyLP7KhmusLV/N61avC9TPam+tekhKeE0tds4EnJ3et
4JdLh+SE4Z4pcuqCjB5MFneIYKKWDx7siU6oesAQtoSJOesfMchX63MhOjOHFP/ch+1gHv3T45hg
IGF7V7TrdREVE4f9631tlVJ1o2Dypsmo/76Itz5WCGlTMjAnWXN8IXxKN+PZ3dyt1wjrZm2P/td+
xiGszFnSLrRvw/HferwtSmRx8q0fiHZ88roGTw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kDX5kq2QEe25429T6vQqBCFvV1McKTJRYfK99ymVNK2GGvGLXSzgwJHwB2fj9rM0wme3zYYY0vQR
x+9F4L7KLlOVY6qY3LB59uDzyXBI3mMZaS905HXHJkdZHWtQWpfHhl27LqL+8FSluaD6F+KFfYOV
CwIOVuCIp/XjxFXpNBik7YiPt4kHOlDA97IXNLnYUn/g1csGqeNWce4UTne50ggWvLYGbTFGmTjT
N67TpUiGRVRCSv8Tax72GWFIMFZk3Tlp68ZUSQEybZMWX1U9XdMdtxfvNGhf8mi5jQJ2SupSzKu4
T/+53IN9T8aLePAiGBKKG1ZBj4y1ZyYA7XYvjw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 48928)
`pragma protect data_block
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
qaO1Jxnkbi9n6T+xuTlOurR6aohK2Q==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif

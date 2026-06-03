// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Mon Jan 19 19:52:04 2026
// Host        : DESKTOP-NG3G9C3 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim d:/FPGA_prj/ip_repo/CCLC2_debug/src/mult_gen_0/mult_gen_0_sim_netlist.v
// Design      : mult_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu4ev-sfvc784-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "mult_gen_0,mult_gen_v12_0_16,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "mult_gen_v12_0_16,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module mult_gen_0
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:b_intf:a_intf, ASSOCIATED_RESET sclr, ASSOCIATED_CLKEN ce, FREQ_HZ 10000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [7:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [12:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [20:0]P;

  wire [7:0]A;
  wire [12:0]B;
  wire CLK;
  wire [20:0]P;
  wire [47:0]NLW_U0_PCASC_UNCONNECTED;
  wire [1:0]NLW_U0_ZERO_DETECT_UNCONNECTED;

  (* C_A_TYPE = "0" *) 
  (* C_A_WIDTH = "8" *) 
  (* C_B_TYPE = "0" *) 
  (* C_B_VALUE = "10000001" *) 
  (* C_B_WIDTH = "13" *) 
  (* C_CCM_IMP = "0" *) 
  (* C_CE_OVERRIDES_SCLR = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_ZERO_DETECT = "0" *) 
  (* C_LATENCY = "3" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_MULT_TYPE = "1" *) 
  (* C_OPTIMIZE_GOAL = "1" *) 
  (* C_OUT_HIGH = "20" *) 
  (* C_OUT_LOW = "0" *) 
  (* C_ROUND_OUTPUT = "0" *) 
  (* C_ROUND_PT = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  mult_gen_0_mult_gen_v12_0_16 U0
       (.A(A),
        .B(B),
        .CE(1'b1),
        .CLK(CLK),
        .P(P),
        .PCASC(NLW_U0_PCASC_UNCONNECTED[47:0]),
        .SCLR(1'b0),
        .ZERO_DETECT(NLW_U0_ZERO_DETECT_UNCONNECTED[1:0]));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
D+9lfS59pj/VVil0GGdJ59k3DOq46v/+7whNz7wCwfYdRiJPbLItui6o/zSBZEKI9gWLjOldtur1
/rmcVBQ3GA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
Al4EzSQFZknJP1zXhKNIjHP2ED06e/ds+6xnXGYdohXSo6+myvUa29WxrDQ2BRCFMopuWgRIHVKr
QIL1R/lyNoyVEM+ZIozLEHgX6l1O/zTuyjCCsopsjgqJb2Wtgn8s+TaOCOvqtDrvLzt0PvLiCx3j
UkBnJ2bYuzUoN4JusSo=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
GryPO/G6YUeEdMxSH6E+Cylnk/9RJIpF3DfZ8qm1ecWq6hYmaGlwqiFs0cnQCPLUX5i7YB1Zhyg7
xWXnsmJ4+UqH7C7kALbZ0VgPMoxq9qXXyR3XFKCabcHGfdH1PGZgCMUJcT1U4IAGCC0HKbpQue4v
BxJxLOKucvmUl0mdNC5jktjqlol5N3LNQ1Nqb0Bi2JUbKhDXyPAghHnYm1RA1WIG/I7KPAHJRMsn
rq61TkO0r9B2jyIUh8Re69O30QuaI8MVXArXwxoLarP1bw33bj+4nw7AKPOj3d27JIY1FecXOlD+
JrglMTs1oca4ii7DTHZWrWcZD11O8wPZrSB/hg==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
gIxs1xJo2g0tw3pn4+ixShAOAMuK8enzcVscdNEALwVHu56ynHRf8QNrBE9hWTm0Zrotj69ZA/BK
kwI2N0AWvjk9ACiHZ+Q82pH5keVYRtMQtsAzmOmN3YJ3UkTFHW6AIALOLN/+b1CJx2DSSbUvSJRL
vYdCMY94F9Lklx9UjVtQ7r4y14DJeU9UdmLHZEJTMZ3ahOPNz53F7Y+D2abS+pN3OTP/hfwC8SXW
Y0mKDR8Tkg+zCHqpFqHVe4sN/fDWpQUR8MUszd4ygr4o7HqUOQ1RTUGx1Mc0Wtrq0QAi8Syc7V28
2OviXFf4KLhcKYs0bZN+gsgApGWiwyRvQRkZsw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
lbc8rPGs9vNVJLV1Ztd+OweNWVf1r3bbhZXmEPzls7ewmRVAwHDdCz0iBVD5zHofb2Pv1cNIx1DF
Cegpi/O809UypK5vc2xsVTWDeqgYhsqvVrROg6FOkBiX78rZZIEYF4NC0rxHw/5ixAFYsGHPS840
rFWEsubE6/eEK5KjxNY=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
dGaX53L9Ek9wU1QC7h+mJBxY9VRQrtTA5cLqpyZvyLoi582YqMcyFxxsOh08z/CW++CYcslxK5c2
nB76qWzDGxhrcZ2LL96TaJdxfIU2EOvAbd+35O26BL5Dr65GaDwdjrxZgGVYX9zZnupIqxn8XhmC
YxZ5OIIBnPbpGQ6ribzMzlGvFizUnWWAzae4ZJK4JY+UWbuv2xdBtaDjg/1YQkACqpob/Aq4IcN9
/z+aEP0pGhrF9aYTALhCIBKRSiEmlWYFi+Y/QtDMcgPf3kf28Jl2zN9nxRNVeqUYEwqb9cl2u01M
MuW6fdTQYP8au8BQaSrUEy47B0go0sgbZVDbwA==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
LEujW+ttFeLDTd6Kj02ulQ4/6kxvxmgT0K9WSqzr2nEKo8u+D1wTZSNxo1Fc+SuL6Np9NoHmXZ6a
quET05vVSiMB+lIOHpijfSVwTqZ7LgYHnhXrPB5My87wRq0b9Jyg7VUy3e0yzOlKBYa8cqDKm5vE
rKtHLezwwsG/dfHwGL5KISY7D5xkA348D53WjZT2GPECqu3z2+qFTyr2skARLi+fP7tdqXthwiZ/
w32KaI0lhDwxw9CdQ/7jGNqq5B4pDSAIRhs657DCGvaZmMrfpEV3TIblWlorFwEQ5UhHeGuVslc+
eN4r6MzOumbMdENFQgB8d3D0vFnoVsLbbL5/3w==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
b1YdODjbk8HFhbv22dlzSJPK8onB4y/bTVR6bwet5BZoTYdYXUmOZH419afEKigqx51IMqa6rnXU
3J62hXejiIyZsm1mV6d/ZILTIg4MvKp/nsB+nzk3mwrxlbUBSjb5Gs4KJEM3QfmnigtYMQ5rNsWx
xO1OBkWglwIieiVxJRpIzrM1m6NiWCqcL1cvpMI1IywHrEeI+DhZWAgf2c+NGLeogq0I5stGLWyl
7mUNnFVREZS2ztdL9JeVlYFnkm9YAu/rEpRnd/ZFnUmo5LDgPLxnWIoTIbnJ9ETXA3VKs5m8RjLa
Y80BwwVZ8VpAYtcyfGThAvkMUN1XkU+RBOhB0w==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
jw11/jyPzYF09qKNLzRASveW80p2lDhif/7GSzkqz1ay8ziMYjGu2PXCgyziHf07D1ydjBZ2Oj+T
1TciExFJYUoS4v8yaGxNYIeVg4lCZtiWwMwIjWi5TbX5hyZCCFDUioAcm2Er0tzXe+UuWzkM8uEj
VcZMHxrNXFh3ip5Q5HwOhZJLT59ez98d86/DgXZNDnY1jAn3tjdLiP3facR+GKZ2RlNKOTvP6BNt
RMIiYfDGS6i/0a2j9G97hV2faBZ9PX1JyNer2z3gD5/XUNbE3bPLm+xmhpk1/K7GiF3yvAO1dtiL
5Mg52QRrud8v05hWjH6y7rmg+wiBc1bnMIMVaw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 3808)
`pragma protect data_block
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
`pragma protect end_protected
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
D+9lfS59pj/VVil0GGdJ59k3DOq46v/+7whNz7wCwfYdRiJPbLItui6o/zSBZEKI9gWLjOldtur1
/rmcVBQ3GA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
Al4EzSQFZknJP1zXhKNIjHP2ED06e/ds+6xnXGYdohXSo6+myvUa29WxrDQ2BRCFMopuWgRIHVKr
QIL1R/lyNoyVEM+ZIozLEHgX6l1O/zTuyjCCsopsjgqJb2Wtgn8s+TaOCOvqtDrvLzt0PvLiCx3j
UkBnJ2bYuzUoN4JusSo=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
GryPO/G6YUeEdMxSH6E+Cylnk/9RJIpF3DfZ8qm1ecWq6hYmaGlwqiFs0cnQCPLUX5i7YB1Zhyg7
xWXnsmJ4+UqH7C7kALbZ0VgPMoxq9qXXyR3XFKCabcHGfdH1PGZgCMUJcT1U4IAGCC0HKbpQue4v
BxJxLOKucvmUl0mdNC5jktjqlol5N3LNQ1Nqb0Bi2JUbKhDXyPAghHnYm1RA1WIG/I7KPAHJRMsn
rq61TkO0r9B2jyIUh8Re69O30QuaI8MVXArXwxoLarP1bw33bj+4nw7AKPOj3d27JIY1FecXOlD+
JrglMTs1oca4ii7DTHZWrWcZD11O8wPZrSB/hg==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
gIxs1xJo2g0tw3pn4+ixShAOAMuK8enzcVscdNEALwVHu56ynHRf8QNrBE9hWTm0Zrotj69ZA/BK
kwI2N0AWvjk9ACiHZ+Q82pH5keVYRtMQtsAzmOmN3YJ3UkTFHW6AIALOLN/+b1CJx2DSSbUvSJRL
vYdCMY94F9Lklx9UjVtQ7r4y14DJeU9UdmLHZEJTMZ3ahOPNz53F7Y+D2abS+pN3OTP/hfwC8SXW
Y0mKDR8Tkg+zCHqpFqHVe4sN/fDWpQUR8MUszd4ygr4o7HqUOQ1RTUGx1Mc0Wtrq0QAi8Syc7V28
2OviXFf4KLhcKYs0bZN+gsgApGWiwyRvQRkZsw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
lbc8rPGs9vNVJLV1Ztd+OweNWVf1r3bbhZXmEPzls7ewmRVAwHDdCz0iBVD5zHofb2Pv1cNIx1DF
Cegpi/O809UypK5vc2xsVTWDeqgYhsqvVrROg6FOkBiX78rZZIEYF4NC0rxHw/5ixAFYsGHPS840
rFWEsubE6/eEK5KjxNY=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
dGaX53L9Ek9wU1QC7h+mJBxY9VRQrtTA5cLqpyZvyLoi582YqMcyFxxsOh08z/CW++CYcslxK5c2
nB76qWzDGxhrcZ2LL96TaJdxfIU2EOvAbd+35O26BL5Dr65GaDwdjrxZgGVYX9zZnupIqxn8XhmC
YxZ5OIIBnPbpGQ6ribzMzlGvFizUnWWAzae4ZJK4JY+UWbuv2xdBtaDjg/1YQkACqpob/Aq4IcN9
/z+aEP0pGhrF9aYTALhCIBKRSiEmlWYFi+Y/QtDMcgPf3kf28Jl2zN9nxRNVeqUYEwqb9cl2u01M
MuW6fdTQYP8au8BQaSrUEy47B0go0sgbZVDbwA==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
LEujW+ttFeLDTd6Kj02ulQ4/6kxvxmgT0K9WSqzr2nEKo8u+D1wTZSNxo1Fc+SuL6Np9NoHmXZ6a
quET05vVSiMB+lIOHpijfSVwTqZ7LgYHnhXrPB5My87wRq0b9Jyg7VUy3e0yzOlKBYa8cqDKm5vE
rKtHLezwwsG/dfHwGL5KISY7D5xkA348D53WjZT2GPECqu3z2+qFTyr2skARLi+fP7tdqXthwiZ/
w32KaI0lhDwxw9CdQ/7jGNqq5B4pDSAIRhs657DCGvaZmMrfpEV3TIblWlorFwEQ5UhHeGuVslc+
eN4r6MzOumbMdENFQgB8d3D0vFnoVsLbbL5/3w==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
b1YdODjbk8HFhbv22dlzSJPK8onB4y/bTVR6bwet5BZoTYdYXUmOZH419afEKigqx51IMqa6rnXU
3J62hXejiIyZsm1mV6d/ZILTIg4MvKp/nsB+nzk3mwrxlbUBSjb5Gs4KJEM3QfmnigtYMQ5rNsWx
xO1OBkWglwIieiVxJRpIzrM1m6NiWCqcL1cvpMI1IywHrEeI+DhZWAgf2c+NGLeogq0I5stGLWyl
7mUNnFVREZS2ztdL9JeVlYFnkm9YAu/rEpRnd/ZFnUmo5LDgPLxnWIoTIbnJ9ETXA3VKs5m8RjLa
Y80BwwVZ8VpAYtcyfGThAvkMUN1XkU+RBOhB0w==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
jw11/jyPzYF09qKNLzRASveW80p2lDhif/7GSzkqz1ay8ziMYjGu2PXCgyziHf07D1ydjBZ2Oj+T
1TciExFJYUoS4v8yaGxNYIeVg4lCZtiWwMwIjWi5TbX5hyZCCFDUioAcm2Er0tzXe+UuWzkM8uEj
VcZMHxrNXFh3ip5Q5HwOhZJLT59ez98d86/DgXZNDnY1jAn3tjdLiP3facR+GKZ2RlNKOTvP6BNt
RMIiYfDGS6i/0a2j9G97hV2faBZ9PX1JyNer2z3gD5/XUNbE3bPLm+xmhpk1/K7GiF3yvAO1dtiL
5Mg52QRrud8v05hWjH6y7rmg+wiBc1bnMIMVaw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
HgKKZrNDQEkmuSbAJh9c/QtJ1ujGB2IOh0+BCmSvKxrvRdo8g8qN/rm2X6wTKIFR3JdOecmWithC
mAqu1ITJL6+u7HOo5BMpdYc8e8tC0kaI8ISwJzeVebpEc0nRbYZgjrah9hRaMI7UQQRuJTR1RMf2
9tmj8vn4VHNm0MPFgT2l442DJUu6Yu2Wj68HM2z65mKzEZAQ3m8KMZqix8F4o3Z9m/Q0jyFxRC6H
VrE+Dy4mreCjpZu64upc8DirYSDAkTJpC4whIYvGAlDC8gBUg573ne1e1e20A21I3PVVy7kuVdUB
G0OJd/hKdTHASzCqiJH8AVm0wGjh5NQPCWPy4Q==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
6EeZgN+gqzCXECs1rDMTlJNlEKQVDwZ+VeMp7mqaeZ1GUyXC+ZyZ2fXAVYwAPZxIot7Frm84bzuF
VnVhvfj2/PxHD3wsvnqTjMDmMOKgJH9h2UUkKb0zzD1ULqxvE4TFKx21p1etVFR1J7KSh2leDlGZ
ZuUdQhI8t+EkBtRuBTMjHNjfnxEcFBdoExv3Rfe4G95xCQgLpbVozwJ/AyZx/aRpWAQXFYgnChBU
eKamlb22f2xM7JhvhUYS7k6t7kDmTWlICKXjhXeD/nA/ZixP5BUYizp7t1SMytpRIfKKQM/cj/B4
YBEV+ckni0Vsk8HpLyQ1LNPHLnm7qLAt0V+LsA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 7664)
`pragma protect data_block
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
V5Q/3tIIL4XDNAM7/GIPDjmiLfd4bHmwDlg=
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

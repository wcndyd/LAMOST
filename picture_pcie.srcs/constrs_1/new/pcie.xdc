#PCIe reference clock 100MHz
set_property PACKAGE_PIN V6 [get_ports {pcie_ref_clk_p[0]}]
create_clock -period 10.000 -name pcie_ref_clk_p [get_ports pcie_ref_clk_p]

# PCIe MGT interface
set_property PACKAGE_PIN P2 [get_ports {pcie_mgt_rxp[0]}]  
set_property PACKAGE_PIN T2 [get_ports {pcie_mgt_rxp[1]}]

# PCIe rst signal
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports pcie_rst_n]

#led0
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports lnk_up_led]

 
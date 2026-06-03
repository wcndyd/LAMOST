# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "channel_num" -parent ${Page_0}
  ipgui::add_param $IPINST -name "output_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "data_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Thres" -parent ${Page_0}
  ipgui::add_param $IPINST -name "tdest_W" -parent ${Page_0}


}

proc update_PARAM_VALUE.Thres { PARAM_VALUE.Thres } {
	# Procedure called to update Thres when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Thres { PARAM_VALUE.Thres } {
	# Procedure called to validate Thres
	return true
}

proc update_PARAM_VALUE.channel_num { PARAM_VALUE.channel_num } {
	# Procedure called to update channel_num when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.channel_num { PARAM_VALUE.channel_num } {
	# Procedure called to validate channel_num
	return true
}

proc update_PARAM_VALUE.data_W { PARAM_VALUE.data_W } {
	# Procedure called to update data_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.data_W { PARAM_VALUE.data_W } {
	# Procedure called to validate data_W
	return true
}

proc update_PARAM_VALUE.output_W { PARAM_VALUE.output_W } {
	# Procedure called to update output_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.output_W { PARAM_VALUE.output_W } {
	# Procedure called to validate output_W
	return true
}

proc update_PARAM_VALUE.tdest_W { PARAM_VALUE.tdest_W } {
	# Procedure called to update tdest_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.tdest_W { PARAM_VALUE.tdest_W } {
	# Procedure called to validate tdest_W
	return true
}


proc update_MODELPARAM_VALUE.Thres { MODELPARAM_VALUE.Thres PARAM_VALUE.Thres } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Thres}] ${MODELPARAM_VALUE.Thres}
}

proc update_MODELPARAM_VALUE.channel_num { MODELPARAM_VALUE.channel_num PARAM_VALUE.channel_num } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.channel_num}] ${MODELPARAM_VALUE.channel_num}
}

proc update_MODELPARAM_VALUE.data_W { MODELPARAM_VALUE.data_W PARAM_VALUE.data_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.data_W}] ${MODELPARAM_VALUE.data_W}
}

proc update_MODELPARAM_VALUE.tdest_W { MODELPARAM_VALUE.tdest_W PARAM_VALUE.tdest_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.tdest_W}] ${MODELPARAM_VALUE.tdest_W}
}

proc update_MODELPARAM_VALUE.output_W { MODELPARAM_VALUE.output_W PARAM_VALUE.output_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.output_W}] ${MODELPARAM_VALUE.output_W}
}


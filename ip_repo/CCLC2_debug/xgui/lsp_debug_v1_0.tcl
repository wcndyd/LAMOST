# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "Width" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Height" -parent ${Page_0}
  ipgui::add_param $IPINST -name "merge_num" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Data_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "COL_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ROW_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "X_weight_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Y_weight_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Gray_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "M_flag_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "count_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "length_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Output_data_W" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BLK_W" -parent ${Page_0}


}

proc update_PARAM_VALUE.BLK_W { PARAM_VALUE.BLK_W } {
	# Procedure called to update BLK_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BLK_W { PARAM_VALUE.BLK_W } {
	# Procedure called to validate BLK_W
	return true
}

proc update_PARAM_VALUE.COL_W { PARAM_VALUE.COL_W } {
	# Procedure called to update COL_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COL_W { PARAM_VALUE.COL_W } {
	# Procedure called to validate COL_W
	return true
}

proc update_PARAM_VALUE.Data_W { PARAM_VALUE.Data_W } {
	# Procedure called to update Data_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Data_W { PARAM_VALUE.Data_W } {
	# Procedure called to validate Data_W
	return true
}

proc update_PARAM_VALUE.Gray_W { PARAM_VALUE.Gray_W } {
	# Procedure called to update Gray_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Gray_W { PARAM_VALUE.Gray_W } {
	# Procedure called to validate Gray_W
	return true
}

proc update_PARAM_VALUE.Height { PARAM_VALUE.Height } {
	# Procedure called to update Height when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Height { PARAM_VALUE.Height } {
	# Procedure called to validate Height
	return true
}

proc update_PARAM_VALUE.M_flag_W { PARAM_VALUE.M_flag_W } {
	# Procedure called to update M_flag_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.M_flag_W { PARAM_VALUE.M_flag_W } {
	# Procedure called to validate M_flag_W
	return true
}

proc update_PARAM_VALUE.Output_data_W { PARAM_VALUE.Output_data_W } {
	# Procedure called to update Output_data_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Output_data_W { PARAM_VALUE.Output_data_W } {
	# Procedure called to validate Output_data_W
	return true
}

proc update_PARAM_VALUE.ROW_W { PARAM_VALUE.ROW_W } {
	# Procedure called to update ROW_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROW_W { PARAM_VALUE.ROW_W } {
	# Procedure called to validate ROW_W
	return true
}

proc update_PARAM_VALUE.Width { PARAM_VALUE.Width } {
	# Procedure called to update Width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Width { PARAM_VALUE.Width } {
	# Procedure called to validate Width
	return true
}

proc update_PARAM_VALUE.X_weight_W { PARAM_VALUE.X_weight_W } {
	# Procedure called to update X_weight_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.X_weight_W { PARAM_VALUE.X_weight_W } {
	# Procedure called to validate X_weight_W
	return true
}

proc update_PARAM_VALUE.Y_weight_W { PARAM_VALUE.Y_weight_W } {
	# Procedure called to update Y_weight_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Y_weight_W { PARAM_VALUE.Y_weight_W } {
	# Procedure called to validate Y_weight_W
	return true
}

proc update_PARAM_VALUE.count_W { PARAM_VALUE.count_W } {
	# Procedure called to update count_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.count_W { PARAM_VALUE.count_W } {
	# Procedure called to validate count_W
	return true
}

proc update_PARAM_VALUE.length_W { PARAM_VALUE.length_W } {
	# Procedure called to update length_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.length_W { PARAM_VALUE.length_W } {
	# Procedure called to validate length_W
	return true
}

proc update_PARAM_VALUE.merge_num { PARAM_VALUE.merge_num } {
	# Procedure called to update merge_num when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.merge_num { PARAM_VALUE.merge_num } {
	# Procedure called to validate merge_num
	return true
}


proc update_MODELPARAM_VALUE.Width { MODELPARAM_VALUE.Width PARAM_VALUE.Width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Width}] ${MODELPARAM_VALUE.Width}
}

proc update_MODELPARAM_VALUE.Height { MODELPARAM_VALUE.Height PARAM_VALUE.Height } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Height}] ${MODELPARAM_VALUE.Height}
}

proc update_MODELPARAM_VALUE.merge_num { MODELPARAM_VALUE.merge_num PARAM_VALUE.merge_num } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.merge_num}] ${MODELPARAM_VALUE.merge_num}
}

proc update_MODELPARAM_VALUE.Data_W { MODELPARAM_VALUE.Data_W PARAM_VALUE.Data_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Data_W}] ${MODELPARAM_VALUE.Data_W}
}

proc update_MODELPARAM_VALUE.COL_W { MODELPARAM_VALUE.COL_W PARAM_VALUE.COL_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COL_W}] ${MODELPARAM_VALUE.COL_W}
}

proc update_MODELPARAM_VALUE.ROW_W { MODELPARAM_VALUE.ROW_W PARAM_VALUE.ROW_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROW_W}] ${MODELPARAM_VALUE.ROW_W}
}

proc update_MODELPARAM_VALUE.X_weight_W { MODELPARAM_VALUE.X_weight_W PARAM_VALUE.X_weight_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.X_weight_W}] ${MODELPARAM_VALUE.X_weight_W}
}

proc update_MODELPARAM_VALUE.Y_weight_W { MODELPARAM_VALUE.Y_weight_W PARAM_VALUE.Y_weight_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Y_weight_W}] ${MODELPARAM_VALUE.Y_weight_W}
}

proc update_MODELPARAM_VALUE.Gray_W { MODELPARAM_VALUE.Gray_W PARAM_VALUE.Gray_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Gray_W}] ${MODELPARAM_VALUE.Gray_W}
}

proc update_MODELPARAM_VALUE.M_flag_W { MODELPARAM_VALUE.M_flag_W PARAM_VALUE.M_flag_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.M_flag_W}] ${MODELPARAM_VALUE.M_flag_W}
}

proc update_MODELPARAM_VALUE.count_W { MODELPARAM_VALUE.count_W PARAM_VALUE.count_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.count_W}] ${MODELPARAM_VALUE.count_W}
}

proc update_MODELPARAM_VALUE.length_W { MODELPARAM_VALUE.length_W PARAM_VALUE.length_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.length_W}] ${MODELPARAM_VALUE.length_W}
}

proc update_MODELPARAM_VALUE.Output_data_W { MODELPARAM_VALUE.Output_data_W PARAM_VALUE.Output_data_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Output_data_W}] ${MODELPARAM_VALUE.Output_data_W}
}

proc update_MODELPARAM_VALUE.BLK_W { MODELPARAM_VALUE.BLK_W PARAM_VALUE.BLK_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BLK_W}] ${MODELPARAM_VALUE.BLK_W}
}


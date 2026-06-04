set project_name "picture_pcie"
set project_dir [file dirname [info script]]
set device_part "xczu4ev-sfvc784-2-i"
set script_path [file dirname [info script]]

#create_project my_prj ./my_prj -part xc7k325tffg900-2
create_project $project_name $project_dir -part $device_part -force

set_property "target_language" "Verilog" [current_project]
set_property "simulator_language" "Mixed" [current_project]
set_property "default_lib" "xil_defaultlib" [current_project]

set_property ip_repo_paths [list [file normalize "[file dirname [info script]]/ip_repo"]] [current_project]
# 执行刷新命令, Vivado 才会去扫描新路径下的 IP
update_ip_catalog -rebuild

set src_dir "[file dirname [info script]]/picture_pcie.srcs/sources_1/hdl"

if { [file exists $src_dir] } {
    puts "INFO: Adding RTL sources for $src_dir"
    add_files -norecurse [glob $src_dir/*.v]
    
    update_compile_order -fileset sources_1
} else {
    puts "EEROR:Cannot find RTL  directory $src_dir"
}

source bd.tcl

generate_target all [get_files design_1.bd]
export_ip_user_files -of_objects [get_files design_1.bd] -no_script -force -quiet

set wrapper_file [make_wrapper -files [get_files design_1.bd] -top]
# 将生成的 wrapper 文件加入工程
add_files -norecurse $wrapper_file

# 更新编译顺序, 将 wrapper 设为 Top
update_compile_order -fileset sources_1

# launch_runs synth_1 -jobs 16
#
# launch_runs impl_1 -jobs 16
#
# launch_runs impl_1 -to_step write_bitstream -jobs 16

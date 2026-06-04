set project_path [file normalize "[file dirname [info script]]/picture_pcie.xpr"]
set bd_name "design_1"
set output_tcl [file normalize "[file dirname [info script]]/bd.tcl"]

# 打开工程
if { [file exists $project_path] } {
    puts "open $project_path"
    open_project $project_path
} else {
   puts "err: 找不到工程"
   return
}

# 打开 BD 所在设计
set bd_file [get_files ${bd_name}.bd]
if { $bd_file ne "" } {
    puts  "获取 bd 文件"
    open_bd_design $bd_file

    puts "导出 bd 文件"
    write_bd_tcl -force -no_ip_version $output_tcl

    # 关闭文件
    close_bd_design [get_bd_designs $bd_name]
} else {
    puts "err: can't find file $bd_name"
}

puts "finish export file "
close_project

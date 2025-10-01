set script_dir [file dirname [info script]]
set origin_dir "$script_dir/.."

#set_param board.repoPaths [list "$origin_dir/../../pynq-z2"]
create_project project_hw $origin_dir/project_hw -part xc7z020clg400-1
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]


# Set IP repository paths
set_property ip_repo_paths "[file normalize $origin_dir/project_ipcores] [file normalize $origin_dir/project_ipcores]" [get_filesets sources_1]

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog

# Add source files
set files []
foreach file [glob $origin_dir/src/rtl/adder/*] {
        lappend files [file normalize "$file"]
    }
if {$argv == "mult" || $argv == "ecdsa"} {
	foreach file [glob $origin_dir/src/rtl/montgomery/*] {
        lappend files [file normalize "$file"]
    }
}
if {$argv == "ecdsa"} {
	foreach file [glob $origin_dir/src/rtl/ecdsa/*] {
        lappend files [file normalize "$file"]
    }
}

add_files -norecurse -fileset [get_filesets sources_1] $files

if {$argv == "ecdsa"} {
foreach bd [list ecdsa_project] {
  source -notrace "${origin_dir}/tcl/${bd}.tcl"
  regenerate_bd_layout
  set bdfile ${origin_dir}/project_hw/project_hw.srcs/sources_1/bd/${bd}/${bd}.bd
  make_wrapper -files [get_files $bdfile] -top
  add_files -fileset sources_1 -norecurse ${origin_dir}/project_hw/project_hw.srcs/sources_1/bd/${bd}/hdl/${bd}_wrapper.v
}
}

# Set the correct files as top for sources
if {$argv == "adder"} { set_property top hweval_adder [get_filesets sources_1] }
if {$argv == "mult"} { set_property top hweval_montgomery [get_filesets sources_1] }
if {$argv == "ecdsa"} { set_property top ecdsa_project_wrapper [get_filesets sources_1] }
set_property top_lib xil_defaultlib [get_filesets sources_1]

# Add Simulation files
set files []
foreach file [glob $origin_dir/src/rtl_tb/adder/*] {
        lappend files [file normalize "$file"]
    }
if {$argv == "mult" || $argv == "ecdsa"} {
	foreach file [glob $origin_dir/src/rtl_tb/montgomery/*] {
        lappend files [file normalize "$file"]
    }
}
if {$argv == "ecdsa"} {
	foreach file [glob $origin_dir/src/rtl_tb/ecdsa/*] {
        lappend files [file normalize "$file"]
    }
}
add_files -norecurse -fileset [get_filesets sim_1] $files

# Set the correct files as top for simulation
if {$argv == "adder"} { set_property top tb_adder [get_filesets sim_1] }
if {$argv == "mult"} { set_property top tb_montgomery [get_filesets sim_1] }
if {$argv == "ecdsa"} { set_property top tb_ecdsa_wrapper [get_filesets sim_1] }
set_property top_lib xil_defaultlib [get_filesets sim_1]

if {$argv == "ecdsa"} {
foreach bd [list tb_ecdsa_project] {
  source -notrace "${origin_dir}/tcl/${bd}.tcl"
  regenerate_bd_layout
  set bdfile ${origin_dir}/project_hw/project_hw.srcs/sources_1/bd/${bd}/${bd}.bd
  make_wrapper -files [get_files $bdfile] -top
  add_files -fileset sources_1 -norecurse ${origin_dir}/project_hw/project_hw.srcs/sources_1/bd/${bd}/hdl/${bd}_wrapper.v
}
}

# Add Constraints
add_files -fileset constrs_1 -norecurse $origin_dir/tcl/constraints.tcl

# Add Waveform Files
if {$argv == "ecdsa"} {
add_files -fileset sim_1 -norecurse $origin_dir/src/wcfg/tb_ecdsa_wrapper_sim_template.wcfg
set_property xsim.view $origin_dir/src/wcfg/tb_ecdsa_wrapper_sim_template.wcfg [get_filesets sim_1]
}

update_compile_order -fileset sim_1
update_compile_order -fileset sources_1

# Latches -> Error
set_msg_config -id {Synth 8-327}     -new_severity {ERROR}

# Multi-driven -> Error
set_msg_config -id {Synth 8-3352}    -new_severity {ERROR}
set_msg_config -id {Synth 8-5559}    -new_severity {ERROR}

# Timing not meet -> WARNING
set_msg_config -id {Timing 38-282}   -new_severity {WARNING}
set_msg_config -id {BD 41-1629}      -new_severity {INFO}
set_msg_config -id {BD 41-1343}      -new_severity {INFO}
set_msg_config -id {BD_TCL-1000}     -new_severity {INFO}
set_msg_config -id {IP_Flow 19-3899} -new_severity {INFO}
set_msg_config -id {IP_Flow 19-3153} -new_severity {INFO}
set_msg_config -id {IP_Flow 19-2207} -new_severity {INFO}
set_msg_config -id {Vivado 12-3482}  -new_severity {INFO}


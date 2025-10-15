set script_dir [file dirname [info script]]
set origin_dir "$script_dir/.."
open_project $origin_dir/project_hw/project_hw.xpr
write_hw_platform -fixed -include_bit -force -file $origin_dir/../sw_project/src/bitstream/ecdsa_project_wrapper.xsa

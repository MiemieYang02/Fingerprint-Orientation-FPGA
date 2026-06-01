set root_dir [file normalize [file join [file dirname [info script]] ..]]
set proj_file [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.xpr]

open_project $proj_file

proc add_missing_files {fileset_name file_list} {
  foreach f $file_list {
    if {[llength [get_files -quiet $f]] == 0} {
      add_files -norecurse -fileset $fileset_name $f
    }
  }
}

set src_files [list \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new image image_source_sim.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new image pixel_window_3x3.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new sobel sobel_core.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new cordic cordic_angle_ip_wrapper.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new direction direction_quantizer.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new direction block_direction_stat.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display hdmi_overlay_stub.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new top fpga_orientation_top.v] \
]

add_missing_files sources_1 $src_files
set_property top fpga_orientation_top [get_filesets sources_1]

set sim_files [list \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sim_1 new tb_fpga_orientation_top.v] \
]
add_missing_files sim_1 $sim_files
set_property top tb_fpga_orientation_top [get_filesets sim_1]

set constr_files [list \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs constrs_1 new phase1_base.xdc] \
]
add_missing_files constrs_1 $constr_files

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project

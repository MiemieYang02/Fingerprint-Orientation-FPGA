set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_source_sim.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/pixel_window_3x3.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/sobel/sobel_core.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_tensor_stat.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_tensor_direction.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_overlay_stub.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_pipeline.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_top.v \
]

foreach f $rtl_files {
  if {![file exists $f]} {
    puts "MISSING_RTL_FILE $f"
  }
}

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_fpga_orientation_top.v
exec xelab tb_fpga_orientation_top -s tb_fpga_orientation_top_sim
exec xsim tb_fpga_orientation_top_sim -runall

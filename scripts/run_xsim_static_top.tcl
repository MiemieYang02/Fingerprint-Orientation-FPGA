set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_static_mem_source.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/pixel_window_3x3.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/sobel/sobel_core.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_angle_ip_wrapper.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/direction_quantizer.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_direction_stat.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_pipeline.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_static_top.v \
]

foreach f $rtl_files {
  if {![file exists $f]} {
    puts "MISSING_RTL_FILE $f"
  }
}

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_fpga_orientation_static_top.v
exec xelab tb_fpga_orientation_static_top -s tb_fpga_orientation_static_top_sim
exec xsim tb_fpga_orientation_static_top_sim -runall

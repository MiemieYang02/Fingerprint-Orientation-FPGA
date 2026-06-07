set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_source_sim.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/pixel_window_3x3.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/sobel/sobel_core.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_tensor_stat.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_tensor_direction.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_pipeline.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_top.v \
]

read_verilog -sv {*}$rtl_files
synth_design -top fpga_orientation_top -part xc7a75tfgg484-2
report_utilization -file [file join $root_dir fingerprint_direction_fpga phase1_utilization_synth.rpt]

set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_static_mem_source.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/pixel_window_3x3.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/sobel/sobel_core.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_tensor_stat.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_tensor_direction.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_pipeline.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fpga_orientation_static_top.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/direction_field_buffer.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_direction_field_renderer.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_hdmi_clock_gen.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_asyn_rst_syn.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_video_driver.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_dvi_encoder.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_serializer_10_to_1.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_dvi_transmitter_top.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/ref_hdmi_top.v \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/top/fingerprint_ref_hdmi_static_top.v \
]

foreach f $rtl_files {
  if {![file exists $f]} {
    puts "MISSING_RTL_FILE $f"
  }
}

set glbl_file [file join $::env(XILINX_VIVADO) data verilog src glbl.v]

exec xvlog -sv {*}$rtl_files $glbl_file
exec xelab -L unisims_ver -L unimacro_ver -L secureip fingerprint_ref_hdmi_static_top glbl -s fingerprint_ref_hdmi_static_top_elab
puts "REF_HDMI_STATIC_ELAB_PASS"

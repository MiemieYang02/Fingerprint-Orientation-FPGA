set root_dir [file normalize [file join [file dirname [info script]] ..]]
set out_dir [file join $root_dir fingerprint_direction_fpga]
set mem_dir [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new image]

set rtl_files [list \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new image image_static_mem_source.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new image pixel_window_3x3.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new sobel sobel_core.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new direction block_tensor_stat.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new direction tensor_field_smoother.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new cordic cordic_tensor_direction.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new top fpga_orientation_pipeline.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new top fpga_orientation_static_top.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display direction_field_buffer.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display hdmi_direction_field_renderer.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_asyn_rst_syn.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_dvi_encoder.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_serializer_10_to_1.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_dvi_transmitter_top.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_video_driver.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_hdmi_top.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new display ref_hdmi_clock_gen.v] \
  [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs sources_1 new top fingerprint_ref_hdmi_static_top.v] \
]

cd $mem_dir
read_verilog -sv {*}$rtl_files
read_xdc [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.srcs constrs_1 new phase1_base.xdc]

synth_design -top fingerprint_ref_hdmi_static_top -part xc7a75tfgg484-2
opt_design
place_design
route_design
report_timing_summary -file [file join $out_dir ref_hdmi_static_timing_summary.rpt]
write_bitstream -force [file join $out_dir fingerprint_ref_hdmi_static.bit]

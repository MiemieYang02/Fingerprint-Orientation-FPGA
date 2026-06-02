set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/hdmi_direction_field_renderer.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_hdmi_direction_field_renderer.v
exec xelab tb_hdmi_direction_field_renderer -s tb_hdmi_direction_field_renderer_sim
exec xsim tb_hdmi_direction_field_renderer_sim -runall

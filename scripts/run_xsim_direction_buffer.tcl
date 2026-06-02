set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/display/direction_field_buffer.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_direction_field_buffer.v
exec xelab tb_direction_field_buffer -s tb_direction_field_buffer_sim
exec xsim tb_direction_field_buffer_sim -runall

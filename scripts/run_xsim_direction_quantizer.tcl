set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/direction_quantizer.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_direction_quantizer.v
exec xelab tb_direction_quantizer -s tb_direction_quantizer_sim
exec xsim tb_direction_quantizer_sim -runall

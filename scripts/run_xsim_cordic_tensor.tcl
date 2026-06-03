set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/cordic/cordic_tensor_direction.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_cordic_tensor_direction.v
exec xelab tb_cordic_tensor_direction -s tb_cordic_tensor_direction_sim
exec xsim tb_cordic_tensor_direction_sim -runall

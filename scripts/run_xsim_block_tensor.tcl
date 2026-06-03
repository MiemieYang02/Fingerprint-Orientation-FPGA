set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_tensor_stat.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_block_tensor_stat.v
exec xelab tb_block_tensor_stat -s tb_block_tensor_stat_sim
exec xsim tb_block_tensor_stat_sim -runall

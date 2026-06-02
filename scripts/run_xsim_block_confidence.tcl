set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/block_direction_stat.v \
]

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_block_direction_stat_confidence.v
exec xelab tb_block_direction_stat_confidence -s tb_block_direction_stat_confidence_sim
exec xsim tb_block_direction_stat_confidence_sim -runall

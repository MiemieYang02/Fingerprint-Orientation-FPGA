set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/direction/tensor_field_smoother.v \
]

foreach f $rtl_files {
  if {![file exists $f]} {
    puts "MISSING_RTL_FILE $f"
  }
}

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_tensor_field_smoother.v
exec xelab tb_tensor_field_smoother -s tb_tensor_field_smoother_sim
exec xsim tb_tensor_field_smoother_sim -runall

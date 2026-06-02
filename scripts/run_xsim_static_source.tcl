set root_dir [file normalize [file join [file dirname [info script]] ..]]
cd $root_dir

set rtl_files [list \
  fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sources_1/new/image/image_static_mem_source.v \
]

foreach f $rtl_files {
  if {![file exists $f]} {
    puts "MISSING_RTL_FILE $f"
  }
}

exec xvlog -sv {*}$rtl_files fingerprint_direction_fpga/fingerprint_direction_fpga.srcs/sim_1/new/tb_static_image_source.v
exec xelab tb_static_image_source -s tb_static_image_source_sim
exec xsim tb_static_image_source_sim -runall

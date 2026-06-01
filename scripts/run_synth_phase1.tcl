set root_dir [file normalize [file join [file dirname [info script]] ..]]
set proj_file [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.xpr]

open_project $proj_file
update_compile_order -fileset sources_1
synth_design -top fpga_orientation_top -part xc7a75tfgg484-2
report_utilization -file [file join $root_dir fingerprint_direction_fpga phase1_utilization_synth.rpt]
close_project

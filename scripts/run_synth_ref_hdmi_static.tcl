set root_dir [file normalize [file join [file dirname [info script]] ..]]
set proj_file [file join $root_dir fingerprint_direction_fpga fingerprint_direction_fpga.xpr]
set out_dir [file join $root_dir fingerprint_direction_fpga]

open_project $proj_file
set_property top fingerprint_ref_hdmi_static_top [get_filesets sources_1]
update_compile_order -fileset sources_1

synth_design -top fingerprint_ref_hdmi_static_top -part xc7a75tfgg484-2
report_utilization -file [file join $out_dir ref_hdmi_static_utilization_synth.rpt]
close_project

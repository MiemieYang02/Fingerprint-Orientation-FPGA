create_clock -period 20.000 -name board_clk [get_ports -quiet {clk sys_clk}]
set_property PACKAGE_PIN Y18 [get_ports -quiet {clk sys_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports -quiet {clk sys_clk}]

set_property PACKAGE_PIN P19 [get_ports -quiet {rst_n sys_rst_n}]
set_property IOSTANDARD LVCMOS33 [get_ports -quiet {rst_n sys_rst_n}]

# HDMI-A pins copied from the reference OV5640 HDMI-A project.
set_property PACKAGE_PIN AA9 [get_ports -quiet {tmds_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports -quiet {tmds_data_p[0]}]

set_property PACKAGE_PIN AA10 [get_ports -quiet {tmds_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports -quiet {tmds_data_p[1]}]

set_property PACKAGE_PIN V10 [get_ports -quiet {tmds_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports -quiet {tmds_data_p[2]}]

set_property PACKAGE_PIN W11 [get_ports -quiet tmds_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports -quiet tmds_clk_p]

set_property PACKAGE_PIN W14 [get_ports -quiet hpdin]
set_property IOSTANDARD LVCMOS33 [get_ports -quiet hpdin]

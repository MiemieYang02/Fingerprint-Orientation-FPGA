create_clock -period 20.000 -name clk [get_ports clk]
set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN P19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Final HDMI/OBS target pins from the reference OV5640 HDMI-A project.
# These are intentionally kept as comments in Phase 1 because the algorithm
# skeleton top does not expose HDMI ports yet.
# set_property PACKAGE_PIN AA9  [get_ports {tmds_data_p[0]}]
# set_property PACKAGE_PIN AA10 [get_ports {tmds_data_p[1]}]
# set_property PACKAGE_PIN V10  [get_ports {tmds_data_p[2]}]
# set_property PACKAGE_PIN W11  [get_ports tmds_clk_p]
# set_property PACKAGE_PIN W14  [get_ports hpdin]

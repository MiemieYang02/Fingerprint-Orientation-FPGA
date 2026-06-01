`timescale 1ns/1ps

module hdmi_clock_gen (
    input  wire clk_in,
    input  wire rst,
    output wire pixel_clk,
    output wire serial_clk_5x,
    output wire locked
);
    wire clkfb;
    wire clkfb_buf;
    wire pixel_clk_unbuf;
    wire serial_clk_unbuf;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(25.0),
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(20.000),
        .CLKOUT0_DIVIDE_F(50.0),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_DIVIDE(10),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0.0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) u_mmcm (
        .CLKIN1(clk_in),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),
        .CLKOUT0(pixel_clk_unbuf),
        .CLKOUT1(serial_clk_unbuf),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(rst)
    );

    BUFG u_clkfb_buf (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG u_pixel_clk_buf (
        .I(pixel_clk_unbuf),
        .O(pixel_clk)
    );

    BUFG u_serial_clk_buf (
        .I(serial_clk_unbuf),
        .O(serial_clk_5x)
    );
endmodule

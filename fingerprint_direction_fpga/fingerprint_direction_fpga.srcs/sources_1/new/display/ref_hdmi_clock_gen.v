`timescale 1ns / 1ps

module ref_hdmi_clock_gen(
    input  wire clk_in,
    input  wire reset,
    output wire pixel_clk,
    output wire pixel_clk_5x,
    output wire locked
);

wire clkfb;
wire clkfb_buf;
wire clk_in_buf;
wire clk_200;
wire clk_50;
wire clk_325;
wire clk_65;
wire clk_200_buf;
wire clk_50_buf;
wire clk_325_buf;
wire clk_65_buf;
wire [15:0] do_unused;
wire drdy_unused;
wire psdone_unused;
wire clkfb_stopped_unused;
wire clkin_stopped_unused;

IBUF u_clk_in_buf (
    .I(clk_in),
    .O(clk_in_buf)
);

MMCME2_ADV #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT4_CASCADE("FALSE"),
    .COMPENSATION("ZHOLD"),
    .STARTUP_WAIT("FALSE"),
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_MULT_F(26.000),
    .CLKFBOUT_PHASE(0.000),
    .CLKFBOUT_USE_FINE_PS("FALSE"),
    .CLKOUT0_DIVIDE_F(6.500),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT0_DUTY_CYCLE(0.500),
    .CLKOUT0_USE_FINE_PS("FALSE"),
    .CLKOUT1_DIVIDE(26),
    .CLKOUT1_PHASE(0.000),
    .CLKOUT1_DUTY_CYCLE(0.500),
    .CLKOUT1_USE_FINE_PS("FALSE"),
    .CLKOUT2_DIVIDE(4),
    .CLKOUT2_PHASE(0.000),
    .CLKOUT2_DUTY_CYCLE(0.500),
    .CLKOUT2_USE_FINE_PS("FALSE"),
    .CLKOUT3_DIVIDE(20),
    .CLKOUT3_PHASE(0.000),
    .CLKOUT3_DUTY_CYCLE(0.500),
    .CLKOUT3_USE_FINE_PS("FALSE"),
    .CLKIN1_PERIOD(20.000)
) u_mmcm (
    .CLKFBIN(clkfb_buf),
    .CLKIN1(clk_in_buf),
    .CLKIN2(1'b0),
    .CLKINSEL(1'b1),
    .RST(reset),
    .PWRDWN(1'b0),
    .DADDR(7'h0),
    .DCLK(1'b0),
    .DEN(1'b0),
    .DI(16'h0),
    .DO(do_unused),
    .DRDY(drdy_unused),
    .DWE(1'b0),
    .PSCLK(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSDONE(psdone_unused),
    .CLKFBOUT(clkfb),
    .CLKFBOUTB(),
    .CLKOUT0(clk_200),
    .CLKOUT0B(),
    .CLKOUT1(clk_50),
    .CLKOUT1B(),
    .CLKOUT2(clk_325),
    .CLKOUT2B(),
    .CLKOUT3(clk_65),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKINSTOPPED(clkin_stopped_unused),
    .CLKFBSTOPPED(clkfb_stopped_unused),
    .LOCKED(locked)
);

BUFG u_bufg_fb (
    .I(clkfb),
    .O(clkfb_buf)
);

BUFG u_bufg_pixel (
    .I(clk_65),
    .O(clk_65_buf)
);

BUFG u_bufg_pixel_5x (
    .I(clk_325),
    .O(clk_325_buf)
);

BUFG u_bufg_200 (
    .I(clk_200),
    .O(clk_200_buf)
);

BUFG u_bufg_50 (
    .I(clk_50),
    .O(clk_50_buf)
);

assign pixel_clk = clk_65_buf;
assign pixel_clk_5x = clk_325_buf;

endmodule

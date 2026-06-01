`timescale 1ns/1ps

module hdmi_overlay_stub (
    input wire clk,
    input wire rst_n
);
    wire unused_clk;
    wire unused_rst_n;

    assign unused_clk = clk;
    assign unused_rst_n = rst_n;
endmodule

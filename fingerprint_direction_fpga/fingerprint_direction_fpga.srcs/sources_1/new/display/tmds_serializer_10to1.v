`timescale 1ns/1ps

module tmds_serializer_10to1 (
    input  wire       rst,
    input  wire       pixel_clk,
    input  wire       serial_clk_5x,
    input  wire [9:0] parallel_data,
    output wire       serial_data
);
    wire shift1;
    wire shift2;

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),
        .SERDES_MODE("MASTER"),
        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    ) u_oserdes_master (
        .CLK(serial_clk_5x),
        .CLKDIV(pixel_clk),
        .RST(rst),
        .OCE(1'b1),
        .OQ(serial_data),
        .D1(parallel_data[0]),
        .D2(parallel_data[1]),
        .D3(parallel_data[2]),
        .D4(parallel_data[3]),
        .D5(parallel_data[4]),
        .D6(parallel_data[5]),
        .D7(parallel_data[6]),
        .D8(parallel_data[7]),
        .SHIFTIN1(shift1),
        .SHIFTIN2(shift2),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .OFB(),
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),
        .TCE(1'b0),
        .TBYTEOUT(),
        .TFB(),
        .TQ()
    );

    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),
        .SERDES_MODE("SLAVE"),
        .TBYTE_CTL("FALSE"),
        .TBYTE_SRC("FALSE"),
        .TRISTATE_WIDTH(1)
    ) u_oserdes_slave (
        .CLK(serial_clk_5x),
        .CLKDIV(pixel_clk),
        .RST(rst),
        .OCE(1'b1),
        .OQ(),
        .D1(1'b0),
        .D2(1'b0),
        .D3(parallel_data[8]),
        .D4(parallel_data[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        .SHIFTOUT1(shift1),
        .SHIFTOUT2(shift2),
        .OFB(),
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),
        .TCE(1'b0),
        .TBYTEOUT(),
        .TFB(),
        .TQ()
    );
endmodule

`timescale 1ns/1ps

module direction_quantizer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_x,
    input  wire [7:0] in_y,
    input  wire [7:0] angle_code,
    output reg        out_valid,
    output reg [7:0]  out_x,
    output reg [7:0]  out_y,
    output reg [2:0]  dir_bin
);
    reg [8:0] rounded_angle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_x <= 8'd0;
            out_y <= 8'd0;
            dir_bin <= 3'd0;
        end else begin
            out_valid <= in_valid;
            out_x <= in_x;
            out_y <= in_y;
            if (in_valid) begin
                rounded_angle = {1'b0, angle_code} + 9'd16;
                dir_bin <= rounded_angle[8] ? 3'd0 : rounded_angle[7:5];
            end
        end
    end
endmodule

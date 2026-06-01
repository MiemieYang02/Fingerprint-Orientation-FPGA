`timescale 1ns/1ps

module sobel_core (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             in_valid,
    input  wire [7:0]       in_x,
    input  wire [7:0]       in_y,
    input  wire [7:0]       p00,
    input  wire [7:0]       p01,
    input  wire [7:0]       p02,
    input  wire [7:0]       p10,
    input  wire [7:0]       p12,
    input  wire [7:0]       p20,
    input  wire [7:0]       p21,
    input  wire [7:0]       p22,
    output reg              out_valid,
    output reg [7:0]        out_x,
    output reg [7:0]        out_y,
    output reg signed [11:0] gx,
    output reg signed [11:0] gy
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_x <= 8'd0;
            out_y <= 8'd0;
            gx <= 12'sd0;
            gy <= 12'sd0;
        end else begin
            out_valid <= in_valid;
            out_x <= in_x;
            out_y <= in_y;
            if (in_valid) begin
                gx <= -$signed({4'd0, p00}) + $signed({4'd0, p02})
                    - ($signed({4'd0, p10}) <<< 1) + ($signed({4'd0, p12}) <<< 1)
                    - $signed({4'd0, p20}) + $signed({4'd0, p22});
                gy <=  $signed({4'd0, p00}) + ($signed({4'd0, p01}) <<< 1) + $signed({4'd0, p02})
                    - $signed({4'd0, p20}) - ($signed({4'd0, p21}) <<< 1) - $signed({4'd0, p22});
            end
        end
    end
endmodule

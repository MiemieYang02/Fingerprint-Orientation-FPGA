`timescale 1ns/1ps

module pixel_window_3x3 #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_gray,
    input  wire [7:0] in_x,
    input  wire [7:0] in_y,
    output reg        out_valid,
    output reg [7:0]  out_x,
    output reg [7:0]  out_y,
    output reg [7:0]  p00,
    output reg [7:0]  p01,
    output reg [7:0]  p02,
    output reg [7:0]  p10,
    output reg [7:0]  p11,
    output reg [7:0]  p12,
    output reg [7:0]  p20,
    output reg [7:0]  p21,
    output reg [7:0]  p22
);
    reg [7:0] line_prev1 [0:IMAGE_W-1];
    reg [7:0] line_prev2 [0:IMAGE_W-1];

    reg [7:0] r0_0;
    reg [7:0] r0_1;
    reg [7:0] r0_2;
    reg [7:0] r1_0;
    reg [7:0] r1_1;
    reg [7:0] r1_2;
    reg [7:0] r2_0;
    reg [7:0] r2_1;
    reg [7:0] r2_2;

    reg [7:0] n0_0;
    reg [7:0] n0_1;
    reg [7:0] n0_2;
    reg [7:0] n1_0;
    reg [7:0] n1_1;
    reg [7:0] n1_2;
    reg [7:0] n2_0;
    reg [7:0] n2_1;
    reg [7:0] n2_2;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_x <= 8'd0;
            out_y <= 8'd0;
            p00 <= 8'd0; p01 <= 8'd0; p02 <= 8'd0;
            p10 <= 8'd0; p11 <= 8'd0; p12 <= 8'd0;
            p20 <= 8'd0; p21 <= 8'd0; p22 <= 8'd0;
            r0_0 <= 8'd0; r0_1 <= 8'd0; r0_2 <= 8'd0;
            r1_0 <= 8'd0; r1_1 <= 8'd0; r1_2 <= 8'd0;
            r2_0 <= 8'd0; r2_1 <= 8'd0; r2_2 <= 8'd0;
            for (i = 0; i < IMAGE_W; i = i + 1) begin
                line_prev1[i] <= 8'd0;
                line_prev2[i] <= 8'd0;
            end
        end else begin
            out_valid <= 1'b0;
            if (in_valid) begin
                n0_0 = r0_1;
                n0_1 = r0_2;
                n0_2 = line_prev2[in_x];
                n1_0 = r1_1;
                n1_1 = r1_2;
                n1_2 = line_prev1[in_x];
                n2_0 = r2_1;
                n2_1 = r2_2;
                n2_2 = in_gray;

                r0_0 <= n0_0; r0_1 <= n0_1; r0_2 <= n0_2;
                r1_0 <= n1_0; r1_1 <= n1_1; r1_2 <= n1_2;
                r2_0 <= n2_0; r2_1 <= n2_1; r2_2 <= n2_2;

                line_prev2[in_x] <= line_prev1[in_x];
                line_prev1[in_x] <= in_gray;

                if ((in_x >= 8'd2) && (in_y >= 8'd2)) begin
                    out_valid <= 1'b1;
                    out_x <= in_x - 8'd1;
                    out_y <= in_y - 8'd1;
                    p00 <= n0_0; p01 <= n0_1; p02 <= n0_2;
                    p10 <= n1_0; p11 <= n1_1; p12 <= n1_2;
                    p20 <= n2_0; p21 <= n2_1; p22 <= n2_2;
                end
            end
        end
    end
endmodule

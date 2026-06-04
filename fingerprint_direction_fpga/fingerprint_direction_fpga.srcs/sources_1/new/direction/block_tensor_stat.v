`timescale 1ns/1ps

// Accumulates Sobel gradients over one 4x4 local block using the standard
// fingerprint orientation tensor:
//   tensor_x = sum(Gx*Gx - Gy*Gy)
//   tensor_y = sum(2*Gx*Gy)
// The CORDIC stage consumes this double-angle vector and converts it to the
// ridge tangent direction used for display.
module block_tensor_stat #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256,
    parameter MIN_BLOCK_VOTES = 3
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire               vote_valid,
    input  wire [7:0]         in_x,
    input  wire [7:0]         in_y,
    input  wire signed [11:0] gx,
    input  wire signed [11:0] gy,
    output reg                block_valid,
    output reg                block_active,
    output reg [5:0]          block_x,
    output reg [5:0]          block_y,
    output reg signed [31:0]  tensor_x,
    output reg signed [31:0]  tensor_y
);
    localparam [7:0] LAST_VALID_X = IMAGE_W - 2;
    localparam [7:0] LAST_VALID_Y = IMAGE_H - 2;

    reg signed [31:0] acc_x [0:63];
    reg signed [31:0] acc_y [0:63];
    reg [4:0] vote_count [0:63];

    wire [23:0] gx_sq = gx * gx;
    wire [23:0] gy_sq = gy * gy;
    wire signed [23:0] gx_gy = gx * gy;
    wire signed [24:0] tensor_x_term_raw = $signed({1'b0, gx_sq}) - $signed({1'b0, gy_sq});
    wire signed [24:0] tensor_y_term_raw = $signed({gx_gy[23], gx_gy}) <<< 1;
    wire signed [31:0] tensor_x_term = {{7{tensor_x_term_raw[24]}}, tensor_x_term_raw};
    wire signed [31:0] tensor_y_term = {{7{tensor_y_term_raw[24]}}, tensor_y_term_raw};

    reg [5:0] bx;
    reg [5:0] by;
    reg signed [31:0] next_acc_x;
    reg signed [31:0] next_acc_y;
    reg [4:0] next_votes;
    reg end_block_x;
    reg end_block_y;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_valid <= 1'b0;
            block_active <= 1'b0;
            block_x <= 6'd0;
            block_y <= 6'd0;
            tensor_x <= 32'sd0;
            tensor_y <= 32'sd0;
            for (i = 0; i < 64; i = i + 1) begin
                acc_x[i] <= 32'sd0;
                acc_y[i] <= 32'sd0;
                vote_count[i] <= 5'd0;
            end
        end else begin
            block_valid <= 1'b0;
            block_active <= 1'b0;

            if (in_valid) begin
                bx = in_x[7:2];
                by = in_y[7:2];

                next_acc_x = acc_x[bx] + (vote_valid ? tensor_x_term : 32'sd0);
                next_acc_y = acc_y[bx] + (vote_valid ? tensor_y_term : 32'sd0);
                next_votes = vote_count[bx] + (vote_valid ? 5'd1 : 5'd0);

                acc_x[bx] <= next_acc_x;
                acc_y[bx] <= next_acc_y;
                vote_count[bx] <= next_votes;

                end_block_x = (in_x[1:0] == 2'd3) || (in_x == LAST_VALID_X);
                end_block_y = (in_y[1:0] == 2'd3) || (in_y == LAST_VALID_Y);

                if (end_block_x && end_block_y) begin
                    block_valid <= 1'b1;
                    block_active <= (next_votes >= MIN_BLOCK_VOTES);
                    block_x <= bx;
                    block_y <= by;
                    tensor_x <= next_acc_x;
                    tensor_y <= next_acc_y;

                    acc_x[bx] <= 32'sd0;
                    acc_y[bx] <= 32'sd0;
                    vote_count[bx] <= 5'd0;
                end
            end
        end
    end
endmodule

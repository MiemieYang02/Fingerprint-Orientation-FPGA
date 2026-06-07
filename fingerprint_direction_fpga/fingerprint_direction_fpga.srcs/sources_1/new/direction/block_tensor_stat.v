`timescale 1ns/1ps

// Accumulates Sobel gradients over one 8x8 local block. Sobel gives the ridge
// normal, so each gradient is first rotated to the fingerprint ridge tangent:
//   ridge_gx = -Gy
//   ridge_gy =  Gx
// The tensor below is therefore already a ridge-tangent double-angle vector
// before it reaches the CORDIC stage.
module block_tensor_stat #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256,
    parameter MIN_BLOCK_VOTES = 8
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
    output reg [4:0]          block_x,
    output reg [4:0]          block_y,
    output reg signed [31:0]  tensor_x,
    output reg signed [31:0]  tensor_y
);
    localparam [7:0] LAST_VALID_X = IMAGE_W - 2;
    localparam [7:0] LAST_VALID_Y = IMAGE_H - 2;

    reg signed [31:0] acc_x [0:31];
    reg signed [31:0] acc_y [0:31];
    reg [6:0] vote_count [0:31];

    wire [23:0] gx_sq = gx * gx;
    wire [23:0] gy_sq = gy * gy;
    wire signed [23:0] gx_gy = gx * gy;
    wire signed [24:0] tensor_x_term_raw = $signed({1'b0, gy_sq}) - $signed({1'b0, gx_sq});
    wire signed [24:0] tensor_xy_double_raw = $signed({gx_gy[23], gx_gy}) <<< 1;
    wire signed [24:0] tensor_y_term_raw = -tensor_xy_double_raw;
    wire signed [31:0] tensor_x_term = {{7{tensor_x_term_raw[24]}}, tensor_x_term_raw};
    wire signed [31:0] tensor_y_term = {{7{tensor_y_term_raw[24]}}, tensor_y_term_raw};

    reg [4:0] bx;
    reg [4:0] by;
    reg signed [31:0] next_acc_x;
    reg signed [31:0] next_acc_y;
    reg [6:0] next_votes;
    reg end_block_x;
    reg end_block_y;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_valid <= 1'b0;
            block_active <= 1'b0;
            block_x <= 5'd0;
            block_y <= 5'd0;
            tensor_x <= 32'sd0;
            tensor_y <= 32'sd0;
            for (i = 0; i < 32; i = i + 1) begin
                acc_x[i] <= 32'sd0;
                acc_y[i] <= 32'sd0;
                vote_count[i] <= 7'd0;
            end
        end else begin
            block_valid <= 1'b0;
            block_active <= 1'b0;

            if (in_valid) begin
                bx = in_x[7:3];
                by = in_y[7:3];

                next_acc_x = acc_x[bx] + (vote_valid ? tensor_x_term : 32'sd0);
                next_acc_y = acc_y[bx] + (vote_valid ? tensor_y_term : 32'sd0);
                next_votes = vote_count[bx] + (vote_valid ? 7'd1 : 7'd0);

                acc_x[bx] <= next_acc_x;
                acc_y[bx] <= next_acc_y;
                vote_count[bx] <= next_votes;

                end_block_x = (in_x[2:0] == 3'd7) || (in_x == LAST_VALID_X);
                end_block_y = (in_y[2:0] == 3'd7) || (in_y == LAST_VALID_Y);

                if (end_block_x && end_block_y) begin
                    block_valid <= 1'b1;
                    block_active <= (next_votes >= MIN_BLOCK_VOTES);
                    block_x <= bx;
                    block_y <= by;
                    tensor_x <= next_acc_x;
                    tensor_y <= next_acc_y;

                    acc_x[bx] <= 32'sd0;
                    acc_y[bx] <= 32'sd0;
                    vote_count[bx] <= 7'd0;
                end
            end
        end
    end
endmodule

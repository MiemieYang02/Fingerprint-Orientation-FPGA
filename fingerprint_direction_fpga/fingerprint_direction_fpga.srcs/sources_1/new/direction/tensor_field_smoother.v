`timescale 1ns/1ps

// Smooths the 4x4 block orientation tensor field before CORDIC conversion.
// A centered 3x3 neighborhood is accumulated in tensor space, not angle space,
// so opposite angle wraparound cannot corrupt the averaged ridge direction.
module tensor_field_smoother #(
    parameter MIN_NEIGHBOR_ACTIVE = 4,
    parameter MIN_SMOOTH_STRENGTH = 512
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire               in_active,
    input  wire [5:0]         in_block_x,
    input  wire [5:0]         in_block_y,
    input  wire signed [31:0] in_tensor_x,
    input  wire signed [31:0] in_tensor_y,
    output reg                out_valid,
    output reg                out_active,
    output reg [5:0]          out_block_x,
    output reg [5:0]          out_block_y,
    output reg signed [31:0]  out_tensor_x,
    output reg signed [31:0]  out_tensor_y
);
    (* ram_style = "distributed" *) reg signed [31:0] prev1_x [0:63];
    (* ram_style = "distributed" *) reg signed [31:0] prev1_y [0:63];
    (* ram_style = "distributed" *) reg signed [31:0] prev2_x [0:63];
    (* ram_style = "distributed" *) reg signed [31:0] prev2_y [0:63];
    (* ram_style = "distributed" *) reg prev1_active [0:63];
    (* ram_style = "distributed" *) reg prev2_active [0:63];

    reg signed [31:0] cur_x1;
    reg signed [31:0] cur_y1;
    reg signed [31:0] cur_x2;
    reg signed [31:0] cur_y2;
    reg cur_active1;
    reg cur_active2;

    reg signed [31:0] p1_x1;
    reg signed [31:0] p1_y1;
    reg signed [31:0] p1_x2;
    reg signed [31:0] p1_y2;
    reg p1_active1;
    reg p1_active2;

    reg signed [31:0] p2_x1;
    reg signed [31:0] p2_y1;
    reg signed [31:0] p2_x2;
    reg signed [31:0] p2_y2;
    reg p2_active1;
    reg p2_active2;

    reg signed [31:0] prev1_cur_x;
    reg signed [31:0] prev1_cur_y;
    reg signed [31:0] prev2_cur_x;
    reg signed [31:0] prev2_cur_y;
    reg prev1_cur_active;
    reg prev2_cur_active;

    reg signed [31:0] smooth_x;
    reg signed [31:0] smooth_y;
    reg [3:0] active_count;
    reg [32:0] smooth_strength;

    function signed [31:0] active_tensor;
        input signed [31:0] value;
        input active;
        begin
            active_tensor = active ? value : 32'sd0;
        end
    endfunction

    function [31:0] abs32;
        input signed [31:0] value;
        begin
            abs32 = value[31] ? (~value + 32'd1) : value;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_active <= 1'b0;
            out_block_x <= 6'd0;
            out_block_y <= 6'd0;
            out_tensor_x <= 32'sd0;
            out_tensor_y <= 32'sd0;

            cur_x1 <= 32'sd0;
            cur_y1 <= 32'sd0;
            cur_x2 <= 32'sd0;
            cur_y2 <= 32'sd0;
            cur_active1 <= 1'b0;
            cur_active2 <= 1'b0;
            p1_x1 <= 32'sd0;
            p1_y1 <= 32'sd0;
            p1_x2 <= 32'sd0;
            p1_y2 <= 32'sd0;
            p1_active1 <= 1'b0;
            p1_active2 <= 1'b0;
            p2_x1 <= 32'sd0;
            p2_y1 <= 32'sd0;
            p2_x2 <= 32'sd0;
            p2_y2 <= 32'sd0;
            p2_active1 <= 1'b0;
            p2_active2 <= 1'b0;

        end else begin
            out_valid <= 1'b0;
            out_active <= 1'b0;

            if (in_valid) begin
                prev1_cur_x = prev1_x[in_block_x];
                prev1_cur_y = prev1_y[in_block_x];
                prev1_cur_active = prev1_active[in_block_x];
                prev2_cur_x = prev2_x[in_block_x];
                prev2_cur_y = prev2_y[in_block_x];
                prev2_cur_active = prev2_active[in_block_x];

                smooth_x =
                    active_tensor(p2_x2, p2_active2) +
                    active_tensor(p2_x1, p2_active1) +
                    active_tensor(prev2_cur_x, prev2_cur_active) +
                    active_tensor(p1_x2, p1_active2) +
                    active_tensor(p1_x1, p1_active1) +
                    active_tensor(prev1_cur_x, prev1_cur_active) +
                    active_tensor(cur_x2, cur_active2) +
                    active_tensor(cur_x1, cur_active1) +
                    active_tensor(in_tensor_x, in_active);
                smooth_y =
                    active_tensor(p2_y2, p2_active2) +
                    active_tensor(p2_y1, p2_active1) +
                    active_tensor(prev2_cur_y, prev2_cur_active) +
                    active_tensor(p1_y2, p1_active2) +
                    active_tensor(p1_y1, p1_active1) +
                    active_tensor(prev1_cur_y, prev1_cur_active) +
                    active_tensor(cur_y2, cur_active2) +
                    active_tensor(cur_y1, cur_active1) +
                    active_tensor(in_tensor_y, in_active);
                active_count = p2_active2 + p2_active1 + prev2_cur_active +
                               p1_active2 + p1_active1 + prev1_cur_active +
                               cur_active2 + cur_active1 + in_active;
                smooth_strength = {1'b0, abs32(smooth_x)} + {1'b0, abs32(smooth_y)};

                out_valid <= (in_block_x >= 6'd2) && (in_block_y >= 6'd2);
                out_active <= (active_count >= MIN_NEIGHBOR_ACTIVE) &&
                              (smooth_strength >= MIN_SMOOTH_STRENGTH);
                out_block_x <= in_block_x - 6'd1;
                out_block_y <= in_block_y - 6'd1;
                out_tensor_x <= smooth_x;
                out_tensor_y <= smooth_y;

                if (in_block_x == 6'd0) begin
                    cur_x2 <= 32'sd0;
                    cur_y2 <= 32'sd0;
                    cur_active2 <= 1'b0;
                    cur_x1 <= in_tensor_x;
                    cur_y1 <= in_tensor_y;
                    cur_active1 <= in_active;
                    p1_x2 <= 32'sd0;
                    p1_y2 <= 32'sd0;
                    p1_active2 <= 1'b0;
                    p1_x1 <= prev1_cur_x;
                    p1_y1 <= prev1_cur_y;
                    p1_active1 <= prev1_cur_active;
                    p2_x2 <= 32'sd0;
                    p2_y2 <= 32'sd0;
                    p2_active2 <= 1'b0;
                    p2_x1 <= prev2_cur_x;
                    p2_y1 <= prev2_cur_y;
                    p2_active1 <= prev2_cur_active;
                end else begin
                    cur_x2 <= cur_x1;
                    cur_y2 <= cur_y1;
                    cur_active2 <= cur_active1;
                    cur_x1 <= in_tensor_x;
                    cur_y1 <= in_tensor_y;
                    cur_active1 <= in_active;
                    p1_x2 <= p1_x1;
                    p1_y2 <= p1_y1;
                    p1_active2 <= p1_active1;
                    p1_x1 <= prev1_cur_x;
                    p1_y1 <= prev1_cur_y;
                    p1_active1 <= prev1_cur_active;
                    p2_x2 <= p2_x1;
                    p2_y2 <= p2_y1;
                    p2_active2 <= p2_active1;
                    p2_x1 <= prev2_cur_x;
                    p2_y1 <= prev2_cur_y;
                    p2_active1 <= prev2_cur_active;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (in_valid) begin
            prev2_x[in_block_x] <= prev1_x[in_block_x];
            prev2_y[in_block_x] <= prev1_y[in_block_x];
            prev2_active[in_block_x] <= prev1_active[in_block_x];
            prev1_x[in_block_x] <= in_tensor_x;
            prev1_y[in_block_x] <= in_tensor_y;
            prev1_active[in_block_x] <= in_active;
        end
    end
endmodule

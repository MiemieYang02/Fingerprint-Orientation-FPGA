`timescale 1ns/1ps

// Converts a block-level orientation tensor into an 8-bin fingerprint ridge
// direction. The tensor vector encodes twice the normal angle, so the final
// ridge direction is half the CORDIC atan2 angle plus 90 degrees.
module cordic_tensor_direction #(
    parameter ITER = 8
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire               in_active,
    input  wire [4:0]         in_block_x,
    input  wire [4:0]         in_block_y,
    input  wire signed [31:0] tensor_x,
    input  wire signed [31:0] tensor_y,
    output reg                block_valid,
    output reg                block_active,
    output reg [4:0]          block_x,
    output reg [4:0]          block_y,
    output reg [2:0]          block_dir
);
    localparam integer DATA_W = 40;
    localparam signed [DATA_W-1:0] ZERO = {DATA_W{1'b0}};

    reg signed [DATA_W-1:0] x_pipe [0:ITER];
    reg signed [DATA_W-1:0] y_pipe [0:ITER];
    reg signed [15:0] z_pipe [0:ITER];
    reg [4:0] x_coord_pipe [0:ITER];
    reg [4:0] y_coord_pipe [0:ITER];
    reg valid_pipe [0:ITER];
    reg active_pipe [0:ITER];
    reg axis_pipe [0:ITER];
    reg [2:0] axis_dir_pipe [0:ITER];

    wire signed [DATA_W-1:0] tensor_x_ext = {{(DATA_W-32){tensor_x[31]}}, tensor_x};
    wire signed [DATA_W-1:0] tensor_y_ext = {{(DATA_W-32){tensor_y[31]}}, tensor_y};

    reg signed [15:0] rounded_ridge_angle;
    integer i;

    function [15:0] atan_code;
        input [3:0] index;
        begin
            case (index)
                4'd0: atan_code = 16'd64; // atan(1)       * 256 / 180
                4'd1: atan_code = 16'd38; // atan(1/2)     * 256 / 180
                4'd2: atan_code = 16'd20; // atan(1/4)     * 256 / 180
                4'd3: atan_code = 16'd10; // atan(1/8)     * 256 / 180
                4'd4: atan_code = 16'd5;  // atan(1/16)    * 256 / 180
                4'd5: atan_code = 16'd3;  // atan(1/32)    * 256 / 180
                4'd6: atan_code = 16'd1;  // atan(1/64)    * 256 / 180
                4'd7: atan_code = 16'd1;  // atan(1/128)   * 256 / 180
                default: atan_code = 16'd0;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_valid <= 1'b0;
            block_active <= 1'b0;
            block_x <= 5'd0;
            block_y <= 5'd0;
            block_dir <= 3'd0;
            rounded_ridge_angle <= 16'sd0;
            for (i = 0; i <= ITER; i = i + 1) begin
                x_pipe[i] <= {DATA_W{1'b0}};
                y_pipe[i] <= {DATA_W{1'b0}};
                z_pipe[i] <= 16'sd0;
                x_coord_pipe[i] <= 5'd0;
                y_coord_pipe[i] <= 5'd0;
                valid_pipe[i] <= 1'b0;
                active_pipe[i] <= 1'b0;
                axis_pipe[i] <= 1'b0;
                axis_dir_pipe[i] <= 3'd0;
            end
        end else begin
            valid_pipe[0] <= in_valid;
            active_pipe[0] <= in_valid && in_active;
            axis_pipe[0] <= in_valid && (tensor_y == 32'sd0);
            axis_dir_pipe[0] <= (tensor_x < 32'sd0) ? 3'd0 : 3'd4;
            x_coord_pipe[0] <= in_block_x;
            y_coord_pipe[0] <= in_block_y;

            // Preserve the full 360-degree double-angle quadrant before the
            // later divide-by-two step. Losing this quadrant is what makes
            // horizontal and vertical ridge directions swap incorrectly.
            if (tensor_x_ext < ZERO) begin
                x_pipe[0] <= -tensor_x_ext;
                y_pipe[0] <= -tensor_y_ext;
                z_pipe[0] <= (tensor_y_ext >= ZERO) ? 16'sd256 : -16'sd256;
            end else begin
                x_pipe[0] <= tensor_x_ext;
                y_pipe[0] <= tensor_y_ext;
                z_pipe[0] <= 16'sd0;
            end

            for (i = 0; i < ITER; i = i + 1) begin
                valid_pipe[i + 1] <= valid_pipe[i];
                active_pipe[i + 1] <= active_pipe[i];
                axis_pipe[i + 1] <= axis_pipe[i];
                axis_dir_pipe[i + 1] <= axis_dir_pipe[i];
                x_coord_pipe[i + 1] <= x_coord_pipe[i];
                y_coord_pipe[i + 1] <= y_coord_pipe[i];

                if (y_pipe[i] >= ZERO) begin
                    x_pipe[i + 1] <= x_pipe[i] + (y_pipe[i] >>> i);
                    y_pipe[i + 1] <= y_pipe[i] - (x_pipe[i] >>> i);
                    z_pipe[i + 1] <= z_pipe[i] + $signed({1'b0, atan_code(i[3:0])});
                end else begin
                    x_pipe[i + 1] <= x_pipe[i] - (y_pipe[i] >>> i);
                    y_pipe[i + 1] <= y_pipe[i] + (x_pipe[i] >>> i);
                    z_pipe[i + 1] <= z_pipe[i] - $signed({1'b0, atan_code(i[3:0])});
                end
            end

            block_valid <= valid_pipe[ITER];
            block_active <= active_pipe[ITER];
            block_x <= x_coord_pipe[ITER];
            block_y <= y_coord_pipe[ITER];
            if (valid_pipe[ITER]) begin
                if (axis_pipe[ITER]) begin
                    block_dir <= axis_dir_pipe[ITER];
                end else begin
                    rounded_ridge_angle = (z_pipe[ITER] >>> 1) + 16'sd128 + 16'sd16;
                    block_dir <= rounded_ridge_angle[7:5];
                end
            end
        end
    end
endmodule

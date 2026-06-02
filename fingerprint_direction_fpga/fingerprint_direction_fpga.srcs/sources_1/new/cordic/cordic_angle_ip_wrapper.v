`timescale 1ns/1ps

module cordic_angle_ip_wrapper (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              in_valid,
    input  wire              in_vote_valid,
    input  wire [7:0]        in_x,
    input  wire [7:0]        in_y,
    input  wire signed [11:0] gx,
    input  wire signed [11:0] gy,
    output reg               out_valid,
    output reg               out_vote_valid,
    output reg [7:0]         out_x,
    output reg [7:0]         out_y,
    output reg [7:0]         angle_code
);
    localparam integer ITER = 8;

    reg signed [23:0] x_pipe [0:ITER];
    reg signed [23:0] y_pipe [0:ITER];
    reg signed [15:0] z_pipe [0:ITER];
    reg [7:0] x_coord_pipe [0:ITER];
    reg [7:0] y_coord_pipe [0:ITER];
    reg valid_pipe [0:ITER];
    reg vote_pipe [0:ITER];

    wire signed [23:0] gx_ext = {{12{gx[11]}}, gx};
    wire signed [23:0] gy_ext = {{12{gy[11]}}, gy};

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
            out_valid <= 1'b0;
            out_vote_valid <= 1'b0;
            out_x <= 8'd0;
            out_y <= 8'd0;
            angle_code <= 8'd0;
            for (i = 0; i <= ITER; i = i + 1) begin
                x_pipe[i] <= 24'sd0;
                y_pipe[i] <= 24'sd0;
                z_pipe[i] <= 16'sd0;
                x_coord_pipe[i] <= 8'd0;
                y_coord_pipe[i] <= 8'd0;
                valid_pipe[i] <= 1'b0;
                vote_pipe[i] <= 1'b0;
            end
        end else begin
            valid_pipe[0] <= in_valid;
            vote_pipe[0] <= in_valid && in_vote_valid;
            x_coord_pipe[0] <= in_x;
            y_coord_pipe[0] <= in_y;

            if (gx_ext < 24'sd0) begin
                x_pipe[0] <= -gx_ext;
                y_pipe[0] <= -gy_ext;
            end else begin
                x_pipe[0] <= gx_ext;
                y_pipe[0] <= gy_ext;
            end
            z_pipe[0] <= 16'sd0;

            for (i = 0; i < ITER; i = i + 1) begin
                valid_pipe[i + 1] <= valid_pipe[i];
                vote_pipe[i + 1] <= vote_pipe[i];
                x_coord_pipe[i + 1] <= x_coord_pipe[i];
                y_coord_pipe[i + 1] <= y_coord_pipe[i];

                if (y_pipe[i] >= 24'sd0) begin
                    x_pipe[i + 1] <= x_pipe[i] + (y_pipe[i] >>> i);
                    y_pipe[i + 1] <= y_pipe[i] - (x_pipe[i] >>> i);
                    z_pipe[i + 1] <= z_pipe[i] + $signed({1'b0, atan_code(i[3:0])});
                end else begin
                    x_pipe[i + 1] <= x_pipe[i] - (y_pipe[i] >>> i);
                    y_pipe[i + 1] <= y_pipe[i] + (x_pipe[i] >>> i);
                    z_pipe[i + 1] <= z_pipe[i] - $signed({1'b0, atan_code(i[3:0])});
                end
            end

            out_valid <= valid_pipe[ITER];
            out_vote_valid <= vote_pipe[ITER];
            out_x <= x_coord_pipe[ITER];
            out_y <= y_coord_pipe[ITER];
            if (valid_pipe[ITER]) begin
                angle_code <= z_pipe[ITER][7:0];
            end
        end
    end
endmodule

`timescale 1ns/1ps

module block_direction_stat #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_x,
    input  wire [7:0] in_y,
    input  wire [2:0] dir_bin,
    output reg        block_valid,
    output reg [3:0]  block_x,
    output reg [3:0]  block_y,
    output reg [2:0]  block_dir
);
    localparam [7:0] LAST_VALID_X = IMAGE_W - 2;
    localparam [7:0] LAST_VALID_Y = IMAGE_H - 2;

    reg [8:0] count0 [0:15];
    reg [8:0] count1 [0:15];
    reg [8:0] count2 [0:15];
    reg [8:0] count3 [0:15];
    reg [8:0] count4 [0:15];
    reg [8:0] count5 [0:15];
    reg [8:0] count6 [0:15];
    reg [8:0] count7 [0:15];

    reg [3:0] bx;
    reg [3:0] by;
    reg [8:0] n0;
    reg [8:0] n1;
    reg [8:0] n2;
    reg [8:0] n3;
    reg [8:0] n4;
    reg [8:0] n5;
    reg [8:0] n6;
    reg [8:0] n7;
    reg [8:0] max_count;
    reg [2:0] max_dir;
    reg end_block_x;
    reg end_block_y;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_valid <= 1'b0;
            block_x <= 4'd0;
            block_y <= 4'd0;
            block_dir <= 3'd0;
            for (i = 0; i < 16; i = i + 1) begin
                count0[i] <= 9'd0; count1[i] <= 9'd0;
                count2[i] <= 9'd0; count3[i] <= 9'd0;
                count4[i] <= 9'd0; count5[i] <= 9'd0;
                count6[i] <= 9'd0; count7[i] <= 9'd0;
            end
        end else begin
            block_valid <= 1'b0;
            if (in_valid) begin
                bx = in_x[7:4];
                by = in_y[7:4];

                n0 = count0[bx] + (dir_bin == 3'd0);
                n1 = count1[bx] + (dir_bin == 3'd1);
                n2 = count2[bx] + (dir_bin == 3'd2);
                n3 = count3[bx] + (dir_bin == 3'd3);
                n4 = count4[bx] + (dir_bin == 3'd4);
                n5 = count5[bx] + (dir_bin == 3'd5);
                n6 = count6[bx] + (dir_bin == 3'd6);
                n7 = count7[bx] + (dir_bin == 3'd7);

                count0[bx] <= n0; count1[bx] <= n1;
                count2[bx] <= n2; count3[bx] <= n3;
                count4[bx] <= n4; count5[bx] <= n5;
                count6[bx] <= n6; count7[bx] <= n7;

                end_block_x = (in_x[3:0] == 4'hf) || (in_x == LAST_VALID_X);
                end_block_y = (in_y[3:0] == 4'hf) || (in_y == LAST_VALID_Y);

                if (end_block_x && end_block_y) begin
                    max_count = n0;
                    max_dir = 3'd0;
                    if (n1 > max_count) begin max_count = n1; max_dir = 3'd1; end
                    if (n2 > max_count) begin max_count = n2; max_dir = 3'd2; end
                    if (n3 > max_count) begin max_count = n3; max_dir = 3'd3; end
                    if (n4 > max_count) begin max_count = n4; max_dir = 3'd4; end
                    if (n5 > max_count) begin max_count = n5; max_dir = 3'd5; end
                    if (n6 > max_count) begin max_count = n6; max_dir = 3'd6; end
                    if (n7 > max_count) begin max_count = n7; max_dir = 3'd7; end

                    block_valid <= 1'b1;
                    block_x <= bx;
                    block_y <= by;
                    block_dir <= max_dir;

                    count0[bx] <= 9'd0; count1[bx] <= 9'd0;
                    count2[bx] <= 9'd0; count3[bx] <= 9'd0;
                    count4[bx] <= 9'd0; count5[bx] <= 9'd0;
                    count6[bx] <= 9'd0; count7[bx] <= 9'd0;
                end
            end
        end
    end
endmodule

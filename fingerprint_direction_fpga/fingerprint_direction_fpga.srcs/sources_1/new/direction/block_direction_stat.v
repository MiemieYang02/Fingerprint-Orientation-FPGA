`timescale 1ns/1ps

module block_direction_stat #(
    parameter IMAGE_W = 256,
    parameter IMAGE_H = 256,
    parameter MIN_BLOCK_VOTES = 8
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire       vote_valid,
    input  wire [7:0] in_x,
    input  wire [7:0] in_y,
    input  wire [2:0] dir_bin,
    output reg        block_valid,
    output reg        block_active,
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

    reg        s0_valid;
    reg [3:0]  s0_block_x;
    reg [3:0]  s0_block_y;
    reg [8:0]  s0_count0;
    reg [8:0]  s0_count1;
    reg [8:0]  s0_count2;
    reg [8:0]  s0_count3;
    reg [8:0]  s0_count4;
    reg [8:0]  s0_count5;
    reg [8:0]  s0_count6;
    reg [8:0]  s0_count7;
    reg [9:0]  s0_total;

    reg        s1_valid;
    reg [3:0]  s1_block_x;
    reg [3:0]  s1_block_y;
    reg [9:0]  s1_total;
    reg [8:0]  s1_count0;
    reg [8:0]  s1_count1;
    reg [8:0]  s1_count2;
    reg [8:0]  s1_count3;
    reg [2:0]  s1_dir0;
    reg [2:0]  s1_dir1;
    reg [2:0]  s1_dir2;
    reg [2:0]  s1_dir3;

    reg        s2_valid;
    reg [3:0]  s2_block_x;
    reg [3:0]  s2_block_y;
    reg [9:0]  s2_total;
    reg [8:0]  s2_count0;
    reg [8:0]  s2_count1;
    reg [2:0]  s2_dir0;
    reg [2:0]  s2_dir1;

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
    reg [9:0] ntotal;
    reg end_block_x;
    reg end_block_y;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_valid <= 1'b0;
            block_active <= 1'b0;
            block_x <= 4'd0;
            block_y <= 4'd0;
            block_dir <= 3'd0;
            s0_valid <= 1'b0;
            s0_block_x <= 4'd0;
            s0_block_y <= 4'd0;
            s0_count0 <= 9'd0; s0_count1 <= 9'd0;
            s0_count2 <= 9'd0; s0_count3 <= 9'd0;
            s0_count4 <= 9'd0; s0_count5 <= 9'd0;
            s0_count6 <= 9'd0; s0_count7 <= 9'd0;
            s0_total <= 10'd0;
            s1_valid <= 1'b0;
            s1_block_x <= 4'd0;
            s1_block_y <= 4'd0;
            s1_total <= 10'd0;
            s1_count0 <= 9'd0; s1_count1 <= 9'd0;
            s1_count2 <= 9'd0; s1_count3 <= 9'd0;
            s1_dir0 <= 3'd0; s1_dir1 <= 3'd0;
            s1_dir2 <= 3'd0; s1_dir3 <= 3'd0;
            s2_valid <= 1'b0;
            s2_block_x <= 4'd0;
            s2_block_y <= 4'd0;
            s2_total <= 10'd0;
            s2_count0 <= 9'd0; s2_count1 <= 9'd0;
            s2_dir0 <= 3'd0; s2_dir1 <= 3'd0;
            for (i = 0; i < 16; i = i + 1) begin
                count0[i] <= 9'd0; count1[i] <= 9'd0;
                count2[i] <= 9'd0; count3[i] <= 9'd0;
                count4[i] <= 9'd0; count5[i] <= 9'd0;
                count6[i] <= 9'd0; count7[i] <= 9'd0;
            end
        end else begin
            block_valid <= 1'b0;
            block_active <= 1'b0;
            s0_valid <= 1'b0;

            // Pipelined max reduction keeps the block statistic stage routable at
            // HDMI pixel-clock rates when real image input is later connected.
            s1_valid <= s0_valid;
            s1_block_x <= s0_block_x;
            s1_block_y <= s0_block_y;
            s1_total <= s0_total;
            if (s0_count1 > s0_count0) begin
                s1_count0 <= s0_count1;
                s1_dir0 <= 3'd1;
            end else begin
                s1_count0 <= s0_count0;
                s1_dir0 <= 3'd0;
            end
            if (s0_count3 > s0_count2) begin
                s1_count1 <= s0_count3;
                s1_dir1 <= 3'd3;
            end else begin
                s1_count1 <= s0_count2;
                s1_dir1 <= 3'd2;
            end
            if (s0_count5 > s0_count4) begin
                s1_count2 <= s0_count5;
                s1_dir2 <= 3'd5;
            end else begin
                s1_count2 <= s0_count4;
                s1_dir2 <= 3'd4;
            end
            if (s0_count7 > s0_count6) begin
                s1_count3 <= s0_count7;
                s1_dir3 <= 3'd7;
            end else begin
                s1_count3 <= s0_count6;
                s1_dir3 <= 3'd6;
            end

            s2_valid <= s1_valid;
            s2_block_x <= s1_block_x;
            s2_block_y <= s1_block_y;
            s2_total <= s1_total;
            if (s1_count1 > s1_count0) begin
                s2_count0 <= s1_count1;
                s2_dir0 <= s1_dir1;
            end else begin
                s2_count0 <= s1_count0;
                s2_dir0 <= s1_dir0;
            end
            if (s1_count3 > s1_count2) begin
                s2_count1 <= s1_count3;
                s2_dir1 <= s1_dir3;
            end else begin
                s2_count1 <= s1_count2;
                s2_dir1 <= s1_dir2;
            end

            if (s2_valid) begin
                block_valid <= 1'b1;
                block_active <= (s2_total >= MIN_BLOCK_VOTES);
                block_x <= s2_block_x;
                block_y <= s2_block_y;
                block_dir <= (s2_count1 > s2_count0) ? s2_dir1 : s2_dir0;
            end

            if (in_valid) begin
                bx = in_x[7:4];
                by = in_y[7:4];

                n0 = count0[bx] + (vote_valid && (dir_bin == 3'd0));
                n1 = count1[bx] + (vote_valid && (dir_bin == 3'd1));
                n2 = count2[bx] + (vote_valid && (dir_bin == 3'd2));
                n3 = count3[bx] + (vote_valid && (dir_bin == 3'd3));
                n4 = count4[bx] + (vote_valid && (dir_bin == 3'd4));
                n5 = count5[bx] + (vote_valid && (dir_bin == 3'd5));
                n6 = count6[bx] + (vote_valid && (dir_bin == 3'd6));
                n7 = count7[bx] + (vote_valid && (dir_bin == 3'd7));
                ntotal = n0 + n1 + n2 + n3 + n4 + n5 + n6 + n7;

                count0[bx] <= n0; count1[bx] <= n1;
                count2[bx] <= n2; count3[bx] <= n3;
                count4[bx] <= n4; count5[bx] <= n5;
                count6[bx] <= n6; count7[bx] <= n7;

                end_block_x = (in_x[3:0] == 4'hf) || (in_x == LAST_VALID_X);
                end_block_y = (in_y[3:0] == 4'hf) || (in_y == LAST_VALID_Y);

                if (end_block_x && end_block_y) begin
                    s0_valid <= 1'b1;
                    s0_block_x <= bx;
                    s0_block_y <= by;
                    s0_count0 <= n0; s0_count1 <= n1;
                    s0_count2 <= n2; s0_count3 <= n3;
                    s0_count4 <= n4; s0_count5 <= n5;
                    s0_count6 <= n6; s0_count7 <= n7;
                    s0_total <= ntotal;

                    count0[bx] <= 9'd0; count1[bx] <= 9'd0;
                    count2[bx] <= 9'd0; count3[bx] <= 9'd0;
                    count4[bx] <= 9'd0; count5[bx] <= 9'd0;
                    count6[bx] <= 9'd0; count7[bx] <= 9'd0;
                end
            end
        end
    end
endmodule

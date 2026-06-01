`timescale 1ns/1ps

module video_timing_640x480 (
    input  wire        pixel_clk,
    input  wire        rst_n,
    output wire        video_hs,
    output wire        video_vs,
    output wire        video_de,
    output wire [10:0] pixel_x,
    output wire [10:0] pixel_y
);
    localparam [10:0] H_ACTIVE = 11'd640;
    localparam [10:0] H_FRONT  = 11'd16;
    localparam [10:0] H_SYNC   = 11'd96;
    localparam [10:0] H_BACK   = 11'd48;
    localparam [10:0] H_TOTAL  = 11'd800;

    localparam [10:0] V_ACTIVE = 11'd480;
    localparam [10:0] V_FRONT  = 11'd10;
    localparam [10:0] V_SYNC   = 11'd2;
    localparam [10:0] V_BACK   = 11'd33;
    localparam [10:0] V_TOTAL  = 11'd525;

    reg [10:0] h_count;
    reg [10:0] v_count;

    assign video_de = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
    assign video_hs = ~((h_count >= H_ACTIVE + H_FRONT) &&
                        (h_count <  H_ACTIVE + H_FRONT + H_SYNC));
    assign video_vs = ~((v_count >= V_ACTIVE + V_FRONT) &&
                        (v_count <  V_ACTIVE + V_FRONT + V_SYNC));
    assign pixel_x = video_de ? h_count : 11'd0;
    assign pixel_y = video_de ? v_count : 11'd0;

    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 11'd0;
            v_count <= 11'd0;
        end else begin
            if (h_count == H_TOTAL - 1'b1) begin
                h_count <= 11'd0;
                if (v_count == V_TOTAL - 1'b1) begin
                    v_count <= 11'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end
endmodule

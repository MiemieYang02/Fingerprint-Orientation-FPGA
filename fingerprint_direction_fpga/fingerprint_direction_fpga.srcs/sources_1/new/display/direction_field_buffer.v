`timescale 1ns / 1ps

module direction_field_buffer(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       block_valid,
    input  wire [3:0] block_x,
    input  wire [3:0] block_y,
    input  wire [2:0] block_dir,
    input  wire [3:0] read_block_x,
    input  wire [3:0] read_block_y,
    output wire [2:0] read_block_dir,
    output reg        frame_ready
);

reg [2:0] dir_mem [0:255];
wire [7:0] write_addr = {block_y, block_x};
wire [7:0] read_addr = {read_block_y, read_block_x};
integer i;

assign read_block_dir = dir_mem[read_addr];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_ready <= 1'b0;
        for (i = 0; i < 256; i = i + 1) begin
            dir_mem[i] <= 3'd0;
        end
    end else if (block_valid) begin
        dir_mem[write_addr] <= block_dir;
        if (block_x == 4'd15 && block_y == 4'd15) begin
            frame_ready <= 1'b1;
        end
    end
end

endmodule

`timescale 1ns / 1ps

module direction_field_buffer(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       block_valid,
    input  wire       block_active,
    input  wire [4:0] block_x,
    input  wire [4:0] block_y,
    input  wire [2:0] block_dir,
    input  wire [4:0] read_block_x,
    input  wire [4:0] read_block_y,
    output wire [2:0] read_block_dir,
    output wire       read_block_active,
    output reg        frame_ready
);

reg [2:0] dir_mem [0:1023];
reg       active_mem [0:1023];
wire [9:0] write_addr = {block_y, block_x};
wire [9:0] read_addr = {read_block_y, read_block_x};
integer i;

assign read_block_dir = dir_mem[read_addr];
assign read_block_active = active_mem[read_addr];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_ready <= 1'b0;
        for (i = 0; i < 1024; i = i + 1) begin
            dir_mem[i] <= 3'd0;
            active_mem[i] <= 1'b0;
        end
    end else if (block_valid) begin
        dir_mem[write_addr] <= block_dir;
        active_mem[write_addr] <= block_active;
        if (block_x == 5'd31 && block_y == 5'd31) begin
            frame_ready <= 1'b1;
        end
    end
end

endmodule

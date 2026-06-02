`timescale 1ns/1ps

module tb_fpga_orientation_top;
    reg clk;
    reg rst_n;
    wire block_valid;
    wire [3:0] block_x;
    wire [3:0] block_y;
    wire [2:0] block_dir;
    wire frame_done;

    integer block_count;
    integer error_count;
    integer fd;

    fpga_orientation_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .block_valid(block_valid),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir),
        .frame_done(frame_done)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        block_count = 0;
        error_count = 0;
        fd = $fopen("dir_map.txt", "w");
        repeat (8) @(posedge clk);
        rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (rst_n && block_valid) begin
            block_count = block_count + 1;
            $fwrite(fd, "%0d %0d %0d\n", block_x, block_y, block_dir);
            if (block_dir !== 3'd4) begin
                $display("DIRECTION_MISMATCH block_x=%0d block_y=%0d dir=%0d", block_x, block_y, block_dir);
                error_count = error_count + 1;
            end
        end

        if (rst_n && frame_done) begin
            $fclose(fd);
            if (block_count != 256) begin
                $display("BLOCK_COUNT_MISMATCH count=%0d expected=256", block_count);
                $finish(1);
            end
            if (error_count != 0) begin
                $display("PHASE1_TEST_FAIL errors=%0d", error_count);
                $finish(1);
            end
            $display("PHASE1_TEST_PASS blocks=%0d", block_count);
            $finish;
        end
    end

    initial begin
        #2000000;
        $display("PHASE1_TEST_TIMEOUT blocks=%0d errors=%0d", block_count, error_count);
        $finish(1);
    end
endmodule

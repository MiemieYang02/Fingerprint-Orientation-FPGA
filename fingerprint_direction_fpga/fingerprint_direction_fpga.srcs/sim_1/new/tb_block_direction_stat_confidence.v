`timescale 1ns/1ps

module tb_block_direction_stat_confidence;
    reg clk;
    reg rst_n;
    reg in_valid;
    reg vote_valid;
    reg [7:0] in_x;
    reg [7:0] in_y;
    reg [2:0] dir_bin;

    wire block_valid;
    wire block_active;
    wire [3:0] block_x;
    wire [3:0] block_y;
    wire [2:0] block_dir;

    integer seen_count;
    reg last_active;
    reg [2:0] last_dir;
    integer x;
    integer y;

    block_direction_stat #(
        .MIN_BLOCK_VOTES(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .vote_valid(vote_valid),
        .in_x(in_x),
        .in_y(in_y),
        .dir_bin(dir_bin),
        .block_valid(block_valid),
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .block_dir(block_dir)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && block_valid) begin
            seen_count = seen_count + 1;
            last_active = block_active;
            last_dir = block_dir;
        end
    end

    task send_pixel;
        input [7:0] px;
        input [7:0] py;
        input [2:0] pdir;
        input       pvote;
        begin
            in_valid = 1'b1;
            vote_valid = pvote;
            in_x = px;
            in_y = py;
            dir_bin = pdir;
            @(posedge clk);
            #1;
        end
    endtask

    task wait_seen;
        input integer expected_count;
        integer guard;
        begin
            guard = 0;
            while (seen_count < expected_count && guard < 20) begin
                @(posedge clk);
                #1;
                guard = guard + 1;
            end
            if (seen_count != expected_count) begin
                $display("CONFIDENCE_TIMEOUT seen=%0d expected=%0d", seen_count, expected_count);
                $finish(1);
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        in_valid = 1'b0;
        vote_valid = 1'b0;
        in_x = 8'd0;
        in_y = 8'd0;
        dir_bin = 3'd0;
        seen_count = 0;
        last_active = 1'b0;
        last_dir = 3'd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        for (y = 0; y < 16; y = y + 1) begin
            for (x = 0; x < 16; x = x + 1) begin
                send_pixel(x[7:0], y[7:0], 3'd5, 1'b0);
            end
        end
        in_valid = 1'b0;
        vote_valid = 1'b0;
        wait_seen(1);
        if (last_active !== 1'b0) begin
            $display("CONFIDENCE_LOW_GRADIENT_ACTIVE dir=%0d", last_dir);
            $finish(1);
        end

        for (y = 0; y < 16; y = y + 1) begin
            for (x = 16; x < 32; x = x + 1) begin
                send_pixel(x[7:0], y[7:0], 3'd3, (x < 20 && y == 0));
            end
        end
        in_valid = 1'b0;
        vote_valid = 1'b0;
        wait_seen(2);
        if (last_active !== 1'b1 || last_dir !== 3'd3) begin
            $display("CONFIDENCE_VALID_BLOCK_FAIL active=%0d dir=%0d", last_active, last_dir);
            $finish(1);
        end

        $display("BLOCK_CONFIDENCE_TEST_PASS");
        $finish;
    end
endmodule

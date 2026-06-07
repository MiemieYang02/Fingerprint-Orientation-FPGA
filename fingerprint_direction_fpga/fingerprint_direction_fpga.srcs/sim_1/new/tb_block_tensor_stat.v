`timescale 1ns/1ps

module tb_block_tensor_stat;
    reg clk;
    reg rst_n;
    reg in_valid;
    reg vote_valid;
    reg [7:0] in_x;
    reg [7:0] in_y;
    reg signed [11:0] gx;
    reg signed [11:0] gy;

    wire block_valid;
    wire block_active;
    wire [4:0] block_x;
    wire [4:0] block_y;
    wire signed [31:0] tensor_x;
    wire signed [31:0] tensor_y;

    integer seen_count;
    reg last_active;
    reg [4:0] last_x;
    reg [4:0] last_y;
    reg signed [31:0] last_tensor_x;
    reg signed [31:0] last_tensor_y;
    integer x;
    integer y;

    block_tensor_stat #(
        .MIN_BLOCK_VOTES(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .vote_valid(vote_valid),
        .in_x(in_x),
        .in_y(in_y),
        .gx(gx),
        .gy(gy),
        .block_valid(block_valid),
        .block_active(block_active),
        .block_x(block_x),
        .block_y(block_y),
        .tensor_x(tensor_x),
        .tensor_y(tensor_y)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n && block_valid) begin
            seen_count = seen_count + 1;
            last_active = block_active;
            last_x = block_x;
            last_y = block_y;
            last_tensor_x = tensor_x;
            last_tensor_y = tensor_y;
        end
    end

    task send_gradient;
        input [7:0] px;
        input [7:0] py;
        input signed [11:0] pgx;
        input signed [11:0] pgy;
        input pvote;
        begin
            in_valid = 1'b1;
            vote_valid = pvote;
            in_x = px;
            in_y = py;
            gx = pgx;
            gy = pgy;
            @(posedge clk);
            #1;
        end
    endtask

    task wait_seen;
        input integer expected_count;
        integer guard;
        begin
            guard = 0;
            while (seen_count < expected_count && guard < 30) begin
                @(posedge clk);
                #1;
                guard = guard + 1;
            end
            if (seen_count != expected_count) begin
                $display("TENSOR_STAT_TIMEOUT seen=%0d expected=%0d", seen_count, expected_count);
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
        gx = 12'sd0;
        gy = 12'sd0;
        seen_count = 0;
        last_active = 1'b0;
        last_x = 5'd0;
        last_y = 5'd0;
        last_tensor_x = 32'sd0;
        last_tensor_y = 32'sd0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        for (y = 0; y < 8; y = y + 1) begin
            for (x = 0; x < 8; x = x + 1) begin
                send_gradient(x[7:0], y[7:0], 12'sd10, 12'sd0, 1'b1);
            end
        end
        in_valid = 1'b0;
        vote_valid = 1'b0;
        wait_seen(1);
        // Horizontal Sobel normal must be rotated before accumulation, so the
        // block tensor describes a vertical fingerprint ridge.
        if (last_x !== 5'd0 || last_y !== 5'd0 || last_active !== 1'b1 ||
            last_tensor_x !== -32'sd6400 || last_tensor_y !== 32'sd0) begin
            $display("TENSOR_STAT_PRE_ROTATE_HORIZONTAL_NORMAL_FAIL x=%0d y=%0d active=%0d tx=%0d ty=%0d",
                     last_x, last_y, last_active, last_tensor_x, last_tensor_y);
            $finish(1);
        end

        for (y = 0; y < 8; y = y + 1) begin
            for (x = 8; x < 16; x = x + 1) begin
                send_gradient(x[7:0], y[7:0], 12'sd0, 12'sd10, (x < 10 && y == 0));
            end
        end
        in_valid = 1'b0;
        vote_valid = 1'b0;
        wait_seen(2);
        if (last_x !== 5'd1 || last_y !== 5'd0 || last_active !== 1'b0 ||
            last_tensor_x !== 32'sd200 || last_tensor_y !== 32'sd0) begin
            $display("TENSOR_STAT_CONFIDENCE_FAIL x=%0d y=%0d active=%0d tx=%0d ty=%0d",
                     last_x, last_y, last_active, last_tensor_x, last_tensor_y);
            $finish(1);
        end

        for (y = 0; y < 8; y = y + 1) begin
            for (x = 16; x < 24; x = x + 1) begin
                send_gradient(x[7:0], y[7:0], 12'sd10, 12'sd10, 1'b1);
            end
        end
        in_valid = 1'b0;
        vote_valid = 1'b0;
        wait_seen(3);
        if (last_x !== 5'd2 || last_y !== 5'd0 || last_active !== 1'b1 ||
            last_tensor_x !== 32'sd0 || last_tensor_y !== -32'sd12800) begin
            $display("TENSOR_STAT_PRE_ROTATE_OBLIQUE_NORMAL_FAIL x=%0d y=%0d active=%0d tx=%0d ty=%0d",
                     last_x, last_y, last_active, last_tensor_x, last_tensor_y);
            $finish(1);
        end

        $display("BLOCK_TENSOR_STAT_TEST_PASS");
        $finish;
    end
endmodule

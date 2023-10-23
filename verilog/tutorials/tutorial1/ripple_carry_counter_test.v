module stimulus;
    
    reg clk;
    reg reset;
    wire[3:0] q;

    ripple_carry_counter r1(q, clk, reset);

    initial begin
        clk = 1'b0;
    end

    always begin
        #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #15 reset = 1'b0;
        #180 reset = 1'b1;
        #10 reset = 1'b0;
        #20 $finish;
    end

    initial begin
        $monitor($time, " Output q= %d", q);
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars;
    end

endmodule
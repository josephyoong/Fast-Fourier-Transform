/*

compile 
iverilog -g2012 -o sim.out src/butterfly.sv sim/tb_butterfly.sv src/complex_multiplier.sv

run
vvp sim.out

view waveform
gtkwave tb_butterfly.vcd

*/

module tb_butterfly ();

logic clk;
logic rst;
logic en;

// inputs
logic signed [15:0] even [0:1]; // {real, imag}
logic signed [15:0] odd [0:1]; // {real, imag}
logic signed [15:0] twi [0:1]; // {real, imag}

// outputs
wire signed [15:0] top [0:1]; // {real, imag}
wire signed [15:0] btm [0:1]; // {real, imag}

always #5 clk = ~clk;

butterfly #(.I(1), .F(15)) dut (
    .i_clk(clk),
    .i_rst(rst),
    .i_en(en),
    .i_even(even),
    .i_odd(odd),
    .i_twi(twi),
    .o_top(top),
    .o_btm(btm)
);

real theta;

initial begin

    $dumpfile("tb_butterfly.vcd");
    $dumpvars(0, tb_butterfly);
    $dumpvars(0, dut);

    $dumpvars(0, tb_butterfly.even[0]);
    $dumpvars(0, tb_butterfly.even[1]);
    $dumpvars(0, tb_butterfly.odd[0]);
    $dumpvars(0, tb_butterfly.odd[1]);
    $dumpvars(0, tb_butterfly.twi[0]);
    $dumpvars(0, tb_butterfly.twi[1]);
    $dumpvars(0, dut.o_top[0]);
    $dumpvars(0, dut.o_top[1]);
    $dumpvars(0, dut.o_btm[0]);
    $dumpvars(0, dut.o_btm[1]);

    clk = 0;
    rst = 1;
    en = 0;
    even[0] = real_to_q1p15(0.5);
    even[1] = real_to_q1p15(0.0);
    odd[0] = real_to_q1p15(0.123872);
    odd[1] = real_to_q1p15(0.0);
    twi[0] = real_to_q1p15(0.0);
    twi[1] = real_to_q1p15(0.0);

    #20;
    en = 1;
    rst = 0;

    $display("even real: %0d ", q1p15_to_real(even[0]));
    $display("odd real: %0d ", q1p15_to_real(odd[0]));

    #50;
    $finish;

end

function real q1p15_to_real(input signed [15:0] q1p15);
    q1p15_to_real = q1p15 / 32768.0;
endfunction

function logic signed [15:0] real_to_q1p15(input real num);
    real scaled;
    begin
        if (num >= 0.999969482421875)      // (32767 / 32768) is Q1.15 0.111111111111111
            real_to_q1p15 = 16'sh7FFF;
        else if (num <= -1.0)
            real_to_q1p15 = 16'sh8000;
        else begin
            scaled = num * 32768.0;

            if (scaled >= 0) // positive
                real_to_q1p15 = $rtoi(scaled + 0.5);
            else // negative
                real_to_q1p15 = $rtoi(scaled - 0.5);
        end
    end
endfunction

// // ============================================================================
// // ASSERTION: Reset clears outputs
// // ============================================================================
// logic prev_reset = 0;

// always @(posedge clk) begin
//     if (prev_reset) begin  // If reset was high last cycle
//         assert (top[0] == 0 && top[1] == 0 && btm[0] == 0 && btm[1] == 0)
//             else $error("Reset did not clear outputs. Got: %0d+%0di",
//                        $signed(product_re), $signed(product_im));
//     end
//     prev_reset <= reset;
// end

// // ============================================================================
// // ASSERTION: When enable is low, outputs don't change
// // ============================================================================
// logic signed [15:0] prev_product_re = 0;
// logic signed [15:0] prev_product_im = 0;
// logic prev_enable = 0;

// always @(posedge clk) begin
//     if (!reset) begin
//         if (!prev_enable) begin
//             assert (product_re == prev_product_re && product_im == prev_product_im)
//                 else $error("Outputs changed while enable was low. Was %0d+%0di, now %0d+%0di",
//                            $signed(prev_product_re), $signed(prev_product_im),
//                            $signed(product_re), $signed(product_im));
//         end
//         prev_product_re <= product_re;
//         prev_product_im <= product_im;
//         prev_enable <= enable;
//     end else begin
//         prev_product_re <= product_re;
//         prev_product_im <= product_im;
//         prev_enable <= enable;
//     end
// end

endmodule
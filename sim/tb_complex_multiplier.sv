/*

compile 
iverilog -g2012 -o sim.out src/complex_multiplier.sv sim/tb_complex_multiplier.sv

run
vvp sim.out

view waveform
gtkwave tb_complex_multiplier.vcd

*/

module tb_complex_multiplier ();

localparam I = 8;
localparam F = 8;

// control inputs
logic clk, reset, enable;
// data inputs
logic signed [15:0] data1_re, data1_im;
logic signed [15:0] data2_re, data2_im;
// data outputs
wire signed [15:0] product_re;
wire signed [15:0] product_im;

wire signed [15:0] data1[0:1];
wire signed [15:0] data2[0:1];
assign data1[0] = data1_re;
assign data1[1] = data1_im;
assign data2[0] = data2_re;
assign data2[1] = data2_im;

wire signed [15:0] product[0:1];
assign product_re = product[0];
assign product_im = product[1];

complex_multiplier_16 #(.I(I), .F(F)) dut (
    .i_clk(clk),
    .i_rst(reset),
    .i_en(enable),
    .i_data1(data1),
    .i_data2(data2),
    .o_product(product)
);

always #5 clk = ~clk;

integer angle_index;
real theta, cos_val, sin_val;

initial begin
    $dumpfile("tb_complex_multiplier.vcd");
    $dumpvars(0, tb_complex_multiplier);

    clk = 0;
    reset = 1;
    enable = 0;

    data1_re = 0;
    data1_im = 0;
    data2_re = 0;
    data2_im = 0;
    
    #20;
    reset = 0;
    enable = 1;

    // ========== RANDOM TESTS ==========
    $display("\n=== Random Tests ===\n");
    
    repeat(100) begin
        @(posedge clk);
        
        angle_index = $random % 256; // 0 to 255
        theta = (angle_index * 3.14159265 * 2.0) / 256.0; // Convert to radians
        
        cos_val = $cos(theta);
        sin_val = $sin(theta);
        
        // Convert to Q8.8 (multiply by 256, since 2^8 = 256)
        data1_re = $rtoi(cos_val * 256.0);
        data1_im = $rtoi(sin_val * 256.0);
        
        data2_re = ($random % 32768) - 16384;
        data2_im = ($random % 32768) - 16384;

        repeat(3) @(posedge clk);
    end

    $finish;
end

// ============================================================================
// ASSERTION: Reset clears outputs
// ============================================================================
logic prev_reset = 0;

always @(posedge clk) begin
    if (prev_reset) begin  // If reset was high last cycle
        assert (product_re == 0 && product_im == 0)
            else $error("Reset did not clear outputs. Got: %0d+%0di",
                       $signed(product_re), $signed(product_im));
    end
    prev_reset <= reset;
end

// ============================================================================
// ASSERTION: When enable is low, outputs don't change
// ============================================================================
logic signed [15:0] prev_product_re = 0;
logic signed [15:0] prev_product_im = 0;
logic prev_enable = 0;

always @(posedge clk) begin
    if (!reset) begin
        if (!prev_enable) begin
            assert (product_re == prev_product_re && product_im == prev_product_im)
                else $error("Outputs changed while enable was low. Was %0d+%0di, now %0d+%0di",
                           $signed(prev_product_re), $signed(prev_product_im),
                           $signed(product_re), $signed(product_im));
        end
        prev_product_re <= product_re;
        prev_product_im <= product_im;
        prev_enable <= enable;
    end else begin
        prev_product_re <= product_re;
        prev_product_im <= product_im;
        prev_enable <= enable;
    end
end

// ============================================================================
// ASSERTION: Check maths
// ============================================================================
// Delay inputs by 3 cycles to match multiplier latency
logic signed [15:0] data1_re_d1 = 0, data1_im_d1 = 0;
logic signed [15:0] data2_re_d1 = 0, data2_im_d1 = 0;
logic signed [15:0] data1_re_d2 = 0, data1_im_d2 = 0;
logic signed [15:0] data2_re_d2 = 0, data2_im_d2 = 0;
logic signed [15:0] data1_re_d3 = 0, data1_im_d3 = 0;
logic signed [15:0] data2_re_d3 = 0, data2_im_d3 = 0;
logic enable_d1 = 0, enable_d2 = 0, enable_d3 = 0;

always @(posedge clk) begin
    if (reset) begin
        data1_re_d1 <= 0; data1_im_d1 <= 0;
        data2_re_d1 <= 0; data2_im_d1 <= 0;
        data1_re_d2 <= 0; data1_im_d2 <= 0;
        data2_re_d2 <= 0; data2_im_d2 <= 0;
        data1_re_d3 <= 0; data1_im_d3 <= 0;
        data2_re_d3 <= 0; data2_im_d3 <= 0;
        enable_d1 <= 0; enable_d2 <= 0; enable_d3 = 0;
    end else begin
        data1_re_d1 <= data1_re;
        data1_im_d1 <= data1_im;
        data2_re_d1 <= data2_re;
        data2_im_d1 <= data2_im;
        enable_d1 <= enable;
        
        data1_re_d2 <= data1_re_d1;
        data1_im_d2 <= data1_im_d1;
        data2_re_d2 <= data2_re_d1;
        data2_im_d2 <= data2_im_d1;
        enable_d2 <= enable_d1;

        data1_re_d3 <= data1_re_d2;
        data1_im_d3 <= data1_im_d2;
        data2_re_d3 <= data2_re_d2;
        data2_im_d3 <= data2_im_d2;
        enable_d3 <= enable_d2;
    end
end

// Helper functions to calculate expected output
function signed [15:0] calc_expected_re(input signed [15:0] a_re, a_im, b_re, b_im);
    logic signed [31:0] prod_ac, prod_bd;
    logic signed [31:0] prod_ac_rnd, prod_bd_rnd;
    logic signed [15:0] prod_ac_trnc, prod_bd_trnc;
    
    prod_ac = a_re * b_re;
    prod_bd = a_im * b_im;
    prod_ac_rnd = prod_ac + (1 << (F-1));
    prod_bd_rnd = prod_bd + (1 << (F-1));
    prod_ac_trnc = prod_ac_rnd[31-I:F];
    prod_bd_trnc = prod_bd_rnd[31-I:F];
    
    return prod_ac_trnc - prod_bd_trnc;
endfunction

function signed [15:0] calc_expected_im(input signed [15:0] a_re, a_im, b_re, b_im);
    logic signed [31:0] prod_ad, prod_bc;
    logic signed [31:0] prod_ad_rnd, prod_bc_rnd;
    logic signed [15:0] prod_ad_trnc, prod_bc_trnc;
    
    prod_ad = a_re * b_im;
    prod_bc = a_im * b_re;
    prod_ad_rnd = prod_ad + (1 << (F-1));
    prod_bc_rnd = prod_bc + (1 << (F-1));
    prod_ad_trnc = prod_ad_rnd[31-I:F];
    prod_bc_trnc = prod_bc_rnd[31-I:F];
    
    return prod_ad_trnc + prod_bc_trnc;
endfunction

logic signed [15:0] expected_re;
logic signed [15:0] expected_im;

always @(posedge clk) begin
    if (!reset && enable_d3) begin
        expected_re = calc_expected_re(
            data1_re_d3, data1_im_d3, data2_re_d3, data2_im_d3);
        expected_im = calc_expected_im(
            data1_re_d3, data1_im_d3, data2_re_d3, data2_im_d3);
        
        assert (product_re == expected_re && product_im == expected_im)
            else $error("Math error. (%0d+%0di)*(%0d+%0di) Expected: %0d+%0di, Got: %0d+%0di",
                       $signed(data1_re_d3), $signed(data1_im_d3), 
                       $signed(data2_re_d3), $signed(data2_im_d3),
                       $signed(expected_re), $signed(expected_im), 
                       $signed(product_re), $signed(product_im));
    end
end

endmodule
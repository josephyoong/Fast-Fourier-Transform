/*

complex_multiplier.sv

(a + bi) * (c + di) = (ab - bd) + (ad + bc)i

one complex number (a + bi) is a twiddle, so mag < 1
bit growth = 0

lattice iCE40UP5 will use sysDSP
sysDSP has 16-bit x 16-bit multiplier and 16-bit adder

if input data is stable for clk edge 1, 
    output data is ready after clk edge 3

*/

module complex_multiplier_16 #(
    parameter I = 1,
    parameter F = 15
) (
    // control inputs
    input i_clk,
    input i_rst,
    input i_en,
    // data inputs
    input signed [0:1] [15:0] i_i_data1,
    input signed [0:1] [15:0] i_i_data2,
    // data output
    output logic signed [0:1] [15:0] o_o_product
);

// yosys packed
logic signed [15:0] i_data1 [0:1];
logic signed [15:0] i_data2 [0:1];
always_comb begin
    for (int j=0; j<2; j++) begin
        i_data1[j] = i_i_data1[j];
        i_data2[j] = i_i_data2[j];
    end
end

logic signed [15:0] o_product [0:1];
assign o_o_product[0] = o_product[0];
assign o_o_product[1] = o_product[1];

logic signed [31:0] prod1;
logic signed [31:0] prod2;
logic signed [31:0] prod3;
logic signed [31:0] prod4;

logic signed [31:0] prod1_rnd = 0;
logic signed [31:0] prod2_rnd = 0;
logic signed [31:0] prod3_rnd = 0;
logic signed [31:0] prod4_rnd = 0;

wire signed [15:0] prod1_trnc = prod1_rnd[31-I:F];
wire signed [15:0] prod2_trnc = prod2_rnd[31-I:F];
wire signed [15:0] prod3_trnc = prod3_rnd[31-I:F];
wire signed [15:0] prod4_trnc = prod4_rnd[31-I:F];

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        prod1 <= 0;
        prod2 <= 0;
        prod3 <= 0;
        prod4 <= 0;

        prod1_rnd <= 0;
        prod2_rnd <= 0;
        prod3_rnd <= 0;
        prod4_rnd <= 0;

        o_product[0] <= 0;
        o_product[1] <= 0;
    end
    else if (i_en) begin
        // 1st clk edge
        prod1 <= i_data1[0] * i_data2[0]; // ac     !!! TIMING ERROR
        prod2 <= i_data1[0] * i_data2[1]; // ad     !!! MAKE IT USE DSP BLOCK
        prod3 <= i_data1[1] * i_data2[0]; // bc     !!! INSTEAD OF LUTS
        prod4 <= i_data1[1] * i_data2[1]; // bd

        // 2nd clk edge - rounding
        prod1_rnd <= (prod1 + (1<<(F-1)));
        prod2_rnd <= (prod2 + (1<<(F-1)));
        prod3_rnd <= (prod3 + (1<<(F-1)));
        prod4_rnd <= (prod4 + (1<<(F-1)));

        // 3rd clk edge
        o_product[0] <= prod1_trnc - prod4_trnc; // ac - bd
        o_product[1] <= prod2_trnc + prod3_trnc; // ad + bc
    end
end

endmodule

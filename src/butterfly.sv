/*

butterfly.sv

   .==-.                   .-==.
   \()8`-._  `.   .'  _.-'8()/
   (88"   ::.  \./  .::   "88)
    \_.'`-::::.(#).::::-'`._/
      `._... .q(_)p. ..._.'
        ""-..-'|=|`-..-""
              ,|=|.
             ((/^\))

o_top = i_even + (i_twi * i_odd)
o_btm = i_even - (i_twi * i_odd)

1 overflow comes from the addition
bit growth = 1

if input data is stable for clk edge 1, 
    output data is ready after clk edge 4

*/

module butterfly #(
    parameter 
    I = 1,
    F = 15
) (
    input i_clk,
    input i_rst,
    input i_en,

    input signed [0:1] [15:0] i_i_even, // {real, imag}
    input signed [0:1] [15:0] i_i_odd, // {real, imag}
    input signed [0:1] [15:0] i_i_twi, // {real, imag}

    output logic signed [0:1] [15:0] o_o_top, // {real, imag}
    output logic signed [0:1] [15:0] o_o_btm // {real, imag}
);

// yosys packed
logic signed [15:0] i_even [0:1];
logic signed [15:0] i_odd [0:1];
logic signed [15:0] i_twi [0:1];
always_comb begin
    for (int j=0; j<2; j++) begin
        i_even[j] = i_i_even[j];
        i_odd[j] = i_i_odd[j];
        i_twi[j] = i_i_twi[j];
    end
end

logic signed [15:0] o_top [0:1];
logic signed [15:0] o_btm [0:1];
assign o_o_top = {o_top[0], o_top[1]};
assign o_o_btm = {o_btm[0], o_btm[1]};

wire signed [15:0] twi_odd [0:1];
logic signed [15:0] shift_even_re [0:2];
logic signed [15:0] shift_even_im [0:2];

wire signed [0:1] [15:0] twi_packed_net;
// 1st, 2nd, 3rd clk edges
// i_odd * i_twi
complex_multiplier_16 #(.I(I), .F(F)) twiddler (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_i_data1(i_i_odd),
    .i_i_data2(i_i_twi),
    .o_o_product(twi_packed_net)
);

assign twi_odd[0] = twi_packed_net[0];
assign twi_odd[1] = twi_packed_net[1];

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        for (int i=0; i<3; i++) begin
            shift_even_re[i] <= 0;
            shift_even_im[i] <= 0;
        end

        o_top[0] <= 0;
        o_top[1] <= 0;
        o_btm[0] <= 0;
        o_btm[1] <= 0;
    end
    else if (i_en) begin
        // 1st, 2nd, 3rd clk edges
        shift_even_re[0] <= i_even[0];
        shift_even_im[0] <= i_even[1];
        for (int i=1; i<3; i++) begin
            shift_even_re[i] <= shift_even_re[i-1];
            shift_even_im[i] <= shift_even_im[i-1];
        end

        // 4th i_clk edge
        o_top[0] <= (shift_even_re[2] + twi_odd[0] + 16'sd1) >>> 1;
        o_btm[0] <= (shift_even_re[2] - twi_odd[0] + 16'sd1) >>> 1;
        o_top[1] <= (shift_even_im[2] + twi_odd[1] + 16'sd1) >>> 1;
        o_btm[1] <= (shift_even_im[2] - twi_odd[1] + 16'sd1) >>> 1;
        // o_top[0] <= shift_even_re[2] + twi_odd[0];
        // o_btm[0] <= shift_even_re[2] - twi_odd[0];
        // o_top[1] <= shift_even_im[2] + twi_odd[1];
        // o_btm[1] <= shift_even_im[2] - twi_odd[1];
    end
end

endmodule
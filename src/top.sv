/*

Programming iCE40

find folder
cd C:\Users\josep\Documents\FPGA\spectrum2

synthesise using yosys
.sv -> .json
yosys -p "read_verilog -sv src\address_generator.sv src\butterfly.sv src\complex_multiplier.sv src\dp_bram_512x16.sv src\fft_control.sv src\grapher.sv src\hvsync_gen.sv src\memory.sv src\rom_512x16.sv src\spectrum_analyser_control.sv src\spectrum_analyser.sv src\top.sv ; synth_ice40 -dsp -top top -json top.json"

place and route using nextpnr
.json -> .asc
nextpnr-ice40 --up5k --package sg48 --json top.json --pcf constraints\io.pcf --asc top.asc --sdc constraints\constraints.sdc  --verbose

generate bitstream using icepack
.asc -> .bin
icepack top.asc top.bin

drag and drop bitstream into iCELink drive

*/

module top (
    // input clk, // for simulation

    output o_led,
    output o_hs,
    output o_vs,
    output o_r0,
    output o_r1,
    output o_r2,
    output o_r3,
    output o_g0,
    output o_g1,
    output o_g2,
    output o_g3,
    output o_b0,
    output o_b1,
    output o_b2,
    output o_b3
);

/*

Clock

Outputs: 
    clk_24MHz      
    clk_25MHz1538
    clk

*/

// clk generation
wire clk_24MHz;
SB_HFOSC #(
    .CLKHF_DIV("0b01") // 24 MHz by division
) OSCInst0 ( 
    .CLKHFEN(1'b1), 
    .CLKHFPU(1'b1), 
    .CLKHF(clk_24MHz) 
) 
/* synthesis ROUTE_THROUGH_FABRIC = 0 */; // (0) to use the clock network, (1) for fabric

// PLL
wire clk_25MHz1538;
wire pll_locked;
SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd12),   // divide by 13
    .DIVF(7'd108),  // multiply by 109
    .DIVQ(3'd3),    // divide by 2^3 = 8
    .FILTER_RANGE(3'd1)
) pll (
    .REFERENCECLK(clk_24MHz),   // input 24 MHz
    .PLLOUTCORE(clk_25MHz1538), // output 25.1538 MHz
    .LOCK(pll_locked),
    .RESETB(1'b1),
    .BYPASS(1'b0)
);
wire clk;
assign clk = clk_25MHz1538;

/*

Time since power-on

*/
logic [7:0] counter = '0;
always_ff @(posedge clk) begin
    if (counter == 8'd100) begin
        counter <= counter;
    end
    else begin
        counter <= counter + 1;
    end
end

/*

Reset

*/
wire rst;
assign rst = (counter < 8'd20);

/*

Enable

*/
wire en;
assign en = (counter > 8'd40);

/*

Start FFT

*/
wire start_fft;
assign start_fft = ((counter > 8'd60) && (counter < 8'd67));
// assign start_fft = counter[7]; // dont do fft

/*

Start graph

*/
wire start_graph;
assign start_graph = (counter > 8'd80);

/*

main

*/
wire g0;
spectrum_analyser top_spectrum_analyser (
    .i_clk(clk),
    .i_rst(rst),
    .i_en(en),
    .i_start_fft(start_fft),
    .i_start_graph(start_graph),

    .o_led       (o_led),
    .o_hs        (o_hs),
    .o_vs        (o_vs),
    .o_g0        (g0)
);

logic zero = 0;

assign o_r0 = zero;
assign o_r1 = zero;
assign o_r2 = zero;
assign o_r3 = zero;

assign o_b0 = zero;
assign o_b1 = zero;
assign o_b2 = zero;
assign o_b3 = zero;

assign o_g0 = g0;
assign o_g1 = g0;
assign o_g2 = g0;
assign o_g3 = g0;

endmodule
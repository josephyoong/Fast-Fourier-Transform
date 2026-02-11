/*

compile 
iverilog -g2012 -DDEBUG -o sim.out sim/tb_main.sv src\address_generator.sv src\butterfly.sv src\complex_multiplier.sv src\dp_bram_512x16.sv src\fft_control.sv src\grapher.sv src\hvsync_gen.sv src\memory.sv src\rom_512x16.sv src\spectrum_analyser_control.sv src\spectrum_analyser.sv src\top.sv

run
vvp sim.out

view waveform
gtkwave tb_main.vcd

*/

module tb_main ();
logic clk;

wire o_led;
wire o_hs;
wire o_vs;
wire o_r0;
wire o_r1;
wire o_r2;
wire o_r3;
wire o_g0;
wire o_g1;
wire o_g2;
wire o_g3;
wire o_b0;
wire o_b1;
wire o_b2;
wire o_b3;

always #5 clk = ~clk;

top dut (
    .clk(clk),
    .o_led(o_led),
    .o_hs(o_hs),
    .o_vs(o_vs),
    .o_r0(o_r0),
    .o_r1(o_r1),
    .o_r2(o_r2),
    .o_r3(o_r),
    .o_g0(o_g0),
    .o_g1(o_g1),
    .o_g2(o_g2),
    .o_g3(o_g3),
    .o_b0(o_b0),
    .o_b1(o_b1),
    .o_b2(o_b2),
    .o_b3(o_b3)
);

integer fd;

initial begin

    $dumpfile("tb_main.vcd");
    $dumpvars(0, tb_main);

    clk = 0;

    #1000000

    // mem1 a real
    fd = $fopen("final_mem1a_real_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
    real val;
    val = $itor($signed(tb_main.dut.top_spectrum_analyser.top_memory.ram1_real_even.r_mem[i]))
          / 32768.0;
    $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    
    $finish;
    
end

endmodule
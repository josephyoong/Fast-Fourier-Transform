/*

compile 
iverilog -g2012 -DDEBUG -o sim.out sim/tb_main.sv src/main.sv src/address_generator.sv src/butterfly.sv src/complex_multiplier.sv src/control.sv src/dp_bram_512x16.sv src/memory.sv src/rom_512x16.sv

run
vvp sim.out

view waveform
gtkwave tb_main.vcd

*/

module tb_main ();
logic clk;
logic rst;
logic en;
logic start;
wire active;

always #5 clk = ~clk;

main dut (
    .i_clk(clk),
    .i_rst(rst),
    .i_en(en),
    .i_start(start),
    .o_active(active)
);

integer fd;
integer log_fd;

initial begin

    log_fd = $fopen("butterfly_trace.txt", "w");
    $fdisplay(log_fd,
        " even odd twi top btm"
    );

    $dumpfile("tb_main.vcd");
    $dumpvars(0, tb_main);

    $dumpvars(0, dut.even[0]);
    $dumpvars(0, dut.even[1]);
    $dumpvars(0, dut.odd[0]);
    $dumpvars(0, dut.odd[1]);
    $dumpvars(0, dut.twi[0]);
    $dumpvars(0, dut.twi[1]);
    $dumpvars(0, dut.top[0]);
    $dumpvars(0, dut.top[1]);
    $dumpvars(0, dut.btm[0]);
    $dumpvars(0, dut.btm[1]);

    fd = $fopen("twiddle_real.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.twiddle_rom_real.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    fd = $fopen("twiddle_imag.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.twiddle_rom_imag.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);

    fd = $fopen("mem1a_real_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.ram1_real_even.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    fd = $fopen("mem1a_imag_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.ram1_imag_even.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    fd = $fopen("mem1b_real_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.ram1_real_odd.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    fd = $fopen("mem1b_imag_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
            real val;
            val = $itor($signed(tb_main.dut.top_memory.ram1_imag_odd.r_mem[i])) / 32768.0;
            $fdisplay(fd, "%f", val);
    end
    $fclose(fd);

    clk = 0;
    rst = 1;
    en = 0;
    start = 0;

    #80
    rst = 0;
    en = 1;
    start = 1;

    wait (active == 1);
    wait (active == 0);

    // mem1 a real
    fd = $fopen("final_mem1a_real_dump.txt", "w");
    for (int i = 0; i < 512; i++) begin
    real val;
    val = $itor($signed(tb_main.dut.top_memory.ram1_real_even.r_mem[i]))
          / 32768.0;
    $fdisplay(fd, "%f", val);
    end
    $fclose(fd);
    
    $finish;
    
end

always @(posedge clk) begin
    if (!rst && active) begin
        $fdisplay(
            log_fd,
            " %f %f %f %f %f ;",

            $itor(dut.top_control.control_address_generator.even_addr),

            $itor(dut.top_control.control_address_generator.odd_addr),

            $itor(dut.top_control.control_address_generator.twi_addr),

            $itor(dut.top_control.control_address_generator.top_addr),

            $itor(dut.top_control.control_address_generator.btm_addr)
        );
    end
end

final begin
    $fclose(log_fd);
end

endmodule
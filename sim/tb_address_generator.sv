/*

compile 
iverilog -g2012 -o sim.out src/address_generator.sv sim/tb_address_generator.sv

run
vvp sim.out

view waveform
gtkwave tb_address_generator.vcd

*/

module tb_address_generator ();
logic clk;
logic [3:0] stage;
logic [8:0] pair;
wire [8:0] rd_addr [0:4];
wire [0:4] rd_en;
wire [8:0] wr_addr [0:3];
wire [0:3] wr_en;

wire [8:0] rd_addr_mem1a;
wire [8:0] rd_addr_mem1b;
wire [8:0] rd_addr_mem2a;
wire [8:0] rd_addr_mem2b;

assign rd_addr_mem1a = rd_addr[1];
assign rd_addr_mem1b = rd_addr[2];
assign rd_addr_mem2a = rd_addr[3];
assign rd_addr_mem2b = rd_addr[4];

address_generator dut (
    .i_stage(stage),
    .i_pair(pair),
    .o_rd_addr(rd_addr),
    .o_rd_en(rd_en),
    .o_wr_addr(wr_addr),
    .o_wr_en(wr_en)
);

always #5 clk = ~clk;

initial begin

    $dumpfile("tb_address_generator.vcd");
    $dumpvars(0, tb_address_generator);

    clk = 0;
    stage = 4'd9;
    pair = 9'd1;

    #10 
    $finish;
end

endmodule
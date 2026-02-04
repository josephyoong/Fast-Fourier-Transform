/*

*/

module memory (
    input i_clk,

    input logic [4:0] i_rd_en,
    input logic [8:0] i_rd_addr [0:4], // [rom mem1a mem1b mem2a mem2b]
    input logic [3:0] i_wr_en,
    input logic [8:0] i_wr_addr [0:3], // [mem1a mem1b mem2a mem2b]
    input logic signed [15:0] i_wr_data [0:3] [0:1], // [real imag] 

    output logic signed [15:0] o_rd_data [0:4] [0:1]  // [real imag] 
);

/**********************************************************
 * rom 
 **********************************************************/
rom_512x16 #(.REAL(1)) twiddle_rom_real (
    .i_clk(i_clk),
    .i_rd_en(i_rd_en[0]),
    .i_rd_addr(i_rd_addr[0]),
    .o_rd_data(o_rd_data[0][0])
);

rom_512x16 #(.REAL(0)) twiddle_rom_imag (
    .i_clk(i_clk),
    .i_rd_en(i_rd_en[0]),
    .i_rd_addr(i_rd_addr[0]),
    .o_rd_data(o_rd_data[0][1])
);

/**********************************************************
 * ram1 even
 *********************************************************/
dp_bram_512x16 #(.TEST(1)) ram1_real_even (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[0]),
    .i_wr_addr(i_wr_addr[0]),
    .i_wr_data(i_wr_data[0][0]),
    .i_rd_en(i_rd_en[1]),
    .i_rd_addr(i_rd_addr[1]),
    .o_rd_data(o_rd_data[1][0])
);

dp_bram_512x16 ram1_imag_even (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[0]),
    .i_wr_addr(i_wr_addr[0]),
    .i_wr_data(i_wr_data[0][1]),
    .i_rd_en(i_rd_en[1]),
    .i_rd_addr(i_rd_addr[1]),
    .o_rd_data(o_rd_data[1][1])
);

/**********************************************************
 * ram1 odd
 *********************************************************/
dp_bram_512x16 #(.TEST(1)) ram1_real_odd (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[1]),
    .i_wr_addr(i_wr_addr[1]),
    .i_wr_data(i_wr_data[1][0]),
    .i_rd_en(i_rd_en[2]),
    .i_rd_addr(i_rd_addr[2]),
    .o_rd_data(o_rd_data[2][0])
);

dp_bram_512x16 ram1_imag_odd (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[1]),
    .i_wr_addr(i_wr_addr[1]),
    .i_wr_data(i_wr_data[1][1]),
    .i_rd_en(i_rd_en[2]),
    .i_rd_addr(i_rd_addr[2]),
    .o_rd_data(o_rd_data[2][1])
);

/**********************************************************
 * ram2 even
 *********************************************************/
dp_bram_512x16 ram2_real_even (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[2]),
    .i_wr_addr(i_wr_addr[2]),
    .i_wr_data(i_wr_data[2][0]),
    .i_rd_en(i_rd_en[3]),
    .i_rd_addr(i_rd_addr[3]),
    .o_rd_data(o_rd_data[3][0])
);

dp_bram_512x16 ram2_imag_even (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[2]),
    .i_wr_addr(i_wr_addr[2]),
    .i_wr_data(i_wr_data[2][1]),
    .i_rd_en(i_rd_en[3]),
    .i_rd_addr(i_rd_addr[3]),
    .o_rd_data(o_rd_data[3][1])
);

/**********************************************************
 * ram2 odd
 *********************************************************/
dp_bram_512x16 ram2_real_odd (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[3]),
    .i_wr_addr(i_wr_addr[3]),
    .i_wr_data(i_wr_data[3][0]),
    .i_rd_en(i_rd_en[4]),
    .i_rd_addr(i_rd_addr[4]),
    .o_rd_data(o_rd_data[4][0])
);

dp_bram_512x16 ram2_imag_odd (
    .i_clk(i_clk),
    .i_wr_en(i_wr_en[3]),
    .i_wr_addr(i_wr_addr[3]),
    .i_wr_data(i_wr_data[3][1]),
    .i_rd_en(i_rd_en[4]),
    .i_rd_addr(i_rd_addr[4]),
    .o_rd_data(o_rd_data[4][1])
);

endmodule

/*

*/

module spectrum_analyser (
    input i_clk,
    input i_rst,
    input i_en,
    input i_start_fft,
    input i_start_graph,

    output o_led,
    output o_hs,
    output o_vs,
    output o_g0
);

wire o_active;

logic signed [15:0] even [0:1];
logic signed [15:0] odd [0:1];
logic signed [15:0] twi [0:1];
logic signed [15:0] top [0:1];
logic signed [15:0] btm [0:1];

logic [4:0] fft_rd_en;
logic [3:0] wr_en; 
logic signed [15:0] rd_data [0:4][0:1];
logic signed [15:0] wr_data [0:3][0:1];
logic [8:0] wr_addr [0:3];
logic [8:0] fft_rd_addr [0:4];

logic final_pair;

wire read_mem1;
wire even_segment;
wire top_even;

// shift reg: read mem1
logic r_read_mem1;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        r_read_mem1 <= 0;
    end
    else if (i_en) begin
        r_read_mem1 <= read_mem1;
    end
end

// shift reg: even segment
logic r_even_segment;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        r_even_segment <= 0;
    end
    else if (i_en) begin
        r_even_segment <= even_segment;
    end
end

// MUX: rd data -> even, odd 
always_comb begin
    for (int j=0; j<2; j++) begin
        if (r_read_mem1 && r_even_segment) begin
            even[j] = rd_data[1][j];
            odd[j] = rd_data[2][j];
        end
        else if (r_read_mem1 && !r_even_segment) begin
            even[j] = rd_data[2][j];
            odd[j] = rd_data[1][j];
        end
        else if (!r_read_mem1 && r_even_segment) begin
            even[j] = rd_data[3][j];
            odd[j] = rd_data[4][j];
        end
        else begin
            even[j] = rd_data[4][j];
            odd[j] = rd_data[3][j];
        end
        twi[j] = rd_data[0][j];
    end
end

// shift reg: top even
logic [0:4] r_top_even;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        for (int i=0; i<5; i++) begin
            r_top_even[i] <= 0;
        end
    end
    else if (i_en) begin
        r_top_even[0] <= top_even;
        for (int i=1; i<5; i++) begin
            r_top_even[i] <= r_top_even[i-1];
        end
    end
end

wire r_top_even4;
assign r_top_even4 = r_top_even[4]; 

// MUX: top, btm -> write data
always_comb begin
    for (int j=0; j<2; j++) begin
        if (r_top_even4) begin
            wr_data[0][j] = top[j];
            wr_data[1][j] = btm[j];
            wr_data[2][j] = top[j];
            wr_data[3][j] = btm[j];
        end
        else begin
            wr_data[0][j] = btm[j];
            wr_data[1][j] = top[j];
            wr_data[2][j] = btm[j];
            wr_data[3][j] = top[j];
        end
    end
end

// shift reg: final pair
logic [0:5] r_final_pair;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        for (int i=0; i<5; i++) begin
            r_final_pair[i] <= 0;
        end
    end
    else if (i_en) begin
        r_final_pair[0] <= final_pair;
        for (int i=1; i<5; i++) begin
            r_final_pair[i] <= r_final_pair[i-1];
        end
    end
end

// shift reg: write address
logic [8:0] r_wr_addr [0:3] [0:4];
always_ff @(posedge i_clk) begin
    for (int j=0; j<4; j++) begin
        if (i_rst) begin
            for (int k=0; k<5; k++) begin
                r_wr_addr[j][k] <= '0;
            end
        end
        else if (i_en) begin
            r_wr_addr[j][0] <= wr_addr[j];
            for (int k=1; k<5; k++) begin
                r_wr_addr[j][k] <= r_wr_addr[j][k-1];
            end
        end
    end
end

logic [8:0] wr_addr4 [0:3];
always_comb begin
    for (int j=0; j<4; j++) begin
        wr_addr4[j] = r_wr_addr[j][4];
    end
end

// shift reg: write enable
logic [0:3] r_wr_en [0:4];
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        for (int j=0; j<5; j++) begin
            r_wr_en[j] <= '0;
        end
    end
    else if (i_en) begin
        r_wr_en[0] <= wr_en;

        for (int j=1; j<5; j++) begin
            r_wr_en[j] <= r_wr_en[j-1];
        end
    end
end

logic [3:0] wr_en4;
always_comb begin
    wr_en4 = r_wr_en[4];
end

wire fft_start; // control
wire fft_active;
wire graph_active;
wire fft_graph;

logic [6:0] r_fft_active;
logic active;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        for (int i=0; i<7; i++) begin
            r_fft_active[i] <= 0;
        end
    end
    else if (i_en) begin
            r_fft_active[0] <= active;
        for (int i=1; i<7; i++) begin
            r_fft_active[i] <= r_fft_active[i-1];
        end
    end
end

spectrum_analyser_control spectrum_analyser_spectrum_analyser_control (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_start_fft(i_start_fft),
    .i_start_graph(i_start_graph),
    .i_fft_active(active), // tells if fft is active o_active
    .o_fft_active(fft_active), // control signal for mux
    .o_graph_active(graph_active),
    .o_fft_start(fft_start),
    .o_fft_graph(fft_graph)
);

logic [0:4] [8:0] packed_fft_rd_addr;
logic [0:3] [8:0] packed_wr_addr;

control top_control (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_start(fft_start),
    .i_done(r_final_pair[5]),
    .o_rd_en(fft_rd_en),
    .o_wr_en(wr_en),
    .o_top_even(top_even),
    .o_o_rd_addr(packed_fft_rd_addr),
    .o_o_wr_addr(packed_wr_addr),
    .o_final_pair(final_pair),
    .o_active(active),
    .o_read_from_mem1(read_mem1),
    .o_even_segment(even_segment)
);

always_comb begin
    for (int i=0; i<5; i++) fft_rd_addr[i] = packed_fft_rd_addr[i];
    for (int i=0; i<4; i++) wr_addr[i] = packed_wr_addr[i];
end

/*

MUX rd_en and rd_addr comes from either fft_control or VGA_grapher
It is controlled by a sel signal from spectrum_analyser_control

*/
logic [4:0] rd_en;
logic [8:0] rd_addr [0:4];
wire grapher_rd_en;
wire [8:0] grapher_rd_addr;
always_comb begin
    if (fft_graph) begin
        rd_en = fft_rd_en;

        for (int j=0; j<5; j++) begin
            rd_addr[j] = fft_rd_addr[j];
        end
    end
    else begin
        rd_en[0] = 0;
        rd_en[1] = grapher_rd_en;
        rd_en[2] = 0;
        rd_en[3] = 0;
        rd_en[4] = 0;

        rd_addr[0] = '0;
        rd_addr[1] = grapher_rd_addr;
        rd_addr[2] = '0;
        rd_addr[3] = '0;
        rd_addr[4] = '0;
    end
end

/*

wr_data -> p_wr_data

p_rd_data -> rd_data

*/
logic signed [0:4][0:1][15:0] rd_data_packed;
logic signed [0:3][0:1][15:0] wr_data_packed;

// Convert unpacked wr_data to packed for memory input
assign wr_data_packed[0][0] = wr_data[0][0];
assign wr_data_packed[0][1] = wr_data[0][1];
assign wr_data_packed[1][0] = wr_data[1][0];
assign wr_data_packed[1][1] = wr_data[1][1];
assign wr_data_packed[2][0] = wr_data[2][0];
assign wr_data_packed[2][1] = wr_data[2][1];
assign wr_data_packed[3][0] = wr_data[3][0];
assign wr_data_packed[3][1] = wr_data[3][1];

// Convert packed rd_data from memory output to unpacked
assign rd_data[0][0] = rd_data_packed[0][0];
assign rd_data[0][1] = rd_data_packed[0][1];
assign rd_data[1][0] = rd_data_packed[1][0];
assign rd_data[1][1] = rd_data_packed[1][1];
assign rd_data[2][0] = rd_data_packed[2][0];
assign rd_data[2][1] = rd_data_packed[2][1];
assign rd_data[3][0] = rd_data_packed[3][0];
assign rd_data[3][1] = rd_data_packed[3][1];
assign rd_data[4][0] = rd_data_packed[4][0];
assign rd_data[4][1] = rd_data_packed[4][1];

memory top_memory (
    .i_clk(i_clk),
    .i_rd_en(rd_en),
    .i_rd_addr({rd_addr[0], rd_addr[1], rd_addr[2], rd_addr[3], rd_addr[4]}), //
    .i_wr_en(wr_en4),
    .i_wr_addr({wr_addr4[0], wr_addr4[1], wr_addr4[2], wr_addr4[3]}), //
    .i_wr_data(wr_data_packed), // 
    .o_rd_data(rd_data_packed) // 
);

logic [0:1][15:0] p_even;
assign p_even[0] = even[0];
assign p_even[1] = even[1];
logic [0:1][15:0] p_odd;
assign p_odd[0] = odd[0];
assign p_odd[1] = odd[1];
logic [0:1][15:0] p_twi;
assign p_twi[0] = twi[0];
assign p_twi[1] = twi[1];
logic [0:1][15:0] p_top;
assign top[0] = p_top[0];
assign top[1] = p_top[1];
logic [0:1][15:0] p_btm;
assign btm[0] = p_btm[0];
assign btm[1] = p_btm[1];

butterfly #(
    .I(1),
    .F(15)
) top_butterfly (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_i_even(p_even),
    .i_i_odd(p_odd),
    .i_i_twi(p_twi),
    .o_o_top(p_top),
    .o_o_btm(p_btm)
);

wire [15:0] mem1a_real_data;
wire [15:0] mem1a_imag_data;

assign mem1a_real_data = rd_data[1][0];
assign mem1a_imag_data = rd_data[1][1];

grapher top_grapher (
    .i_clk_24MHz (i_clk),
    .i_rst       (i_rst),
    .i_en        (graph_active),

    .i_rd_data0  (mem1a_real_data),
    .i_rd_data1  (mem1a_imag_data),

    .o_rd_addr   (grapher_rd_addr),
    .o_rd_en     (grapher_rd_en),

    .o_led       (o_led),

    .o_hs        (o_hs),
    .o_vs        (o_vs),

    .o_g0        (o_g0)
);

endmodule
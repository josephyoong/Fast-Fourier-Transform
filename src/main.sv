/*

*/

module main (
    input i_clk,
    input i_rst,
    input i_en,
    input i_start,
    output o_active
);

logic signed [15:0] even [0:1];
logic signed [15:0] odd [0:1];
logic signed [15:0] twi [0:1];
logic signed [15:0] top [0:1];
logic signed [15:0] btm [0:1];

logic [4:0] rd_en;
logic [3:0] wr_en; 
logic signed [15:0] rd_data [0:4] [0:1];
logic signed [15:0] wr_data [0:3] [0:1];
logic [8:0] wr_addr [0:3];
logic [8:0] rd_addr [0:4];

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
logic r_final_pair [0:4];
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
logic [8:0] r_wr_addr [0:3][0:4];
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
logic r_wr_en [0:3][0:4];
always_ff @(posedge i_clk) begin
    for (int j=0; j<4; j++) begin
        if (i_rst) begin
            for (int k=0; k<5; k++) begin
                r_wr_en[j][k] <= 0;
            end
        end
        else if (i_en) begin
            r_wr_en[j][0] <= wr_en[j];
            for (int k=1; k<5; k++) begin
                r_wr_en[j][k] <= r_wr_en[j][k-1];
            end
        end
    end
end

logic [3:0] wr_en4;
always_comb begin
    for (int j=0; j<4; j++) begin
        wr_en4[j] = r_wr_en[j][4];
    end
end

control top_control (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_start(i_start),
    .i_done(r_final_pair[4]),
    .o_rd_en(rd_en),
    .o_wr_en(wr_en),
    .o_top_even(top_even),
    .o_rd_addr(rd_addr),
    .o_wr_addr(wr_addr),
    .o_final_pair(final_pair),
    .o_active(o_active),
    .o_read_from_mem1(read_mem1),
    .o_even_segment(even_segment)
);

memory top_memory (
    .i_clk(i_clk),
    .i_rd_en(rd_en),
    .i_rd_addr(rd_addr),
    .i_wr_en(wr_en4),
    .i_wr_addr(wr_addr4),
    .i_wr_data(wr_data),
    .o_rd_data(rd_data)
);

butterfly #(
    .I(1),
    .F(15)
) top_butterfly (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_en(i_en),
    .i_even(even),
    .i_odd(odd),
    .i_twi(twi),
    .o_top(top),
    .o_btm(btm)
);

endmodule
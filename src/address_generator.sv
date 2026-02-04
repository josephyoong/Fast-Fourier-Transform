/*

address_generator.sv

purely combinational

Memory structure: 
mem1a mem1b mem2a mem2b

*/

module address_generator  (
    input i_en,
    input [3:0] i_stage,
    input [8:0] i_pair,
    output logic [8:0] o_rd_addr [0:4],
    output logic [4:0] o_rd_en,
    output logic [8:0] o_wr_addr [0:3],
    output logic [3:0] o_wr_en,
    output o_top_even,
    output o_read_from_mem1,
    output o_even_segment
);

logic [8:0] twi_addr;
logic [8:0] even_addr;
logic [8:0] odd_addr;
logic [8:0] top_addr;
logic [8:0] btm_addr;

logic top_to_a;

logic [8:0] segment_count;
logic even_segment;
logic [9:0] dif;
logic [8:0] segment2_count;

// if even stage, read from mem1 and write to mem2
wire even_stage;
wire read_mem1;
wire write_mem2;
assign even_stage = ~i_stage[0];
assign read_mem1 = even_stage;
assign write_mem2 = even_stage;

assign even_segment = ~segment_count[0];

wire even_segment2;
assign even_segment2 = ~segment2_count[0];

assign top_to_a = ~segment2_count[0];

logic [3:0] shift_val;

always_comb begin

    if (i_en) begin
        o_rd_en[0] = 1'b1; // twi
        o_rd_en[1] = read_mem1; // mem1 a
        o_rd_en[2] = read_mem1; // mem1 b
        o_rd_en[3] = ~read_mem1; // mem2 a
        o_rd_en[4] = ~read_mem1; // mem2 b

        o_wr_en[0] = ~write_mem2; // mem1 a
        o_wr_en[1] = ~write_mem2; // mem1 b
        o_wr_en[2] = write_mem2; // mem2 a
        o_wr_en[3] = write_mem2; // mem2 b
    end
    else begin
        o_rd_en[0] = 0; // twi
        o_rd_en[1] = 0; // mem1 a
        o_rd_en[2] = 0; // mem1 b
        o_rd_en[3] = 0; // mem2 a
        o_rd_en[4] = 0; // mem2 b

        o_wr_en[0] = 0; // mem1 a
        o_wr_en[1] = 0; // mem1 b
        o_wr_en[2] = 0; // mem2 a
        o_wr_en[3] = 0; // mem2 b
    end

        dif = 10'd512 >> i_stage;

        segment_count = i_pair >> (9 - i_stage); // pair >> log2(N) - (stage + 1)

        // read addresses
        if (even_segment) begin // if its an even even_segment
            even_addr = i_pair; // even comes from sub bank a
            odd_addr = i_pair + dif; // odd comes from sub bank b
            o_rd_addr[1] = even_addr; // mem1 a
            o_rd_addr[2] = odd_addr; // mem1 b
            o_rd_addr[3] = even_addr; // mem2 a
            o_rd_addr[4] = odd_addr; // mem2 b
        end
        else begin // if its an odd even_segment
            even_addr = i_pair - dif; // even comes from sub bank b
            odd_addr = i_pair; // odd comes from sub bank a
            o_rd_addr[1] = odd_addr; // mem1 a
            o_rd_addr[2] = even_addr; // mem1 b
            o_rd_addr[3] = odd_addr; // mem2 a
            o_rd_addr[4] = even_addr; // mem2 b
        end

        // bit reversal
        for (int i=0; i<9; i++) begin
            twi_addr[8-i] = segment_count[i];
        end
        o_rd_addr[0] = twi_addr;

        // write addresses
        top_addr = i_pair;
        btm_addr = i_pair;

        if (i_stage == 4'd9) begin
            
        end
        else begin
            segment2_count = i_pair >> (8 - i_stage); // pair >> log2(N) - (stage + 2)
        end


        // THIS FIXED IT
        shift_val = (i_stage < 9) ? (8 - i_stage) : 0;
        segment2_count = i_pair >> shift_val;
        // THIS FIXED IT

        if (even_segment2) begin
            o_wr_addr[0] = top_addr; // mem1 a
            o_wr_addr[1] = btm_addr; // mem1 b
            o_wr_addr[2] = top_addr; // mem2 a
            o_wr_addr[3] = btm_addr; // mem2 b
        end
        else begin
            o_wr_addr[0] = btm_addr; // mem1 a
            o_wr_addr[1] = top_addr; // mem1 b
            o_wr_addr[2] = btm_addr; // mem2 a
            o_wr_addr[3] = top_addr; // mem2 b
        end

end

assign o_top_even = even_segment2;
assign o_read_from_mem1 = read_mem1;
assign o_even_segment = even_segment;

endmodule
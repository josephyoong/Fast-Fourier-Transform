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
    output logic [0:4] [8:0] o_o_rd_addr,
    output logic [4:0] o_rd_en,
    output logic [0:3] [8:0] o_o_wr_addr,
    output logic [3:0] o_wr_en,
    output o_top_even,
    output o_read_from_mem1,
    output o_even_segment
);

// yosys packed
logic [8:0] o_rd_addr [0:4];
logic [8:0] o_wr_addr [0:3];

// For Read Addresses
assign o_o_rd_addr[0] = o_rd_addr[0];
assign o_o_rd_addr[1] = o_rd_addr[1];
assign o_o_rd_addr[2] = o_rd_addr[2];
assign o_o_rd_addr[3] = o_rd_addr[3];
assign o_o_rd_addr[4] = o_rd_addr[4];

// For Write Addresses
assign o_o_wr_addr[0] = o_wr_addr[0];
assign o_o_wr_addr[1] = o_wr_addr[1];
assign o_o_wr_addr[2] = o_wr_addr[2];
assign o_o_wr_addr[3] = o_wr_addr[3];

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

        /*

        difference between segments

        */
        dif = 10'd512 >> i_stage; // variable shift
        // alternative to variable shift
        // case (i_stage)
        //     4'd0: dif = 10'd512;
        //     4'd1: dif = 10'd256;
        //     4'd2: dif = 10'd128;
        //     4'd3: dif = 10'd64;
        //     4'd4: dif = 10'd32;
        //     4'd5: dif = 10'd16;
        //     4'd6: dif = 10'd8;
        //     4'd7: dif = 10'd4;
        //     4'd8: dif = 10'd2;
        //     4'd9: dif = 10'd1;
        //     default: dif = '0;
        // endcase

        /*

        segment count

        */
        segment_count = i_pair >> (9 - i_stage); // pair >> log2(N) - (stage + 1); variable shift
        // alternative to variable shift
        // case (i_stage)
        //     4'd0: segment_count = 9'd0;
        //     4'd1: segment_count = {8'd0, i_pair[8]};
        //     4'd2: segment_count = {7'd0, i_pair[8:7]};
        //     4'd3: segment_count = {6'd0, i_pair[8:6]};
        //     4'd4: segment_count = {5'd0, i_pair[8:5]};
        //     4'd5: segment_count = {4'd0, i_pair[8:4]};
        //     4'd6: segment_count = {3'd0, i_pair[8:3]};
        //     4'd7: segment_count = {2'd0, i_pair[8:2]};
        //     4'd8: segment_count = {1'd0, i_pair[8:1]};
        //     4'd9: segment_count = i_pair;
        //     default: segment_count = '0;
        // endcase

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
            segment2_count = i_pair >> (8 - i_stage); // pair >> log2(N) - (stage + 2); variable shift
            // alternative to variable shift
            // case (i_stage)
            //     4'd0: segment2_count = {8'd0, i_pair[8]};
            //     4'd1: segment2_count = {7'd0, i_pair[8:7]};
            //     4'd2: segment2_count = {6'd0, i_pair[8:6]};
            //     4'd3: segment2_count = {5'd0, i_pair[8:5]};
            //     4'd4: segment2_count = {4'd0, i_pair[8:4]};
            //     4'd5: segment2_count = {3'd0, i_pair[8:3]};
            //     4'd6: segment2_count = {2'd0, i_pair[8:2]};
            //     4'd7: segment2_count = {1'd0, i_pair[8:1]};
            //     4'd8: segment2_count = i_pair;
            //     default: segment2_count = '0;
            // endcase
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
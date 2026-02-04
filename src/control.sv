/*

*/

module control (
    input i_clk,
    input i_rst,
    input i_en,
    input i_start,
    input i_done,
    output [4:0] o_rd_en,
    output [8:0] o_rd_addr [0:4],
    output o_read_from_mem1,
    output o_even_segment,
    output o_top_even,
    output [3:0] o_wr_en,
    output [8:0] o_wr_addr [0:3],
    output o_final_pair,
    output logic o_active
);

logic en_counter = 0;
logic [3:0] counter_stage = 4'd0;
logic [8:0] counter_pair = 9'd0;
wire start;
wire done;

assign start = !o_active & i_start;
assign done = o_active & i_done;

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_active <= 0;
        en_counter <= 0;
    end
    else if (i_en) begin
        if (start) begin
            o_active <= 1;
            en_counter <= 1;
        end
        if (done) begin
            o_active <= 0;
        end
    end
end

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        counter_stage <= 4'd0;
        counter_pair <= 9'd0;
    end
    else if (i_en) begin
        if (en_counter) begin
            if (counter_pair == 9'd511) begin
                counter_pair <= 9'd0;

                if (counter_stage == 4'd9) begin
                    en_counter <= 0;
                    counter_stage <= 4'd0;
                    counter_pair <= 9'd0;
                end
                else begin
                    counter_stage <= counter_stage + 1;
                end
            end
            else begin
                counter_pair <= counter_pair + 1;
            end
        end
    end
end

address_generator control_address_generator (
    .i_stage(counter_stage),
    .i_pair(counter_pair),
    .i_en(en_counter),
    .o_rd_addr(o_rd_addr),
    .o_rd_en(o_rd_en),
    .o_wr_addr(o_wr_addr),
    .o_wr_en(o_wr_en),
    .o_top_even(o_top_even),
    .o_read_from_mem1(o_read_from_mem1),
    .o_even_segment(o_even_segment)
);

assign o_final_pair = en_counter && (counter_stage == 4'd9) && (counter_pair == 9'd511);

endmodule
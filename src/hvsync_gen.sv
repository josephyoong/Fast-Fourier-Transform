/*

hvscync_gen.sv

i_clk must be ~25.175 MHz

*/

module hvsync_gen (
    input i_clk,
    output logic o_hsync,
    output logic o_vsync,
    output o_active_video,
    output [9:0] o_x_pos,
    output [8:0] o_y_pos 
);

logic [9:0] h_counter = 10'd0;
logic [9:0] v_counter = 10'd0;

always_ff @(posedge i_clk) begin
    if (h_counter == 10'd799) begin
        h_counter <= 10'd0;

        if (v_counter == 10'd524) begin
            v_counter <= 10'd0;
        end
        else begin
            v_counter <= v_counter + 1;
        end
    end
    else begin
        h_counter <= h_counter + 1;
    end
end

always_ff @(posedge i_clk) begin
    o_hsync = ~((h_counter >= 656) && (h_counter <= 751));
    o_vsync = ~((v_counter >= 490) && (v_counter <= 491));
end

assign o_active_video = (h_counter < 640) && (v_counter < 480);

assign o_x_pos = o_active_video ? h_counter : 10'd0;
assign o_y_pos = o_active_video ? v_counter[8:0] : 9'd0;

endmodule
/*

top.sv

VGA grapher

640 x 480 @ 60 Hz
=> clk frequency = 25.175 MHz
=> 24 MHz is good enough

*/

module grapher (
    input i_clk_24MHz,
    input i_rst,
    input i_en,

    input signed [15:0] i_rd_data0,
    input signed [15:0] i_rd_data1,

    output logic [8:0] o_rd_addr,
    output logic o_rd_en,

    output o_led,

    output o_hs,
    output o_vs,

    output o_g0
);

logic r_red = 0;
logic r_green = 0;
logic r_blue = 0;

logic draw;

logic [24:0] led_counter = 25'b0;

wire active_video;
wire [9:0] x_pos;
wire [8:0] y_pos;
logic [9:0] r_x_pos [0:1];
logic [8:0] r_y_pos [0:1];
logic [8:0] x_pos_graph;
logic [8:0] y_pos_graph;
logic [8:0] r_y_pos_graph;
logic [8:0] r_x_pos_graph;
wire hs;
wire vs;
logic [1:0] r_hs;
logic [1:0] r_vs;

// LED blink 
always_ff @(posedge i_clk_24MHz) begin
    led_counter <= led_counter + 1;
end

assign o_led = led_counter[24];

// hsync vsync generator
hvsync_gen grapher_hvsync_gen (
    .i_clk(i_clk_24MHz),
    .o_hsync(hs),
    .o_vsync(vs),
    .o_active_video(active_video),
    .o_x_pos(x_pos),
    .o_y_pos(y_pos)
);

/*

hs and vs registers

add 2 clk cycle latency because mem read has 1 clk cycle latency and 1 clk for calc

*/
always_ff @(posedge i_clk_24MHz) begin
    if (i_rst) begin
        r_hs[0] <= 0;
        r_vs[0] <= 0;
        r_hs[1] <= 0;
        r_vs[1] <= 0;
        r_x_pos[0] <= 0;
        r_y_pos[0] <= 0;
        r_x_pos[1] <= 0;
        r_y_pos[1] <= 0;
    end
    else if (i_en) begin
        r_hs[0] <= hs;
        r_vs[0] <= vs;
        r_hs[1] <= r_hs[0];
        r_vs[1] <= r_vs[0];
        r_x_pos[0] <= x_pos;
        r_y_pos[0] <= y_pos;
        r_x_pos[1] <= r_x_pos[0];
        r_y_pos[1] <= r_y_pos[0];
    end
end
assign o_hs = r_hs[1];
assign o_vs = r_vs[1];

/*
read memory at address x_pos + offset x - takes 1 clk cycle
compare data with y_pos + offset y
if same, colour
*/

// read memory
localparam X_START_GRAPH = 50;
localparam GRAPH_WIDTH = 512;
localparam X_END_GRAPH = X_START_GRAPH + GRAPH_WIDTH;
localparam Y_START_GRAPH = 100;
localparam GRAPH_HEIGHT = 256;
localparam Y_END_GRAPH = Y_START_GRAPH + GRAPH_HEIGHT;

/*

1st clk cycle

send out rd en and rd addr and determine graph positions

*/
logic active_graph;
logic r_active_graph;

always_comb begin
    if ((active_video) && 
        (x_pos >= X_START_GRAPH) && (x_pos < X_END_GRAPH) &&
        (y_pos >= Y_START_GRAPH) && (y_pos < Y_END_GRAPH)) begin

        active_graph = 1;
        o_rd_en = 1;
        x_pos_graph = x_pos - X_START_GRAPH;
        y_pos_graph = y_pos - Y_START_GRAPH;
        // bit reversal
        for (int i=0; i<9; i++) begin
                o_rd_addr[i] = x_pos_graph[8-i];
        end
    end
    else begin
        active_graph = 0;
        o_rd_en = 0;
        x_pos_graph = 0;
        y_pos_graph = 0;
        o_rd_addr = 0;
    end
end

/*

2nd clk cycle

rd data is available

calculate the magnitude and compare to y pos graph (prev cycle)

*/
// register y pos graph
always_ff @(posedge i_clk_24MHz) begin
    if (i_rst) begin
        r_y_pos_graph <= 0;
        r_x_pos_graph <= 0;
        r_active_graph <= 0;
    end
    else if (i_en) begin
        r_y_pos_graph <= y_pos_graph;
        r_x_pos_graph <= x_pos_graph;
        r_active_graph <= active_graph;
    end
end

logic [15:0] abs_rd_data [0:1];
logic [16:0] sum_abs_rd_data;
logic [8:0] scaled_abs_rd_data;

wire [1:0] i_rd_data15_0;
wire [1:0] i_rd_data15_1;
assign i_rd_data15_0 = i_rd_data0[15];
assign i_rd_data15_1 = i_rd_data1[15];

always_comb begin

    if (i_rd_data15_0) begin //  if negative
        abs_rd_data[0] = -i_rd_data0;
    end
    else begin
        abs_rd_data[0] = i_rd_data0;
    end

    if (i_rd_data15_1) begin //  if negative
        abs_rd_data[1] = -i_rd_data1;
    end
    else begin
        abs_rd_data[1] = i_rd_data1;
    end

    sum_abs_rd_data = abs_rd_data[0] + abs_rd_data[1];

    scaled_abs_rd_data = sum_abs_rd_data >> 6; // 8 for max 255???
end

// compare 
always_comb begin
    if (r_active_graph) begin
        // draw = 1; // colour in the graph area

        if ((r_y_pos_graph == 9'd255) ||
            (r_x_pos_graph == 9'd0) ||
            (r_y_pos_graph >= (GRAPH_HEIGHT - scaled_abs_rd_data))) begin
            // (r_y_pos_graph == (scaled_abs_rd_data))) begin

            draw = 1;
        end
        else begin
            draw = 0;
        end


        // if ((GRAPH_HEIGHT - r_y_pos_graph) == scaled_abs_rd_data) begin
        //     draw = 1;
        // end
        // else begin
        //     draw = 0;
        // end

        // upside down worked
        // if (r_y_pos_graph == scaled_abs_rd_data) begin
        //     draw = 1;
        // end
        // else begin
        //     draw = 0;
        // end
    end
    else begin
        draw = 0;
    end
end

/*

3rd clk cycle

*/
always_ff @(posedge i_clk_24MHz) begin
    if (i_rst) begin
        r_green <=0;
        r_red <= 0;
        r_blue <= 0;
    end
    else if (i_en) begin
        r_green <= draw;
    end
end

assign o_g0 = r_green;

endmodule
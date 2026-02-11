/*

*/

module spectrum_analyser_control (
    input i_clk,
    input i_rst,
    input i_en,
    input i_start_fft,
    input i_start_graph,
    input i_fft_active, // tells if fft is active
    output logic o_fft_active, // control signal for mux
    output logic o_graph_active,
    output logic o_fft_start,
    output logic o_fft_graph
);

typedef enum logic [1:0] {
    IDLE,
    FFT,
    GRAPH
} t_state;

t_state state;
t_state next_state;

/*

sequential state

*/
logic r_end_fft;
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        state <= IDLE;
    end
    else if (i_en) begin
        state <= next_state;
    end
end

/*

combinational next state

*/
always_comb begin

    case (state) 
        IDLE: begin
            if (i_start_fft) begin
                next_state = FFT;

                // IDLE -> FFT transition output
                o_fft_start = 1;
            end
            else begin
                if (i_start_graph) begin
                    next_state = GRAPH;

                    o_fft_start = 0;
                end
                else begin
                    next_state = IDLE;

                    o_fft_start = 0;
                end
            end
        end

        FFT: begin
            if (i_fft_active) begin
                next_state = FFT;

                o_fft_start = 0;
            end
            else begin
                if (i_start_graph) begin
                    next_state = GRAPH;

                    o_fft_start = 0;
                end
                else begin
                    next_state = IDLE;

                    o_fft_start = 0;
                end
            end
        end

        GRAPH: begin
            if (i_start_fft) begin
                next_state = FFT;

                // GRAPH -> FFT transition output
                o_fft_start = 1;
            end
            else begin
                next_state = GRAPH;

                o_fft_start = 0;
            end
        end

        default: begin
            o_fft_start = 0;
            next_state = IDLE;
        end
    endcase
end

/*

combinational outputs

*/
always_comb begin
    case (state) 
        IDLE: begin
            o_fft_active = 0;
            o_graph_active = 0;
            o_fft_graph = 0;
        end

        FFT: begin
            o_fft_active = 1;
            o_graph_active = 0;
            o_fft_graph = 1;
        end

        GRAPH: begin
            o_fft_active = 0;
            o_graph_active = 1;
            o_fft_graph = 0;
        end
        
        default: begin
            o_fft_active = 0;
            o_graph_active = 0;
            o_fft_graph = 0;
        end
    endcase
end

endmodule
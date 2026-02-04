/*

dual port BRAM - dual port block ram

for lattice iCE40UP5, use sysMEM embedded block RAM (EBR) memory as BRAM
there are 30 EBR, each with 4k bits size to be configured as
256 x 16
512 x 8
1024 x 4
2048 x 2

use two 256 x 16 EBR for 512 x 16 BRAM

*/

module dp_bram_512x16 #(
    parameter TEST = 0
) (
    input i_clk,

    input i_wr_en,
    input [8:0] i_wr_addr,
    input signed [15:0] i_wr_data,
    input i_rd_en,
    input [8:0] i_rd_addr,

    output logic signed [15:0] o_rd_data
);

logic [15:0] r_mem [0:511];

// real angle;

initial begin
    if (TEST) begin
        for (int i=0; i<512; i++) begin
            // r_mem[i] = 16'b0010000000000000; // 0.5

            real angle;
            angle = 2.0 * 3.141592653589793 * 50 * i / 512.0;
            r_mem[i] = $rtoi($cos(angle) * 8191);
        end
    end
    else begin
        for (int i=0; i<512; i++) begin
            r_mem[i] = 16'd0;
        end
    end
end

always_ff @(posedge i_clk) begin
    if (i_wr_en) begin
        r_mem[i_wr_addr] <= i_wr_data;
    end
    if (i_rd_en) begin
        o_rd_data <= r_mem[i_rd_addr];
    end
    else begin
        o_rd_data <= 16'd0;
    end
end
    
endmodule 
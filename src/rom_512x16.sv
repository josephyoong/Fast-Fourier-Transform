/*

ROM - read only memory

for lattice iCE40UP5, use sysMEM embedded block RAM (EBR) memory as ROM
there are 30 EBR, each with 4k bits size to be configured as
256 x 16
512 x 8
1024 x 4
2048 x 2

use two 256 x 16 EBR for 512 x 16 ROM

need two rom_512x16: one for real, one for imaginary

*/

module rom_512x16 #(
    parameter REAL // 1 REAL, 0 IMAG
) (
    input i_clk,

    input i_rd_en,
    input [8:0] i_rd_addr,

    output logic [15:0] o_rd_data
);

reg [15:0] r_mem [0:511];

real angle;

// trig values Q1.15
initial begin
    for (int i=0; i<512; i++) begin
        // Divisor 1024.0 ensures i=511 results in angle PI (N/2)
        angle = 2.0 * 3.14159265358979323846 * i / 1024.0;
        
        if (REAL)
             r_mem[i] = real_to_q1p15($cos(angle));
        else
             r_mem[i] = real_to_q1p15(-$sin(angle));
    end
end

always_ff @(posedge i_clk) begin
    o_rd_data <= i_rd_en ? r_mem[i_rd_addr] : 0;
end

endmodule

function logic signed [15:0] real_to_q1p15(input real num);
    real scaled;
    begin
        if (num >= 0.999969482421875)      // (32767 / 32768) is Q1.15 0.111111111111111
            real_to_q1p15 = 16'sh7FFF;
        else if (num <= -1.0)
            real_to_q1p15 = 16'sh8000;
        else begin
            scaled = num * 32768.0;

            if (scaled >= 0) // positive
                real_to_q1p15 = $rtoi(scaled + 0.5);
            else // negative
                real_to_q1p15 = $rtoi(scaled - 0.5);
        end
    end
endfunction
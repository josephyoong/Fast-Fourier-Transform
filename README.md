##

Successful FFT

The output signal is stored in mem1a and can be visualised in MATLAB

Next step: VGA interface to display input time domain signal and output frequency domain signal

# Simulating with Icarus Verilog

install oss cad suite

enter oss cad suite environment through command prompt
cd C:\Users\josep\Documents\FPGA\oss-cad-suite
environment.bat

check version 
iverilog -V

navigate to FFT folder 
cd C:\Users\josep\Documents\FPGA\FFT

compile 
iverilog -g2012 -o sim.out src/butterfly.sv tb/tb_butterfly.sv src/complex_multiplier.sv

run
vvp sim.out

view waveform
gtkwave tb_butterfly.vcd



# iCE40 Programming Instructions

install oss cad suite

enter oss cad suite environment through command prompt
cd C:\Users\josep\Documents\FPGA\oss-cad-suite
environment.bat

synthesise using yosys
.sv -> .json

place and route using nextpnr
.json -> .asc

generate bitstream using icepack
.asc -> .bin


drag and drop bitstream into iCELink drive

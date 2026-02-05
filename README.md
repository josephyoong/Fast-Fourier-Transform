# Fast Fourier Transform on iCE40 FPGA

Joseph Yoong

The output frequency domain signal is stored in mem1a and can be visualised in MATLAB

Next step: VGA interface to display input time domain signal and output frequency domain signal on a monitor

## Simulating with Icarus Verilog

### Install OSS CAD Suite

### Enter the OSS CAD Suite environment through command prompt

cd C:\Users\josep\Documents\FPGA\oss-cad-suite

environment.bat

### Check version 

iverilog -V

### Navigate to FFT folder 
cd C:\Users\josep\Documents\FPGA\FFT

### Compile 
iverilog -g2012 -o sim.out src/butterfly.sv tb/tb_butterfly.sv src/complex_multiplier.sv

### Run
vvp sim.out

### View waveform
gtkwave tb_butterfly.vcd



## iCE40 Programming Instructions

### Install OSS CAD Suite

### Enter the OSS CAD Suite environment through command prompt

cd C:\Users\josep\Documents\FPGA\oss-cad-suite

environment.bat

### Synthesise using yosys
.sv -> .json

### Place and route using nextpnr
.json -> .asc

### Generate bitstream using icepack
.asc -> .bin

### Drag and drop bitstream into iCELink drive


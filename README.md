# Fast Fourier Transform on iCE40 FPGA

Joseph Yoong

Performs the fast Fourier transform on an input signal and displays the output frequency spectrum on a monitor via VGA



## Simulating with Icarus Verilog

### Install OSS CAD Suite

### Enter the OSS CAD SUITE environment through command prompt

cd C:\Users\josep\Documents\FPGA\oss-cad-suite

environment.bat

### Navigate to the folder

cd C:\Users\josep\Documents\FPGA\Fast-Fourier-Transform

### Compile 

iverilog -g2012 -DDEBUG -o sim.out sim/tb_main.sv src\address_generator.sv src\butterfly.sv src\complex_multiplier.sv src\dp_bram_512x16.sv src\fft_control.sv src\grapher.sv src\hvsync_gen.sv src\memory.sv src\rom_512x16.sv src\spectrum_analyser_control.sv src\spectrum_analyser.sv src\top.sv

### Run

vvp sim.out

### View waveform

gtkwave tb_main.vcd



## iCE40 Programming Instructions

### Install OSS CAD Suite

### Enter the OSS CAD SUITE environment through command prompt

cd C:\Users\josep\Documents\FPGA\oss-cad-suite

environment.bat

### Synthesise using yosys

.sv -> .json

yosys -p "read_verilog -sv src\address_generator.sv src\butterfly.sv src\complex_multiplier.sv src\dp_bram_512x16.sv src\fft_control.sv src\grapher.sv src\hvsync_gen.sv src\memory.sv src\rom_512x16.sv src\spectrum_analyser_control.sv src\spectrum_analyser.sv src\top.sv ; synth_ice40 -dsp -top top -json top.json"


### Place and route using nextpnr

.json -> .asc

nextpnr-ice40 --up5k --package sg48 --json top.json --pcf constraints\io.pcf --asc top.asc --sdc constraints\constraints.sdc  --verbose


### Generate bitstream using icepack

.asc -> .bin

icepack top.asc top.bin


### Drag and drop bitstream into iCELink drive

# Vivado Simulation Environment using WSL and Makefile
## Overview

  This setup allows you to compile and simulate Verilog/SystemVerilog projects using Xilinx Vivado (installed on
  Windows) from a WSL (Windows Subsystem for Linux) terminal, automated with a Makefile.

  Waveforms from the simulation can be viewed using gtkwave.

## Prerequisites
### On Windows
   1. Xilinx Vivado: This project is configured for Vivado 2020.2, but other versions should work with minor
      changes.
       - Important: You must update the VIVADO_BIN_WIN variable in the Makefile to point to your specific Vivado
         installation path.
   2. X Server (for Windows 10): To display GUI applications like gtkwave from WSL, you need an X server.
       - Popular options include VcXsrv (https://sourceforge.net/projects/vcxsrv/) or GWSL
         (https://github.com/Opticos/GWSL-Source).
       - Note: On Windows 11, WSLg is included by default, so a separate X server is not required.

### On WSL

   1. make: The build automation tool.
   2. gtkwave: The waveform viewer.

  You can install them on a Debian-based WSL distribution (like Ubuntu) with the following command:

   1 sudo apt update
   2 sudo apt install make gtkwave

  3. How to Use

  The entire workflow is managed by the Makefile.

   - `make TARGET={TARGET_NAME} compile`
      Compiles the HDL source files specified by the TARGET variable.

   - `make TARGET={TARGET_NAME} sim`
      Runs the simulation for the compiled testbench.

   - `make TARGET={TARGET_NAME} wave`
      Opens the generated VCD waveform file (.vcd) in gtkwave.

   - `make TARGET={TARGET_NAME} all`
      Runs compile, sim, and wave targets sequentially.

   - `make TARGET={TARGET_NAME} clean`
      Removes the build directory.

  You can specify a different target by setting the TARGET variable:
   1 make all TARGET=your_other_target

## Troubleshooting

  gtkwave dconf-WARNING

  When running make wave or gtkwave, you might see the following warning:

   1 (gtkwave:xxxx): dconf-WARNING **: ...: failed to commit changes to dconf: Could not connect: No such
     file or directory

  This is a non-critical warning. It simply means gtkwave cannot save its settings (like window size or signal
  arrangement) because the dconf configuration service isn't running in the default WSL environment.

  The core functionality of viewing waveforms is not affected, so you can safely ignore this message.

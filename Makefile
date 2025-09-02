#Makefile

TARGET ?= target

VIVADO_BIN_WIN = C:\Xilinx\Vivado\2020.2\bin

SRC_DIR = $(TARGET)/src
SIM_DIR = sim
TB_DIR = $(TARGET)/tb

BUILD_DIR = build/$(TARGET)
IFS_DIR = ifs

.PHONY: compile sim wave all clean

compile:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && powershell.exe -Command "& $(VIVADO_BIN_WIN)\vivado.bat -mode batch \
	-source ../../$(SIM_DIR)/compile.tcl -tclargs $(TARGET) \
	-log vivado.log"

sim:
	cd $(BUILD_DIR) && powershell.exe -Command "$(VIVADO_BIN_WIN)\xsim.bat tb_$(TARGET) -tclbatch ../../$(SIM_DIR)/sim.tcl"

clean:
	rm -rf $(BUILD_DIR) 

wave:
	gtkwave $(BUILD_DIR)/*.vcd &

all: compile sim wave

run: compile sim

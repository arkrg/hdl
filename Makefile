#Makefile

TARGET ?= target
TB ?= tb_$(TARGET)

VIVADO_BIN_WIN = C:\Xilinx\Vivado\2020.2\bin
VIVADO_PROJECTS = /mnt/d/workplace/fpga

SRC_DIR = $(TARGET)/src
SIM_DIR = sim
TB_DIR = $(TARGET)/tb

BUILD_DIR = build/$(TARGET)
IFS_DIR = ifs

.PHONY: compile sim wave all clean copy_src copy_sim copy_all

compile:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && powershell.exe -Command "& $(VIVADO_BIN_WIN)\vivado.bat -mode batch \
	-source ../../$(SIM_DIR)/compile.tcl -tclargs $(TARGET) $(TB) \
	-log vivado.log"

sim:
	cd $(BUILD_DIR) && powershell.exe -Command "$(VIVADO_BIN_WIN)\xsim.bat $(TB) -tclbatch ../../$(SIM_DIR)/sim.tcl"

clean:
	rm -rf $(BUILD_DIR)

wave:
	gtkwave $(BUILD_DIR)/*.vcd &

run: compile sim

all: compile sim wave

# Kill vivado simulation process
kill:
	@taskkill.exe /F /IM xsimk.exe /T >nul 2>&1 || true

copy_src:
	mkdir -p $(TARGET)
	mkdir -p $(SRC_DIR)
	find $(VIVADO_PROJECTS)/$(TARGET)/*.srcs/sources_1 -name "*v" -print0 | xargs -0 -I {} cp {} $(SRC_DIR)/.

copy_sim:
	mkdir -p $(TARGET)
	mkdir -p $(TB_DIR)
	find $(VIVADO_PROJECTS)/$(TARGET)/*.srcs/sim_1 -name "*v" -print0 | xargs -0 -I {} cp {} $(TB_DIR)/.

copy_all: copy_src copy_sim

# pull_src:
# 	find $(SRC_DIR) -name "*v"-print0 | xargs -0 -I {} cp {} $(VIVADO_PROJECTS)/$(TARGET)/*.srcs/sources_1

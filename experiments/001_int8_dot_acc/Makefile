SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

VCS ?= vcs
TOP := tb_int8_dot_acc
SIM_DIR := sim
LOG_DIR := logs

RTL := rtl/int8_dot_acc.sv
SVA := sva/int8_dot_acc_sva.sv
TB  := tb/tb_int8_dot_acc.sv

.PHONY: sim compile run clean

sim: compile run

compile:
	mkdir -p $(SIM_DIR) $(LOG_DIR)
	$(VCS) -full64 -sverilog -timescale=1ns/1ps -debug_access+all $(RTL) $(SVA) $(TB) -top $(TOP) -o $(SIM_DIR)/simv 2>&1 | tee $(LOG_DIR)/compile.log

run:
	./$(SIM_DIR)/simv 2>&1 | tee $(LOG_DIR)/sim.log

clean:
	rm -rf $(SIM_DIR) csrc simv.daidir ucli.key vc_hdrs.h $(LOG_DIR)/*.log

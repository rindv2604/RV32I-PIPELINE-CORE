IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

BUILD_DIR       ?= build
SIM              = $(BUILD_DIR)/tb_cpu_top.vvp
WAVE             = $(BUILD_DIR)/reference_program.vcd
RTL_SOURCES      = $(shell sed -e '/^[[:space:]]*$$/d' files.f)
LIBRELANE_ROOT  ?= /home/rin/eda/librelane
LIBRELANE_CONFIG = $(CURDIR)/librelane/config.json

.PHONY: test test-reference test-wb-id test-load-use wave view-wave librelane-synth librelane clean

test: test-reference test-wb-id test-load-use

test-reference: $(SIM)
	$(VVP) $(SIM) \
		+IMEM=tests/reference_program.mem \
		+TEST_NAME=reference_program \
		+MAX_CYCLES=80 \
		+DONE_REG=17 +DONE_VALUE=0000000a \
		+EXPECT_X17=0000000a +EXPECT_X29=00000001

test-wb-id: $(SIM)
	$(VVP) $(SIM) \
		+IMEM=tests/wb_id_hazard.mem \
		+TEST_NAME=wb_id_hazard \
		+MAX_CYCLES=40 \
		+DONE_REG=31 +DONE_VALUE=00000001 \
		+EXPECT_X13=0000002a

test-load-use: $(SIM)
	$(VVP) $(SIM) \
		+IMEM=tests/load_use_hazard.mem \
		+TEST_NAME=load_use_hazard \
		+MAX_CYCLES=50 \
		+DONE_REG=31 +DONE_VALUE=00000001 \
		+EXPECT_X3=0000002a +EXPECT_X4=00000054

wave: $(SIM)
	$(VVP) $(SIM) \
		+IMEM=tests/reference_program.mem \
		+TEST_NAME=reference_wave \
		+MAX_CYCLES=80 \
		+DONE_REG=17 +DONE_VALUE=0000000a \
		+EXPECT_X17=0000000a +EXPECT_X29=00000001 \
		+VCD=$(WAVE)

view-wave: wave
	$(GTKWAVE) $(WAVE) modelsim/wave.sav &

librelane-synth:
	nix-shell $(LIBRELANE_ROOT)/shell.nix --run \
		'librelane --condensed --hide-progress-bar --run-tag SYNTH_CHECK --overwrite --to Yosys.Synthesis $(LIBRELANE_CONFIG)'

librelane:
	nix-shell $(LIBRELANE_ROOT)/shell.nix --run \
		'librelane --condensed --hide-progress-bar $(LIBRELANE_CONFIG)'

$(SIM): files.f $(RTL_SOURCES) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -Wall -o $@ -s tb_cpu_top -f files.f

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

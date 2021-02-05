#
# Copyright 2021 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later

# Include IP directory Makefile
BASE_DIR = $(abspath ../../../usrp3/top)
IP_DIR = $(BASE_DIR)/x400/ip
TOOLS_DIR = $(BASE_DIR)/../tools
include $(IP_DIR)/Makefile.inc

# avoid checkout of gcc compilers by hwSetup
POSSIBLE_COMPILERS :=

.PHONY: all regmap

all: regmap

# Generate verilog headers first with highest privileges.
# Generate open source html documentation (privilege=5) afterwards.
# Then move the documentation to target directory.
regmap:
	xmlparse --sync --norbm --settingsfile=vsmakesettings_xmlparse.xml X4XX_FPGA
	xmlparse --norbm --privilege=5 --settingsfile=vsmakesettings_xmlparse.xml X4XX_FPGA
	mv ./pri5/*.htm $(BASE_DIR)/x400/doc/
	rm -rf pri5

# tb_adc_100m_bd and tb_dac_100m_bd both depend on export_bd_sims (which
# builds simulation models for both BD's) because of a limitation in vsmake.
# Vsmake always executes the nisim precompile commands for all testbenches, so
# if any testbench includes nisim precompile commands, vsmake will compile no
# testbench unless the precompile commands from all testbenches can succeed.
# tb_dac_100m_bd and tb_adc_100m_bd contain precompile commands that execute
# vsim_ops_dac_100m_bd.tcl and vsim_ops_adc_100m_bd.tcl, which are produced by
# the recipe export_bd_sims
#
# To summarize, this vsmake limitation means that all testbenches depend on
# export_bd_sims.
test: setup export_bd_sims
	vsmake --sync
	nisim --JUnitOutput

export_bd_sims: \
  $(IP_DIR)/adc_100m_bd/sim/compile_adc_100m_bd.tcl \
  $(IP_DIR)/dac_100m_bd/sim/compile_dac_100m_bd.tcl

$(IP_DIR)/adc_100m_bd/sim/compile_adc_100m_bd.tcl: $(IP_X4XX_ADC_100M_ORIG_SRCS) $(IP_X4XX_ADC_100M_HDL_SRCS)
	vivado -mode batch -source ./scripts/bd_sim_model.tcl -tclargs adc_100m_bd $(IP_DIR)

$(IP_DIR)/dac_100m_bd/sim/compile_dac_100m_bd.tcl: $(IP_X4XX_DAC_100M_ORIG_SRCS) $(IP_X4XX_DAC_100M_HDL_SRCS)
	vivado -mode batch -source ./scripts/bd_sim_model.tcl -tclargs dac_100m_bd $(IP_DIR)

setup:
	vsmake --CompileLibraries=all

#
# Copyright 2019 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later

# avoid checkout of gcc compilers by hwSetup
POSSIBLE_COMPILERS :=

# path to X400 code
X400_SOURCE_DIR = ../../../usrp3/top/x400

# linux style MODELSIM path
MODELSIM_PATH=$(subst \,/,$(MODELSIM))

.PHONY: test regmap setup ip cpld clean cpld_defaults cdc_report

# executed by pipeline for testing design
test: | ip cpld_defaults regmap setup
	vsmake
	nisim --JUnitOutput

# clean needed to ensure recompilation of verilog files using updated headers
regmap: modelsim_lib
	xmlparse --sync --norbm
	vsmake --clean

setup: modelsim_lib
	vsmake --CompileLibraries=all
	vsmake --sync

dev: modelsim_lib
	vsmake
	nisim

ip:
	make -C $(X400_SOURCE_DIR)/dboards/zr/cpld ip

cpld:
	make -C $(X400_SOURCE_DIR)/dboards/zr/cpld

clean:
	make -C $(X400_SOURCE_DIR)/dboards/zr/cpld clean
	vsmake --clean
	git clean -Xdf .

modelsim_lib: ../lib/mti_util_modified.vhd

../lib/mti_util_modified.vhd:
	mkdir -p ../lib
	sed s/default/default_renamed/g $(MODELSIM_PATH)/../vhdl_src/modelsim_lib/mti_util.vhd > ../lib/mti_util_modified.vhd

cpld_defaults:
	make -C $(X400_SOURCE_DIR)/dboards/zr/cpld cpld_defaults
	mkdir -p modelsim/register_endpoints/memory_init_files
	cp $(X400_SOURCE_DIR)/dboards/zr/cpld/register_endpoints/memory_init_files/*.hex modelsim/register_endpoints/memory_init_files/

cdc_report: ip
	make -C CdcRdc/Target/nicdc cdc_report

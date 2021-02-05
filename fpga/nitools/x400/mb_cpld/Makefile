#
# Copyright 2019 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later

# avoid checkout of gcc compilers by hwSetup
POSSIBLE_COMPILERS :=

# path to X400 code
X400_SOURCE_DIR = ../../../usrp3/top/x400

.PHONY: test regmap setup ip cpld clean

# executed by pipeline for testing design
test: | ip regmap setup
	vsmake
	nisim --JUnitOutput

# clean needed to ensure recompilation of verilog files using updated headers
regmap:
	xmlparse --sync --norbm
	vsmake --clean

setup:
	vsmake --CompileLibraries=all
	vsmake --sync

ip: netlist
	make -C $(X400_SOURCE_DIR)/cpld ip

cpld:
	make -C $(X400_SOURCE_DIR)/cpld

clean:
	make -C $(X400_SOURCE_DIR)/cpld clean
	vsmake --clean
	git clean -Xdf .

cdc_report: ip
	make -C CdcRdc/Target/nicdc cdc_report

NUGET_VERSION = 1.0.0-d20120222
NUGET_PATH = nuget/UsrpHw4.X4xx.CMI.$(NUGET_VERSION)/content

# Use just last file touched from netlist instructions below to guarantee up to
# date files.
NETLIST_TARGETS = modelsim/PcieCmiEncryptedVhdl.vhdp
netlist: ${NETLIST_TARGETS}

# - install nuget from scratch
# - move files needed for synthesis to target directory to make sure changes are
#   detected by git status
${NETLIST_TARGETS}: ./Makefile
	rm -rf nuget
	nuget install UsrpHw4.X4xx.CMI -Version $(NUGET_VERSION) \
	  -Source http://ninugetsvr.amer.corp.natinst.com/nuget/packages/ \
	  -OutputDirectory nuget -NoCache
	cp $(NUGET_PATH)/PcieCmi.qxp $(X400_SOURCE_DIR)/cpld/ip/cmi
	python3 replace_HDL_header.py -i $(NUGET_PATH)/PcieCmi.vhd \
		-o $(X400_SOURCE_DIR)/cpld/ip/cmi/PcieCmi.vhd
	python3 replace_HDL_header.py -i $(NUGET_PATH)/PcieCmiWrapper.vhd \
	  -o  $(X400_SOURCE_DIR)/cpld/ip/cmi/PcieCmiWrapper.vhd
	mkdir -p modelsim
	cp $(NUGET_PATH)/PcieCmiEncryptedVhdl.vhdp modelsim/

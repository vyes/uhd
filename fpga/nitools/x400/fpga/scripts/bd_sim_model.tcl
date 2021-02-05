#
# Copyright 2020 Ettus Research, A National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Module: bd_sim_model.tcl
# Description:
# This tcl script can be passed to Vivado to generate a simulation model for
# most Block Designs. The name of the block design must be passed as the first
# parameter. Sample syntax:
#
# vivado -mode batch -source ./sim/bd_sim_model.tcl -tclargs adc_100m_bd ../ip

set bdName [lindex $argv 0]
set ipDir  [lindex $argv 1]
niBdOpenDesign -part xczu28dr-ffvg1517-1-e -userScript ${ipDir}/${bdName}/hdl_sources.tcl -bdName $bdName -sourceDir ${ipDir}/${bdName}
niBdExport -simHdl -stub
niBdClose
exit


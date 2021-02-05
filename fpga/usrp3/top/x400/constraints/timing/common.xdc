#
# Copyright 2019 Ettus Research, A National Instruments Brand
# SPDX-License-Identifier: LGPL-3.0
#

#*******************************************************************************
## Motherboard Clocks

# TODO: Uncomment this section when using ports in top-level.
# 10/25 MHz reference clock from rear panel connector. Constrain to the fastest
# possible clock rate.
set ref_clk_period 40.00
create_clock -name ref_clk       -period $ref_clk_period     [get_ports BASE_REFCLK_FPGA_P]
# 20M WR Reference for DDMTD
# create_clock -name wr_ddmtd      -period 50.000              [get_ports WR_20M_REF]
# Base Reference for Data Clock
set pll_ref_clk_period 15.625
create_clock -name pll_ref_clk     -period $pll_ref_clk_period [get_ports PLL_REFCLK_FPGA_P]
# MGT 10 GbE Clocks
create_clock -name mgt_ref_0       -period  6.400              [get_ports MGT_REFCLK_LMK_P[0]]
create_clock -name mgt_ref_3       -period  6.400              [get_ports MGT_REFCLK_LMK_P[3]]
# PCIe Clocks
# create_clock -name mgt_ref_1     -period  8.000              [get_ports MGT_REFCLK_LMK_P[1]]
# create_clock -name mgt_ref_2     -period  6.400              [get_ports MGT_REFCLK_LMK_P[2]]

#*******************************************************************************
## Aliases for auto-generated clocks

# Name the PS clocks. These are originally declared in the PS8 IP block.
# Create the clocks based on the PS PLCLK pins.
# This generates critical warnings in the OSS flow because the clocks were already
# define and we are completely rewriting the old clock definition... this is OK.
create_clock -name clk100 -period 10.000 \
  [get_pins -of_objects [get_cells -hierarchical {*PS8_i}] -filter {NAME =~ *PLCLK[0]}]

create_clock -name clk40  -period 25.000 \
  [get_pins -of_objects [get_cells -hierarchical {*PS8_i}] -filter {NAME =~ *PLCLK[1]}]

create_clock -name clk166 -period  6.000 \
  [get_pins -of_objects [get_cells -hierarchical {*PS8_i}] -filter {NAME =~ *PLCLK[2]}]

create_clock -name clk200 -period  5.000 \
  [get_pins -of_objects [get_cells -hierarchical {*PS8_i}] -filter {NAME =~ *PLCLK[3]}]

#*******************************************************************************
## Sync to DB synthesizer sync CPLD input
#
# synth_sync_hold_requirement and synth_sync_setup_requirement are shared
# between the FPGA and DB CPLD. The values are set in
# shared_constants.sdc
set synth_sync_ports [get_ports {DB0_SYNTH_SYNC DB1_SYNTH_SYNC}]
set_output_delay -clock [get_clocks pll_ref_clk] -min -$synth_sync_hold_requirement $synth_sync_ports
set_output_delay -clock [get_clocks pll_ref_clk] -max $synth_sync_setup_requirement $synth_sync_ports

#*******************************************************************************
## SPI to MB CPLD (PL)
# This interface is defined as system synchronous to pll_ref_clk.

# The output delays are choosen to allow a large time window of valid data
# for the MB CPLD logic.
set spi_min_out_delay  0.000
set spi_max_out_delay 11.000

# set output constraints for all ports
set spi_out_ports [get_ports {PL_CPLD_SCLK PL_CPLD_MOSI PL_CPLD_CS0_n PL_CPLD_CS1_n}]
set_output_delay -clock [get_clocks pll_ref_clk] -min $spi_min_out_delay $spi_out_ports
set_output_delay -clock [get_clocks pll_ref_clk] -max $spi_max_out_delay $spi_out_ports

# CPLD and FPGA both use PLL reference clock from a common clock chip.
# The traces from that clock chip to the ICs are not length matched
# Assume a worst case clock difference of 0.5 ns at the IC inputs.
# There is no direction defined. The clock can arrive faster or slower
# on one IC.
set pl_clock_diff 0.500

# The longest trace on the PL SPI interface is (sssuming 170.0 ps/in)
#   Longest trace | Trace length | Trace delay
#   PL_CPLD_MISO  |   3.863 in   |   0.657 ns
set pl_spi_board_delay 0.657

# Output delay timings of the MB CPLD design, which still meet timing
set pl_spi_cpld_min_out -1.000
set pl_spi_cpld_max_out  8.000

set spi_in_port [get_ports {PL_CPLD_MISO}]
set_input_delay -clock [get_clocks pll_ref_clk] \
  -min [expr {- $pl_spi_cpld_min_out - $pl_clock_diff}] \
  $spi_in_port
set_input_delay -clock [get_clocks pll_ref_clk] \
  -max [expr {$pll_ref_clk_period - $pl_spi_cpld_max_out + $pl_spi_board_delay + $pl_clock_diff}] \
  $spi_in_port


#*******************************************************************************
## 10 GbE

# These are the exceptions from "xge_pcs_pma_exceptions.xdc" which are to be
# used when not using the example design.
#
# "clk100" used here is the clock that's connected to the "dclk" input in the core.
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks clk100] -datapath_only 6.40
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks clk100] -datapath_only 6.40
set_max_delay -from [get_clocks clk100] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10.000
set_max_delay -from [get_clocks clk100] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10.000
# Double synchronizer false paths
set_false_path -to [get_pins -hierarchical -filter {NAME =~ */ten_gige_phy_i/*reset_done_ms_reg/D}]


#*******************************************************************************
## Misc Constraints

# Double synchronizer false paths
set_false_path -to [get_pins -hierarchical -filter {NAME =~ */synchronizer_false_path/stages[0].value_reg[0][*]/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ */rf_reset_controller*/*_ms_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ */rfdc/rf_nco_reset_0/*_ms*/D}]

# MMCM IP is not setting false paths for all asynchronous reset paths.
# Xilinx SR number: 10481720 (TODO: pending Xilinx confirmation)
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *data_clock_mmcm/inst/CLK_CORE_DRP_I/*/seq_reg*_reg[*]/CLR}]

# We treat these buffers as asynchronous, with knowledge that code clocked in this domain will be reset after
# this clocked is enabled. This will make timing easier to meet on these clock domains.
set_false_path -from [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*rEnableRfdcBufg1x*}]      \
               -to	 [get_pins -hierarchical -filter {NAME =~ */rfdc/rf_clock_buffers/rfdc_clk_1x_buf/*BUFGCE*/CE}]

set_false_path -from [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*rEnableRfdcBufg2x**}]      \
               -to	 [get_pins -hierarchical -filter {NAME =~ */rfdc/rf_clock_buffers/rfdc_clk_2x_buf/*BUFGCE*/CE}]

set_false_path -from [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*rEnableDataBufg1x*}]      \
               -to	 [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*DataClk1xSafeBufg/CE}]

set_false_path -from [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*rEnableDataBufg2x*}]      \
               -to	 [get_pins -hierarchical -filter {NAME =~ */rfdc/clock_gates_0/*DataClk2xSafeBufg/CE}]

# GTY_RCV_CLK_* is driven by a OBUFDS_GTE4 buffer, which has an asynchronous clock-enable pin.
# By experimentation, it was observed that explicitly setting a false_path to this pin improved timing.
set gty_rcv_clk_buff_ceb [get_pins -of_objects [get_cells -of_objects [all_fanin -flat -startpoints_only [get_ports {GTY_RCV_CLK_P}]]] -filter {NAME=~ "*CEB"}]
set_false_path -from [get_clocks {clk40}] -through $gty_rcv_clk_buff_ceb

#*******************************************************************************
## DIO
# Those GPIO pins are considered asynchronous paths. The user has to add
# constraints in case required. Therefore not setting false_paths from / to user
# logic to allow user generated timing constraints to be applied.

# Ignore paths from "slow" PS interface to not interfere with user constraints.
set dio_ports     [get_ports {DIOA_FPGA[*] DIOB_FPGA[*]}]
set dio_registers [get_cells -hierarchical -filter {NAME =~ *x4xx_dio_i* && IS_SEQUENTIAL && IS_PRIMITIVE}]
set_false_path -from $dio_registers -to $dio_ports
set_false_path -from $dio_ports     -to $dio_registers

#*******************************************************************************
## PPS

# The TRIG_IO port may be driven by either the PPS in BRC domain to
# enable direct sync between 2 devices, or by any other user logic.
# When PPS is exported through Trigger I/O, timing must be analyzed
# to ensure determinism in the PPS exporting.
# But, when other user logic drives TRIG_IO, then the port should be
# treated as asynchronous (or close to async at least).
# To achieve this conditional timing analysis, the following trick is
# used:
#   1. A virtual copy of ref_clk is created for I/O timing - virtual_ref_clk
#   2. Set output_delay constraints to assign a clock to the TRIG_IO port.
#   3. A set_max_delay constraint is used to time the output path to TRIG_IO
#        set_max_delay makes the timing constraint driver agnostic, and as long
#        as the critical output delay is met for driving PPS through TRIG_IO, we
#        should be fine as this requirement is relatively loose.

# 1)
# Creating copy of ref_clk to only analyze timing to TRIG_IO port (output)
# when output is driven by ref_clk (PPS generation in ref_clk domain).
create_clock -name virtual_ref_clk -period $ref_clk_period

# Trigger IO port is used as output for the PPS signal
# TRIG_IO_1V8 trace length MB = 4.050 + 1.190 inch = 5.240 inch
# TRIG_IO_1V8 trace length DB = 2.401 + 0.120 + 0.457 + 0.261 inch = 3.239 inch
# TRIG_IO buffer max switching time = 3.3
set trig_max_out_delay [expr {8.479 * 0.17 + 3.3}]
# Set minimum output delay hold time to a small amount to grant external devices
# some hold time. Delay should be simple to achieve as there is no PLL in the
# clocking path and some combinatorial logic.
set trig_min_out_delay 2.000

# 2)
# set_output_delay for assigning clocks to TRIG_IO. Use zero for delay to avoid
# adding extra delay requirements on top of the set_max|min_delay constraints below.
set_output_delay -clock [get_clocks virtual_ref_clk] 0.0 [get_ports {TRIG_IO}]

# 3)
# Min and max delays make constraining driver agnostic. We just make sure the critical
# timing for PPS export is met though.
set_max_delay -through [get_port {TRIG_IO}] -to [get_clocks {virtual_ref_clk}] \
  [expr {$ref_clk_period - $trig_max_out_delay}]
set_min_delay -through [get_port {TRIG_IO}] -to [get_clocks {virtual_ref_clk}] \
  $trig_min_out_delay

# Treat TRIG_IO input as asynchronous.
set_false_path -from [get_ports {TRIG_IO}]
# But, for documentation purposes, these are the input max/min delays for TRIG_IO:
#   - Input delay assuming zero trace delay and TRIG_IO buffer min switching time (B->A) = 0.1 ns
#   - TRIG_IO buffer max switching time (B->A = input) = 3.7 ns + same trace length as for output (8.479)

# assuming no delay on external clock distribution
# account for the PPS min output delay only (for the case two X410 are directly connected
# to each other)
set pps_min_in_delay $trig_min_out_delay
# PPS_IN trace length DB = 0.535 + 0.133 + 0.117 + 0.061 + 2.745 inch = 3.591 inch
# PPS_IN trace length MB = 5.726 inch
# PPS switch max propagation delay = 3.6
# assume 50% of the clock period is used for external PPS clock distribution
# as the PPS out is used to synchronize one X410 (master) with another X410 (slave)
# the PPS out (trig_io) delay is added to the PPS input
set pps_max_in_delay [expr {9.317 * 0.17 + 3.6 + 0.5 * $ref_clk_period + $trig_max_out_delay}]
# apply PPS input constraints
set_input_delay -clock [get_clocks ref_clk] -min $pps_min_in_delay [get_ports {PPS_IN}]
set_input_delay -clock [get_clocks ref_clk] -max $pps_max_in_delay [get_ports {PPS_IN}]

# the PPS LED should be updated within a clock cycle
set pps_led_skew [expr {$ref_clk_period / 4}]
set_output_delay -clock [get_clocks ref_clk] -max -$pps_led_skew [get_ports {PPS_LED}]
set_output_delay -clock [get_clocks ref_clk] -min  $pps_led_skew [get_ports {PPS_LED}]
set_multicycle_path -setup -to [get_ports {PPS_LED}] -start 0
set_multicycle_path -hold  -to [get_ports {PPS_LED}] -1

# PPS clock domain crossing BRC -> PRC on the aligned edge
# use a data path of half PLL reference clock period to make sure the value is
# captured without metastability
set_max_delay -from [get_cells -hierarchical pps_delayed_brc_reg] \
  -to [get_clocks pll_ref_clk*] [expr {$pll_ref_clk_period/2}]

#*******************************************************************************
## LMK sync
# The timings are derived by simulation.

#  Clock Buffer ADCLK944 -> FPGA
set buffer_to_fpga_min_clk_delay 0.997
set buffer_to_fpga_max_clk_delay 1.154

# Clock Buffer ADCLK944  -> Sample clock PLL (LMK04832)
set buffer_to_spll_min_clk_delay 0.000
set buffer_to_spll_max_clk_delay 0.014

# FPGA -> Sample clock PLL SYNC input
set fpga_to_spll_min_clk_delay   0.381
set fpga_to_spll_max_clk_delay   0.460

# Sample clock PLL requirements
set lmk_sync_input_hold          4.000
set lmk_sync_input_setup         4.000

set lmk_sync_output_max_delay [expr {$fpga_to_spll_max_clk_delay + $buffer_to_fpga_max_clk_delay + \
                                $lmk_sync_input_setup - $buffer_to_spll_min_clk_delay}]
set lmk_sync_output_min_delay [expr {$fpga_to_spll_min_clk_delay + $buffer_to_fpga_min_clk_delay - \
                                $buffer_to_spll_max_clk_delay - $lmk_sync_input_hold}]
set_output_delay -clock ref_clk -max $lmk_sync_output_max_delay [get_ports {LMK_SYNC}]
set_output_delay -clock ref_clk -min $lmk_sync_output_min_delay [get_ports {LMK_SYNC}]

#*******************************************************************************
## DB GPIO
# This interface is defined as system synchronous to pll_ref_clk.
# Some timing constants in this section are declared in
# fpga/usrp3/top/x400/constraints/timing/shared_constants.sdc

# set output constraints for all ports
set db_gpio_ports [get_ports {DB0_GPIO[*] DB1_GPIO[*]}]
set_output_delay -clock [get_clocks pll_ref_clk] -min $db_gpio_fpga_min_out $db_gpio_ports
set_output_delay -clock [get_clocks pll_ref_clk] -max $db_gpio_fpga_max_out $db_gpio_ports

# output enable signal is available one clock cycle ahead of valid data
# this enables the use of multicycle paths
set db_gpio_out_en_regs [get_cells -hierarchical -filter \
  {PRIMITIVE_TYPE =~ REGISTER.*.* && NAME =~ "*bytestream_output_enable*"}]
set_multicycle_path 2 -setup -from $db_gpio_out_en_regs -to $db_gpio_ports
set_multicycle_path 1 -hold  -from $db_gpio_out_en_regs -to $db_gpio_ports

# calculate output delays back from capturing edge, add board delay and clock difference
# Assume worst case as data being generated late and receiving an early clock:
#  - Max CPLD TCO
#  - Max data propagation delay
#  - Max CPLD clock propagation delay and minimum FPGA clock propagation delay
#  - Maximum delay from MC100EPT23 clock buffer
set_input_delay -clock pll_ref_clk \
  -max [expr {$pll_ref_clk_period - $db_gpio_cpld_max_out + $db_gpio_board_max_delay \
              + $db_cpld_prc_clock_prop_max - $fpga_prc_clock_prop_min + $clock_translate_max}] \
  $db_gpio_ports

# Negate minimum output delay as it is defined from the change to the start clock edge.
# Assume worst case as data being generated early and receiving an late clock:
#  - Min CPLD TCO
#  - Min data propagation delay (0)
#  - Min CPLD clock propagation delay and max FPGA clock propagation delay
set_input_delay -clock pll_ref_clk \
  -min [expr {- $db_gpio_cpld_min_out                                    \
              - $db_gpio_board_min_delay                                 \
              - $db_cpld_prc_clock_prop_min + $fpga_prc_clock_prop_max}] \
  $db_gpio_ports

#*******************************************************************************
## x4xx_ps_rfdc_bd false paths
# The calibration_muxes component contains a clock crossing from some GPIO
# component instances that are synchronous to a configuration clock and ending
# in some AXI registers synchronous the data clock. The GPIO registers are
# essentially constant. When they are changing (due to a register write), the
# latching registers can definitely become metastable, so the software must
# ensure that the corrupted data appears at a safe time.
#
set gpio_regs [get_pins -of [get_cells -filter {IS_SEQUENTIAL && NAME =~ *rfdc/calibration_muxes/axi_gpio*} -hier] -filter {IS_CLOCK}]
set mux_regs [get_cells -hier -filter {IS_SEQUENTIAL && NAME =~ *rfdc/calibration_muxes/gpio_to_axis_mux*}]
set_false_path -from $gpio_regs -to $mux_regs

# This property tells Vivado that we require these clocks to be well aligned.
# We have synchronous clock domain crossings between these clocks that can have
# large hold violations after placement due to uneven clock loading.
set_property CLOCK_DELAY_GROUP DataClkGroup [get_nets -hier -filter {\
  NAME=~*/rfdc/data_clock_mmcm/inst/CLK_CORE_DRP_I/clk_inst/data_clk        ||\
  NAME=~*/rfdc/data_clock_mmcm/inst/CLK_CORE_DRP_I/clk_inst/data_clk_2x     ||\
  NAME=~*/rfdc/data_clock_mmcm/inst/CLK_CORE_DRP_I/clk_inst/pll_ref_clk_out ||\
  NAME=~*/rfdc/data_clock_mmcm/inst/CLK_CORE_DRP_I/clk_inst/rfdc_clk_2x     ||\
  NAME=~*/rfdc/data_clock_mmcm/inst/CLK_CORE_DRP_I/clk_inst/rfdc_clk \
}]

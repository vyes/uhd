###############################################################################
# CDC Message Exceptions
###############################################################################

msg report item -status verified -id hcdc-2 \
    -owner WadeFife \
    -arg port=*.clk \
    -comment "Many of the interface clocks are connected but not used because \
              they are duplicated in other interfaces. Ignore warnings about \
              interface clocks that weren't inferred but are connected."

msg report item -status verified -id hcdc-76 \
  -owner WadeFife \
  -comment "Many ports have constant inputs. Ignore all of these."

msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=adc_400m_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=axi_eth_dma_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=axi_interconnect_app_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=axi_interconnect_dma_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=axi_interconnect_eth_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=complex_multiplier_dds \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=dac_400m_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=dds_sin_cos_lut_only \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=axi_hb47 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=hb47_1to2 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=hb47_2to1 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=hbdec1 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=hbdec2 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=hbdec3 \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=x4xx_ps_rfdc_bd \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."
msg report item -status verified -id parser-47 \
  -owner WadeFife \
  -arg module=xge_pcs_pma_common_wrapper \
  -comment "Ignore unresolved module warnings for IP that has an HDM defined."

# I tried to filter this more to just vopt-2672 (unresolved module) and 
# vopt-2241 (port-width mismatches) but every arg filter I tried didn't work.
msg report item -status verified -id parser-285 \
  -owner WadeFife \
  -comment "Ignore vopt warnings about unresolved modules and port-width \
            mismatches."

msg report item -status verified -id hcdc-8 \
  -owner WadeFife \
  -arg port=x4xx_core_i.x4xx_core_common_i.x4xx_dio_i.synchronizer_dio.in \
  -comment "Questa sees the tristate driving the DIO*_FPGA I/O as \
            combinatorial logic and flags it as a violation of the no-combo \
            assumption for the input of the double synchronizer."

msg report item -status verified -id parser-3 \
  -owner WadeFife \
  -arg module=axi_fifo_flop \
  -comment "Several modules in the OSS library do not use all port connects. \
            This is legal in Verilog, but is flagged by Questa."
msg report item -status verified -id parser-3 \
  -owner WadeFife \
  -arg module=dds_freq_tune \
  -comment "Several modules in the OSS library do not use all port connects. \
            This is legal in Verilog, but is flagged by Questa."
msg report item -status verified -id parser-3 \
  -owner WadeFife \
  -arg module=join_complex \
  -comment "Several modules in the OSS library do not use all port connects. \
            This is legal in Verilog, but is flagged by Questa."
msg report item -status verified -id parser-3 \
  -owner WadeFife \
  -arg module=cam_priority_encoder \
  -comment "Several modules in the OSS library do not use all port connects. \
            This is legal in Verilog, but is flagged by Questa."
msg report item -status verified -id parser-3 \
  -owner WadeFife \
  -arg module=split_complex \
  -comment "Several modules in the OSS library do not use all port connects. \
            This is legal in Verilog, but is flagged by Questa."

msg report item -status verified -id parser-275 \
  -owner WadeFife \
  -arg file=*axi4s_add_bytes.sv*  \
  -comment "Ignore warnings about unsupported initial statements."
msg report item -status verified -id parser-275 \
  -owner WadeFife \
  -arg file=*axi4s_width_conv.sv*  \
  -comment "Ignore warnings about unsupported initial statements."
msg report item -status verified -id parser-275 \
  -owner WadeFife \
  -arg file=*ram_2port_impl.vh*  \
  -comment "Ignore warnings about unsupported initial statements."

msg report item -status verified -id elaboration-215 \
  -owner WadeFife \
  -arg module=mult  \
  -comment "Questa warns about out-of-bounds array index in mult.v, but this is
            a proven library component and this is legal in Verilog."

msg report item -status verified -id elaboration-215 \
  -owner WadeFife \
  -arg module=axis_data_swap  \
  -comment "Questa warns about out-of-bounds array index in axis_data_swap.v.
            This is legal in Verilog, but the out-of-bounds value will not be
            used anyway due to the conditions in the assignment. Also, this is
            a proven library component."

msg report item -status verified -id elaboration-549 \
  -owner WadeFife \
  -arg file=*ram_2port_impl.vh* \
  -comment "Questa warns about multiple always blocks driving a RAM. This is \
            known-good library component and this construct is supported by \
            the Xilinx tools."

msg report item -status verified -id parser-275 \
  -owner WadeFife \
  -arg file=*synchronizer_impl.v* \
  -comment "Questa warns about unsupported initial statement, but this is a \
            known-good component and this shouldn't affect CDC analysis."

msg report item -status verified -id reset-2 \
  -owner WadeFife \
  -arg signal=x4xx_ps_rfdc_bd_i.pl_resetn0 \
  -comment "Questa sees the reset_sync core as having a synchronous reset \
            input, but the x4xx_qsfp_wrapper as having an asynchronous reset \
            input and warns about this sync/async conflict. The connection of \
            pl_resetn0 to reset_sync are OK so we can ignore this warning."

msg report item -status verified -id hdl-241 \
  -owner WadeFife \
  -comment "Questa warns about inferred clocks. The inferred clocks are \
            part IP outputs and described by HDM. This is expected and the \
            Questa CDC manual says no resolution is needed in this case."

msg report item -status verified -id netlist-82 \
  -owner WadeFife \
  -comment "Questa warns about reset ports not driven by a primary input. \
            These are expected, as some resets are software controlled."


###############################################################################
# CDC Exceptions
###############################################################################

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from ADC_CLK_* -to x4xx_ps_rfdc_bd_i.adc* \
    -message "The ADC signals are described as asynchronous because they \
              go into a black box (Xilinx IP). Ignore them for CDC purposes. \
              {ExpectedCount = 4}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from DAC_CLK_* -to x4xx_ps_rfdc_bd_i.dac* \
    -message "The DAC signals are described as asynchronous because they \
              go into a black box (Xilinx IP). Ignore them for CDC purposes.
              {ExpectedCount = 4}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from DB*_RX_* -to x4xx_ps_rfdc_bd_i.adc_tile* \
    -message "The ADC signals are described as asynchronous because they \
              are connected to a black box (IP). Ignore them for CDC purposes. \
              {ExpectedCount = 8}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from x4xx_ps_rfdc_bd_i.dac_tile* -to DB*_TX_* \
    -message "The DAC signals are described as asynchronous because they \
              are connected to a black box (IP). Ignore them for CDC purposes. \
              {ExpectedCount = 8}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync \
    -from QSFP*_RX_* \
    -to x4xx_qsfp_wrapper_*.x4xx_qsfp_wrapper_i.mgt_lanes.lane_loop* \
    -message "The high-speed serial signals for the QSFP are described as \
              asynchronous because they are connected to a black box (IP). \
              Ignore them for CDC purposes. {ExpectedCount = 32}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync \
    -from x4xx_qsfp_wrapper_*.x4xx_qsfp_wrapper_i.mgt_lanes.lane_loop*.x4xx_mgt_io_core_i.tx_* \
    -to QSFP*_*_TX_* \
    -message "The high-speed serial signals for the QSFP are described as \
              asynchronous because they are connected to a black box (IP). \
              Ignore them for CDC purposes. {ExpectedCount = 8}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from QSFP*_MODPRS_n -to x4xx_ps_rfdc_bd_i.gpio_0_tri_i* \
    -message "QSFP MODPRS# signal is sent and received asynchronously using \
              GPIO. {ExpectedCount = 2}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from SYSREF_FABRIC_* -to x4xx_ps_rfdc_bd_i.sysref_pl_in \
    -message "SYSREF_FABRIC goes into a black box (BD) where it gets double \
              synchronized in the module capture_sysref. {ExpectedCount = 1}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from SYSREF_RF_* -to x4xx_ps_rfdc_bd_i.sysref_rf_in_diff_* \
    -message "SYSREF_RF goes directly into the SYSREF RFDC input.
              {ExpectedCount = 2}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync -from x4xx_pps_sync_i.pps_brc -to x4xx_ps_rfdc_bd_i.gpio_0_tri_i* \
    -message "PPS, in base_ref_clk domain, gets passed to PS GPIO. This is OK.
              {ExpectedCount = 1}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync \
    -from x4xx_qsfp_wrapper_0.x4xx_qsfp_wrapper_i.mgt_lanes.lane_loop*.eth_*_irq \
    -to x4xx_ps_rfdc_bd_i.pl_ps_irq* \
    -message "Ethernet IRQ registers are connected to PS IRQ. This is OK.\
              {ExpectedCount = 8}"

cdc report item -status verified -owner WadeFife \
    -scheme no_sync \
    -from x4xx_qsfp_wrapper_*.x4xx_qsfp_wrapper_i.mgt_lanes.lane_loop*.x4xx_mgt_io_core_i.link_up \
    -to x4xx_ps_rfdc_bd_i.gpio_0_tri_i* \
    -message "Ethernet link status registers are connected to PS GPIO. \
              This is OK. {ExpectedCount = 8}"

cdc report item -status verified -owner WadeFife \
    -scheme multi_bits -regexp \
    -to "x4xx_qsfp_wrapper_.*\.eth_dispatch_i\.(my_mac.*|my_ip.*|my_udp_chdr_port.*|my_pause_set.*|my_pause_clear.*)" \
    -message "MAC/IP/UDP registers are configured once before the port is \
              brought up and never changed at run time. Because they are \
              static, they are synchronized in a bit-wise manner. \
              {ExpectedCount = 52}"

cdc report item -status verified -owner WadeFife \
    -scheme port_combo_logic \
    -from x4xx_core_i.x4xx_core_common_i.x4xx_global_regs_i.trig_io_select_reg \
    -to TRIG_IO \
    -message "Questa sees combinational logic before a synchronizer. In this \
              case that combinational logic is actually the tristate, so this
              logic is expected. {ExpectedCount = 1}"

cdc report item -status verified -owner WadeFife \
    -scheme reconvergence \
    -from x4xx_core_i.rfnoc_image_core_i.*.flush_2clk_rb_i.genblk1.synchronizer_false_path.* \
    -message "Questa sees reconvergence issues from this double synchronizer, \
              but the bits going through this synchronizer do not need to be \
              correlated, so the reconvergence is OK. {ExpectedCount = 12}"

cdc report item -status verified -owner WadeFife \
    -scheme reconvergence \
    -from cpld_interface_i.qsfp_led_controller_i.synchronizer* \
    -to cpld_interface_i.qsfp_led_controller_i.transfer_in_progress \
    -message "Questa sees reconvergence issues from this double synchronizer, \
              but the bits going through this synchronizer do not need to be \
              correlated (they are LEDs), so the reconvergence is OK. \
              {ExpectedCount = 1}"

cdc report item -status verified -owner WadeFife \
    -scheme redundant \
    -from x4xx_ps_rfdc_bd_i.pl_resetn0 \
    -to reset*.reset_double_sync.genblk1.synchronizer_false_path.value* \
    -message "Questa sees the reset getting synchronized to two related clock \
              domains and flags this as redundant. While this is technically \
              true, it makes sense to synchronize the signal to both clock \
              domains rather than crossing it between related but different \
              clock domains. {ExpectedCount = 2}"

cdc report item -status verified -owner WadeFife \
    -scheme port_sync \
    -message "Questa flags asynchronous outputs because they require a \
              synchronizer outside of the design. All these signals are \
              correctly used on the PCB outside the FPGA.
              {ExpectedCount = 3}"

cdc report item -status verified -owner WadeFife \
    -scheme shift_reg \
    -to *synchronizer_false_path.value* \
    -message "Questa reports all synchronizers based on shift registers in \
              case you want to evaluate them. The OSS synchronizer uses a \
              shift register, so these all get reported. These messages can \
              be safely ignored. {ExpectedCount = 91}"

# x4xx_pps_sync exceptions
cdc report item -status verified -owner WadeFife \
    -scheme reconvergence_bus \
    -from x4xx_pps_sync_i.*.synchronizer_false_path.value* \
    -to x4xx_pps_sync_i.pps_delayed_*rc \
    -message "Questa finds reconvergent synchronizer logic in x4xx_pps_inc, \
              which is accurate. This code has been reviewed, tested, and \
              validated as is. Attempting to remove the reconvergent logic \
              poses a greater risk than leaving it as is. \
              {ExpectedCount = 2}"
cdc report item -status verified -owner WadeFife \
    -scheme reconvergence_mixed \
    -from x4xx_pps_sync_i.*.synchronizer_false_path.value* \
    -to x4xx_pps_sync_i.pps_out_rc \
    -message "Questa finds reconvergent synchronizer logic in x4xx_pps_inc \
              driving pps_out_rc. This code has been reviewed, tested, and \
              validated as is. Attempting to remove the reconvergent logic \
              poses a greater risk than leaving as is. \
              {ExpectedCount = 1}"
cdc report item -status verified -owner WadeFife \
    -scheme reconvergence_mixed \
    -from x4xx_pps_sync_i.*.synchronizer_false_path.value* \
    -to x4xx_pps_sync_i.state \
    -message "Questa finds reconvergent synchronizer logic in x4xx_pps_inc, \
              driving x4xx_pps_sync_i.state. This code has been reviewed, tested, and \
              validated as is. Attempting to remove the reconvergent logic \
              poses a greater risk than leaving as is. \
              {ExpectedCount = 1}"
cdc report item -status verified -owner WadeFife \
    -scheme bus_shift_reg \
    -to x4xx_pps_sync_i.*.synchronizer_false_path.value* \
    -message "Questa finds bus shift-register synchronizer and asks us to \
              evaluate it. This is for the same synchronizers as above. \
              {ExpectedCount = 5}"


###############################################################################
# RDC Message Exceptions
###############################################################################

msg report item -status verified -id hrdc-3 \
  -owner WadeFife \
  -comment "Questa complains that a reset is connected to something that it did
            not detect as a reset at the block level. These are synchronous 
            resets and Questa apparently doesn't infer them as reset 
            automatically."

msg report item -status verified -id hrdc-4 \
  -owner WadeFife \
  -comment "Questa complains that a reset is connected to something that it did
            not detect as a reset at the block level. These are synchronous 
            resets and Questa apparently doesn't infer them as reset 
            automatically."


###############################################################################
# RDC Exceptions
###############################################################################

resetcheck report item -status verified -owner WadeFife \
    -scheme reset_dual_polarity -check \
    -message "Questa thinks the reset is used both active-high and active-low \
              but it appears that it doesn't see the inversion on the reset. \
              I have verified that the reset it says is active low is active \
              high."

resetcheck report item -status verified -owner WadeFife \
    -scheme reset_as_data -check \
    -message "Questa sees the reset used as data. Every instance of this is \
              where the reset is double-synchronized to another clock \
              domain."

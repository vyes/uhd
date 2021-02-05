# General Warnings

msg report item -status verified -id hcdc-76 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg signal=*req_handshake_inst.data_a* \
  -comment "(Warning)Top bits of clock-crossing data are unused {ExpectedCount = 3}"

msg report item -status verified -id hcdc-76 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg signal=pll_ref_clk_enable_sync_i.rst \
  -comment "(Warning)This synchronizer for this pll enable is always running,\
            hence we hard-code the rst to 0 {ExpectedCount = 1}"

msg report item -status verified -id hrdc-4 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg port=pll_ref_clk_enable_sync_i.rst \
  -comment "(Warning)Linked to the exception above(PLL enable synchronizer),\
            as we are specifying that the model requires a reset on the input\
            but are not providing one(instead hard-coding 0) {ExpectedCount = 1}"

msg report item -status verified -id hcdc-76 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg signal=*spi_slave_async.data_sync_inst.rst \
  -comment "(Warning)This synchronizer is always running, hence we hard-code the rst to 0\
            It's used to indicate the RefClk domain that a SPI transaction has been \
            completely received {ExpectedCount = 1}"

msg report item -status verified -id hrdc-4 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg port=*spi_slave_async.data_sync_inst.rst \
  -comment "(Warning)Linked to the exception above(SPI reception complete),\
            as we are specifying that the model requires a reset on the input\
            but are not providing one(instead hard-coding 0) {ExpectedCount = 1}"

msg report item -status verified -id elaboration-549 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -arg module=ram_2port_impl_auto* \
  -comment "(Warning)DualPort Ram implementation causes these warning to appear, as always block\
            target the same memory {ExpectedCount = 7}"

msg report item -status verified -id netlist-82 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)Internal resets are expected, as we derive resets in every clock\
            domain from the input reset {ExpectedCount = 1}"

msg report item -status verified -id elaboration-4 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)Black boxes inside flash IP simulation model {ExpectedCount = 3}"

msg report item -status verified -id parser-47 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)Unresolved models inside the Flash IP simulation models.\
            These directly match black-boxes above {ExpectedCount = 3}"

msg report item -status verified -id parser-285 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)These optimization warnings are caused by the simulation model for the\
            flash ip not having all signals connected {ExpectedCount = 9}"

msg report item -status verified -id parser-275 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)These accounts for tu initial block detected:\
            the initialization of ram models to match hardware {ExpectedCount = 1}"

msg report item -status verified -id netlist-44 \
  -owner Max-Köhler -reviewer Javier-Valenzuela \
  -comment "(Warning)Suppressing warning caused by not having a clk domain assigned to
            synchronizer input {ExpectedCount = 1}"

# Clock Crossing Exceptions
cdc report item -status verified -owner Max-Köhler -reviewer Javier-Valenzuela \
  -scheme multi_bits -to spi_slave_to_ctrlport_master_i.spi_slave_async.transmit_bits \
  -message "(Violation) There is a 8 sclk padding time that we use to ensure that any \
            ctrlport transactions will propagate and drive data_in way before it is needed. \
            This helps in being able to assert data_in_valid 5 clk domain clock cycles after the \
            falling edge of sclk, where transmit_word will be latched, making it so that the path \
            to transmit_bits has enough time to settle(2+ clk cycles) and act as synchronous to sclk\
            {ExpectedCount = 1}"

cdc report item -status verified -owner Max-Köhler -reviewer Javier-Valenzuela \
  -scheme multi_bits -from spi_slave_to_ctrlport_master_i.spi_slave_async.received_word \
  -to spi_slave_to_ctrlport_master_i.spi_slave_async.data_out \
  -message "(Violation) reception_complete_clk creates a logic cloud behind this flop that will be \
            safe when reception_complete_clk as the input to the flop will change synchronously to
            its time domain, and the input to this flop will not change until the next byte is received. \
            when received_word changes, even if the logic bubble behind this flop makes the flop \
            metastable, any bad data won't be propagated due to any distribution of the settled metastability \
            being gated by data_out_valid{ExpectedCount = 1}"

# Reset exceptions
resetcheck report item -status verified -owner Max-Köhler -reviewer Javier-Valenzuela \
  -scheme reset_dual_areset_sreset -reset ctrlport_rst_crc -check \
  -message "This exception is generated because the flash IP utilizes a synchronized reset\
            asynchronously. The synchronized version of the reset is used in the reconfiguration\
            engine. Even though this exceptions handles one Caution item, the expected count is\
            se to 0, as nicdc has an issue properly matching paths to static checks{ExpectedCount = 0}"

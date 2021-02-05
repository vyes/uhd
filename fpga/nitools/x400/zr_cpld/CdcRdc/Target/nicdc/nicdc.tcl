# Common root directories
set projectRoot "[file normalize ../../../../../..]"

# Files required for synthesis
set vlogFiles [list $projectRoot/usrp3/lib/fifo/axi_fifo_flop.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_timer.v \
                    $projectRoot/usrp3/top/x400/dboards/ctrlport_byte_serializer.v \
                    $projectRoot/usrp3/top/x400/dboards/db_gpio_interface.v \
                    $projectRoot/usrp3/top/x400/dboards/db_gpio_reordering.v \
                    $projectRoot/usrp3/lib/control/setting_reg.v \
                    $projectRoot/usrp3/lib/control/simple_spi_core_64bit.v \
                    $projectRoot/usrp3/top/x400/ctrlport_spi_master.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/osc/osc/simulation/submodules/altera_int_osc.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/osc/osc/simulation/osc.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/clkctrl/clkctrl/simulation/submodules/clkctrl_altclkctrl_0.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/clkctrl/clkctrl/simulation/clkctrl.v \
                    $projectRoot/usrp3/top/x400/dboards/ctrlport_byte_deserializer.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ctrlport_window.v \
                    $projectRoot/usrp3/lib/control/synchronizer_impl.v \
                    $projectRoot/usrp3/lib/control/synchronizer.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_combiner.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_splitter.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/atr_controller.v \
                    $projectRoot/usrp3/lib/control/ram_2port.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/led_control.v \
                    $projectRoot/usrp3/lib/wb_spi/rtl/verilog/spi_clgen.v \
                    $projectRoot/usrp3/lib/wb_spi/rtl/verilog/spi_shift.v \
                    $projectRoot/usrp3/lib/wb_spi/rtl/verilog/spi_top.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/lo_control.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/basic_regs.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/power_regs.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_avmm_csr_controller.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_util.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_avmm_data_controller.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/ip/flash/on_chip_flash/simulation/on_chip_flash.v \
                    $projectRoot/usrp3/top/x400/cpld/reconfig_engine.v \
                    $projectRoot/usrp3/top/x400/cpld/spi_slave.v \
                    $projectRoot/usrp3/top/x400/cpld/spi_slave_to_ctrlport_master.v \
                    $projectRoot/usrp3/lib/control/reset_sync.v \
                    $projectRoot/usrp3/lib/control/pulse_synchronizer.v \
                    $projectRoot/usrp3/lib/control/handshake.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_clk_cross.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/switch_control.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/register_endpoints/dsa_control.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/zr_cpld_core.v \
                    $projectRoot/usrp3/top/x400/dboards/zr/cpld/zr_top_cpld.v ]

netlist fpga -vendor altera -library quartus -version 20.1_pro

vlog -quiet $vlogFiles

do directives.tcl
do exceptions.tcl

# CDC
cdc run -d zr_top_cpld
cdc generate report cdc_detail.rpt

msg generate report msg.rpt

ni_check_cdc


# RDC
resetcheck run -d zr_top_cpld
resetcheck generate report rdc_detail.rpt

msg generate report msg.rpt

ni_check_rdc

ni_report_summary
# Cross your fingers

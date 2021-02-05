# Common root directories
set projectRoot "[file normalize ../../../../../..]"

set vlogFiles [list $projectRoot/usrp3/lib/control/setting_reg.v \
                    $projectRoot/usrp3/lib/control/simple_spi_core.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/pll/pll.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/clkctrl/clkctrl/simulation/submodules/clkctrl_altclkctrl_0.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/clkctrl/clkctrl/simulation/clkctrl.v \
                    $projectRoot/usrp3/top/x400/cpld/pwr_supply_clk_gen.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/oddr/oddr.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_splitter.v \
                    $projectRoot/usrp3/top/x400/cpld/pl_cpld_regs.v \
                    $projectRoot/usrp3/top/x400/cpld/ctrlport_to_jtag.v \
                    $projectRoot/usrp3/lib/rfnoc/utils/ctrlport_terminator.v \
                    $projectRoot/usrp3/top/x400/cpld/ps_cpld_regs.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_avmm_csr_controller.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_util.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash_avmm_data_controller.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/flash/on_chip_flash/simulation/submodules/altera_onchip_flash.v \
                    $projectRoot/usrp3/top/x400/cpld/ip/flash/on_chip_flash/simulation/on_chip_flash.v \
                    $projectRoot/usrp3/top/x400/cpld/reconfig_engine.v \
                    $projectRoot/usrp3/lib/control/synchronizer_impl.v \
                    $projectRoot/usrp3/lib/control/synchronizer.v \
                    $projectRoot/usrp3/lib/control/simple_spi_core_64bit.v \
                    $projectRoot/usrp3/top/x400/ctrlport_spi_master.v \
                    $projectRoot/usrp3/top/x400/cpld/reset_generator.v \
                    $projectRoot/usrp3/top/x400/cpld/spi_slave.v \
                    $projectRoot/usrp3/top/x400/cpld/spi_slave_to_ctrlport_master.v \
                    $projectRoot/usrp3/top/x400/cpld/ps_power_regs.v \
                    $projectRoot/usrp3/lib/control/pulse_synchronizer.v \
                    $projectRoot/usrp3/lib/control/handshake.v \
                    $projectRoot/usrp3/top/x400/cpld/mb_cpld.v ]


set vcomFiles [list $projectRoot/usrp3/lib/vivado_ipi/axi_bitq/bitq_fsm.vhd \
                    $projectRoot/usrp3/top/x400/cpld/ip/cmi/PcieCmiWrapper.vhd ]

netlist fpga -vendor altera -library quartus -version 20.1_pro

vcom -quiet -2008 -skipsynthoffregion $vcomFiles
vlog -quiet $vlogFiles

do directives.tcl
do exceptions.tcl

# CDC
cdc run -d mb_cpld
cdc generate report cdc_detail.rpt

ni_check_cdc


# # RDC
resetcheck run -d mb_cpld
resetcheck generate report rdc_detail.rpt

msg generate report msg.rpt

ni_check_rdc

ni_report_summary
# Cross your fingers

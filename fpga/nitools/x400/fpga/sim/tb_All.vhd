--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_All
-- Description:
--  Instantiates all fpga related testbenches

--synopsys translate_off
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;

entity tb_All is
end tb_All;

architecture test of tb_All is

begin

    process
    begin
        Verbosity.Set(error);
        wait;
    end process;

    --nisim --Batch --quiet

    --vhook_e tb_x4xx
    tb_x4xxx: entity work.tb_x4xx (test);

    --vhook_e tb_cpld_interface
    tb_cpld_interfacex: entity work.tb_cpld_interface (test);

    --vhook_e tb_x4xx_core_common
    tb_x4xx_core_commonx: entity work.tb_x4xx_core_common (test);

    --vhook_e tb_pps_sync
    tb_pps_syncx: entity work.tb_pps_sync (test);

    --vhook_e tb_adc_100m_bd_filter
    tb_adc_100m_bd_filterx: entity work.tb_adc_100m_bd_filter (test);

    --vhook_e tb_adc_100m_bd
    tb_adc_100m_bdx: entity work.tb_adc_100m_bd (test);

    --vhook_e tb_dac_100m_bd
    tb_dac_100m_bdx: entity work.tb_dac_100m_bd (test);

    --vhook_e tb_rf_nco_reset
    tb_rf_nco_resetx: entity work.tb_rf_nco_reset (RTL);

    --vhook_e tb_rf_reset_controller
    tb_rf_reset_controllerx: entity work.tb_rf_reset_controller (RTL);

    --vhook_e tb_adc_3_1_clk_converter
    tb_adc_3_1_clk_converterx: entity work.tb_adc_3_1_clk_converter (RTL);

    --vhook_e tb_dac_1_3_clk_converter
    tb_dac_1_3_clk_converterx: entity work.tb_dac_1_3_clk_converter (RTL);

    --vhook_e tb_dac_2_1_clk_converter
    tb_dac_2_1_clk_converterx: entity work.tb_dac_2_1_clk_converter (RTL);

    --vhook_e tb_dac_gearbox_6x8
    tb_dac_gearbox_6x8x: entity work.tb_dac_gearbox_6x8 (RTL);

    --vhook_e tb_simple_spi_core_64bit_wrapper
    tb_simple_spi_core_64bit_wrapperx: entity work.tb_simple_spi_core_64bit_wrapper (test);

    --vhook_e tb_axis_mux
    tb_axis_muxx: entity work.tb_axis_mux (test);

    --vhook_e tb_gpio_to_axis_mux
    tb_gpio_to_axis_muxx: entity work.tb_gpio_to_axis_mux (test);

    --vhook_e tb_clock_gates
    tb_clock_gatesx: entity work.tb_clock_gates (test);

end test;

--synopsys translate_on

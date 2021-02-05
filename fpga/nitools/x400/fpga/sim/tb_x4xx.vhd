--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_x4xx
-- Description:
--  Dummy testbench to let vsmake compile x4xx toplevel

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_x4xx is end tb_x4xx;

architecture test of tb_x4xx is

  --vhook_d x4xx
  component x4xx
    port (
      SYSREF_RF_P        : in  std_logic;
      SYSREF_RF_N        : in  std_logic;
      ADC_CLK_P          : in  std_logic_vector(3 downto 0);
      ADC_CLK_N          : in  std_logic_vector(3 downto 0);
      DAC_CLK_P          : in  std_logic_vector(1 downto 0);
      DAC_CLK_N          : in  std_logic_vector(1 downto 0);
      DB0_RX_P           : in  std_logic_vector(1 downto 0);
      DB0_RX_N           : in  std_logic_vector(1 downto 0);
      DB1_RX_P           : in  std_logic_vector(1 downto 0);
      DB1_RX_N           : in  std_logic_vector(1 downto 0);
      DB0_TX_P           : out std_logic_vector(1 downto 0);
      DB0_TX_N           : out std_logic_vector(1 downto 0);
      DB1_TX_P           : out std_logic_vector(1 downto 0);
      DB1_TX_N           : out std_logic_vector(1 downto 0);
      MGT_REFCLK_LMK_P   : in  std_logic_vector(3 downto 0);
      MGT_REFCLK_LMK_N   : in  std_logic_vector(3 downto 0);
      DB0_GPIO           : inout std_logic_vector(19 downto 0);
      DB0_SYNTH_SYNC     : out std_logic;
      DB1_GPIO           : inout std_logic_vector(19 downto 0);
      DB1_SYNTH_SYNC     : out std_logic;
      LMK_SYNC           : out std_logic;
      PPS_IN             : in  std_logic;
      PL_CPLD_SCLK       : out std_logic;
      PL_CPLD_MOSI       : out std_logic;
      PL_CPLD_MISO       : in  std_logic;
      FPGA_AUX_REF       : in  std_logic;
      FABRIC_CLK_OUT_P   : out std_logic;
      FABRIC_CLK_OUT_N   : out std_logic;
      PLL_REFCLK_FPGA_P  : in  std_logic;
      PLL_REFCLK_FPGA_N  : in  std_logic;
      BASE_REFCLK_FPGA_P : in  std_logic;
      BASE_REFCLK_FPGA_N : in  std_logic;
      SYSREF_FABRIC_P    : in  std_logic;
      SYSREF_FABRIC_N    : in  std_logic;
      QSFP0_MODPRS_n     : in  std_logic;
      QSFP0_RESET_n      : out std_logic;
      QSFP0_LPMODE_n     : out std_logic;
      QSFP1_MODPRS_n     : in  std_logic;
      QSFP1_RESET_n      : out std_logic;
      QSFP1_LPMODE_n     : out std_logic;
      DIOA_FPGA          : inout std_logic_vector(11 downto 0);
      DIOB_FPGA          : inout std_logic_vector(11 downto 0);
      CPLD_JTAG_OE_n     : out std_logic;
      PPS_LED            : out std_logic;
      TRIG_IO            : inout std_logic;
      PL_CPLD_JTAGEN     : out std_logic;
      PL_CPLD_CS0_n      : out std_logic;
      PL_CPLD_CS1_n      : out std_logic;
      FPGA_TEST          : out std_logic);
  end component;

begin
  main: process
  begin
    wait;
  end process;

end test;
--synopsys translate_on

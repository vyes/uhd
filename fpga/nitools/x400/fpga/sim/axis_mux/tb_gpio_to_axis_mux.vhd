---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_gpio_to_axis_mux.vhd
--
-- Purpose:
-- This tests gpio_to_axis_mux. Most of the testing work is done in
-- AxisMuxStimulus, which will produce random stimulus as long as the
-- clock keeps toggling. AxisMuxChecker monitors the outputs for correct
-- behavior.
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;

entity tb_gpio_to_axis_mux is
end entity tb_gpio_to_axis_mux;

architecture test of tb_gpio_to_axis_mux is

  constant kGpioWidth : natural := 32;
  constant kAxiWidth : natural := 256;

  --vhook_sigstart
  signal gpio: std_logic_vector(kGpioWidth-1 downto 0);
  signal m_axis_tdata_0: std_logic_vector(kAxiWidth-1 downto 0);
  signal m_axis_tdata_1: std_logic_vector(kAxiWidth-1 downto 0);
  signal m_axis_tdata_2: std_logic_vector(kAxiWidth-1 downto 0);
  signal m_axis_tdata_3: std_logic_vector(kAxiWidth-1 downto 0);
  signal m_axis_tvalid_0: std_logic;
  signal m_axis_tvalid_1: std_logic;
  signal m_axis_tvalid_2: std_logic;
  signal m_axis_tvalid_3: std_logic;
  signal mux_select: std_logic_vector(7 downto 0);
  signal s_axis_aclk: std_logic := '0';
  signal s_axis_tdata_0: std_logic_vector(kAxiWidth-1 downto 0);
  signal s_axis_tdata_1: std_logic_vector(kAxiWidth-1 downto 0);
  signal s_axis_tdata_2: std_logic_vector(kAxiWidth-1 downto 0);
  signal s_axis_tdata_3: std_logic_vector(kAxiWidth-1 downto 0);
  signal s_axis_tready_0: std_logic;
  signal s_axis_tready_1: std_logic;
  signal s_axis_tready_2: std_logic;
  signal s_axis_tready_3: std_logic;
  signal s_axis_tvalid_0: std_logic;
  signal s_axis_tvalid_1: std_logic;
  signal s_axis_tvalid_2: std_logic;
  signal s_axis_tvalid_3: std_logic;
  --vhook_sigend

  procedure ClkWait (n : natural := 1) is
  begin
    for i in 1 to n loop
      wait until rising_edge(s_axis_aclk);
    end loop;
  end procedure ClkWait;

  signal StopSim : boolean := false;

begin

  ClockDriver:
  s_axis_aclk <= not s_axis_aclk after 5 ns when not StopSim else '0';

  --vhook_e gpio_to_axis_mux DUT
  --vhook_a {._axis_.*_aclk} s_axis_aclk
  DUT: entity work.gpio_to_axis_mux (RTL)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio            => gpio,             --in  std_logic_vector(kGpioWidth-1:0)
      mux_select      => mux_select,       --in  std_logic_vector(7:0)
      s_axis_0_aclk   => s_axis_aclk,      --in  std_logic
      s_axis_tdata_0  => s_axis_tdata_0,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid_0 => s_axis_tvalid_0,  --in  std_logic
      s_axis_tready_0 => s_axis_tready_0,  --out std_logic
      m_axis_0_aclk   => s_axis_aclk,      --in  std_logic
      m_axis_tvalid_0 => m_axis_tvalid_0,  --out std_logic
      m_axis_tdata_0  => m_axis_tdata_0,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_1_aclk   => s_axis_aclk,      --in  std_logic
      s_axis_tdata_1  => s_axis_tdata_1,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid_1 => s_axis_tvalid_1,  --in  std_logic
      s_axis_tready_1 => s_axis_tready_1,  --out std_logic
      m_axis_1_aclk   => s_axis_aclk,      --in  std_logic
      m_axis_tvalid_1 => m_axis_tvalid_1,  --out std_logic
      m_axis_tdata_1  => m_axis_tdata_1,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_2_aclk   => s_axis_aclk,      --in  std_logic
      s_axis_tdata_2  => s_axis_tdata_2,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid_2 => s_axis_tvalid_2,  --in  std_logic
      s_axis_tready_2 => s_axis_tready_2,  --out std_logic
      m_axis_2_aclk   => s_axis_aclk,      --in  std_logic
      m_axis_tvalid_2 => m_axis_tvalid_2,  --out std_logic
      m_axis_tdata_2  => m_axis_tdata_2,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_3_aclk   => s_axis_aclk,      --in  std_logic
      s_axis_tdata_3  => s_axis_tdata_3,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid_3 => s_axis_tvalid_3,  --in  std_logic
      s_axis_tready_3 => s_axis_tready_3,  --out std_logic
      m_axis_3_aclk   => s_axis_aclk,      --in  std_logic
      m_axis_tvalid_3 => m_axis_tvalid_3,  --out std_logic
      m_axis_tdata_3  => m_axis_tdata_3);  --out std_logic_vector(kAxiWidth-1:0)

  TestControl: process is
  begin
    -- AxisMuxStimlusAndChecker will provide random stimulus and check expected
    -- behavior for as long as this process waits before stopping the clock.
    ClkWait(100);

    StopSim <= true;
    wait;
  end process TestControl;

  --vhook_e AxisMuxStimulus Stimulus0
  --vhook_a mux_select mux_select(0)
  --vhook_a gpio gpio
  --vhook_a s_axis_tdata s_axis_tdata_0
  --vhook_a s_axis_tvalid s_axis_tvalid_0
  Stimulus0: entity work.AxisMuxStimulus (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,             --out std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select(0),    --out std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_0,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid_0); --out std_logic

  --vhook_e AxisMuxStimulus Stimulus1
  --vhook_a mux_select mux_select(1)
  --vhook_a gpio open
  --vhook_a s_axis_tdata s_axis_tdata_1
  --vhook_a s_axis_tvalid s_axis_tvalid_1
  Stimulus1: entity work.AxisMuxStimulus (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => open,             --out std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select(1),    --out std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_1,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid_1); --out std_logic

  --vhook_e AxisMuxStimulus Stimulus2
  --vhook_a mux_select mux_select(4)
  --vhook_a gpio open
  --vhook_a s_axis_tdata s_axis_tdata_2
  --vhook_a s_axis_tvalid s_axis_tvalid_2
  Stimulus2: entity work.AxisMuxStimulus (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => open,             --out std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select(4),    --out std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_2,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid_2); --out std_logic

  --vhook_e AxisMuxStimulus Stimulus3
  --vhook_a mux_select mux_select(5)
  --vhook_a gpio open
  --vhook_a s_axis_tdata s_axis_tdata_3
  --vhook_a s_axis_tvalid s_axis_tvalid_3
  Stimulus3: entity work.AxisMuxStimulus (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => open,             --out std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select(5),    --out std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_3,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid_3); --out std_logic

  --vhook_e AxisMuxChecker Checker0
  --vhook_a m_axis_tdata m_axis_tdata_0
  --vhook_a m_axis_tvalid m_axis_tvalid_0
  --vhook_a mux_select mux_select(0)
  --vhook_a s_axis_tdata s_axis_tdata_0
  --vhook_a s_axis_tvalid s_axis_tvalid_0
  --vhook_a s_axis_tready s_axis_tready_0
  Checker0: entity work.AxisMuxChecker (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,             --in  std_logic_vector(kGpioWidth-1:0)
      m_axis_tdata  => m_axis_tdata_0,   --in  std_logic_vector(kAxiWidth-1:0)
      m_axis_tvalid => m_axis_tvalid_0,  --in  std_logic
      mux_select    => mux_select(0),    --in  std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_0,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tready => s_axis_tready_0,  --in  std_logic
      s_axis_tvalid => s_axis_tvalid_0); --in  std_logic

  --vhook_e AxisMuxChecker Checker1
  --vhook_a m_axis_tdata m_axis_tdata_1
  --vhook_a m_axis_tvalid m_axis_tvalid_1
  --vhook_a mux_select mux_select(1)
  --vhook_a s_axis_tdata s_axis_tdata_1
  --vhook_a s_axis_tvalid s_axis_tvalid_1
  --vhook_a s_axis_tready s_axis_tready_1
  Checker1: entity work.AxisMuxChecker (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,             --in  std_logic_vector(kGpioWidth-1:0)
      m_axis_tdata  => m_axis_tdata_1,   --in  std_logic_vector(kAxiWidth-1:0)
      m_axis_tvalid => m_axis_tvalid_1,  --in  std_logic
      mux_select    => mux_select(1),    --in  std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_1,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tready => s_axis_tready_1,  --in  std_logic
      s_axis_tvalid => s_axis_tvalid_1); --in  std_logic

  --vhook_e AxisMuxChecker Checker2
  --vhook_a m_axis_tdata m_axis_tdata_2
  --vhook_a m_axis_tvalid m_axis_tvalid_2
  --vhook_a mux_select mux_select(4)
  --vhook_a s_axis_tdata s_axis_tdata_2
  --vhook_a s_axis_tvalid s_axis_tvalid_2
  --vhook_a s_axis_tready s_axis_tready_2
  Checker2: entity work.AxisMuxChecker (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,             --in  std_logic_vector(kGpioWidth-1:0)
      m_axis_tdata  => m_axis_tdata_2,   --in  std_logic_vector(kAxiWidth-1:0)
      m_axis_tvalid => m_axis_tvalid_2,  --in  std_logic
      mux_select    => mux_select(4),    --in  std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_2,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tready => s_axis_tready_2,  --in  std_logic
      s_axis_tvalid => s_axis_tvalid_2); --in  std_logic

  --vhook_e AxisMuxChecker Checker3
  --vhook_a m_axis_tdata m_axis_tdata_3
  --vhook_a m_axis_tvalid m_axis_tvalid_3
  --vhook_a mux_select mux_select(5)
  --vhook_a s_axis_tdata s_axis_tdata_3
  --vhook_a s_axis_tvalid s_axis_tvalid_3
  --vhook_a s_axis_tready s_axis_tready_3
  Checker3: entity work.AxisMuxChecker (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,             --in  std_logic_vector(kGpioWidth-1:0)
      m_axis_tdata  => m_axis_tdata_3,   --in  std_logic_vector(kAxiWidth-1:0)
      m_axis_tvalid => m_axis_tvalid_3,  --in  std_logic
      mux_select    => mux_select(5),    --in  std_logic
      s_axis_aclk   => s_axis_aclk,      --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata_3,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tready => s_axis_tready_3,  --in  std_logic
      s_axis_tvalid => s_axis_tvalid_3); --in  std_logic

end test;

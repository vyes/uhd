---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_axis_mux.vhd
--
-- Purpose:
-- This tests AxisMux. Most of the testing work is done in
-- AxisMuxStimulusAndChecker, which will produce random stimulus as long as the
-- clock keeps toggling.
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;

entity tb_axis_mux is
end entity tb_axis_mux;

architecture test of tb_axis_mux is

  constant kGpioWidth : natural := 32;
  constant kAxiWidth : natural := 256;

  --vhook_sigstart
  signal gpio: std_logic_vector(kGpioWidth-1 downto 0);
  signal m_axis_tdata: std_logic_vector(kAxiWidth-1 downto 0);
  signal m_axis_tvalid: std_logic;
  signal mux_select: std_logic;
  signal s_axis_aclk: std_logic := '0';
  signal s_axis_tdata: std_logic_vector(kAxiWidth-1 downto 0);
  signal s_axis_tready: std_logic;
  signal s_axis_tvalid: std_logic;
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

  --vhook_e axis_mux DUT
  --vhook_a m_axis_aclk s_axis_aclk
  DUT: entity work.axis_mux (RTL)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,           --in  std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select,     --in  std_logic
      s_axis_aclk   => s_axis_aclk,    --in  std_logic
      s_axis_tdata  => s_axis_tdata,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid,  --in  std_logic
      s_axis_tready => s_axis_tready,  --out std_logic
      m_axis_aclk   => s_axis_aclk,    --in  std_logic
      m_axis_tvalid => m_axis_tvalid,  --out std_logic
      m_axis_tdata  => m_axis_tdata);  --out std_logic_vector(kAxiWidth-1:0)

  TestControl: process is
  begin
    -- AxisMuxStimlusAndChecker will provide random stimulus and check expected
    -- behavior for as long as this process waits before stopping the clock.
    ClkWait(100);

    StopSim <= true;
    wait;
  end process TestControl;

  --vhook_e AxisMuxStimulus
  AxisMuxStimulusx: entity work.AxisMuxStimulus (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,           --out std_logic_vector(kGpioWidth-1:0)
      mux_select    => mux_select,     --out std_logic
      s_axis_aclk   => s_axis_aclk,    --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata,   --out std_logic_vector(kAxiWidth-1:0)
      s_axis_tvalid => s_axis_tvalid); --out std_logic

  --vhook_e AxisMuxChecker
  AxisMuxCheckerx: entity work.AxisMuxChecker (test)
    generic map (
      kGpioWidth => kGpioWidth,  --natural:=32
      kAxiWidth  => kAxiWidth)   --natural:=256
    port map (
      gpio          => gpio,           --in  std_logic_vector(kGpioWidth-1:0)
      m_axis_tdata  => m_axis_tdata,   --in  std_logic_vector(kAxiWidth-1:0)
      m_axis_tvalid => m_axis_tvalid,  --in  std_logic
      mux_select    => mux_select,     --in  std_logic
      s_axis_aclk   => s_axis_aclk,    --in  std_logic:='0'
      s_axis_tdata  => s_axis_tdata,   --in  std_logic_vector(kAxiWidth-1:0)
      s_axis_tready => s_axis_tready,  --in  std_logic
      s_axis_tvalid => s_axis_tvalid); --in  std_logic

end test;

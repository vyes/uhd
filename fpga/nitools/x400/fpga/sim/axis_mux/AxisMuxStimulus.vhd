---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: AxisMuxStimulus.vhd
--
-- Purpose:
-- This module produces random stimulus for tb_AxisMux and tb_gpio_to_axis_mux.
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;
  use WORK.PkgAxisMuxStimulus.all;

entity AxisMuxStimulus is
  generic(
    kGpioWidth : natural := 32;
    kAxiWidth : natural := 256
  );
  port (
    gpio : out std_logic_vector(kGpioWidth-1 downto 0);
    mux_select : out std_logic;
    s_axis_aclk : in std_logic := '0';
    s_axis_tdata : out std_logic_vector(kAxiWidth-1 downto 0);
    s_axis_tvalid : out std_logic
  );
end entity;

architecture test of AxisMuxStimulus is
begin

  Stimulus: process(s_axis_aclk) is
  begin
    if rising_edge(s_axis_aclk) then
      s_axis_tdata <= Random.GetStdLogicVector(s_axis_tdata'length);
      s_axis_tvalid <= to_StdLogic(Random.GetBoolean(PercentTrue => 0.90));
      gpio <= Random.GetStdLogicVector(gpio'length);
      mux_select <= Random.GetStdLogic;
    end if;
  end process Stimulus;

end test;


---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: AxisMuxChecker.vhd
--
-- Purpose:
-- This module checks for correct behavior in tb_AxisMux and
-- tb_gpio_to_axis_mux.
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;

entity AxisMuxChecker is
  generic(
    kGpioWidth : natural := 32;
    kAxiWidth : natural := 256
  );
  port (
    gpio : in std_logic_vector(kGpioWidth-1 downto 0);
    m_axis_tdata : in std_logic_vector(kAxiWidth-1 downto 0);
    m_axis_tvalid : in std_logic;
    mux_select : in std_logic;
    s_axis_aclk : in std_logic := '0';
    s_axis_tdata : in std_logic_vector(kAxiWidth-1 downto 0);
    s_axis_tready : in std_logic;
    s_axis_tvalid : in std_logic
  );
end entity;

architecture test of AxisMuxChecker is
begin

  OutputChecker:
  Process ( s_axis_aclk ) is
    subtype Gpio_t is std_logic_vector(gpio'range);
    subtype AxiData_t is std_logic_vector(s_axis_tdata'range);

    variable LastInputGpio : Gpio_t;
    variable LastInputTData : AxiData_t;
    variable LastInputTValid : std_logic;
    variable LastMuxSelect : std_logic;

    function ConcatenateData (word : Gpio_t) return AxiData_t is
      variable rval : AxiData_t;
      constant kWordCount : natural := AxiData_t'length / Gpio_t'length;
      constant kWordSize : natural := word'length;
    begin
      for i in 0 to kWordCount - 1 loop
        rval(i*kWordSize + kWordSize - 1 downto i*kWordSize) := word;
      end loop;
      return rval;
    end function ConcatenateData;

  begin
    if rising_edge(s_axis_aclk) then
      assert s_axis_tready = '1'
        report "s_axis_tready should always be high";

      if LastMuxSelect='1' then
        assert m_axis_tdata = ConcatenateData(LastInputGpio)
          report "data mismatch when mux_select high";

        assert m_axis_tvalid = '1'
          report "tvalid mismatch when mux_select low";
      else
        assert m_axis_tdata = LastInputTData
          report "data mismatch when mux_select low";

        assert m_axis_tvalid = LastInputTValid
          report "tvalid mismatch when mux_select high";
      end if;

      LastInputTData := s_axis_tdata;
      LastInputTValid := s_axis_tvalid;
      LastInputGpio := gpio;
      LastMuxSelect := mux_select;
    end if;
  end process OutputChecker;

end test;

-------------------------------------------------------------------------------
--
-- File: USR_ACCESS2.vhd
-- Author: Wade Fife
-- Original Project: X410
-- Date: 1 April 2021
--
-------------------------------------------------------------------------------
-- (c) 2021 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
-------------------------------------------------------------------------------
--
-- Purpose:
-- A VScan model for the Xilinx USR_ACCESS2.
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity USR_ACCESSE2 is
  port (
    CFGCLK    : out std_ulogic;
    DATA      : out std_logic_vector(31 downto 0);
    DATAVALID : out std_ulogic
  );
end USR_ACCESSE2;

architecture rtl of USR_ACCESSE2 is
begin
  CFGCLK    <= '0';
  DATA      <= x"00000000";
  DATAVALID <= '0';
end rtl;

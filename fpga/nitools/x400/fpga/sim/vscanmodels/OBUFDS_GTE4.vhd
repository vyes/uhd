-------------------------------------------------------------------------------
--
-- File: OBUFDS_GTE4.vhd
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
-- A VScan model for the Xilinx OBUFDS_GTE4.
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity OBUFDS_GTE4 is
  generic (
    REFCLK_EN_TX_PATH : bit                          := '0';
    REFCLK_ICNTL_TX   : std_logic_vector(4 downto 0) := "00000"
  );
  port (
    O   : out std_ulogic;
    OB  : out std_ulogic;
    CEB : in  std_ulogic;
    I   : in  std_ulogic
  );
end OBUFDS_GTE4;

architecture rtl of OBUFDS_GTE4 is
begin
  process (I, CEB)
  begin
    if CEB='1' then
      O  <= '0';
      OB <= '1';
    else
      O <= I;
      OB <= not I;
    end if;
  end process;
end rtl;

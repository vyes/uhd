-------------------------------------------------------------------------------
--
-- File: ODDRE1.vhd
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
-- A VScan model for the Xilinx ODDRE1.
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity ODDRE1 is
  generic (
    IS_C_INVERTED  : bit    := '0';          -- Optional inversion for C
    IS_D1_INVERTED : bit    := '0';          -- Unsupported, do not use
    IS_D2_INVERTED : bit    := '0';          -- Unsupported, do not use
    SIM_DEVICE     : string := "ULTRASCALE"; -- Set the device version (ULTRASCALE)
    SRVAL          : bit    := '0'           -- Initializes the ODDRE1 Flip-Flops
    );
  port (
    C  : in  std_logic;
    SR : in  std_logic;
    D1 : in  std_logic;
    D2 : in  std_logic;
    Q  : out std_logic
  );
end ODDRE1;

architecture rtl of ODDRE1 is
begin
  
  --vhook_nowarn ODDRE1.IS_C_INVERTED ODDRE1.IS_D1_INVERTED 
  --vhook_nowarn ODDRE1.IS_D2_INVERTED ODDRE1.SIM_DEVICE ODDRE1.SRVAL

  process (SR, C)
  begin
    if SR='1' then
      Q <= '0';
    elsif rising_edge(C) then
      Q <= D1 or D2;
    end if;
  end process;
end rtl;

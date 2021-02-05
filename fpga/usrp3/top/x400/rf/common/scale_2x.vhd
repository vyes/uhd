---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: scale_2x.vhd
--
-- Purpose:
--
-- This block does the scaling of IQ data by 2. The data from the mixer
-- is 1/2 the full scale and the upper two bits will only have the
-- signed bits, so it is okay to multiply the data by 2 and resize it
-- back to 16 bits.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgRf.all;

entity scale_2x is
  generic(
    -- This should be a multiple of 16 bits.
    kDataWidth       : integer range 1 to 256 := 32);
  port(
    -- [..Q1,I1,Q0,I0] (I in LSBs). Each I and Q data is 16 bits wide, but
    -- since the data is only 1/2 full scale. Useful information is only
    -- in the lower 15 bits, with upper two bits used as a signed bit.
    cDataIn          : in std_logic_vector(kDataWidth-1 downto 0);
    cDataValidIn     : in std_logic;
    -- [..Q1,I1,Q0,I0] (I in LSBs). 16 bit output with a gain of 2x.
    cDataOut         : out std_logic_vector(kDataWidth-1 downto 0);
    cDataValidOut    : out std_logic );
end scale_2x;

architecture RTL of scale_2x is

begin

 -- scale the date by 2 by shifting the data to the left by 1 bit.
 cDataOut <= Gain2x(cDataIn);
 cDataValidOut <= cDataValidIn;

end RTL;

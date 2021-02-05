-------------------------------------------------------------------------------
--
-- File: OBUFDS.vhd
-- Author: Craig Conway
-- Original Project: NiCores
-- Date: 6 March 2009
--
-------------------------------------------------------------------------------
-- (c) 2009 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
-------------------------------------------------------------------------------
--
-- Purpose:
-- A VScan model for the Xilinx OBUFDS.
--
-- http://www.xilinx.com/itp/xilinx10/books/docs/virtex4_hdl/virtex4_hdl.pdf
--
-- OBUFDS: Differential Output Buffer
-- Virtex-II/II-Pro/4/5, Spartan-3/3E/3A
-- Xilinx HDL Libraries Guide, version 10.1.2
--
-- Required library:
--library UNISIM;
--use UNISIM.vcomponents.all;
--
-- vreview_group simple
-- vreview_closed http://review-board.natinst.com/r/207319/
-- vreview_closed http://review-board.natinst.com/r/79823/
-- vreview_closed http://review-board.natinst.com/r/79588/
--
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;

entity OBUFDS is
  port (
    O : out std_logic;
    OB : out std_logic;
    I : in std_logic
  );
end OBUFDS;

architecture rtl of OBUFDS is

-- Note that the example instance below includes some generics which we don't include
-- above.  So you only get the default values.

--OBUFDS_inst : OBUFDS
--  generic map (
--    IOSTANDARD => "DEFAULT")
--  port map (
--    O => O,   -- Diff_p output (connect directly to top-level port)
--    OB => OB, -- Diff_n output (connect directly to top-level port)
--    I => I    -- Buffer input
--  );


begin

  O <= I;
  OB <= not I;

end rtl;



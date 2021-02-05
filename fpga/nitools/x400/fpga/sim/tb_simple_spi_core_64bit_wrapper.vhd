---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_simple_spi_core_64bit_wrapper
--
-- Purpose:
-- This testbench calls tb_simple_spi_core_64bit with different MAX_BITS values.
--
----------------------------------------------------------------------

entity tb_simple_spi_core_64bit_wrapper is
end tb_simple_spi_core_64bit_wrapper;

architecture test of tb_simple_spi_core_64bit_wrapper is
begin

  --vhook_e tb_simple_spi_core_64bit inst_8bit
  --vhook_a MAX_BITS 8
  inst_8bit: entity work.tb_simple_spi_core_64bit (test)
    generic map (MAX_BITS => 8); --natural:=64

  --vhook_e tb_simple_spi_core_64bit inst_16bit
  --vhook_a MAX_BITS 16
  inst_16bit: entity work.tb_simple_spi_core_64bit (test)
    generic map (MAX_BITS => 16); --natural:=64

  --vhook_e tb_simple_spi_core_64bit inst_32bit
  --vhook_a MAX_BITS 32
  inst_32bit: entity work.tb_simple_spi_core_64bit (test)
    generic map (MAX_BITS => 32); --natural:=64

  --vhook_e tb_simple_spi_core_64bit inst_64bit
  --vhook_a MAX_BITS 64
  inst_64bit: entity work.tb_simple_spi_core_64bit (test)
    generic map (MAX_BITS => 64); --natural:=64

end test;

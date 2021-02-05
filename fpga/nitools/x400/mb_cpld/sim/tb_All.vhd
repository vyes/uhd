--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_All
-- Description:
--  Instantiates all MB CPLD related testbenches

--synopsys translate_off
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;

entity tb_All is
end tb_All;

architecture test of tb_All is

begin

    process
    begin
        Verbosity.Set(error);
        wait;
    end process;

    --nisim --Batch --quiet

    --vhook_e mb_cpld_tb
    mb_cpld_tbx: entity work.mb_cpld_tb (test);

    --vhook_e tb_ps_spi_binary_decode
    tb_ps_spi_binary_decodex: entity work.tb_ps_spi_binary_decode (test);

end test;

--synopsys translate_on

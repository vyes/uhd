--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_All
-- Description:
--  Instantiates all zr_cpld testbenches

--nisim --op1="-L altera_mf_ver"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
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

    --vhook_e tb_zr_top_cpld
    tb_zr_top_cpldx: entity work.tb_zr_top_cpld (test);

    --vhook_e tb_db_gpio tb_db_gpio_2
    --vhook_a kClockRatio 2
    tb_db_gpio_2: entity work.tb_db_gpio (test)
      generic map (kClockRatio => 2); --natural range 2:4 :=2

    --vhook_e tb_db_gpio tb_db_gpio_4
    --vhook_a kClockRatio 4
    tb_db_gpio_4: entity work.tb_db_gpio (test)
      generic map (kClockRatio => 4); --natural range 2:4 :=2

    --vhook_e tb_db_gpio_latency
    tb_db_gpio_latencyx: entity work.tb_db_gpio_latency (test);

end test;

--synopsys translate_on

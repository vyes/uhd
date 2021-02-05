--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: clock_period_check
-- Description:
-- Testbench for checking the clock period of the provided signal.
-- Additionally checks for occurences of the desired edges to make sure the
-- clock is running.

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;

entity clock_period_check is
generic (
  expectedClockPeriod : time := 0 us;
  checkFallingEdges : boolean := false
);
port (
  clk : in std_logic
);
end clock_period_check;

architecture test of clock_period_check is

  -- cover points for pkgScoreboard
  constant powerSupplyClockFrequency : string := test'path_name & "clock frequency violation";
  constant powerSupplyClockEdges: string := test'path_name & "clock edge count";

  -- check minimal time has passed
  -- assert if passed time is less
  procedure CheckClockPeriodInRange(ExpectedTime, PassedTime : in time; CoverPoint : in string) is
    constant kMaxOffset : time := 20 ns; -- clock can be slighty faster up to this amount
  begin
    gScoreboard.NoteCoverIf((PassedTime > ExpectedTime) or
      (PassedTime < (ExpectedTime-kMaxOffset)), CoverPoint,
      "Clock period was violated! " & LF &
      "expected time: " & time'image(ExpectedTime) & LF &
      "passed time: " & time'image(PassedTime)
    );
  end procedure;

begin

  main: process
  begin
    -- register scoreboard cover points
    gScoreboard.RegisterRestrictedCover(powerSupplyClockFrequency);
    gScoreboard.RegisterCover(powerSupplyClockEdges, integer'high, 2);

    -- disable clock periode checks for first clock edge
    gScoreboard.Disable(powerSupplyClockFrequency);

    wait;
  end process;

  ------------------------------------------------------------------------------
  -- Check of power supply clocks
  ------------------------------------------------------------------------------
  clockCheck: process(clk)
    variable LastEdgeTimeStamp : time := 0 ns;
    variable disabled : boolean := true;
  begin
    if (rising_edge(clk) and not checkFallingEdges) or (falling_edge(clk) and checkFallingEdges) then
      CheckClockPeriodInRange(expectedClockPeriod, (now-LastEdgeTimeStamp), powerSupplyClockFrequency);
      if (disabled) then
        gScoreboard.Enable(powerSupplyClockFrequency);
        disabled := false;
      end if;
      gScoreboard.NoteCover(powerSupplyClockEdges);
      LastEdgeTimeStamp := now;
    end if;
  end process;

end test;
--synopsys translate_on
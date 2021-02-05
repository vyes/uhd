---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_dac_gearbox_6x8.v
--
-- Purpose:
--
-- Self-checking testbench used to test the gearbox that expands a 
-- 6 SPC data into a 8 SPC data.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Used only for HexImage function. Can be deleted.
library work;
  use work.PkgNiSim.all;


entity tb_dac_gearbox_6x8 is
end tb_dac_gearbox_6x8;


architecture RTL of tb_dac_gearbox_6x8 is

  signal TestStart : boolean;

  --vhook_sigstart
  signal ac1Reset_n: std_logic;
  signal ac2Reset_n: std_logic;
  signal arReset_n: std_logic;
  signal rDataOut: std_logic_vector(255 downto 0);
  signal rDataValidOut: std_logic;
  signal rReadyForOutput: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kPer : time := 12 ns;

  signal Clk1x: std_logic := '1';
  signal Clk2x: std_logic := '1';
  signal RfClk: std_logic := '1';
  signal rDataToCheck, rDataToCheckDly0, rDataToCheckDly1, rDataToCheckDly2,
         rDataToCheckDly3, rDataToCheckDly4, rDataToCheckDly5, rDataToCheckDly6,
         rDataToCheckDly7, rDataToCheckDly8
         : std_logic_vector(255 downto 0) := (others => '0');
  signal c2DataIn: std_logic_vector(191 downto 0) := (others => '0');
  signal c2DataValidIn: std_logic := '0';
  signal rEdgeAligned : boolean := false;

  procedure RfClkWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(RfClk);
    end loop;
  end procedure RfClkWait;

  procedure Clk1xWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(Clk1x);
    end loop;
  end procedure Clk1xWait;

  procedure Clk2xWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(Clk2x);
    end loop;
  end procedure Clk2xWait;

begin

  Clk1x  <= not Clk1x after kPer/4 when not StopSim else '0';
  Clk2x  <= not Clk2x after kPer/8 when not StopSim else '0';
  RfClk  <= not RfClk after kPer/6 when not StopSim else '0';

  --vhook_e dac_gearbox_6x8 DUT
  DUT: entity work.dac_gearbox_6x8 (struct)
    port map (
      Clk1x           => Clk1x,            --in  std_logic
      Clk2x           => Clk2x,            --in  std_logic
      RfClk           => RfClk,            --in  std_logic
      ac1Reset_n      => ac1Reset_n,       --in  std_logic
      ac2Reset_n      => ac2Reset_n,       --in  std_logic
      arReset_n       => arReset_n,        --in  std_logic
      c2DataIn        => c2DataIn,         --in  std_logic_vector(191:0)
      c2DataValidIn   => c2DataValidIn,    --in  std_logic
      rDataOut        => rDataOut,         --out std_logic_vector(255:0):=(others=>'0')
      rReadyForOutput => rReadyForOutput,  --in  std_logic
      rDataValidOut   => rDataValidOut);   --out std_logic:='0'


  main: process
    procedure PhaseTest (EdgeAligned : boolean := false;
                         ClkPhase    : positive := 1) is
    begin
      for i in 0 to 7 loop
        -- RfClk and Clk1x are phase aligned. Dly7 (4)
        -- Wait until both Clk2x and RfClk rising edge are aligned.
        wait until (rising_edge(Clk2x) and rising_edge(RfClk));
        -- Wait for 1 Clk2x clock to assert c2DataValidIn on falling edge of RfClk.
        Clk2xWait(ClkPhase);
        TestStart <= true;
        rEdgeAligned <= EdgeAligned;
        Clk2xWait(120+2*i);

        -- stop test iteration
        TestStart <= false;
        -- Wait until output datavalid is deasserted. This is needed so the
        -- next test iteration is not started before the current test is done.
        wait until rDataValidOut = '0' for 1 us;
      end loop;
    end procedure;
  begin
    ac1Reset_n <= '0';
    ac2Reset_n <= '0';
    arReset_n  <= '0';
    TestStart <= false;
    Clk1xWait(5);
    ac1Reset_n <= '1';
    ac2Reset_n <= '1';
    arReset_n  <= '1';
    rReadyForOutput  <= '1';

    assert rDataValidOut = '0'
      report "Data output valid is expected to be 0 after reset"
      severity warning;
    PhaseTest(false, 1);
    -- Input Data valid is asserted when Clk2x and RfClk is rising edge aligned.
    PhaseTest(true, 2);
    PhaseTest(false, 3);
    PhaseTest(true, 4);

    Clk2xWait;
    StopSim <= true;
    wait;
  end process;

  -- process to generate input data.
  driver: process(Clk2x)
    variable qDataIn : unsigned(15 downto 0) := x"0001";
    variable iDataIn : unsigned(15 downto 0) := x"0080";
  begin
    if rising_edge(Clk2x) then
      c2DataValidIn <= '0';
      if TestStart then
        c2DataValidIn <= '1';
        c2DataIn <= std_logic_vector((qDataIn+5)  & (iDataIn+5)  &
                                     (qDataIn+4)  & (iDataIn+4)  &
                                     (qDataIn+3)  & (iDataIn+3)  &
                                     (qDataIn+2)  & (iDataIn+2)  &
                                     (qDataIn+1)  & (iDataIn+1)  &
                                     (qDataIn+0)  & (iDataIn+0));
        qDataIn := qDataIn +6;
        iDataIn := iDataIn +6;

      else
        c2DataValidIn <= '0';
        qDataIn := x"0001";
        iDataIn := x"0080";
      end if;
    end if;
  end process;

  -- Process to generate expected output data.
  ExpectedData: process(RfClk)
    variable qDataOut : unsigned(15 downto 0) := x"0001";
    variable iDataOut : unsigned(15 downto 0) := x"0080";
  begin
    if rising_edge(RfClk) then
      if TestStart then
        rDataToCheck <= std_logic_vector((qDataOut+7)  & (iDataOut+7)  &
                                         (qDataOut+6)  & (iDataOut+6)  &
                                         (qDataOut+5)  & (iDataOut+5)  &
                                         (qDataOut+4)  & (iDataOut+4)  &
                                         (qDataOut+3)  & (iDataOut+3)  &
                                         (qDataOut+2)  & (iDataOut+2)  &
                                         (qDataOut+1)  & (iDataOut+1)  &
                                         (qDataOut+0)  & (iDataOut+0));

        qDataOut := qDataOut+8;
        iDataOut := iDataOut+8;
      else
        qDataOut := x"0001";
        iDataOut := x"0080";
      end if;
      rDataToCheckDly0 <= rDataToCheck;
      rDataToCheckDly1 <= rDataToCheckDly0;
      rDataToCheckDly2 <= rDataToCheckDly1;
      rDataToCheckDly3 <= rDataToCheckDly2;
      rDataToCheckDly4 <= rDataToCheckDly3;
      rDataToCheckDly5 <= rDataToCheckDly4;
      rDataToCheckDly6 <= rDataToCheckDly5;
      rDataToCheckDly7 <= rDataToCheckDly6;
      rDataToCheckDly8 <= rDataToCheckDly7;
    end if;
  end process;

  --process to check output data with expected data
  checker: process(RfClk)
  begin
    if falling_edge(RfClk) then
      if rDataValidOut = '1' then
        if rEdgeAligned then
          assert rDataOut = rDataToCheckDly7
            report "DAC data out mismatch from expected"      & LF &
                   "Expected : " & HexImage(rDataToCheckDly7) & LF &
                   "Received : " & HexImage(rDataOut)
            severity warning;
        else
          assert rDataOut = rDataToCheckDly8
            report "DAC data out mismatch from expected"      & LF &
                   "Expected : " & HexImage(rDataToCheckDly8) & LF &
                   "Received : " & HexImage(rDataOut)
            severity error;
          end if;
      end if;
    end if;
  end process;

end RTL;


---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_dac_gearbox_12x8.v
--
-- Purpose:
--
-- Self-checking testbench for a gearbox that decreases the SPCs from
-- 12 to 8.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_dac_gearbox_12x8 is
end tb_dac_gearbox_12x8;


architecture RTL of tb_dac_gearbox_12x8 is

  signal TestStart : boolean;

  --vhook_sigstart
  signal rDataOut: std_logic_vector(255 downto 0);
  signal rDataValidOut: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kPer : time := 12 ns;

  signal Clk1x: std_logic := '1';
  signal RfClk: std_logic := '1';
  signal ac1Reset_n: std_logic := '0';
  signal arReset_n : std_logic := '0';
  signal rReadyForOutput: std_logic := '1';
  signal c1DataIn: std_logic_vector(383 downto 0) := (others => '0');
  signal c1DataValidIn: std_logic := '0';
  signal rDataToCheck, rDataToCheckDly0, rDataToCheckDly1, rDataToCheckDly2,
         rDataToCheckDly3, rDataToCheckDly4 
         : std_logic_vector(255 downto 0) := (others => '0');

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

begin

  Clk1x  <= not Clk1x after kPer/4 when not StopSim else '0';
  RfClk  <= not RfClk after kPer/6 when not StopSim else '0';

  --vhook_e dac_gearbox_12x8 DUT
  DUT: entity work.dac_gearbox_12x8 (RTL)
    port map (
      Clk1x           => Clk1x,            --in  std_logic
      RfClk           => RfClk,            --in  std_logic
      ac1Reset_n      => ac1Reset_n,       --in  std_logic
      arReset_n       => arReset_n,        --in  std_logic
      c1DataIn        => c1DataIn,         --in  std_logic_vector(383:0)
      c1DataValidIn   => c1DataValidIn,    --in  std_logic
      rDataOut        => rDataOut,         --out std_logic_vector(255:0):=(others=>'0')
      rReadyForOutput => rReadyForOutput,  --in  std_logic
      rDataValidOut   => rDataValidOut);   --out std_logic

  main: process
    -- procedure to start and stop data generation.
    -- WaitCycles : This is a wait in Clk1x cycle. This is used to shift data
    --              valid assertion. Depending on the Clk1x cycle, data valid
    --              will be asserted either when both RfClk and Clk1x are phase
    --              aligned or when both clocks are not phase aligned.
    procedure PhaseTest(WaitCycles  : positive := 1) is
    begin
      for i in 0 to 31 loop
        -- Wait for certain RfClk cycles before starting the test.
        Clk1xWait(WaitCycles);
        TestStart <= true;
        Clk1xWait(1000+i); -- Random wait
        TestStart <= false;
        -- wait for few clock cycles for the output data valid to de-assert.
        Clk1xWait(10);
      end loop;
    end procedure;

  begin
    ac1Reset_n <= '0';
    arReset_n  <= '0';
    TestStart <= false;
    Clk1xWait(5);
    ac1Reset_n <= '1';
    arReset_n  <= '1';
    rReadyForOutput <= '1';

    -- RfClk and Clk1x are phase aligned
    PhaseTest(1);

    -- RfClk and Clk1x are phase aligned
    PhaseTest(2);

    -- RfClk and Clk1x are not phase aligned
    PhaseTest(3);

    -- Stop data input to the DUT and wait for few clock cycles for the
    -- output data valid to be de-asserted.
    TestStart <= false;
    RfClkWait(10);

    StopSim <= true;
    wait;
  end process;

  -- process to generate input data.
  driver: process(Clk1x)
    variable qDataIn : unsigned(15 downto 0) := x"0001";
    variable iDataIn : unsigned(15 downto 0) := x"0080";
  begin
    if rising_edge(Clk1x) then
      c1DataValidIn <= '0';
      if TestStart then
        c1DataValidIn <= '1';
        c1DataIn <= std_logic_vector((qDataIn+11) & (iDataIn+11) &
                                     (qDataIn+10) & (iDataIn+10) &
                                     (qDataIn+9)  & (iDataIn+9)  &
                                     (qDataIn+8)  & (iDataIn+8)  &
                                     (qDataIn+7)  & (iDataIn+7)  &
                                     (qDataIn+6)  & (iDataIn+6)  &
                                     (qDataIn+5)  & (iDataIn+5)  &
                                     (qDataIn+4)  & (iDataIn+4)  &
                                     (qDataIn+3)  & (iDataIn+3)  &
                                     (qDataIn+2)  & (iDataIn+2)  &
                                     (qDataIn+1)  & (iDataIn+1)  &
                                     (qDataIn+0)  & (iDataIn+0));
        qDataIn := qDataIn +12;
        iDataIn := iDataIn +12;

      else
        c1DataValidIn <= '0';
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

        -- Dataoutput that has to be verified.
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
    end if;
  end process;

  --process to check output data with expected data
  checker: process(RfClk)
  begin
    if falling_edge(RfClk) then
      if rDataValidOut = '1' then
        assert rDataOut = rDataToCheckDly4
          report "DAC data out mismatch from expected"
          severity error;
      end if;
    end if;
  end process;

end RTL;


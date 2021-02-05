---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_dac_2_1_clk_converter
--
-- Purpose:
--
-- Test dac_2_1_clk_converter with different clock phases, and phases of
-- s_axis_tvalid.
--
---------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;

entity tb_dac_2_1_clk_converter is
end entity tb_dac_2_1_clk_converter;

architecture RTL of tb_dac_2_1_clk_converter is

  --vhook_sigstart
  signal m_axis_aclk: std_logic := '0';
  signal m_axis_aresetn: std_logic;
  signal m_axis_tdata: std_logic_vector(63 downto 0);
  signal m_axis_tvalid: std_logic;
  signal s_axis_aresetn: std_logic;
  signal s_axis_tdata: std_logic_vector(63 downto 0);
  signal s_axis_tvalid: std_logic;
  --vhook_sigend

  signal s_axis_aclk: std_logic := '1';
  signal PauseFastClk : boolean := false;
  constant kShortClkPulse : time := 3 ns;
  signal StopSim : boolean := false;

  constant kWordsPerPhase : natural := 10;

  signal ExpectedDataCount, ReceivedDataCount : natural := 0;

begin

  s_axis_aclk <= not s_axis_aclk after kShortClkPulse when not (StopSim or PauseFastClk) else '0';

  m_axis_aclk <= not m_axis_aclk after 2 * kShortClkPulse when not StopSim else '0';

  stimulus:
  process is

    procedure ClkWait (signal clk : std_logic; n : natural := 1 ) is
    begin
      for i in 1 to n loop
        wait until clk='1';
      end loop;
    end procedure ClkWait;

    -- The 2:1 clock ratio means that incoming data can arrive 1 or 2
    -- s_axis_aclk periods before the next rising m_axis_aclk edge. This procedure
    -- allows us to test that data can arrive at any of those times.
    procedure SetDataPhase(DataPhase : natural) is
    begin
      ClkWait(m_axis_aclk);
      ClkWait(s_axis_aclk, DataPhase);
    end procedure SetDataPhase;

    procedure SetClkPhase(ClkPhase : natural) is
    begin
      -- Wait for s_axis_aclk to go low before disabling it, just to avoid
      -- creating clock glitches (the clock goes immediately low when
      -- PauseFastClk asserts).
      wait until s_axis_aclk='0';
      PauseFastClk <= true;

      ClkWait(m_axis_aclk);
      PauseFastClk <= false after kShortClkPulse * ClkPhase;

      -- We don't want to return until the clock is toggling again
      ClkWait(s_axis_aclk);
    end procedure SetClkPhase;

    variable rand : Random_t;
    procedure pushData is
    begin
      s_axis_tdata <= rand.GetStdLogicVector(s_axis_tdata'length);
      s_axis_tvalid <= '1';
      ClkWait(s_axis_aclk);
      s_axis_tvalid <= '0';
      ClkWait(s_axis_aclk,1);
      ExpectedDataCount <= ExpectedDataCount + 1;
    end procedure pushData;

  begin
    s_axis_tvalid <= '0';
    s_axis_aresetn <= '0';
    m_axis_aresetn <= '0';

    ClkWait(s_axis_aclk, 2);
    s_axis_aresetn <= '1';

    ClkWait(m_axis_aclk);
    m_axis_aresetn <= '1';

    ClkWait(s_axis_aclk, 2);

    for ClkPhase in 1 to 2 loop
      SetClkPhase(ClkPhase);
      for DataPhase in 1 to 2 loop
        SetDataPhase(DataPhase);
        for i in 1 to kWordsPerPhase loop
          pushData;
        end loop;
        -- Wait for all the data to pass through the DUT before proceeding
        wait until rising_edge(m_axis_aclk) and m_axis_tvalid='0'
          for 10 ms;

        assert rising_edge(m_axis_aclk) and m_axis_tvalid='0'
          report "time out waiting for last data";
      end loop;
    end loop;

    assert ReceivedDataCount = ExpectedDataCount;

    StopSim <= true;
    wait;
  end process stimulus;

  --vhook_e dac_2_1_clk_converter DUT
  --vhook_a m_axis_tready '1'
  DUT: entity work.dac_2_1_clk_converter (RTL)
    port map (
      s_axis_aclk    => s_axis_aclk,     --in  std_logic
      s_axis_aresetn => s_axis_aresetn,  --in  std_logic
      s_axis_tvalid  => s_axis_tvalid,   --in  std_logic
      s_axis_tdata   => s_axis_tdata,    --in  std_logic_vector(63:0)
      m_axis_aclk    => m_axis_aclk,     --in  std_logic
      m_axis_aresetn => m_axis_aresetn,  --in  std_logic
      m_axis_tready  => '1',             --in  std_logic
      m_axis_tvalid  => m_axis_tvalid,   --out std_logic
      m_axis_tdata   => m_axis_tdata);   --out std_logic_vector(63:0)

  OutputChecker: process(m_axis_aclk) is
    variable rand : Random_t;

    procedure CheckData is
      variable ExpectedData : std_logic_vector(m_axis_tdata'range);
    begin
      if m_axis_tvalid='1' then
        ExpectedData := rand.GetStdLogicVector(ExpectedData'length);
        assert (m_axis_tdata = ExpectedData)
          report "incorrect output data";

        assert ExpectedDataCount > ReceivedDataCount
          report "received unexpected data";

        ReceivedDataCount <= ReceivedDataCount + 1;
      end if;
    end procedure CheckData;

  begin
    if rising_edge(m_axis_aclk) then
      CheckData;
    end if;
  end process OutputChecker;

end RTL;

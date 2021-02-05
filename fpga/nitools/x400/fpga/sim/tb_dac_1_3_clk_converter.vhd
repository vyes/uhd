---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_dac_1_3_aclk_converter
--
-- Purpose:
--
-- Test dac_1_3_aclk_converter for correct data transfers with different clock
-- phase relationships.
--
---------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgNiSim.all;

entity tb_dac_1_3_clk_converter is
end entity tb_dac_1_3_clk_converter;

architecture RTL of tb_dac_1_3_clk_converter is

  --vhook_sigstart
  signal m_axis_aclk: std_logic := '0';
  signal m_axis_aresetn: std_logic;
  signal m_axis_tdata: std_logic_vector(31 downto 0);
  signal m_axis_tready: std_logic;
  signal m_axis_tvalid: std_logic;
  signal s_axis_aresetn: std_logic;
  signal s_axis_tdata: std_logic_vector(31 downto 0);
  signal s_axis_tready: std_logic;
  signal s_axis_tvalid: std_logic;
  --vhook_sigend

  signal s_axis_aclk: std_logic := '1';
  signal StopSim : boolean := false;

  constant kWordsPerPhase : natural := 10;

  constant kShortClkPulse : time := 3 ns;
  signal PauseFastClk : boolean;

  signal ExpectedDataCount : natural := 0;
  signal ReceivedDataCount : natural := 0;

  shared variable OutputRand : Random_t;

begin

  m_axis_aclk <= not m_axis_aclk after kShortClkPulse when not (StopSim or PauseFastClk) else '0';

  s_axis_aclk <= not s_axis_aclk after 3 * kShortClkPulse when not StopSim else '0';

  stimulus:
  process is

    procedure ClkWait (signal clk : std_logic; n : natural := 1 ) is
    begin
      for i in 1 to n loop
        wait until clk='1';
      end loop;
    end procedure ClkWait;

    procedure SetClkPhase(phase : natural) is
    begin
      -- Wait for m_axis_aclk to go low before disabling it, just to avoid
      -- creating clock glitches (the clock goes immediately low when
      -- PauseFastClk asserts).
      wait until m_axis_aclk='0';
      PauseFastClk <= true;

      ClkWait(s_axis_aclk);
      PauseFastClk <= false after kShortClkPulse * phase;

      -- We don't want to return until the clock is toggling again
      ClkWait(m_axis_aclk);
    end procedure SetClkPhase;

    variable rand : Random_t;

    procedure pushData is
    begin
      s_axis_tdata <= rand.GetStdLogicVector(s_axis_tdata'length);
      s_axis_tvalid <= '1';
      ClkWait(s_axis_aclk);
      s_axis_tvalid <= '0';
    end procedure pushData;

    procedure DataTransferTest is
    begin
      ClkWait(s_axis_aclk, 3);

      for phase in 1 to 2 loop
        SetClkPhase(phase);
        for i in 1 to kWordsPerPhase loop
          pushData;
          ExpectedDataCount <= ExpectedDataCount + 1;
        end loop;
        ClkWait(s_axis_aclk, 3);
      end loop;

      if ReceivedDataCount < ExpectedDataCount then
        wait until ReceivedDataCount = ExpectedDataCount
            for 10 ms;
      end if;

      assert ReceivedDataCount = ExpectedDataCount;
    end procedure DataTransferTest;

    variable DiscardedData : std_logic_vector(m_axis_tdata'range);

  begin
    s_axis_tvalid <= '0';
    m_axis_tready <= '1';
    s_axis_aresetn <= '0';
    m_axis_aresetn <= '0';
    ClkWait(s_axis_aclk, 3);
    s_axis_aresetn <= '1';
    m_axis_aresetn <= '1';

    DataTransferTest;

    -- The following sequence tests that we can reset the DUT while it is in the
    -- "got_data" state.
    ClkWait(s_axis_aclk);
    pushData;
    ClkWait(m_axis_aclk,3);
    m_axis_aresetn <= '0';
    ClkWait(m_axis_aclk);
    m_axis_aresetn <= '1';

    -- Wait a while and verify that no new data appeared as a result of the
    -- pushData that we aborted by asserting m_axis_aresetn
    ClkWait(m_axis_aclk, 10);
    assert ReceivedDataCount = ExpectedDataCount;

    -- Discard the next expected output that was lost during the reset assertion
    DiscardedData := OutputRand.GetStdLogicVector(DiscardedData'length);

    -- Verify that the DUT recovers from reset
    DataTransferTest;

    StopSim <= true;
    wait;
  end process stimulus;

  --vhook_e dac_1_3_clk_converter DUT
  DUT: entity work.dac_1_3_clk_converter (RTL)
    port map (
      s_axis_aclk    => s_axis_aclk,     --in  std_logic
      s_axis_aresetn => s_axis_aresetn,  --in  std_logic
      s_axis_tvalid  => s_axis_tvalid,   --in  std_logic
      s_axis_tdata   => s_axis_tdata,    --in  std_logic_vector(31:0)
      s_axis_tready  => s_axis_tready,   --out std_logic:='1'
      m_axis_aclk    => m_axis_aclk,     --in  std_logic
      m_axis_aresetn => m_axis_aresetn,  --in  std_logic
      m_axis_tready  => m_axis_tready,   --in  std_logic
      m_axis_tdata   => m_axis_tdata,    --out std_logic_vector(31:0)
      m_axis_tvalid  => m_axis_tvalid);  --out std_logic

  OutputChecker: process(m_axis_aclk) is

    procedure CheckData is
      variable ExpectedData : std_logic_vector(m_axis_tdata'range);
    begin
      if m_axis_tvalid='1' then
        ExpectedData := OutputRand.GetStdLogicVector(ExpectedData'length);
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

  assert s_axis_tready='1'
    report "s_axis_tready should be constant 1";

end RTL;

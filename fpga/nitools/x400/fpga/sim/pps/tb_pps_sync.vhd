--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_pps_sync
-- Description:
-- Testbench for pps generation (in multiple clock domains) / consumption and
-- LMK sync

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgGLOBAL_REGS_REGMAP.all;

entity tb_pps_sync is end tb_pps_sync;

architecture test of tb_pps_sync is

  component x4xx_pps_sync
    generic (SIMULATION : integer := 0);
    port (
      base_ref_clk     : in  std_logic;
      pll_ref_clk      : in  std_logic;
      ctrl_clk         : in  std_logic;
      radio_clk        : in  std_logic;
      brc_rst          : in  std_logic;
      pps_in           : in  std_logic;
      pps_out_brc      : out std_logic;
      pps_out_rc       : out std_logic;
      sync             : out std_logic;
      pps_select       : in  std_logic_vector(1 downto 0);
      pll_sync_trigger : in  std_logic;
      pll_sync_delay   : in  std_logic_vector(7 downto 0);
      pll_sync_done    : out std_logic;
      pps_brc_delay    : in  std_logic_vector(7 downto 0);
      pps_prc_delay    : in  std_logic_vector(25 downto 0);
      prc_rc_divider   : in  std_logic_vector(1 downto 0);
      pps_rc_enabled   : in  std_logic;
      debug            : out std_logic_vector(1 downto 0));
  end component;

  --vhook_sigstart
  signal base_ref_clk: std_logic := '0';
  signal brc_rst: std_logic;
  signal ctrl_clk: std_logic := '0';
  signal debug: std_logic_vector(1 downto 0);
  signal m_pll_sync_delay: std_logic_vector(7 downto 0);
  signal m_pll_sync_done: std_logic;
  signal m_pll_sync_trigger: std_logic;
  signal m_pps_brc_delay: std_logic_vector(7 downto 0);
  signal m_pps_out_rc: std_logic;
  signal m_pps_refclk: std_logic := '0';
  signal m_pps_select: std_logic_vector(1 downto 0);
  signal m_sync: std_logic;
  signal pll_ref_clk: std_logic := '0';
  signal pps_prc_delay: std_logic_vector(25 downto 0);
  signal pps_rc_enabled: std_logic;
  signal prc_rc_divider: std_logic_vector(1 downto 0);
  signal radio_clk: std_logic := '0';
  signal s_pll_sync_delay: std_logic_vector(7 downto 0);
  signal s_pll_sync_trigger: std_logic;
  signal s_pps_brc_delay: std_logic_vector(7 downto 0);
  signal s_pps_out_rc: std_logic;
  signal s_pps_refclk: std_logic := '0';
  signal s_pps_select: std_logic_vector(1 downto 0);
  signal s_sync: std_logic;
  --vhook_sigend

  -- simulation control signals
  signal StopSim : boolean := false;

  -- clocking constants
  constant kRefClkPeriod : time := 100 ns;  -- 10 MHz
  constant kCtrlClkPeriod : time := 25 ns;  -- 40 MHz
  constant kPllClkPeriod : time := 15.625 ns; -- 64 MHz
  constant kRadioClkMultiplier : integer := 2;
  -- For simulation speedup the PPS period was reduced by 1000 as all the clocks
  -- used above are a multiple of 2 MHz (could be divided even further).
  constant kPpsPeriod : time := 1 ms;

  -- helper signals for checks in this simulation
  signal alignedEdge : boolean := false;
  signal repeatedAlignedEdge : boolean := false;
  signal activateChecks : boolean := false;

  ------------------------------------------------------------------------------
  -- constants to be checked
  ------------------------------------------------------------------------------
  -- There are constant delays from master PPS rising edge to appearance of LMK sync
  -- of master and slave.
  -- THOSE CONSTANTS ARE DOCUMENTED IN THE REGISTER INTERFACE. IF YOU HAVE TO CHANGE
  -- THE VALUE HERE MAKE SURE THE DOCUMENTATION IS UPDATED ACCORDINGLY.
  -- delay of master PPS rising edge to master sync signal
  constant kPpsToSyncEdges : integer := 2;
  -- delay of master sync signal to slave sync signal
  constant kSlaveSyncDelay : integer := 3;
  -- value to be substracted from brc pps delay
  constant kBrcDelayDiff : integer := 1;
  -- value to be substracted from prc pps delay
  constant kPrcDelayDiff : integer := 4;
  -- value to be substracted from prc to rc clock multiplier
  constant kClkMultiplierDiff : integer := 2;

  ------------------------------------------------------------------------------
  -- random values choosen for this simulation
  ------------------------------------------------------------------------------
  -- delay of LMK sync signal to aligned clock edge
  constant kLmkSyncCycles : integer := 5;
  -- shift the sync in time to see an alignment in the clocks
  constant kSyncOffset : integer := 4;

begin

  base_ref_clk <= not base_ref_clk after kRefClkPeriod/2 when not StopSim else '0';
  ctrl_clk <= not ctrl_clk after kCtrlClkPeriod/2 when not StopSim else '0';

  --vhook x4xx_pps_sync master_dut
  --vhook_a SIMULATION 1
  --vhook_a pps_in '0'
  --vhook_a pps_brc_delay m_pps_brc_delay
  --vhook_a {pps_(.?rc.*)} pps_$1
  --vhook_a {pps_(.*)} m_pps_$1
  --vhook_a {pll_sync_(.*)} m_pll_sync_$1
  --vhook_a pps_out_brc m_pps_refclk
  --vhook_a sync m_sync
  --vhook_a debug open
  master_dut: x4xx_pps_sync
    generic map (SIMULATION => 1)  --integer:=0
    port map (
      base_ref_clk     => base_ref_clk,        --in  wire
      pll_ref_clk      => pll_ref_clk,         --in  wire
      ctrl_clk         => ctrl_clk,            --in  wire
      radio_clk        => radio_clk,           --in  wire
      brc_rst          => brc_rst,             --in  wire
      pps_in           => '0',                 --in  wire
      pps_out_brc      => m_pps_refclk,        --out wire
      pps_out_rc       => m_pps_out_rc,        --out wire
      sync             => m_sync,              --out wire
      pps_select       => m_pps_select,        --in  wire[1:0]
      pll_sync_trigger => m_pll_sync_trigger,  --in  wire
      pll_sync_delay   => m_pll_sync_delay,    --in  wire[7:0]
      pll_sync_done    => m_pll_sync_done,     --out wire
      pps_brc_delay    => m_pps_brc_delay,     --in  wire[7:0]
      pps_prc_delay    => pps_prc_delay,       --in  wire[25:0]
      prc_rc_divider   => prc_rc_divider,      --in  wire[1:0]
      pps_rc_enabled   => pps_rc_enabled,      --in  wire
      debug            => open);               --out wire[1:0]

  --vhook x4xx_pps_sync slave_dut
  --vhook_a SIMULATION 0
  --vhook_a pps_in m_pps_refclk
  --vhook_a pps_brc_delay s_pps_brc_delay
  --vhook_a {pps_(.?rc.*)} pps_$1
  --vhook_a {pps_(.*)} s_pps_$1
  --vhook_a {pll_sync_(.*)} s_pll_sync_$1
  --vhook_a pps_out_brc s_pps_refclk
  --vhook_a sync s_sync
  --vhook_a pll_sync_done open
  slave_dut: x4xx_pps_sync
    generic map (SIMULATION => 0)  --integer:=0
    port map (
      base_ref_clk     => base_ref_clk,        --in  wire
      pll_ref_clk      => pll_ref_clk,         --in  wire
      ctrl_clk         => ctrl_clk,            --in  wire
      radio_clk        => radio_clk,           --in  wire
      brc_rst          => brc_rst,             --in  wire
      pps_in           => m_pps_refclk,        --in  wire
      pps_out_brc      => s_pps_refclk,        --out wire
      pps_out_rc       => s_pps_out_rc,        --out wire
      sync             => s_sync,              --out wire
      pps_select       => s_pps_select,        --in  wire[1:0]
      pll_sync_trigger => s_pll_sync_trigger,  --in  wire
      pll_sync_delay   => s_pll_sync_delay,    --in  wire[7:0]
      pll_sync_done    => open,                --out wire
      pps_brc_delay    => s_pps_brc_delay,     --in  wire[7:0]
      pps_prc_delay    => pps_prc_delay,       --in  wire[25:0]
      prc_rc_divider   => prc_rc_divider,      --in  wire[1:0]
      pps_rc_enabled   => pps_rc_enabled,      --in  wire
      debug            => debug);              --out wire[1:0]

  -- This process might not work in all cases during the first alignment of
  -- edges but it works well once the edges are aligned.
  -- During the first alignment the inner loop for generating kRadioClkMultiplier
  -- clock cycles for one PRC cycle is interrupted upon appearance of the aligned
  -- edge signal. This might skip cycles and / or shorten the current radio clock
  -- cycle.
  radioClkProcess : process
  begin
    wait until rising_edge(pll_ref_clk);
    radio_clk <= '1', '0' after kPllClkPeriod/2/kRadioClkMultiplier;
    for i in 2 to kRadioClkMultiplier loop
      wait until alignedEdge for kPllClkPeriod/kRadioClkMultiplier;
      radio_clk <= '1', '0' after kPllClkPeriod/2/kRadioClkMultiplier;
    end loop;
  end process;

  pllClkProcess: process
  begin
    pll_ref_clk <= '1', '0' after kPllClkPeriod/2;
    wait until alignedEdge for kPllClkPeriod;

    -- abort on stopsim
    if StopSim then
      wait;
    end if;
  end process;

  alignProcess: process
  begin
    -- sync procedure
    wait until s_sync = '1';
    for i in 0 to kLmkSyncCycles loop
      wait until rising_edge(base_ref_clk);
    end loop;
    alignedEdge <= true;
    wait until rising_edge(base_ref_clk);
    alignedEdge <= false;

    -- abort on stopsim
    if StopSim then
      wait;
    end if;
  end process;

  repeatAlignProcess: process
  begin
    wait until alignedEdge;
    l1 : loop
      repeatedAlignedEdge <= true, false after kRefClkPeriod;
      wait until alignedEdge for kPpsPeriod;
      if StopSim then
        wait;
      end if;
    end loop l1;
  end process;

  main: process
    -- time measurements
    variable startTime : time := 0 sec;
    variable endTime : time := 0 sec;
    variable expectedTime : time := 0 sec;
  begin
    --initial values
    m_pps_select <= (others => '0');
    m_pll_sync_delay <= (others => '0');
    m_pll_sync_trigger <= '0';
    s_pps_select <= (others => '0');
    s_pll_sync_delay <= std_logic_vector(to_unsigned(kSyncOffset, kPLL_SYNC_DELAYSize));
    s_pll_sync_trigger <= '0';

    m_pps_brc_delay <= std_logic_vector(to_unsigned(kLmkSyncCycles+kPpsToSyncEdges+kSyncOffset+kSlaveSyncDelay-kBrcDelayDiff, m_pps_brc_delay'length));
    s_pps_brc_delay <= std_logic_vector(to_unsigned(kLmkSyncCycles+kPpsToSyncEdges+kSyncOffset-kBrcDelayDiff, s_pps_brc_delay'length));
    -- 64 MHz PRC clock and 1ms PPS period in simulation -> 64000
    pps_prc_delay <= std_logic_vector(to_unsigned(64000-kPrcDelayDiff, pps_prc_delay'length));
    prc_rc_divider <= std_logic_vector(to_unsigned(kRadioClkMultiplier-kClkMultiplierDiff, prc_rc_divider'length));
    pps_rc_enabled <= '0';

    -- reset
    brc_rst <= '1';
    ClkWaitF(3, base_ref_clk);
    brc_rst <= '0';

    -- setup master to generate sync signal
    ClkWaitF(1, ctrl_clk);
    m_pps_select <= std_logic_vector(to_unsigned(kPPS_INT_10MHZ, kPPS_SELECTSize));

    -- setup slave to consume sync signal
    s_pps_select <= std_logic_vector(to_unsigned(kPPS_EXT, kPPS_SELECTSize));

    -- run sync 2 times
    for i in 0 to 1 loop

      -- wait for falling edge of PPS to trigger sync
      wait until falling_edge(m_pps_refclk) for kPpsPeriod;
      ClkWaitF(1, ctrl_clk);
      m_pll_sync_trigger <= '1';
      s_pll_sync_trigger <= '1';
      m_pll_sync_delay <= std_logic_vector(to_unsigned(i+kSyncOffset, kPLL_SYNC_DELAYSize));

      -- wait for rising edge of PPS
      wait until rising_edge(m_pps_refclk) for kPpsPeriod;
      startTime := now;
      expectedTime := (i+kPpsToSyncEdges+kSyncOffset)*kRefClkPeriod + 0.5*kRefClkPeriod;

      -- wait for rising edge of the SYNC signal
      wait until rising_edge(m_sync) for 2*expectedTime;
      endTime := now;
      -- check for expected amount of time
      assert (endTime - startTime) = expectedTime
        report "master LMK sync trigger does not meet the expectation of " & time'image(expectedTime) & "; actual time: " & time'image(endTime - startTime)
        severity error;

      -- check for slave sync
      startTime := now;
      expectedTime := (kSlaveSyncDelay-i)*kRefClkPeriod;
      wait until rising_edge(s_sync) for 2*expectedTime;
      endTime := now;
      assert (endTime - startTime) = expectedTime
        report "slave LMK sync trigger does not meet the expectation of " & time'image(expectedTime) & "; actual time: " & time'image(endTime - startTime)
        severity error;

      -- check for done after sync pulse ended
      wait until falling_edge(m_sync) for 100*kRefClkPeriod;
      assert m_sync = '0' report "falling edge of sync signal missing" severity error;
      wait until m_pll_sync_done = '1' for 10*kCtrlClkPeriod + 10*kRefClkPeriod;
      assert m_pll_sync_done = '1' report "PLL sync done signal missing" severity error;

      -- check that sync pulse is not issued a second time
      wait until rising_edge(m_pps_refclk) for kPpsPeriod;
      wait until rising_edge(m_sync) for 2*256*kRefClkPeriod;
      assert m_sync = '0' report "second sync pulse detected" severity error;

      -- reset sync state machine to IDLE
      ClkWaitF(1, ctrl_clk);
      m_pll_sync_trigger <= '0';
      s_pll_sync_trigger <= '0';
      wait until falling_edge(m_pll_sync_done) for 10*kCtrlClkPeriod + 10*kRefClkPeriod;
      assert m_pll_sync_done = '0' report "sync done did not deassert" severity error;

    end loop;

    -- assuming that the upper functionality of issuing LMK sync is working correctly
    -- assign correct values to sync master and slave correctly
    ClkWaitF(1, ctrl_clk);
    m_pll_sync_delay <= std_logic_vector(to_unsigned(kSlaveSyncDelay+kSyncOffset, kPLL_SYNC_DELAYSize));
    m_pll_sync_trigger <= '1';
    s_pll_sync_trigger <= '1';

    -- wait for clock to be aligned
    wait until s_sync = '1' for kPpsPeriod;
    activateChecks <= true;
    pps_rc_enabled <= '1';

    -- wait for 10 aligned clocks
    for i in 1 to 10 loop
      wait until rising_edge(s_pps_refclk) for kPpsPeriod;
    end loop;

    activateChecks <= false;
    StopSim <= true;

    -- check scoreboard results
    gScoreboard.PrintResults;
    assert gScoreboard.IsCovered("*")
      report "Some cover points not hit; see transcript to determine which"
      severity ERROR;
  end process;

  --vhook_e clock_period_check master_pps_brc_check
  --vhook_a clk m_pps_refclk
  --vhook_a expectedClockPeriod kPpsPeriod
  --vhook_a checkFallingEdges true
  master_pps_brc_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => kPpsPeriod,  --time:=0us
      checkFallingEdges   => true)        --boolean:=false
    port map (clk => m_pps_refclk); --in  std_logic

  --vhook_e clock_period_check slave_pps_brc_check
  --vhook_a clk s_pps_refclk
  --vhook_a expectedClockPeriod kPpsPeriod
  --vhook_a checkFallingEdges true
  slave_pps_brc_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => kPpsPeriod,  --time:=0us
      checkFallingEdges   => true)        --boolean:=false
    port map (clk => s_pps_refclk); --in  std_logic

   --vhook_e clock_period_check master_pps_rc_check
  --vhook_a clk m_pps_out_rc
  --vhook_a expectedClockPeriod kPpsPeriod
  --vhook_a checkFallingEdges false
   master_pps_rc_check: entity work.clock_period_check (test)
     generic map (
       expectedClockPeriod => kPpsPeriod,  --time:=0us
       checkFallingEdges   => false)       --boolean:=false
     port map (clk => m_pps_out_rc); --in  std_logic

  --vhook_e clock_period_check slave_pps_rc_check
  --vhook_a clk s_pps_out_rc
  --vhook_a expectedClockPeriod kPpsPeriod
  --vhook_a checkFallingEdges false
  slave_pps_rc_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => kPpsPeriod,  --time:=0us
      checkFallingEdges   => false)       --boolean:=false
    port map (clk => s_pps_out_rc); --in  std_logic

  ppsBrcCheck : process
  begin
    wait until falling_edge(base_ref_clk);
    if activateChecks and repeatedAlignedEdge then
      assert to_Boolean(debug(0)) report "the delayed PPS in BRC domain has to align with the aligned edge" severity error;
    end if;
  end process;

  ppsPrcCheck : process
  begin
    wait until debug(1) = '1';
    -- go to the falling edge during PPS active
    wait until falling_edge(pll_ref_clk);
    -- go to the next clock cycle
    wait until falling_edge(pll_ref_clk);
    if activateChecks then
      assert repeatedAlignedEdge report "the delayed PPS in PRC domain has to be in the PLL ref clk cycle before the aligned edge" severity error;
    end if;
  end process;

  ppsRcCheck : process
  begin
    wait until repeatedAlignedEdge = true;
    wait until falling_edge(radio_clk) for kPllClkPeriod/kRadioClkMultiplier;
    if activateChecks then
      assert s_pps_out_rc = '1' report "the slave PPS in RC domain has to align with the first cycle of radio clock after the aligned edge" severity error;
      assert m_pps_out_rc = '1' report "the master master and slave PPS have to align" severity error;
    end if;
  end process;

end test;
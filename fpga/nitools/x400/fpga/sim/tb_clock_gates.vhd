---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_clock_gates
--
-- Purpose:
-- This testbench mainly tests clock_gates and the different
-- circumstances under which clocks are enabled
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiUtilities.all;
  use work.PkgNiSim.all;
  use work.PkgRFDC_REGS_REGMAP.all;

library std;
  use std.env.finish;

entity tb_clock_gates is
end tb_clock_gates;

architecture test of tb_clock_gates is

  component clock_gates
    generic (kReliableClkPeriodNs : integer := 25);
    port (
      rPllReset_n            : in  std_logic;
      aPllLocked             : in  std_logic;
      ReliableClk            : in  std_logic;
      DataClk1xPll           : in  std_logic;
      DataClk2xPll           : in  std_logic;
      DataClk1x              : out std_logic;
      DataClk2x              : out std_logic;
      aEnableRfBufg1x        : out std_logic_vector(0 downto 0);
      aEnableRfBufg2x        : out std_logic_vector(0 downto 0);
      rPllLocked             : out std_logic;
      rSafeToEnableGatedClks : in  std_logic;
      rGatedBaseClksValid    : out std_logic;
      rSoftwareControl       : in  std_logic_vector(31 downto 0);
      rSoftwareStatus        : out std_logic_vector(31 downto 0));
  end component;

  --vhook_sigstart
  signal aEnableRfBufg1x: std_logic_vector(0 downto 0);
  signal aEnableRfBufg2x: std_logic_vector(0 downto 0);
  signal aPllLocked: std_logic;
  signal DataClk1x: std_logic := '0';
  signal DataClk2x: std_logic := '0';
  signal rGatedBaseClksValid: std_logic := '0';
  signal rPllLocked: std_logic;
  signal rPllReset_n: std_logic;
  signal rSafeToEnableGatedClks: std_logic := '0';
  signal rSoftwareControl: std_logic_vector(31 downto 0);
  signal rSoftwareStatus: std_logic_vector(31 downto 0);
  --vhook_sigend

  signal StopSim : boolean := false;
  signal TestStatus : TestStatusString_t := (others => ' ');

  signal s_axi_config_clk   : std_logic := '0';
  signal DataClk1xPll       : std_logic := '1';
  signal DataClk2xPll       : std_logic := '1';
  signal RfdcClk1xPll       : std_logic := '1';
  signal RfdcClk2xPll       : std_logic := '1';

  constant kDataClockPeriod : time := 12 ns;
  constant kData2ClockPeriod : time := 6 ns;
  constant kRfDcClockPeriod : time := 8 ns;
  constant kRfDc2ClockPeriod : time := 4 ns;
  constant kConfigClockPeriod : time := 25 ns;

  signal aCheckDataClk      : boolean := false;
  signal aCheckDataClk2x    : boolean := false;
  signal aExpectedRfdcCe    : std_logic := '-';
  signal aExpectedRfdcCe2x  : std_logic := '-';

  signal rExpectedSoftwareStatus : std_logic_vector(31 downto 0) := (others => '0');

  procedure ClkWait(signal clk : in std_logic; X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(clk);
    end loop;
  end procedure ClkWait;

begin

  VPrint(TestStatus);

  DataClk1xPll     <= not DataClk1xPll     after kDataClockPeriod/2    when not StopSim else '0';
  DataClk2xPll     <= not DataClk2xPll     after kData2ClockPeriod/2   when not StopSim else '0';
  RfdcClk1xPll     <= not RfdcClk1xPll     after kRfDcClockPeriod/2    when not StopSim else '0';
  RfdcClk2xPll     <= not RfdcClk2xPll     after kRfDc2ClockPeriod/2   when not StopSim else '0';
  s_axi_config_clk <= not s_axi_config_clk after kConfigClockPeriod/2  when not StopSim else '0';

  -- Check aEnableRfBufg1x propagation at all times
  CheckRfdcBuffer: process(RfdcClk1xPll)
  begin
    if rising_edge(RfdcClk1xPll) then
      assert aExpectedRfdcCe = aEnableRfBufg1x(0)
        report "Incorrect CE for RfdcClk1x" & LF &
          "Expected: " & Image(aExpectedRfdcCe) & LF &
          "Actual: " & Image(aEnableRfBufg1x(0))
        severity error;
    end if;
  end process CheckRfdcBuffer;

  -- Check aEnableRfBufg2x propagation at all times
  CheckRfdc2xBuffer: process(RfdcClk2xPll)
  begin
    if rising_edge(RfdcClk2xPll) then
      assert aExpectedRfdcCe2x = aEnableRfBufg2x(0)
        report "Incorrect CE for RfdcClk2x" & LF &
          "Expected: " & Image(aExpectedRfdcCe2x) & LF &
          "Actual: " & Image(aEnableRfBufg2x(0))
        severity error;
    end if;
  end process CheckRfdc2xBuffer;

  -- Check DataClk1x's proper propagation. We compare against
  -- a delayed version of the input clock to avoid delta-cycle
  -- issues.
  CheckDataClock : process(DataClk1xPll'delayed(kDataClockPeriod/4))
  begin
    if rising_edge(DataClk1xPll'delayed(kDataClockPeriod/4)) or
       falling_edge(DataClk1xPll'delayed(kDataClockPeriod/4)) then
      if aCheckDataClk then
        assert DataClk1x = DataClk1xPll
          report "Incorrect DataClk Propagation behavior" severity error;
      else
        assert DataClk1x = '0'
          report "Incorrect DataClk Disable behavior" severity error;
      end if;
    end if;
  end process CheckDataClock;

  -- Check DataClk2x's proper propagation. We compare against
  -- a delayed version of the input clock to avoid delta-cycle
  -- issues.
  CheckDataClock2x : process(DataClk2xPll'delayed(kData2ClockPeriod/4))
  begin
    if rising_edge(DataClk2xPll'delayed(kData2ClockPeriod/4)) or
       falling_edge(DataClk2xPll'delayed(kData2ClockPeriod/4)) then
      if aCheckDataClk2x then
        assert DataClk2x = DataClk2xPll
          report "Incorrect DataClk2x Propagation behavior" severity error;
      else
        assert DataClk2x = '0'
          report "Incorrect DataClk2x Disable behavior" severity error;
      end if;
    end if;
  end process CheckDataClock2x;

  -- Constantly compares the value in rSoftwareStatus to a expected signal
  CheckSoftwareStatus: process(s_axi_config_clk)
  begin
    if rising_edge(s_axi_config_clk) then
      for i in rSoftwareStatus'range loop
        assert rSoftwareStatus(i) = rExpectedSoftwareStatus(i)
          report  "Unexpected software status" & LF &
                  "bit : " & Image(i) & LF &
                  "Expected: " & Image(rExpectedSoftwareStatus(i)) & LF &
                  "Actual: " & Image(rSoftwareStatus(i))
          severity error;
      end loop;
    end if;
  end process CheckSoftwareStatus;

  -- rGatedBaseClksValid validation
  CheckClksValid: process(s_axi_config_clk)
  begin
    if rising_edge(s_axi_config_clk) then
      assert rGatedBaseClksValid = rPllLocked
        report  "Unexpected clks valid status" & LF &
                "Expected: " & Image(rPllLocked) & LF &
                "Actual: " & Image(rGatedBaseClksValid)
        severity error;
    end if;

  end process CheckClksValid;

  StimulusProcess: process

  begin
    VPrint(TestStatus);

    -- Initialize initial values for control signals and
    -- expected values
    TestStatus <= rs("Initialization");
    rExpectedSoftwareStatus <= (others => 'U');
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '0';
    rExpectedSoftwareStatus(kDATA_CLK_PLL_UNLOCKED_STICKY) <= '0';

    aExpectedRfdcCe2x   <= '0';
    aExpectedRfdcCe     <= '0';
    rSoftwareControl    <= (others => '0');

    rPllReset_n <= '0';
    ClkWait(s_axi_config_clk, 10);
    rPllReset_n <= '1';
    ClkWait(s_axi_config_clk, 10);

    -- CLOCK GATING
    --------------------------------------------------------------
    -- There are 3 conditions to be met for clocks to be enabled:
    -- - respective rSoftwareControl bit being high
    -- - rSafeToEnableGatedClks being high
    -- - rPllUnlockedSticky being low, this is reflected in
    --   rExpectedSoftwareStatus(kDATA_CLK_PLL_UNLOCKED_STICKY)
    --
    -- Any of the above conditions not being met results in an un-driven clock.
    -- We will test the behavior of each independent gating signal below

    -- We test that clocks are gated after setting only the rSoftwareControl bits.
    -- These fields will not be set in software until rPllLocked has asserted.
    aPllLocked <= '0';
    rSafeToEnableGatedClks <= '0';
    rSoftwareControl(kENABLE_DATA_CLK) <= '1';
    rSoftwareControl(kENABLE_DATA_CLK_2X) <= '1';
    rSoftwareControl(kENABLE_RF_CLK) <= '1';
    rSoftwareControl(kENABLE_RF_CLK_2X) <= '1';


    TestStatus <= rs("Test Idle");
    wait until rPllLocked = '1' for 200 us;
    assert rPllLocked = '0'
      report "PLL indicator should be de-asserted"
      severity error;

    -- We test that clocks are gated after setting rSafeToEnableGatedClks only.
    aPllLocked <= '1';
    rSafeToEnableGatedClks <= '0';

    TestStatus <= rs("Test PLL Locked Propagation");
    wait until rPllLocked = '1' for 200 us;
    assert rPllLocked = '1'
      report "PLL indicator should be asserted"
      severity error;
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '1';


    -- Test clock gating via PllUnlockedSticky
    TestStatus <= rs("Test PLL Unlocked Sticky");
    -- to stimulate the Pll unlocked bit, de-assert aPllLocked after rPllLocked
    -- had previously asserted
    aPllLocked <= '0';
    -- Allow for aPllLocked double synchronizer and PllUnlockedSticky
    -- flop to propagate
    ClkWait(s_axi_config_clk, 3);
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '0';
    rExpectedSoftwareStatus(kDATA_CLK_PLL_UNLOCKED_STICKY) <= '1';

    -- Validate that enabling has no effect, as now the clocks are
    -- gated by PllUnlockedSticky
    rSafeToEnableGatedClks <= '1';

    ClkWait(s_axi_config_clk, 10);

    -- Even re-asserting aPllLocked show have no effect on the
    -- clocks until the sticky bit is cleared
    TestStatus <= rs("Test Sticky Gate");
    aPllLocked <= '1';
    rSafeToEnableGatedClks <= '1';
    wait until rPllLocked = '1' for 200 us;
    assert rPllLocked = '1'
      report "PLL indicator should be asserted"
      severity error;
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '1';

    -- Clear the sticky bit
    TestStatus <= rs("Clear Sticky Status");
    rSoftwareControl(kCLEAR_DATA_CLK_UNLOCKED) <= '1';
    aPllLocked <= '0';
    rSafeToEnableGatedClks <= '0';
    -- allow for PllUnlockedSticky flop to register
    ClkWait(s_axi_config_clk, 1);
    rExpectedSoftwareStatus(kDATA_CLK_PLL_UNLOCKED_STICKY) <= '0';
    -- Let aPllLocked double synchronizer propagate
    ClkWait(s_axi_config_clk, 2);
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '0';

    -- Test clock and clock enable operations
    TestStatus <= rs("Test clock propagation");
    rSoftwareControl <= (others => '0');
    aPllLocked <= '1';
    rSafeToEnableGatedClks <= '1';
    wait until rPllLocked = '1' for 200 us;
    assert rPllLocked = '1'
      report "PLL indicator should be asserted"
      severity error;
    rExpectedSoftwareStatus(kDATA_CLK_PLL_LOCKED) <= '1';

    -- Once the PLL is locked, we can enable the functionality
    -- of the different clocks.


    -- Enable and validate DataClk1x
    TestStatus <= rs("Enable Data Clk");
    rSoftwareControl(kENABLE_DATA_CLK) <= '1';
    -- let input change be registered
    ClkWait(s_axi_config_clk, 1);
    aCheckDataClk <= true;
    ClkWait(s_axi_config_clk, 100);

    -- Enable and validate DataClk2x
    TestStatus <= rs("Enable Data Clk 2x");
    rSoftwareControl(kENABLE_DATA_CLK_2X) <= '1';
    -- let input change be registered
    ClkWait(s_axi_config_clk, 1);
    aCheckDataClk2x <= true;
    ClkWait(s_axi_config_clk, 100);

    -- Enable and validate RfdcClk1x
    TestStatus <= rs("Enable Rfdc Clk");
    rSoftwareControl(kENABLE_RF_CLK) <= '1';
    -- let input change be registered
    ClkWait(s_axi_config_clk, 1);
    aExpectedRfdcCe <= '1';
    ClkWait(s_axi_config_clk, 100);

    -- Enable and validate RfdcClk2x
    TestStatus <= rs("Enable Rfdc Clk 2x");
    rSoftwareControl(kENABLE_RF_CLK_2X) <= '1';
    -- let input change be registered
    ClkWait(s_axi_config_clk, 1);
    aExpectedRfdcCe2x <= '1';

    ClkWait(s_axi_config_clk, 100);

    StopSim <= true;
    wait;
  end process StimulusProcess;

  --vhook clock_gates
  --vhook_a kReliableClkPeriodNs 25
  --vhook_a ReliableClk s_axi_config_clk
  clock_gatesx: clock_gates
    generic map (kReliableClkPeriodNs => 25)  --integer:=25
    port map (
      rPllReset_n            => rPllReset_n,             --in  std_logic
      aPllLocked             => aPllLocked,              --in  std_logic
      ReliableClk            => s_axi_config_clk,        --in  std_logic
      DataClk1xPll           => DataClk1xPll,            --in  std_logic
      DataClk2xPll           => DataClk2xPll,            --in  std_logic
      DataClk1x              => DataClk1x,               --out std_logic
      DataClk2x              => DataClk2x,               --out std_logic
      aEnableRfBufg1x        => aEnableRfBufg1x,         --out std_logic_vector(0:0)
      aEnableRfBufg2x        => aEnableRfBufg2x,         --out std_logic_vector(0:0)
      rPllLocked             => rPllLocked,              --out std_logic
      rSafeToEnableGatedClks => rSafeToEnableGatedClks,  --in  std_logic
      rGatedBaseClksValid    => rGatedBaseClksValid,     --out std_logic
      rSoftwareControl       => rSoftwareControl,        --in  std_logic_vector(31:0)
      rSoftwareStatus        => rSoftwareStatus);        --out std_logic_vector(31:0)

end test;

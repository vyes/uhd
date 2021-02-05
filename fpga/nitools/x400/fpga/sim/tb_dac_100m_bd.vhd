---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_dac_100m_bd
--
-- Purpose:
-- This testbench mainly tests dac_100m_bd, but as a side effect it tests some
-- of rf_reset_controller and verifies that those two components are compatible
-- with each other.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiUtilities.all;
  use work.PkgNiSim.all;
  use work.PkgBusApi.all;

library std;
  use std.env.finish;

entity tb_dac_100m_bd is
end tb_dac_100m_bd;

architecture test of tb_dac_100m_bd is

  component dac_100m_bd
    port (
      dac_data_in_resetn_dclk   : in  STD_LOGIC;
      dac_data_in_resetn_rclk   : in  STD_LOGIC;
      dac_data_in_resetn_rclk2x : in  STD_LOGIC;
      data_clk                  : in  STD_LOGIC;
      rfdc_clk                  : in  STD_LOGIC;
      rfdc_clk_2x               : in  STD_LOGIC;
      dac_data_out_tdata        : out STD_LOGIC_VECTOR(63 downto 0);
      dac_data_out_tvalid       : out STD_LOGIC;
      dac_data_out_tready       : in  STD_LOGIC;
      dac_data_in_tdata         : in  STD_LOGIC_VECTOR(31 downto 0);
      dac_data_in_tvalid        : in  STD_LOGIC;
      dac_data_in_tready        : out STD_LOGIC);
  end component;

  --nisim --PreLoadCmd="source vsim_ops_dac_100m_bd.tcl"
  --nisim --op1="{*}$vsimOps"

  --vhook_sigstart
  signal cSoftwareControl: std_logic_vector(31 downto 0);
  signal dac_data_in_resetn_dclk: std_logic := '0';
  signal dac_data_in_resetn_rclk: std_logic := '0';
  signal dac_data_in_resetn_rclk2x: std_logic := '0';
  signal dac_data_in_tdata: STD_LOGIC_VECTOR(31 downto 0);
  signal dac_data_in_tready: STD_LOGIC;
  signal dac_data_in_tvalid: STD_LOGIC;
  signal dac_data_out_tdata: STD_LOGIC_VECTOR(63 downto 0);
  signal dac_data_out_tready: STD_LOGIC;
  signal dac_data_out_tvalid: STD_LOGIC;
  signal data_clk_2x: std_logic := '0';
  signal dDacResetPulse: std_logic;
  signal PllRefClk: std_logic := '0';
  signal s_axi_config_clk: std_logic := '0';
  --vhook_sigend

  signal ExpectOutputData : boolean := false;
  signal dOutputCount : natural;

  signal MeasureLatency : boolean;
  signal MeasureLatencyDone : boolean;
  signal Latency : time;

  signal StopSim : boolean := false;
  signal TestStatus : TestStatusString_t := (others => ' ');

  signal data_clk    : std_logic := '1';
  signal rfdc_clk    : std_logic := '1';
  signal rfdc_clk_2x : std_logic := '1';

  constant kPllRefClockPeriod : time := 18 ns;
  constant kDataClockPeriod   : time := 9 ns;
  constant kRfDcClockPeriod   : time := 6 ns;
  constant kRfDc2ClockPeriod  : time := 3 ns;

  procedure ClkWait(signal clk : in std_logic; X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(clk);
    end loop;
  end procedure ClkWait;

begin

  VPrint(TestStatus);

  PllRefClk   <= not PllRefClk   after kPllRefClockPeriod/2  when not StopSim else '0';
  data_clk    <= not data_clk    after kDataClockPeriod/2    when not StopSim else '0';
  rfdc_clk    <= not rfdc_clk    after kRfDcClockPeriod/2    when not StopSim else '0';
  rfdc_clk_2x <= not rfdc_clk_2x after kRfDc2ClockPeriod/2   when not StopSim else '0';

  DriverProcess: process

    procedure SendSomeData(count : natural := 50) is
      variable startingCount : natural;
    begin
      startingCount := dOutputCount;
      ExpectOutputData <= true;
      MeasureLatency <= true;
      for i in 1 to count loop
        ClkWait(data_clk);
        dac_data_in_tvalid <= '1';
        dac_data_in_tdata  <= (others=>'0');
      end loop;

      ClkWait(data_clk);
      dac_data_in_tvalid <= '0';
      dac_data_in_tdata <= (others => 'X');

      -- Output data should cease soon
      wait until rising_edge(data_clk) and dac_data_out_tvalid='0'
        for 10 ms;

      assert rising_edge(data_clk) and dac_data_out_tvalid='0'
        report "timed out waiting for last data output";

      -- There should be no more output data
      ExpectOutputData <= false;

      assert MeasureLatencyDone
        report "Latency measurement failed";

      MeasureLatency <= false;

      assert dOutputCount - startingCount = count
        report "received wrong amount of data"  & LF
             & "Expected = " & integer'image(dOutputCount-startingCount) & LF
             & "Actual = " & integer'image(count) severity error;
    end procedure SendSomeData;

    procedure Reset is
    begin
      cSoftwareControl <= (others => '0');

      dac_data_in_tdata <= (others => 'X');
      dac_data_in_tvalid <= '0';
      -- Assert the output TREADY (and keep it asserted)
      dac_data_out_tready <= '1';

      -- Assert all resets.
      dDacResetPulse <= '1';
      ClkWait(data_clk);
      dDacResetPulse <= '0';

      wait until (dac_data_in_resetn_dclk='1')
            and (dac_data_in_resetn_rclk='1')
            and (dac_data_in_resetn_rclk2x='1')
        for 10 ms;

      assert (dac_data_in_resetn_dclk='1')
         and (dac_data_in_resetn_rclk='1')
         and (dac_data_in_resetn_rclk2x='1')
        report "timeout waiting for reset deassertion";

    end procedure Reset;

  begin

    Reset;


    SendSomeData;

    Reset;

    SendSomeData;

    StopSim <= true;

    -- finish(2);
    wait;
  end process DriverProcess;

  ValidMonitor: process(data_clk) is
  begin
    if rising_edge(data_clk) then
      if (dac_data_out_tvalid and dac_data_out_tready) = '1' then
        dOutputCount <= dOutputCount + 1;
        assert dac_data_out_tdata = Zeros(dac_data_out_tdata'length)
          report "output should be always 0"
          severity ERROR;

        assert ExpectOutputData
          report "detected unexpected data"
          severity ERROR;
      end if;
    end if;
  end process ValidMonitor;

  LatencyMonitor: process is
    variable startTime : time;
  begin
    wait until MeasureLatency;
    wait until (dac_data_in_tvalid and dac_data_in_tready)='1'
         for 10 ms;
    assert (dac_data_in_tvalid and dac_data_in_tready)='1'
      report "timeout waiting for input data";

    startTime := now;

    wait until (dac_data_out_tvalid and dac_data_out_tready)='1'
         for 10 ms;
    assert (dac_data_out_tvalid and dac_data_out_tready)='1'
      report "timeout waiting for output data";

    Latency <= now - startTime;
    MeasureLatencyDone <= true;
    wait until not MeasureLatency;
    MeasureLatencyDone <= false;

  end process LatencyMonitor;

  --vhook dac_100m_bd
  dac_100m_bdx: dac_100m_bd
    port map (
      dac_data_in_resetn_dclk   => dac_data_in_resetn_dclk,    --in  STD_LOGIC
      dac_data_in_resetn_rclk   => dac_data_in_resetn_rclk,    --in  STD_LOGIC
      dac_data_in_resetn_rclk2x => dac_data_in_resetn_rclk2x,  --in  STD_LOGIC
      data_clk                  => data_clk,                   --in  STD_LOGIC
      rfdc_clk                  => rfdc_clk,                   --in  STD_LOGIC
      rfdc_clk_2x               => rfdc_clk_2x,                --in  STD_LOGIC
      dac_data_out_tdata        => dac_data_out_tdata,         --out STD_LOGIC_VECTOR(63:0)
      dac_data_out_tvalid       => dac_data_out_tvalid,        --out STD_LOGIC
      dac_data_out_tready       => dac_data_out_tready,        --in  STD_LOGIC
      dac_data_in_tdata         => dac_data_in_tdata,          --in  STD_LOGIC_VECTOR(31:0)
      dac_data_in_tvalid        => dac_data_in_tvalid,         --in  STD_LOGIC
      dac_data_in_tready        => dac_data_in_tready);        --out STD_LOGIC


  --vhook_e rf_reset_controller
  --vhook_a ConfigClk s_axi_config_clk
  --vhook_a DataClk   data_clk
  --vhook_a RfClk     rfdc_clk
  --vhook_a RfClk2x   rfdc_clk_2x
  --vhook_a dAdcResetPulse   '0'
  --vhook_a dDacResetPulse   dDacResetPulse
  --vhook_#
  --vhook_a dAdcDataOutReset_n  open
  --vhook_a r2AdcFirReset_n     open
  --vhook_a rAdcRfdcAxiReset_n  open
  --vhook_a rAdcEnableData      open
  --vhook_a rAdcGearboxReset_n  open
  --vhook_#
  --vhook_a dDacDataInReset_n   dac_data_in_resetn_dclk
  --vhook_a r2DacFirReset_n     dac_data_in_resetn_rclk2x
  --vhook_a rDacRfdcAxiReset_n  open
  --vhook_a rDacGearboxReset_n dac_data_in_resetn_rclk
  --vhook_#
  --vhook_a d2DacFirReset_n     open
  --vhook_a DataClk2x           data_clk_2x
  --vhook_a cSoftwareStatus     open
  rf_reset_controllerx: entity work.rf_reset_controller (RTL)
    port map (
      ConfigClk          => s_axi_config_clk,           --in  std_logic
      DataClk            => data_clk,                   --in  std_logic
      PllRefClk          => PllRefClk,                  --in  std_logic
      RfClk              => rfdc_clk,                   --in  std_logic
      RfClk2x            => rfdc_clk_2x,                --in  std_logic
      DataClk2x          => data_clk_2x,                --in  std_logic
      dAdcResetPulse     => '0',                        --in  std_logic
      dDacResetPulse     => dDacResetPulse,             --in  std_logic
      dAdcDataOutReset_n => open,                       --out std_logic
      r2AdcFirReset_n    => open,                       --out std_logic
      rAdcRfdcAxiReset_n => open,                       --out std_logic
      rAdcEnableData     => open,                       --out std_logic
      rAdcGearboxReset_n => open,                       --out std_logic
      dDacDataInReset_n  => dac_data_in_resetn_dclk,    --out std_logic
      r2DacFirReset_n    => dac_data_in_resetn_rclk2x,  --out std_logic
      d2DacFirReset_n    => open,                       --out std_logic
      rDacRfdcAxiReset_n => open,                       --out std_logic
      rDacGearboxReset_n => dac_data_in_resetn_rclk,    --out std_logic
      cSoftwareControl   => cSoftwareControl,           --in  std_logic_vector(31:0)
      cSoftwareStatus    => open);                      --out std_logic_vector(31:0)


end test;

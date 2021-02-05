---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_adc_100m_bd
--
-- Purpose:
-- This testbench mainly tests adc_100m_bd, but as a side effect it tests some
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
  use work.PkgRFDC_REGS_REGMAP.all;

library std;
  use std.env.finish;

entity tb_adc_100m_bd is
end tb_adc_100m_bd;

architecture test of tb_adc_100m_bd is

  component adc_100m_bd
    port (
      adc_data_out_resetn_dclk : in  STD_LOGIC;
      data_clk                 : in  STD_LOGIC;
      enable_data_to_fir_rclk  : in  STD_LOGIC;
      fir_resetn_rclk2x        : in  STD_LOGIC;
      rfdc_adc_axi_resetn_rclk : in  STD_LOGIC;
      rfdc_clk                 : in  STD_LOGIC;
      rfdc_clk_2x              : in  STD_LOGIC;
      swap_iq_2x               : in  STD_LOGIC;
      adc_data_out_tvalid      : out STD_LOGIC;
      adc_data_out_tdata       : out STD_LOGIC_VECTOR(31 downto 0);
      adc_i_data_in_tvalid     : in  STD_LOGIC;
      adc_i_data_in_tready     : out STD_LOGIC;
      adc_i_data_in_tdata      : in  STD_LOGIC_VECTOR(31 downto 0);
      adc_q_data_in_tvalid     : in  STD_LOGIC;
      adc_q_data_in_tready     : out STD_LOGIC;
      adc_q_data_in_tdata      : in  STD_LOGIC_VECTOR(31 downto 0));
  end component;

  --nisim --PreLoadCmd="source vsim_ops_adc_100m_bd.tcl"
  --nisim --op1="{*}$vsimOps"

  --vhook_sigstart
  signal adc_data_out_resetn_dclk: std_logic := '0';
  signal adc_data_out_tdata: STD_LOGIC_VECTOR(31 downto 0);
  signal adc_data_out_tvalid: STD_LOGIC;
  signal adc_i_data_in_tdata: STD_LOGIC_VECTOR(31 downto 0);
  signal adc_i_data_in_tready: STD_LOGIC;
  signal adc_i_data_in_tvalid: STD_LOGIC;
  signal adc_q_data_in_tdata: STD_LOGIC_VECTOR(31 downto 0);
  signal adc_q_data_in_tready: STD_LOGIC;
  signal adc_q_data_in_tvalid: STD_LOGIC;
  signal adc_reset_pulse_dclk: std_logic := '0';
  signal cSoftwareControl: std_logic_vector(31 downto 0);
  signal data_clk_2x: std_logic := '0';
  signal enable_adc_data_rclk: std_logic := '0';
  signal fir_resetn_rclk2x: std_logic := '0';
  signal PllRefClk: std_logic := '0';
  signal rfdc_adc_resetn_rclk: std_logic := '0';
  signal swap_iq_2x: STD_LOGIC;
  --vhook_sigend

  signal StopSim : boolean := false;
  signal TestStatus : TestStatusString_t := (others => ' ');

  signal s_axi_config_clk : std_logic := '0';
  signal data_clk    : std_logic := '1';
  signal rfdc_clk    : std_logic := '1';
  signal rfdc_clk_2x : std_logic := '1';

  signal MeasureLatency : boolean;
  signal MeasureLatencyDone : boolean;
  signal Latency : time;

  constant kPllRefClockPeriod : time := 18 ns;
  constant kDataClockPeriod : time := 9 ns;
  constant kRfDcClockPeriod : time := 6 ns;
  constant kRfDc2ClockPeriod : time := 3 ns;
  constant kConfigClockPeriod : time := 1 ns;

  procedure ClkWait(signal clk : in std_logic; X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(clk);
    end loop;
  end procedure ClkWait;

  signal data_out_i, data_out_q : std_logic_vector(15 downto 0) := (others => '0');

begin

  VPrint(TestStatus);

  PllRefClk   <= not PllRefClk   after kPllRefClockPeriod/2  when not StopSim else '0';
  data_clk    <= not data_clk    after kDataClockPeriod/2    when not StopSim else '0';
  rfdc_clk    <= not rfdc_clk    after kRfDcClockPeriod/2    when not StopSim else '0';
  rfdc_clk_2x <= not rfdc_clk_2x after kRfDc2ClockPeriod/2   when not StopSim else '0';
  s_axi_config_clk <= not s_axi_config_clk after kConfigClockPeriod/2   when not StopSim else '0';

  -- RFDC is not throttled and is always providing ADC data.
  rfdc_model:process (rfdc_clk) is
    variable tempdata : integer := 1;
    variable rand : Random_t;
  begin
    if rising_edge(rfdc_clk) then
      adc_i_data_in_tvalid <= '1';
      adc_q_data_in_tvalid <= '1';
      adc_i_data_in_tdata <= rand.GetStdLogicVector(adc_i_data_in_tdata'length);
      adc_q_data_in_tdata <= (others => '0');
      tempData := tempData + 1;
    end if;
  end process rfdc_model;

  DriverProcess: process

    -- This expected latency is a function of the simulated clock periods in
    -- this testbench, but the fact that this test will fail if the latency
    -- changes, means we could, in principle anyway, document our input latency.
    -- If you make a change that breaks the latency test, you must change the
    -- expected value, but you should also update the documented latency. The
    -- documented latency should take into consideration the actual clock
    -- period.
    constant ExpectedLatency : time := 99 ns;

    procedure SendSomeData is
    begin
      TestStatus <= rs("Begin SendSomeData");
      MeasureLatency <= true;

      wait until enable_adc_data_rclk = '1' for kDataClockPeriod*1000;
      assert enable_adc_data_rclk = '1'
        report "enable_adc_data_rclk failed to de-assert"
        severity error;

      assert (adc_i_data_in_tready = '1' and adc_q_data_in_tready = '1')
        report "Core not reporting TREADY after reset de-assertion"
        severity error;

      wait until rising_edge(rfdc_clk);

      assert MeasureLatencyDone
        report "Latency measurement failed" severity error;
      TestStatus <= rs("latency = " & time'image(Latency));

      -- After the latency has been measured once, all subsequent measurements
      -- should be the same.
      assert Latency = ExpectedLatency
        report "Latency mismatch." & LF
             & "Expected = " & time'image(ExpectedLatency) & LF
             & "Actual = " & time'image(Latency) severity error;

      MeasureLatency <= false;

      wait until not MeasureLatencyDone for 10 us;
      assert not MeasureLatencyDone report "timeout on not latency done";

      if swap_iq_2x = '0' then
        -- The output monitor does not model the DUT's data transformation, but it
        -- does verify that the i/q data does not get swapped. By driving only 0 Q
        -- data at the input, we can then check that the output Q data has always
        -- been 0.
        assert data_out_q = Zeros(data_out_q'length)
          report "output imaginary part should be 0";

        assert data_out_i /= Zeros(data_out_i'length)
            and not is_X(data_out_i)
          report "output real part should be non-0";
      else
        -- In this case, the data is supposed to be swapped
        assert data_out_q /= Zeros(data_out_q'length)
            and not is_X(data_out_q)
          report "output imaginary part should be non-0";

        assert data_out_i = Zeros(data_out_i'length)
          report "output real part should be 0";
      end if;
      TestStatus <= rs("Exit SendSomeData");
    end procedure SendSomeData;

    procedure Reset is
    begin
      TestStatus <= rs("Begin Reset");

      -- Assert all ADC resets.
      adc_reset_pulse_dclk <= '1';
      ClkWait(data_clk);
      adc_reset_pulse_dclk <= '0';
      ClkWait(data_clk, 50);

      wait until rfdc_adc_resetn_rclk = '1' for kDataClockPeriod*1000;
      assert rfdc_adc_resetn_rclk = '1'
        report "rfdc_adc_resetn_rclk failed to de-assert"
        severity error;
      TestStatus <= rs("Exit Reset");
    end procedure Reset;

    procedure SetPhase (aligned : boolean) is
    begin
      TestStatus <= rs("Begin SetPhase(" & boolean'image(aligned) & ")");
      if aligned then
        wait until rising_edge(rfdc_clk) and rising_edge(data_clk);
      else
        wait until falling_edge(rfdc_clk) and rising_edge(data_clk);
      end if;
      TestStatus <= rs("Exit SetPhase");
    end procedure SetPhase;

  begin
    VPrint(TestStatus);

    swap_iq_2x <= '0';

    adc_reset_pulse_dclk <= '0';
    cSoftwareControl(kADC_RESET) <= '0';
    cSoftwareControl(kDAC_RESET) <= '0';
    cSoftwareControl(kADC_ENABLE) <= '0';
    cSoftwareControl(kDAC_ENABLE) <= '0';

    Reset;
    SetPhase(true);
    SendSomeData;

    Reset;
    SetPhase(false);
    SendSomeData;

    Reset;
    SetPhase(true);
    SendSomeData;

    swap_iq_2x <= '1';

    Reset;
    SetPhase(false);
    SendSomeData;

    Reset;
    SetPhase(true);
    SendSomeData;

    Reset;
    StopSim <= true;
    wait;
  end process DriverProcess;

  LatencyMonitor: process is
    variable startTime : time;
  begin
    wait until adc_data_out_resetn_dclk='1'
         for 10 us;
    assert adc_data_out_resetn_dclk='1'
      report "timeout waiting for reset to be de-asserted";

    startTime := now;

    wait until (adc_data_out_tvalid)='1'
         for 10 us;
    assert (adc_data_out_tvalid)='1'
      report "timeout waiting for output data";

    Latency <= now - startTime;
    MeasureLatencyDone <= true;
    wait until not MeasureLatency;
    MeasureLatencyDone <= false;

  end process LatencyMonitor;

  -- The data monitor keeps a running "OR" of the output data so the testbench
  -- can easily detect I/Q data swapping.
  DataMonitor: process(data_clk) is
  begin
    if rising_edge(data_clk) then
      if rfdc_adc_resetn_rclk='0' then
        data_out_q <= (others => '0');
        data_out_i <= (others => '0');
      elsif (adc_data_out_tvalid)='1' then
        data_out_q <= data_out_q or adc_data_out_tdata(31 downto 16);
        data_out_i <= data_out_i or adc_data_out_tdata(15 downto 0);
      end if;
    end if;
  end process DataMonitor;

  --vhook adc_100m_bd
  --vhook_a enable_data_to_fir_rclk enable_adc_data_rclk
  --vhook_a rfdc_adc_axi_resetn_rclk rfdc_adc_resetn_rclk
  adc_100m_bdx: adc_100m_bd
    port map (
      adc_data_out_resetn_dclk => adc_data_out_resetn_dclk,  --in  STD_LOGIC
      data_clk                 => data_clk,                  --in  STD_LOGIC
      enable_data_to_fir_rclk  => enable_adc_data_rclk,      --in  STD_LOGIC
      fir_resetn_rclk2x        => fir_resetn_rclk2x,         --in  STD_LOGIC
      rfdc_adc_axi_resetn_rclk => rfdc_adc_resetn_rclk,      --in  STD_LOGIC
      rfdc_clk                 => rfdc_clk,                  --in  STD_LOGIC
      rfdc_clk_2x              => rfdc_clk_2x,               --in  STD_LOGIC
      swap_iq_2x               => swap_iq_2x,                --in  STD_LOGIC
      adc_data_out_tvalid      => adc_data_out_tvalid,       --out STD_LOGIC
      adc_data_out_tdata       => adc_data_out_tdata,        --out STD_LOGIC_VECTOR(31:0)
      adc_i_data_in_tvalid     => adc_i_data_in_tvalid,      --in  STD_LOGIC
      adc_i_data_in_tready     => adc_i_data_in_tready,      --out STD_LOGIC
      adc_i_data_in_tdata      => adc_i_data_in_tdata,       --in  STD_LOGIC_VECTOR(31:0)
      adc_q_data_in_tvalid     => adc_q_data_in_tvalid,      --in  STD_LOGIC
      adc_q_data_in_tready     => adc_q_data_in_tready,      --out STD_LOGIC
      adc_q_data_in_tdata      => adc_q_data_in_tdata);      --in  STD_LOGIC_VECTOR(31:0)

  --vhook_e rf_reset_controller
  --vhook_a ConfigClk s_axi_config_clk
  --vhook_a DataClk   data_clk
  --vhook_a RfClk     rfdc_clk
  --vhook_a RfClk2x   rfdc_clk_2x
  --vhook_a dAdcResetPulse   adc_reset_pulse_dclk
  --vhook_a dDacResetPulse   '0'
  --vhook_#
  --vhook_a dAdcDataOutReset_n  adc_data_out_resetn_dclk
  --vhook_a r2AdcFirReset_n     fir_resetn_rclk2x
  --vhook_a rAdcRfdcAxiReset_n  open
  --vhook_a rAdcGearboxReset_n  rfdc_adc_resetn_rclk
  --vhook_a rAdcEnableData      enable_adc_data_rclk
  --vhook_#
  --vhook_a dDacDataInReset_n   open
  --vhook_a r2DacFirReset_n     open
  --vhook_a rDacRfdcAxiReset_n  open
  --vhook_a rDacGearboxReset_n  open
  --vhook_#
  --vhook_a d2DacFirReset_n     open
  --vhook_a DataClk2x           data_clk_2x
  --vhook_a cSoftwareStatus     open
  rf_reset_controllerx: entity work.rf_reset_controller (RTL)
    port map (
      ConfigClk          => s_axi_config_clk,          --in  std_logic
      DataClk            => data_clk,                  --in  std_logic
      PllRefClk          => PllRefClk,                 --in  std_logic
      RfClk              => rfdc_clk,                  --in  std_logic
      RfClk2x            => rfdc_clk_2x,               --in  std_logic
      DataClk2x          => data_clk_2x,               --in  std_logic
      dAdcResetPulse     => adc_reset_pulse_dclk,      --in  std_logic
      dDacResetPulse     => '0',                       --in  std_logic
      dAdcDataOutReset_n => adc_data_out_resetn_dclk,  --out std_logic
      r2AdcFirReset_n    => fir_resetn_rclk2x,         --out std_logic
      rAdcRfdcAxiReset_n => open,                      --out std_logic
      rAdcEnableData     => enable_adc_data_rclk,      --out std_logic
      rAdcGearboxReset_n => rfdc_adc_resetn_rclk,      --out std_logic
      dDacDataInReset_n  => open,                      --out std_logic
      r2DacFirReset_n    => open,                      --out std_logic
      d2DacFirReset_n    => open,                      --out std_logic
      rDacRfdcAxiReset_n => open,                      --out std_logic
      rDacGearboxReset_n => open,                      --out std_logic
      cSoftwareControl   => cSoftwareControl,          --in  std_logic_vector(31:0)
      cSoftwareStatus    => open);                     --out std_logic_vector(31:0)

end test;

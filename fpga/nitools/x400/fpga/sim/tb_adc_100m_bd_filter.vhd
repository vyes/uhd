---------------------------------------------------------------------
--
-- Copyright 2021 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_adc_100m_bd_filter
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
  use ieee.math_real.all;
  use ieee.math_complex.all;

library work;
  use work.PkgNiUtilities.all;
  use work.PkgNiSim.all;
  use work.PkgBusApi.all;
  use work.PkgRFDC_REGS_REGMAP.all;
  use work.PkgDSP.all;
  use work.PkgAdc100mBD.all;

library std;
  use std.env.finish;

entity tb_adc_100m_bd_filter is
end tb_adc_100m_bd_filter;

architecture test of tb_adc_100m_bd_filter is

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

  constant kPllRefClockPeriod : time := 18 ns;
  constant kDataClockPeriod : time := 9 ns;
  constant kRfDcClockPeriod : time := 6 ns;
  constant kRfDc2ClockPeriod : time := 3 ns;
  constant kConfigClockPeriod : time := 1 ns;

  -- adc_100m_bd decimates by 3, and this testbench is only prepared to deal
  -- with whole numbers, so kInputWordCount should be a multiple of 3.
  constant kDecimationRatio : positive := 3;
  constant kInputWordCount : natural := kDecimationRatio*100;

  procedure ClkWait(signal clk : in std_logic; X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(clk);
    end loop;
  end procedure ClkWait;

  /*
  -- A delta function input makes the output FFT easy to visualize. Any phase
  -- that is not an integer multiple of MATH_PI or MATH_PI/2.0 will produce a
  -- stimulus with non-zero real and imaginary parts. The main downside of using
  -- a delta-cycle stimulus is that only one input word is non-zero. However,
  -- there will be many non-zero words beginning with the output of the FIR.
  constant kSig : ComplexArray_t(0 to 1023) :=
    (1 => POLAR_TO_COMPLEX((mag=>1.0, arg=>MATH_PI/4.0)),
    others => MATH_CZERO);
  */

  shared variable Rand : Random_t;

  -- A complex random number might occasionally be a good stimulus choice.
  impure function CRand (N : natural ) return ComplexArray_t is
    variable rval : ComplexArray_t(0 to N-1);
  begin
    for i in rval'range loop
      rval(i) :=polar_to_complex( (MAG => Rand.GetReal(0.5), ARG => Rand.GetReal(math_2_pi)-math_pi));
    end loop;
    return rval;
  end function CRand;

  -- An alternative stimulus is drive tones at several frequencies below and
  -- above cutoff.
  -- The ComplexSignal function receives two parameters to generate a
  -- discrete frequency stimuli:
  --   ComplexSignal(Cycles, Samples)
  --
  -- A discrete frequency is known as the normalized frequency (fn) and
  -- is measured in cycles per sample. This normalized frequency comes
  -- from dividing analog frequency (f) over sampling frequency (fs):
  --
  --                           f   [cycles/sec]
  --   fn [cycles/samples] = -----
  --                           fs  [samples/sec]
  --
  -- The normalized frequency ranges from 0.0 to 1.0, which corresponds
  -- to a real frequency range of 0 to the sampling frequency (fs).
  --
  -- For this testbench, the Samples value is arbitrarily set to 256.
  -- Also, we only care about producing stimuli from 0 to fs/2 (Nyquist
  -- rate).
  --
  -- So, if fn = 1.0 for a signal with f = fs:
  --   1.0 = cycles / samples
  -- Then,
  --   cycles = samples / 1.0
  -- Hence, for fs/2:
  --   cycles = samples / 0.5 = 256 / 0.5 = 128
  --
  -- The expected frequency response of the DUT is a low-pass filter
  -- starting to roll off at around 0.33 (normalized frequency) based on
  -- its /3 decimation factor.
  -- Note that the 0.33 is the normalized frequency for the filter,
  -- which is different to the normalized frequency of the generated
  -- stimuli. In other words, the filter's fn = 1.0 is equivalent to the
  -- stimulus' fn = 0.5 = fs/2.
  -- Based on this, the following Cycles values were chosen to create
  -- stimuli at different "locations" of the filter's response:
  --
  -- -------------------------\
  --      :                  : \
  --      :                  :  \
  --      :                  :  :\
  --      :                  :  : \
  --      :                  :  :  \
  --      :                  :  :   \_________...________________
  --      :                  :  :       :          :
  --   0.08                0.3  0.35  0.4       0.76  (Filter's fn)
  --      :                  :  :       :          :
  --     10                 38  45     51         97  (Signal's Cycles)
  constant kSig : ComplexArray_t :=
      ComplexSignal (10, 256)
   &  ComplexSignal (38, 256)
   &  ComplexSignal (45, 256)
   &  ComplexSignal (51, 256)
   &  ComplexSignal (97, 256);

  -- Quantize converts the input to fixed-point and back to floating point. This
  -- is useful for the testbench to more closely mimic the input values while
  -- keeping the convenience of floating point numbers.
  function Quantize (C : ComplexArray_t ) return ComplexArray_t is
    variable rval : ComplexArray_t ( C'range );
  begin
    for i in C'range loop
      rval(i) := to_Complex(to_SLV32(C(i)));
    end loop;
    return rval;
  end function Quantize;

  constant kSampledSig : ComplexArray_t := Quantize(kSig);

  --vhook_nowarn InputData
  --vhook_nowarn InputDataPolar
  -- InputData and InputDataPolar have no readers, but they can be useful
  -- waveforms when debugging.
  signal InputData : complex := MATH_CZERO;
  signal InputDataPolar : complex_polar := (others => 0.0);

  --vhook_nowarn DUTOutputDataSig
  --vhook_nowarn ExpectedOutputDataSig
  -- DUTOutputDataSig and ExpectedOutputDataSig have no readers, but they can be
  -- useful waveforms when debugging.
  signal DUTOutputDataSig : complex := MATH_CZERO;
  signal ExpectedOutputDataSig : complex := MATH_CZERO;

  -- Because the signal chain ends with a scale by 2, the least significant
  -- non-zero bit is 2^-14 instead of 2^-15 as you'd expect for a 1.15 formatted
  -- fixed point number:
  constant kLSb : real := 2.0 ** (-14.0);

  -- The LV VI this test is based on expected the floating point calculation to
  -- match the DUT's output within 1 LSB, but this testbench disagrees with the
  -- DUT output by up to two LSB's occasionally for reasons I haven't diagnosed.
  constant kMaxMismatch : real := kLSb * 2.0; -- two LSb's
  signal MismatchSig : complex := MATH_CZERO;
  signal MaxMismatchSig : complex := MATH_CZERO;

  constant kOutputLength : natural := kSig'length + kFIR'length - 1;
  constant kPaddedOutputLength : natural := 2**log2(kOutputLength);

  signal DUTOutputs : ComplexArray_t(0 to kPaddedOutputLength-1) := (others => MATH_CZERO);

  --vhook_nowarn DUTOutputsFFT
  -- DUTOutputsFFT is a debugging convenience. When kSig is a delta function,
  -- add this signal to a Modelsim waveform and format the MagnitudeIndB as
  -- analog with max = -9.5 and min = -15. The waveform will show the filter's
  -- response in log-log format. It might be helpful to also format the
  -- Frequency field as an analog with the range 0 to 1 to visualize the
  -- normalized frequency in the time dimension of the waveform.
  signal DUTOutputsFFT : FFTVisual_t;
begin

  VPrint(TestStatus);

  PllRefClk   <= not PllRefClk   after kPllRefClockPeriod/2  when not StopSim else '0';
  data_clk    <= not data_clk    after kDataClockPeriod/2    when not StopSim else '0';
  rfdc_clk    <= not rfdc_clk    after kRfDcClockPeriod/2    when not StopSim else '0';
  rfdc_clk_2x <= not rfdc_clk_2x after kRfDc2ClockPeriod/2   when not StopSim else '0';
  s_axi_config_clk <= not s_axi_config_clk after kConfigClockPeriod/2   when not StopSim else '0';

  rfdc_model:process is
    variable word1 : std_logic_vector(31 downto 0);
    variable word2 : std_logic_vector(31 downto 0);
  begin
      adc_i_data_in_tvalid <= '0';
      adc_q_data_in_tvalid <= '0';
      adc_i_data_in_tdata <= (others => 'X');
      adc_q_data_in_tdata <= (others => 'X');
    wait until rfdc_adc_resetn_rclk = '1' and enable_adc_data_rclk='1' and rising_edge(rfdc_clk);
    wait until rising_edge(rfdc_clk);
      adc_i_data_in_tvalid <= '1';
      adc_q_data_in_tvalid <= '1';
      for i in 0 to kSig'length/2 - 1 loop
        word2 := to_SLV32(kSig(i*2));
        word1 := to_SLV32(kSig(i*2+1));
        adc_i_data_in_tdata <=  word1(15 downto 0) & word2(15 downto 0);
        adc_q_data_in_tdata <=  word1(31 downto 16) & word2(31 downto 16);
        wait until rising_edge(rfdc_clk);
      end loop;
      adc_i_data_in_tvalid <= '0';
      adc_q_data_in_tvalid <= '0';
      adc_i_data_in_tdata <= (others => 'X');
      adc_q_data_in_tdata <= (others => 'X');
    wait;

  end process rfdc_model;

  -- This process drives InputData and InputDataPolar strictly as a convenience
  -- for debugging. It's simple to watch a waveform of InputData one sample at a
  -- time instead of 2 samples per cycle.
  StimulusVisual: process is
  begin
    wait until rfdc_adc_resetn_rclk='1' and enable_adc_data_rclk='1' and rising_edge(rfdc_clk);
    for i in kSampledSig'range loop
      InputData <= kSampledSig(i);
      InputDataPolar <= COMPLEX_TO_POLAR(kSampledSig(i));

      -- Since we're sending two samples per cycle, wait on either clock edge
      wait on rfdc_clk;
    end loop;
    wait;
  end process StimulusVisual;

  DriverProcess: process

    procedure SendSomeData is
    begin
      TestStatus <= rs("Begin SendSomeData");

      wait until enable_adc_data_rclk = '1' for kDataClockPeriod*1000;
      assert enable_adc_data_rclk = '1'
        report "enable_adc_data_rclk failed to de-assert"
        severity error;

      assert (adc_i_data_in_tready = '1' and adc_q_data_in_tready = '1')
        report "Core not reporting TREADY after reset de-assertion"
        severity error;

      -- Drive some data on the bus
      ClkWait(rfdc_clk, kInputWordCount);

      wait until rising_edge(rfdc_clk);

      wait until rising_edge(data_clk) and adc_data_out_tvalid ='0'
                 for 10 ms;

      assert rising_edge(data_clk) and adc_data_out_tvalid ='0'
        report "timeout waiting for last data output";

      TestStatus <= rs("Exit SendSomeData");
      ClkWait(data_clk);
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
      ClkWait(data_clk);
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
      ClkWait(data_clk);
    end procedure SetPhase;

    variable FFTVisuals : FFTVisuals_t(DUTOutputs'range);
  begin
    VReport(TestStatus);

    swap_iq_2x <= '0';

    adc_reset_pulse_dclk <= '0';
    cSoftwareControl(kADC_RESET) <= '0';
    cSoftwareControl(kDAC_RESET) <= '0';
    cSoftwareControl(kADC_ENABLE) <= '0';
    cSoftwareControl(kDAC_ENABLE) <= '0';

    Reset;
    SetPhase(true);
    SendSomeData;
    FFTVisuals := VisualizeFFT(DUTOutputs);
    for i in FFTVisuals'range loop
      DUTOutputsFFT <= FFTVisuals(i);
      wait for 1 ns;
    end loop;

    Reset;

    report "max mismatch = (RE=> " & real'image(MaxMismatchSig.RE)
           & ", IM=> " & real'image(MaxMismatchSig.IM) & ")";

    finish;
    StopSim <= true;
    wait;
  end process DriverProcess;

  -- The data monitor records every valid output to DUTOutputs so the testbench
  -- can perform an FFT for human visualization of the results. This process
  -- also measures the difference between the output and expected value (the
  -- difference is not expected to be zero because the expected output is
  -- computed with floating point, while the DUT is a fixed-point
  -- implementation).
  DataMonitor: process is

    -- Scale multiplies each complex value in C by the real value S.
    function Scale (C : ComplexArray_t; S : real) return ComplexArray_t is
      variable rval : ComplexArray_t(C'range);
    begin
      for i in rval'range loop
        rval(i) := S * C(i);
      end loop;
      return rval;
    end function Scale;

    -- The DUT includes a multiply-by-2 following the FIR, so kConvolvedData's
    -- value includes a scale by 2.
    constant kConvolvedData : ComplexArray_t := Convolve(kFIR, kSampledSig);
    constant kExpectedData : ComplexArray_t := Scale(Quantize(DownSample(kConvolvedData, 3, 1)), 2.0);
    variable DUTOutputData : complex;
    variable ExpectedOutputData : complex;
    variable mismatch : complex;
    variable maxMismatch : complex := MATH_CZERO;
  begin
    for i in kExpectedData'range loop
      wait until (adc_data_out_tvalid)='1' and rising_edge(data_clk);
        DUTOutputs(i) <= to_complex(adc_data_out_tdata);
        DUTOutputData := to_complex(adc_data_out_tdata);
        DUTOutputDataSig <= DUTOutputData;
        ExpectedOutputData := kExpectedData(i);
        ExpectedOutputDataSig <= ExpectedOutputData;
        mismatch := (
          RE => abs(DUTOutputData.RE - ExpectedOutputData.RE),
          IM => abs(DUTOutputData.IM - ExpectedOutputData.IM)
        );
        MismatchSig <= mismatch;

        maxMismatch.RE := MAXIMUM(maxMismatch.RE, mismatch.RE);
        maxMismatch.IM := MAXIMUM(maxMismatch.IM, mismatch.IM);
        MaxMismatchSig <= maxMismatch;
    end loop;
    wait;
  end process DataMonitor;

  assert MismatchSig.RE <= kMaxMismatch
    report "output RE mismatch exceeded threshold = " & real'image(MismatchSig.RE)
    severity error;

  assert MismatchSig.IM <= kMaxMismatch
    report "output IM mismatch exceeded threshold = " & real'image(MismatchSig.IM)
    severity error;

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

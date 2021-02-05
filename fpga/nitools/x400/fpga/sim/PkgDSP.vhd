---------------------------------------------------------------------
--
-- Copyright 2021 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: PkgDSP
--
-- Purpose:
-- Some utility functions for testing DSP logic.
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.math_real.all;
  use IEEE.math_complex.all;

library STD;
  use STD.textio.all;

library WORK;
  use WORK.PkgNiUtilities.all;

package PkgDSP is

  type ComplexArray_t is array(natural range<>) of IEEE.math_complex.complex;
  function "+" (Left, Right : ComplexArray_t) return ComplexArray_t;
  function "/" (Left : ComplexArray_t; Right : real) return ComplexArray_t;
  function "*" (Left : ComplexArray_t; Right : real) return ComplexArray_t;

  type RealArray_t is array(natural range<>) of real;

  -- Computes a convolution Reals * Complexes. This is useful for computing a FIR output,
  -- where Reals is the filter's coefficients and Complexes is the sampled signal. The
  -- returned value's length is Reals'length + Complexes'length - 1.
  function Convolve (Reals : RealArray_t; Complexes : ComplexArray_t ) return ComplexArray_t;

  -- DFT computes a Discrete Fourier Transform. This accepts an arbitrary length of
  -- Complexes, but is slower than FFT.
  function DFT (Complexes : ComplexArray_t) return ComplexArray_t;

  -- FFT computes a Fast Fourier Transform. Complexes must be a power of 2 in length,
  -- but FFT is faster than DFT, even if the input requires substantial zero
  -- padding.
  function FFT (Complexes : ComplexArray_t) return ComplexArray_t;

  type FFTVisual_t is record
    Value : Complex_Polar;
    MagnitudeIndB : real;
    Frequency : real;
  end record FFTVisual_t;

  type FFTVisuals_t is array (natural range<>) of FFTVisual_t;

  -- VisualizeFFT returns an array of FFTVisual_t so that plotting MagnitudeIndB
  -- over time with a constant time increment will plot the FFT's magnitude
  -- response in a log-log format. That is, magnitude is in dB, and time
  -- represents frequency on a log scale.
  -- The Frequency record field represents a normalized frequency where
  -- Frequency=1.0 corresponds to Fs/2.
  impure function VisualizeFFT(Samples : ComplexArray_t) return FFTVisuals_t;

  function DownSample(Complexes : ComplexArray_t; DownSamplingFactor : positive; Offset : Natural) return ComplexArray_t;

  function UpSample(Samples : ComplexArray_t; UpSamplingFactor : positive) return ComplexArray_t;

end package PkgDSP;

package body PkgDSP is

  function "+" (Left, Right : ComplexArray_t) return ComplexArray_t is
    alias aLeft : ComplexArray_t(1 to Left'length) is Left;
    alias aRight : ComplexArray_t(1 to Right'length) is Right;
    variable rval : ComplexArray_t(aRight'range);
  begin
    assert aLeft'length = aRight'length
      report "sum of ComplexArray_t requires equal length inputs"
      severity failure;

    for i in rval'range loop
      rval(i) := aLeft(i) + aRight(i);
    end loop;

    return rval;
  end function "+";

  function "/" (Left : ComplexArray_t; Right : real) return ComplexArray_t is
    variable rval : ComplexArray_t(Left'range);
  begin
    for i in rval'range loop
      rval(i) := Left(i) / Right;
    end loop;
    return rval;
  end function "/";

  function "*" (Left : ComplexArray_t; Right : real) return ComplexArray_t is
    variable rval : ComplexArray_t(Left'range);
  begin
    for i in rval'range loop
      rval(i) := Left(i) * Right;
    end loop;
    return rval;
  end function "*";

  -- returns Reals(i) else 0.0 if i is out of range
  function ZeroIndex (Reals : RealArray_t; i : integer) return Real is
  begin
    if (i < Reals'low) or (i > Reals'high) then
      return 0.0;
    else
      return Reals(i);
    end if;
  end function ZeroIndex;

  -- returns Complexes(i) else MATH_CZERO if i is out of range
  function ZeroIndex (Complexes : ComplexArray_t; i : integer) return Complex is
  begin
    if (i < Complexes'low) or (i > Complexes'high) then
      return MATH_CZERO;
    else
      return Complexes(i);
    end if;
  end function ZeroIndex;

  -- computes one convolution output
  function ConvolveStep (Reals : RealArray_t; Complexes : ComplexArray_t; step : natural) return Complex is
    alias aComplexes : ComplexArray_t (0 to Complexes'length - 1) is Complexes;
    alias aReals : RealArray_t (0 to Reals'length - 1) is Reals;

    variable rval : Complex;
  begin
    rval := MATH_CZERO;
    for i in 0 to step loop
      rval := rval + ZeroIndex(aComplexes,step-i) * ZeroIndex(aReals,i);
    end loop;

    return rval;
  end function ConvolveStep;

  function Convolve (Reals : RealArray_t; Complexes : ComplexArray_t) return ComplexArray_t is
    variable rval : ComplexArray_t (0 to Complexes'length + Reals'length-2);
  begin
    for i in rval'range loop
      rval(i) := ConvolveStep(Reals, Complexes, i);
    end loop;

    return rval;
  end function Convolve;

  -- DFTStep computes one value of a DFT.
  function DFTstep (Complexes : ComplexArray_t; step : natural) return Complex is
    alias aC : ComplexArray_t(0 to Complexes'length-1) is Complexes;
    variable rval : Complex;
  begin
    rval := math_czero;
    for i in aC'range loop
      rval := rval + aC(i)*exp(-math_cbase_j * math_2_pi * real(i) * real(step) / real(Complexes'length));
    end loop;
    return rval;
  end function DFTstep;

  -- DFT computes a Discrete Fourier Transform. This is based on the Wikipedia article:
  -- https://en.wikipedia.org/wiki/Discrete_Fourier_transform
  function DFT (Complexes : ComplexArray_t) return ComplexArray_t is
    alias aC : ComplexArray_t(0 to Complexes'length-1) is Complexes;
    variable rval : ComplexArray_t(aC'range);
  begin
    for i in rval'range loop
      rval(i) := DFTstep(aC, i);
    end loop;
    return rval;
  end function DFT;

  -- HalfTheValues returns either the odd or even samples from Complexes.
  function HalfTheValues (Complexes : ComplexArray_t; Even : boolean) return ComplexArray_t is
    alias aC : ComplexArray_t(0 to Complexes'length-1) is Complexes;
    variable rval : ComplexArray_t(0 to Complexes'length/2-1);
    variable offset : natural;
  begin
    assert Complexes'length mod 2 = 0
      report "Can't take half of an odd number. You probably passed a non-power-of-2 sized array to the FFT function."
      severity failure;

    if Even then
      offset := 0;
    else
      offset := 1;
    end if;

    for i in rval'range loop
      rval(i) := aC(2*i + offset);
    end loop;
    return rval;
  end function HalfTheValues;

  -- FFT computes a Fast Fourier Transform. The implementation is based on this article:
  -- https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm
  function FFT (Complexes : ComplexArray_t) return ComplexArray_t is
    alias aC : ComplexArray_t(0 to Complexes'length-1) is Complexes;
    variable rval : ComplexArray_t(aC'range);
    variable EvenSamples : ComplexArray_t(0 to Complexes'length/2 - 1);
    variable OddSamples : ComplexArray_t(0 to Complexes'length/2 - 1);
    variable EvenDFT : ComplexArray_t(0 to Complexes'length/2 - 1);
    variable OddDFT : ComplexArray_t(0 to Complexes'length/2 - 1);
    variable CommonFactor : COMPLEX;
  begin

    if aC'length=1 then
      rval := DFT(aC);
      return rval;
    end if;

    EvenSamples := HalfTheValues(aC,true);
    OddSamples := HalfTheValues(aC,false);

    EvenDFT := FFT(EvenSamples);
    OddDFT := FFT(OddSamples);

    for k in EvenDFT'range loop
      CommonFactor := EXP(-MATH_CBASE_J * MATH_2_PI * real(k) / real(aC'length) );
      rval(k)                := EvenDFT(k) + CommonFactor * OddDFT(k);
      rval(k+EvenDFT'length) := EvenDFT(k) - CommonFactor * OddDFT(k);
    end loop;
    return rval;
  end function FFT;

  -- LogFrequencyScale accepts a percentage of normalized frequency, where 1.0
  -- indicates Fs/2. The return value is also over the range 0.0 to 1.0, but
  -- with an exponential distribution useful for plotting a log scale.
  function LogFrequencyScale (t : real range 0.0 to 1.0) return real is
  begin
    -- The 0.5 corresponds to the Fs/2.
    return (10.0**t * 0.5 - 0.5)/4.5;
  end function LogFrequencyScale;

  impure function VisualizeFFT(Samples : ComplexArray_t) return FFTVisuals_t is
    constant kNearestPowerOf2 : integer := integer(ceil(log2(real(Samples'length))));

    variable paddedSamples : ComplexArray_t(0 to (2**kNearestPowerOf2)-1);
    variable paddedSamplesFFT : ComplexArray_t(paddedSamples'range);
    variable rval : FFTVisuals_t(paddedSamples'range);
    variable LogI : integer;
    variable absSampleFFT : real;
  begin
    paddedSamples := (others => math_czero);
    paddedSamples(0 to Samples'length-1) := Samples;
    paddedSamplesFFT := FFT(paddedSamples) / real(paddedSamples'length) * 2.0;

    --readline(input, userInput);
    for i in rval'range loop
      rval(i).Frequency := LogFrequencyScale(real(i)/real(rval'length));
      LogI := integer(rval(i).Frequency * real(rval'length)/2.0);
      rval(i).Value := complex_to_polar(paddedSamplesFFT(LogI));

      --coerce an FFT bin with value 0 to a small non-zero value to avoid an
      --error in the subsequent call to "log10"
      absSampleFFT := MAXIMUM(abs(paddedSamplesFFT(LogI)), 1.0E-308);
      rval(i).MagnitudeIndB := 20.0 * log10(absSampleFFT);
    end loop;

    return rval;
  end function VisualizeFFT;

  function DownSample(Complexes : ComplexArray_t; DownSamplingFactor : positive; Offset : Natural) return ComplexArray_t is
    alias aC : ComplexArray_t(0 to Complexes'length - 1) is Complexes;
    variable rval : ComplexArray_t(0 to Complexes'length/DownSamplingFactor - 1);
  begin
    assert Offset < DownSamplingFactor
      report "Offset must be strictly less than DownSamplingFactor"
      severity FAILURE;

    for i in rval'range loop
      rval(i) := aC(i*DownSamplingFactor+Offset);
    end loop;
    return rval;
  end function DownSample;

  function UpSample(Samples : complexArray_t; UpSamplingFactor : positive) return ComplexArray_t is
  begin
    report "UpSample unimplemented"
      severity FAILURE;
    return Samples;
  end function UpSample;

end package body PkgDSP;

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.math_real.all;
  use IEEE.math_complex.all;

library STD;
  use STD.textio.all;

library WORK;
  use WORK.PkgDSP.all;

-- tb_PkgDSP does not perform any correctness checks, but it does demonstrate
-- how to use PkgDSP.
entity tb_PkgDSP is
end entity tb_PkgDSP;

architecture test of tb_PkgDSP is

  -- A low pass filter
  constant kFIR : RealArray_t := (
      -1.52588E-5,
      0.0,
      6.10352E-5,
      9.15527E-5,
      0.0,
      -0.000198364,
      -0.000274658,
      0.0,
      0.000480652,
      0.000617981,
      0.0,
      -0.000991821,
      -0.00122833,
      0.0,
      0.00183868,
      0.00222015,
      0.0,
      -0.0031662,
      -0.00374603,
      0.0,
      0.00515747,
      0.00601196,
      0.0,
      -0.00807953,
      -0.00933075,
      0.0,
      0.0123672,
      0.0142212,
      0.0,
      -0.0188675,
      -0.0218201,
      0.0,
      0.0296936,
      0.0351486,
      0.0,
      -0.0520325,
      -0.0664139,
      0.0,
      0.136566,
      0.275024,
      0.333328,
      0.275024,
      0.136566,
      0.0,
      -0.0664139,
      -0.0520325,
      0.0,
      0.0351486,
      0.0296936,
      0.0,
      -0.0218201,
      -0.0188675,
      0.0,
      0.0142212,
      0.0123672,
      0.0,
      -0.00933075,
      -0.00807953,
      0.0,
      0.00601196,
      0.00515747,
      0.0,
      -0.00374603,
      -0.0031662,
      0.0,
      0.00222015,
      0.00183868,
      0.0,
      -0.00122833,
      -0.000991821,
      0.0,
      0.000617981,
      0.000480652,
      0.0,
      -0.000274658,
      -0.000198364,
      0.0,
      9.15527E-5,
      6.10352E-5,
      0.0,
      -1.52588E-5);

  -- kSig is a delta function, so the DFT of the filtered result will show the
  -- filter's impulse response.
  constant kSig : ComplexArray_t(0 to 1023) := (0 => math_cbase_1, others => math_czero);

  --vhook_nowarn FFTVisual
  --FFTVisual is unread, but it is useful as a waveform signal for visualizing the FFT.
  --Look for "tb_PkgDSP.do" to setup the waveforms for visualizing the FFT result.
  signal FFTVisual : FFTVisual_t := (Frequency => 1.0, MagnitudeIndB=>0.0, Value => complex_to_polar(math_czero));

begin

  stimulus:
  process is
    procedure VPrint(s : string) is
      variable l : line;
    begin
      write(l, s);
      writeline(output, l);
    end procedure VPrint;

    procedure VPrint(Complexes : ComplexArray_t) is
    begin
      for i in Complexes'range loop
        VPrint("i=" & integer'image(i) & " re -> " & real'image(Complexes(i).Re) & " im -> " & real'image(Complexes(i).Im));
      end loop;
    end procedure VPrint;

    constant kConvolution : ComplexArray_t := work.PkgDSP.Convolve(kFIR, kSig);

    constant kFFTVisuals : FFTVisuals_t := VisualizeFFT(kConvolution);

  begin

    for i in kFFTVisuals'range loop
      FFTVisual <= kFFTVisuals(i);
      wait for 1 ns;
    end loop;

    wait;
  end process stimulus;

end architecture test;

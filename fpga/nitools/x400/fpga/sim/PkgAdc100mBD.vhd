---------------------------------------------------------------------
--
-- Copyright 2021 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: PkgAdc100mBD
--
-- Purpose:
-- This package provides some support for DSP testing in simulation. These
-- functions are useful for creating stimulus and expected output in floating
-- point.
--
----------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.math_real.all;
  use IEEE.math_complex.all;
  use IEEE.fixed_pkg.all;

library WORK;
  use WORK.PkgNiUtilities.all;
  use WORK.PkgDSP.all;

package PkgAdc100mBD is

  -- A signed fixed-point number with one integer bit and 15 fractional bits:
  subtype Fixed_t is IEEE.FIXED_PKG.unresolved_sfixed(0 downto -15);

  -- to_SLV32 converts a floating point complex sample into fixed-point. It's
  -- good for producing the DUT's stimulus.
  function to_SLV32 (C : Complex) return std_logic_vector;

  -- to_Complex converts a fixed-point {Q, I} pair to Complex. It's useful for
  -- reading the DUT's output and converting to real numbers for comparison and
  -- display in the testbench.
  function to_Complex (C : std_logic_vector) return Complex;

  -- ComplexSignal is useful for producing stimulus. It returns an array of
  -- Complex with the specified number of samples filled with "Cycles" sin/cos
  -- periods.
  function ComplexSignal (Cycles : natural; samples : natural) return ComplexArray_t;

  -- FIR coefficients for a low-pass filter. These were taken from the FIR in
  -- the x410's adc_100m_bd.
  constant kFIR : RealArray_t := (
      -1.52587890625E-5,
      0.0,
      6.103515625E-5,
      9.1552734375E-5,
      0.0,
      -0.0001983642578125,
      -0.000274658203125,
      0.0,
      0.0004806518554687,
      0.0006179809570312,
      0.0,
      -0.0009918212890625,
      -0.001228332519531,
      0.0,
      0.001838684082031,
      0.002220153808594,
      0.0,
      -0.003166198730469,
      -0.003746032714844,
      0.0,
      0.005157470703125,
      0.006011962890625,
      0.0,
      -0.008079528808594,
      -0.009330749511719,
      0.0,
      0.01236724853516,
      0.01422119140625,
      0.0,
      -0.01886749267578,
      -0.02182006835937,
      0.0,
      0.02969360351562,
      0.03514862060547,
      0.0,
      -0.05203247070312,
      -0.06641387939453,
      0.0,
      0.1365661621094,
      0.2750244140625,
      0.3333282470703,
      0.2750244140625,
      0.1365661621094,
      0.0,
      -0.06641387939453,
      -0.05203247070312,
      0.0,
      0.03514862060547,
      0.02969360351562,
      0.0,
      -0.02182006835937,
      -0.01886749267578,
      0.0,
      0.01422119140625,
      0.01236724853516,
      0.0,
      -0.009330749511719,
      -0.008079528808594,
      0.0,
      0.006011962890625,
      0.005157470703125,
      0.0,
      -0.003746032714844,
      -0.003166198730469,
      0.0,
      0.002220153808594,
      0.001838684082031,
      0.0,
      -0.001228332519531,
      -0.0009918212890625,
      0.0,
      0.0006179809570312,
      0.0004806518554687,
      0.0,
      -0.000274658203125,
      -0.0001983642578125,
      0.0,
      9.1552734375E-5,
      6.103515625E-5,
      0.0,
      -1.52587890625E-5
      );

end package PkgAdc100mBD;

package body PkgAdc100mBD is

  function to_SLV32 (C : Complex) return std_logic_vector is
    variable i, q : Fixed_t;
    subtype result_type is std_logic_vector(Fixed_t'length-1 downto 0);
    variable rval : std_logic_vector(31 downto 0);
  begin
    i := to_sfixed(C.Re, i);
    q := to_sfixed(C.Im, q);
    rval := result_type(q) & result_type(i);
    return rval;
  end function to_SLV32;

  function to_Complex (C : std_logic_vector) return Complex is
    variable i, q : signed (15 downto 0);
    variable rval : complex;
  begin
    i := signed(C(15 downto 0));
    q := signed(C(31 downto 16));
    rval := (re => real(to_integer(i)) / real(2**15),
             im => real(to_integer(q)) / real(2**15));
    return rval;
  end function to_Complex;

  function ComplexSignal (Cycles : natural; samples : natural) return ComplexArray_t is
    variable Period : real := real(samples) / real(Cycles);
    variable rval : ComplexArray_t (0 to samples + 100);
  begin
    rval := (others => math_czero);
    for i in 0 to samples-1 loop
      -- The amplitude is 85% of a half-scale signal. The DUT includes a
      -- multiply-by-2, so an input greater than 1/2 scale can cause an
      -- overflow.
      rval(i).re := 0.5 * 0.85 * ieee.math_real.sin(math_2_pi * real(i) / Period);
      rval(i).im := 0.5 * 0.85 * ieee.math_real.sin(math_2_pi * real(i) / Period - math_pi / 2.0);
    end loop;

    return rval;
  end function ComplexSignal;

end package body PkgAdc100mBD;

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.math_real.all;
  use IEEE.math_complex.all;

library WORK;
  use WORK.PkgDSP.all;
  use WORK.PkgAdc100mBD.all;

-- tb_PkgAdc100mBD exercises some of the functionality in PkgAdc100mBD, but does
-- not perform any checks for correctness. It is useful for experimenting with
-- the package, and may provide some examples of how to use the package.
entity tb_PkgAdc100mBD is
end entity tb_PkgAdc100mBD;

architecture RTL of tb_PkgAdc100mBD is

  -- A delta function input will show the filters response at all frequencies
  constant kSig : ComplexArray_t(0 to 8191) :=
    (1 => POLAR_TO_COMPLEX((mag=>1.0, arg=>MATH_PI/4.0)),
     others => MATH_CZERO);

  --vhook_nowarn StimulusPolar
  --vhook_nowarn FFTResultPolar
  -- StimulusPolar and FFTResultPolar have no readers, but they are useful as
  -- waveforms for visualizing the simulation results.
  signal StimulusPolar : complex_polar := (others => 0.0);
  signal FFTResultPolar : complex_polar := (others => 0.0);

begin

  stimulus:
  process is

    variable StimulusPadded : ComplexArray_t(0 to 2**WORK.PkgNiUtilities.log2(kSig'length)-1) := (others => MATH_CZERO);
    constant kConvolution : ComplexArray_t := work.PkgDSP.Convolve(kFIR, kSig);
    constant kExpected : ComplexArray_t := DownSample(kConvolution, 3, 1);
    variable ResultPadded : ComplexArray_t(0 to 2**WORK.PkgNiUtilities.log2(kExpected'length)-1) := (others => MATH_CZERO);
    variable FFTResultWhole : ComplexArray_t(0 to 2**WORK.PkgNiUtilities.log2(kExpected'length)-1) := (others => MATH_CZERO);

  begin

    StimulusPadded(0 to kSig'high) := kSig;

    ResultPadded(0 to kExpected'high) := kExpected;
    FFTResultWhole := FFT(ResultPadded);

    for i in StimulusPadded'range loop
      StimulusPolar <= COMPLEX_TO_POLAR(StimulusPadded(i));
      wait for 1 ns;
    end loop;

    -- This is kind of weird since an FFT output should have frequency on the X
    -- axis, but this will allow FFTResultPolar to plot the FFT output in a simulator
    -- waveform.
    for i in FFTResultWhole'range loop
      FFTResultPolar <= COMPLEX_TO_POLAR(FFTResultWhole(i));
      wait for 1 ns;
    end loop;

    wait;
  end process stimulus;

end RTL;

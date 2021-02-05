---------------------------------------------------------------------
--
-- Copyright 2019 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_duc_400m_saturate.vhd
--
-- Purpose:
--
-- Self-checking testbench used to check the saturation logic needed
-- in DDC.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgRf.all;

entity tb_duc_400m_saturate is
end tb_duc_400m_saturate;


architecture RTL of tb_duc_400m_saturate is

  component duc_400m_saturate
    port (
      Clk            : in  std_logic;
      cDataIn        : in  std_logic_vector(287 downto 0);
      cDataValidIn   : in  std_logic;
      cReadyForInput : out std_logic;
      cDataOut       : out std_logic_vector(191 downto 0);
      cDataValidOut  : out std_logic := '0');
  end component;

  --vhook_sigstart
  signal cDataIn: std_logic_vector(287 downto 0);
  signal cDataOut: std_logic_vector(191 downto 0);
  signal cDataValidIn: std_logic;
  signal cDataValidOut: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kPer : time := 10 ns;
  constant kSamplesPerClock  : integer := 12;

  signal Clk: std_logic := '1';
  signal TestStart : boolean := false;

  procedure ClkWait(X : positive := 1) is
  begin
    for i in 1 to X loop
      wait until rising_edge(Clk);
    end loop;
  end procedure ClkWait;

begin

  Clk   <= not Clk after kPer/2 when not StopSim else '0';


  --vhook   duc_400m_saturate
  --vhook_# cReadyForInput is a constant in the design and is not being tested.
  --vhook_a cReadyForInput open
  duc_400m_saturatex: duc_400m_saturate
    port map (
      Clk            => Clk,            --in  std_logic
      cDataIn        => cDataIn,        --in  std_logic_vector(287:0)
      cDataValidIn   => cDataValidIn,   --in  std_logic
      cReadyForInput => open,           --out std_logic
      cDataOut       => cDataOut,       --out std_logic_vector(191:0)
      cDataValidOut  => cDataValidOut); --out std_logic:='0'


  main: process
  begin

    ClkWait;
    TestStart <= false;
    ClkWait;
    TestStart <= true;

    -- This wait is needed to sweep through the entire range of 18 bits
    -- signed value. Since we operate the saturation logic with 12 samples
    -- per cycle, we need to wait for 2^kDucDataOutWidth/12. We are adding
    -- an extra 10 clock cycles wait just as a buffer for the DUT latency.
    ClkWait(2**kDucDataOutWidth/kSamplesPerClock + 10);
    StopSim <= true;
    wait;
  end process;

  -- Process to generate 18-bit signed data.
  DataGen: process(Clk)
    variable Sample : Sample18_t := kSmallest18;
  begin
    if falling_edge(Clk) then
      if TestStart then
        cDataValidIn <= '1';
        cDataIn <= "000000" & std_logic_vector(Sample+kSamplesPerClock-1) &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-2) &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-3)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-4)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-5)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-6)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-7)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-8)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-9)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-10)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-11)  &
                   "000000" & std_logic_vector(Sample+kSamplesPerClock-12);
        Sample := Sample +12;
      end if;
    end if;
  end process;

  -- Check if saturation and data packing is done correctly.
  DataCheck: process(Clk)
    variable Sample : Sample18_t := kSmallest18;
    variable ExpectedData : std_logic_vector(15 downto 0);

  begin
    if falling_edge(Clk) then
      if cDataValidOut then
        for i in 1 to 12 loop
          ExpectedData := tb_saturate(std_logic_vector(Sample));
          assert cDataOut(kSatDataWidth*i-1 downto kSatDataWidth*(i-1)) = ExpectedData
            report "Saturation data out mismatch in index : " & to_string(i) & LF &
                   "Expected data is : " & to_hstring(ExpectedData) & LF &
                   "Received data is : " & to_hstring(cDataOut(kSatDataWidth*i-1 downto kSatDataWidth*(i-1)))
            severity error;
          Sample := Sample+1;
        end loop;
      end if;
    end if;
  end process;

end RTL;

---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_simple_spi_core_64bit
--
-- Purpose:
-- This testbench tests various combinations of configurations of divider and
-- bits per transmission. Data bits are captured on the rising edge of sclk and
-- driven on the falling edge of sclk.
--
----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.PkgNiUtilities.all;
  use work.PkgNiSim.all;

entity tb_simple_spi_core_64bit is
  generic (
    MAX_BITS : natural := 64
  );
end tb_simple_spi_core_64bit;

architecture test of tb_simple_spi_core_64bit is

  component simple_spi_core_64bit
    generic (
      BASE     : integer := 0;
      WIDTH    : integer := 8;
      CLK_IDLE : integer := 0;
      SEN_IDLE : integer := 2#111111111111111111111111#;
      MAX_BITS : integer := 32);
    port (
      clock        : in  std_logic;
      reset        : in  std_logic;
      set_stb      : in  std_logic;
      set_addr     : in  std_logic_vector(7 downto 0);
      set_data     : in  std_logic_vector(31 downto 0);
      readback     : out std_logic_vector((MAX_BITS-1) downto 0);
      readback_stb : out std_logic;
      ready        : out std_logic;
      sen          : out std_logic_vector((WIDTH-1) downto 0);
      sclk         : out std_logic;
      mosi         : out std_logic;
      miso         : in  std_logic;
      debug        : out std_logic_vector(23 downto 0));
  end component;

  procedure ClkWait (signal clk : std_logic; n : natural := 1 ) is
  begin
    for i in 1 to n loop
      wait until clk='1';
    end loop;
  end procedure ClkWait;

  --vhook_sigstart
  signal miso: std_logic;
  signal mosi: std_logic;
  signal readback: std_logic_vector(MAX_BITS-1 downto 0);
  signal readback_stb: std_logic;
  signal ready: std_logic;
  signal reset: std_logic;
  signal sclk: std_logic := '0';
  signal sen: std_logic_vector(0 downto 0);
  signal set_addr: std_logic_vector(7 downto 0);
  signal set_data: std_logic_vector(31 downto 0);
  signal set_stb: std_logic;
  --vhook_sigend

  signal StopSim : boolean := false;
  signal TestStatus : TestStatusString_t := (others => ' ');

  signal clock : std_logic := '1';
  constant kClockPeriod : time := 10 ns;

  -- data registers
  signal spiMosiData : std_logic_vector(63 downto 0);
  signal spiMisoData : std_logic_vector(63 downto 0);
  signal spiSlaveReceivedData : std_logic_vector(63 downto 0);

  -- SPI slave bit counter
  signal spiSlaveBitCounter : integer := 0;

  -- random generator
  shared variable random : Random_t;

  -- protocol check signals
  signal sclkDelayed : std_logic;
  signal senDelayed : std_logic_vector(sen'range);
  signal checksEnabled : boolean := False;

begin

  VPrint(TestStatus);

  clock <= not clock after kClockPeriod/2 when not StopSim else '0';

  controlProcess: process
  begin
    -- reset core on startup
    reset <= '1';
    wait for kClockPeriod*10;
    wait until falling_edge(clock);
    reset <= '0';

    -- wait for ready to assert
    wait until ready = '1' for 10 ms;

    -- configure divider
    for divider in 0 to 10 loop
      for numBits in 1 to MAX_BITS loop
        -- generate new data set
        spiMosiData <= random.GetStdLogicVector(spiMosiData'length);
        spiMisoData <= random.GetStdLogicVector(spiMisoData'length);

        -- ensure module is ready
        assert ready = '1' report "ready not asserted" severity error;

        -- configure divider
        wait until falling_edge(clock);
        set_stb  <= '1';
        set_addr <= X"00";
        set_data <= std_logic_vector(to_unsigned(divider, set_data'length));

        -- configure configuration
        wait until falling_edge(clock);
        set_stb  <= '1';
        set_addr <= X"01";
        set_data <= "01" & std_logic_vector(to_unsigned(numBits, 6)) & Ones(24);

        -- configure data (LSBs)
        wait until falling_edge(clock);
        set_stb  <= '1';
        set_addr <= X"03";
        set_data <= spiMosiData(31 downto 0);

        -- configure data (MSBs), which starts transaction
        wait until falling_edge(clock);
        set_stb  <= '1';
        set_addr <= X"02";
        set_data <= spiMosiData(63 downto 32);
        checksEnabled <= True;

        wait until falling_edge(clock);
        set_stb  <= '0';

        -- wait for transmission to be finished
        wait until readback_stb = '1' for 10 ms;
        assert readback_stb = '1' report "transmission did not finish" severity error;
        checksEnabled <= False;

        -- compare mosi data
        assert spiSlaveReceivedData(numBits - 1 downto 0) = spiMosiData(spiMosiData'high downto spiMosiData'high - numBits + 1)
          report "MOSI data mismatch" severity error;

        -- compare miso data
        assert readback(numBits - 1 downto 0) = spiMisoData(spiMosiData'high downto spiMosiData'high - numBits + 1)
          report "MISO data mismatch" severity error;
      end loop;
    end loop;

    -- stop simulation
    StopSim <= true;
    wait;
  end process controlProcess;

  --vhook simple_spi_core_64bit
  --vhook_a BASE      0
  --vhook_a WIDTH     1
  --vhook_a CLK_IDLE  0
  --vhook_a SEN_IDLE  1
  --vhook_a debug     open
  simple_spi_core_64bitx: simple_spi_core_64bit
    generic map (
      BASE     => 0,         --integer:=0
      WIDTH    => 1,         --integer:=8
      CLK_IDLE => 0,         --integer:=0
      SEN_IDLE => 1,         --integer:=2#111111111111111111111111#
      MAX_BITS => MAX_BITS)  --integer:=32
    port map (
      clock        => clock,         --in  wire
      reset        => reset,         --in  wire
      set_stb      => set_stb,       --in  wire
      set_addr     => set_addr,      --in  wire[7:0]
      set_data     => set_data,      --in  wire[31:0]
      readback     => readback,      --out wire[(MAX_BITS-1):0]
      readback_stb => readback_stb,  --out wire
      ready        => ready,         --out wire
      sen          => sen,           --out wire[(WIDTH-1):0]
      sclk         => sclk,          --out wire
      mosi         => mosi,          --out wire
      miso         => miso,          --in  wire
      debug        => open);         --out wire[23:0]

  -- emulate simple spi slave
  spiSlaveProcess: process(sclk, sen)
  begin
    if falling_edge(sen(0)) then
      spiSlaveBitCounter <= 0;
    end if;

    if falling_edge(sclk) then
      spiSlaveBitCounter <= spiSlaveBitCounter + 1;
      -- prevent counter from running out of spiMisoData range
      if (spiSlaveBitCounter = spiMisoData'high) then
        spiSlaveBitCounter <= 0;
      end if;
    end if;

    if rising_edge(sclk) then
      spiSlaveReceivedData <= spiSlaveReceivedData(spiSlaveReceivedData'high - 1 downto 0) & mosi;
    end if;
  end process spiSlaveProcess;

  miso <= spiMisoData(spiMisoData'high - spiSlaveBitCounter);

  ------------------------------------------------------------------------------
  -- Protocol checks
  ------------------------------------------------------------------------------
  sclkDelayed <= sclk after kClockPeriod;
  senDelayed <= sen after kClockPeriod;

  -- check MOSI and MISO te be aligned with falling edge of sclk or sen(0)
  mosiCheck: process(mosi)
  begin
    if checksEnabled then
      assert (sclk = '0' and sclkDelayed = '1') or (sen(0) = '0' and senDelayed(0) = '1')
        report "unaligned MOSI change" severity error;
    end if;
  end process mosiCheck;

  misoCheck: process(miso)
  begin
    if (checksEnabled) then
      assert (sclk = '0' and sclkDelayed = '1') or (sen(0) = '0' and senDelayed(0) = '1')
        report "unaligned MISO change" severity error;
    end if;
  end process misoCheck;

end test;

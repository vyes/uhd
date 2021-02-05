--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_ps_spi_binary_decode
-- Description:
-- Testbench for binary decoding of PS SPI interface. Focus is the detection of
-- glitches. Functional correctness testing is part of mb_cpld_tb.

--nisim --PreLoadCmd="vlog -work work ../../../../usrp3/top/x400/cpld/ip/oddr/oddr/altera_gpio_lite.sv"
--nisim --op1="-L altera_mf_ver -L fiftyfivenm_ver -L altera_ver -L lpm_ver +nowarnTFMPC"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgMB_CPLD_PS_REGMAP.all;
library std;
  use std.env.all;

entity tb_ps_spi_binary_decode is
end tb_ps_spi_binary_decode;

architecture test of tb_ps_spi_binary_decode is

  component mb_cpld
    generic (SIMULATION : integer := 0);
    port (
      PLL_REF_CLK           : in  std_logic;
      CLK_100               : in  std_logic;
      PWR_SUPPLY_CLK_CORE   : out std_logic;
      PWR_SUPPLY_CLK_DDR4_S : out std_logic;
      PWR_SUPPLY_CLK_DDR4_N : out std_logic;
      PWR_SUPPLY_CLK_0P9V   : out std_logic;
      PWR_SUPPLY_CLK_1P8V   : out std_logic;
      PWR_SUPPLY_CLK_2P5V   : out std_logic;
      PWR_SUPPLY_CLK_3P3V   : out std_logic;
      PWR_SUPPLY_CLK_3P6V   : out std_logic;
      PWR_EN_5V_OSC_100     : out std_logic;
      PWR_EN_5V_OSC_122_88  : out std_logic;
      IPASS_POWER_DISABLE   : out std_logic;
      IPASS_POWER_EN_FAULT  : in  std_logic_vector(1 downto 0);
      PL_CPLD_SCLK          : in  std_logic;
      PL_CPLD_MOSI          : in  std_logic;
      PL_CPLD_MISO          : out std_logic;
      PL_CPLD_CS_N          : in  std_logic_vector(1 downto 0);
      PL_CPLD_IRQ           : out std_logic;
      PS_CPLD_SCLK          : in  std_logic;
      PS_CPLD_MOSI          : in  std_logic;
      PS_CPLD_MISO          : out std_logic;
      PS_CPLD_CS_N          : in  std_logic_vector(3 downto 0);
      CLK_DB_SCLK           : out std_logic;
      CLK_DB_MOSI           : out std_logic;
      CLK_DB_MISO           : in  std_logic;
      CLK_DB_CS_N           : out std_logic;
      QSFP0_LED_ACTIVE      : out std_logic_vector(3 downto 0);
      QSFP0_LED_LINK        : out std_logic_vector(3 downto 0);
      QSFP1_LED_ACTIVE      : out std_logic_vector(3 downto 0);
      QSFP1_LED_LINK        : out std_logic_vector(3 downto 0);
      DB_CTRL_SCLK          : out std_logic_vector(1 downto 0);
      DB_CTRL_MOSI          : out std_logic_vector(1 downto 0);
      DB_CTRL_MISO          : in  std_logic_vector(1 downto 0);
      DB_CTRL_CS_N          : out std_logic_vector(1 downto 0);
      DB_REF_CLK            : out std_logic_vector(1 downto 0);
      DB_ARST               : out std_logic_vector(1 downto 0);
      DB_JTAG_TCK           : out std_logic_vector(1 downto 0);
      DB_JTAG_TDI           : out std_logic_vector(1 downto 0);
      DB_JTAG_TDO           : in  std_logic_vector(1 downto 0);
      DB_JTAG_TMS           : out std_logic_vector(1 downto 0);
      LMK32_SCLK            : out std_logic;
      LMK32_MOSI            : out std_logic;
      LMK32_MISO            : in  std_logic;
      LMK32_CS_N            : out std_logic;
      TPM_SCLK              : out std_logic;
      TPM_MOSI              : out std_logic;
      TPM_MISO              : in  std_logic;
      TPM_CS_N              : out std_logic;
      PHASE_DAC_SCLK        : out std_logic;
      PHASE_DAC_MOSI        : out std_logic;
      PHASE_DAC_CS_N        : out std_logic;
      DIO_DIRECTION_A       : out std_logic_vector(11 downto 0);
      DIO_DIRECTION_B       : out std_logic_vector(11 downto 0);
      DB_CALEEPROM_SCLK     : out std_logic_vector(1 downto 0);
      DB_CALEEPROM_MOSI     : out std_logic_vector(1 downto 0);
      DB_CALEEPROM_MISO     : in  std_logic_vector(1 downto 0);
      DB_CALEEPROM_CS_N     : out std_logic_vector(1 downto 0);
      PS_CLK_ON_CPLD        : out std_logic;
      IPASS_PRESENT_N       : in  std_logic_vector(1 downto 0);
      IPASS_SCL             : inout std_logic_vector(1 downto 0);
      IPASS_SDA             : inout std_logic_vector(1 downto 0);
      PCIE_RESET            : out std_logic;
      TPM_RESET_n           : out std_logic);
  end component;

  --vhook_sigstart
  signal CLK_DB_CS_N: std_logic := '1';
  signal DB_CALEEPROM_CS_N: std_logic_vector(1 downto 0);
  signal LMK32_CS_N: std_logic;
  signal PHASE_DAC_CS_N: std_logic;
  signal PS_CPLD_CS_N: std_logic_vector(3 downto 0);
  signal TPM_CS_N: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kReliableClkPer : time := 10 ns;  -- 100 MHz
  constant kTransactionDuration : time := 1 us;

  signal CLK_100: std_logic := '0';

  -- random generators
  shared variable Random : Random_t;

  -- combined CS vector
  signal decodedChipSelects : std_logic_vector(kSPI_ENDPOINTSize-2 downto 0) := (others => '1');

  -- enable check process
  signal enableChecks : boolean := false;

begin

  CLK_100 <= not CLK_100 after kReliableClkPer/2 when not StopSim else '0';

  -- Simulation generic is not needed as this only speeds up PCI-Express reset
  -- functionality, which is untouched by this testbench.
  --vhook mb_cpld dutx
  --vhook_a SIMULATION 0
  --vhook_a CLK_100 CLK_100
  --vhook_a {^((?!PL|DB_CTRL|WR).*CS_N)} $1
  --vhook_# ignore all other ports
  --vhook_a * open mode=out
  --vhook_a * open mode=inout
  --vhook_a * '0' mode=in type=std_logic
  --vhook_a * (others => '0') mode=in type=std_logic_vector
  dutx: mb_cpld
    generic map (SIMULATION => 0)  --integer:=0
    port map (
      PLL_REF_CLK           => '0',                --in  wire
      CLK_100               => CLK_100,            --in  wire
      PWR_SUPPLY_CLK_CORE   => open,               --out wire
      PWR_SUPPLY_CLK_DDR4_S => open,               --out wire
      PWR_SUPPLY_CLK_DDR4_N => open,               --out wire
      PWR_SUPPLY_CLK_0P9V   => open,               --out wire
      PWR_SUPPLY_CLK_1P8V   => open,               --out wire
      PWR_SUPPLY_CLK_2P5V   => open,               --out wire
      PWR_SUPPLY_CLK_3P3V   => open,               --out wire
      PWR_SUPPLY_CLK_3P6V   => open,               --out wire
      PWR_EN_5V_OSC_100     => open,               --out wire
      PWR_EN_5V_OSC_122_88  => open,               --out wire
      IPASS_POWER_DISABLE   => open,               --out wire
      IPASS_POWER_EN_FAULT  => (others => '0'),    --in  wire[1:0]
      PL_CPLD_SCLK          => '0',                --in  wire
      PL_CPLD_MOSI          => '0',                --in  wire
      PL_CPLD_MISO          => open,               --out wire
      PL_CPLD_CS_N          => (others => '0'),    --in  wire[1:0]
      PL_CPLD_IRQ           => open,               --out wire
      PS_CPLD_SCLK          => '0',                --in  wire
      PS_CPLD_MOSI          => '0',                --in  wire
      PS_CPLD_MISO          => open,               --out wire
      PS_CPLD_CS_N          => PS_CPLD_CS_N,       --in  wire[3:0]
      CLK_DB_SCLK           => open,               --out wire
      CLK_DB_MOSI           => open,               --out wire
      CLK_DB_MISO           => '0',                --in  wire
      CLK_DB_CS_N           => CLK_DB_CS_N,        --out wire
      QSFP0_LED_ACTIVE      => open,               --out wire[3:0]
      QSFP0_LED_LINK        => open,               --out wire[3:0]
      QSFP1_LED_ACTIVE      => open,               --out wire[3:0]
      QSFP1_LED_LINK        => open,               --out wire[3:0]
      DB_CTRL_SCLK          => open,               --out wire[1:0]
      DB_CTRL_MOSI          => open,               --out wire[1:0]
      DB_CTRL_MISO          => (others => '0'),    --in  wire[1:0]
      DB_CTRL_CS_N          => open,               --out wire[1:0]
      DB_REF_CLK            => open,               --out wire[1:0]
      DB_ARST               => open,               --out wire[1:0]
      DB_JTAG_TCK           => open,               --out wire[1:0]
      DB_JTAG_TDI           => open,               --out wire[1:0]
      DB_JTAG_TDO           => (others => '0'),    --in  wire[1:0]
      DB_JTAG_TMS           => open,               --out wire[1:0]
      LMK32_SCLK            => open,               --out wire
      LMK32_MOSI            => open,               --out wire
      LMK32_MISO            => '0',                --in  wire
      LMK32_CS_N            => LMK32_CS_N,         --out wire
      TPM_SCLK              => open,               --out wire
      TPM_MOSI              => open,               --out wire
      TPM_MISO              => '0',                --in  wire
      TPM_CS_N              => TPM_CS_N,           --out wire
      PHASE_DAC_SCLK        => open,               --out wire
      PHASE_DAC_MOSI        => open,               --out wire
      PHASE_DAC_CS_N        => PHASE_DAC_CS_N,     --out wire
      DIO_DIRECTION_A       => open,               --out wire[11:0]
      DIO_DIRECTION_B       => open,               --out wire[11:0]
      DB_CALEEPROM_SCLK     => open,               --out wire[1:0]
      DB_CALEEPROM_MOSI     => open,               --out wire[1:0]
      DB_CALEEPROM_MISO     => (others => '0'),    --in  wire[1:0]
      DB_CALEEPROM_CS_N     => DB_CALEEPROM_CS_N,  --out wire[1:0]
      PS_CLK_ON_CPLD        => open,               --out wire
      IPASS_PRESENT_N       => (others => '0'),    --in  wire[1:0]
      IPASS_SCL             => open,               --inout wire[1:0]
      IPASS_SDA             => open,               --inout wire[1:0]
      PCIE_RESET            => open,               --out wire
      TPM_RESET_n           => open);              --out wire

  -- combine all CS lines into one vector
  decodedChipSelects(kPS_CS_MB_CPLD) <= '1'; -- not visible here
  decodedChipSelects(kPS_CS_LMK32) <= LMK32_CS_N;
  decodedChipSelects(kPS_CS_TPM) <= TPM_CS_N;
  decodedChipSelects(kPS_CS_PHASE_DAC) <= PHASE_DAC_CS_N;
  decodedChipSelects(kPS_CS_DB0_CAL_EEPROM) <= DB_CALEEPROM_CS_N(0);
  decodedChipSelects(kPS_CS_DB1_CAL_EEPROM) <= DB_CALEEPROM_CS_N(1);
  decodedChipSelects(kPS_CS_CLK_AUX_DB) <= CLK_DB_CS_N;

  controlProcess: process
    variable spiBinarySlaveSelect : natural;
    variable spiBinarySlaveSelectSlv : std_logic_vector(2 downto 0);
  begin
    -- CS line 3 is unused for the binary decoding -> tie to 1
    PS_CPLD_CS_N <= "1111";

    -- loop through each ps of 4 ns clock period (250 MHz)
    for i in 1 to 1000 loop
      -- shift to move through the clock period
      wait for 4 ps;

      -- pause between transactions
      wait for kTransactionDuration;

      -- get slave within supported range (IDLE and MB_CPLD are excluded)
      spiBinarySlaveSelect := random.GetNatural(kSPI_ENDPOINTSize-2) + kPS_CS_LMK32;
      spiBinarySlaveSelectSlv := std_logic_vector(to_unsigned(spiBinarySlaveSelect, spiBinarySlaveSelectSlv'length));

      -- assert lines within 1 ns
      enableChecks <= true;
      for j in 0 to 2 loop
        PS_CPLD_CS_N(j) <= spiBinarySlaveSelectSlv(j) after random.GetNatural(1000) * 1 ps;
      end loop;

      -- keep the wires for a full transaction (just a wait here)
      wait for kTransactionDuration;

      -- check for correct chip signal to be asserted
      assert decodedChipSelects(spiBinarySlaveSelect) = '0'
        report "incorrect decoding result" severity error;

      -- deassert lines within 1 ns
      for j in 0 to 2 loop
        PS_CPLD_CS_N(j) <= '1' after random.GetNatural(1000) * 1 ps;
      end loop;
    end loop;

    StopSim <= true;
    -- simulation does not end automatically
    Finish(1);
    wait;
  end process;

  checkProces: process(decodedChipSelects)
    -- keep timestamp of last change to report any glitches
    variable lastChangeTS : time := -kTransactionDuration;
  begin
    -- check if check is already enabled
    if (enableChecks) then
      -- Check for timing between changes change. Transaction time is divided by
      -- two as there might be a few clock cycles jitter when asserting and
      -- deasserting the signals. Potential glitches are expected to be much
      -- shorter.
      assert (now - lastChangeTS) > kTransactionDuration/2 report
        "glitch occured" & LF &
        "minimum required time: " & time'image(kTransactionDuration/2) & LF &
        "passed time: " & time'image(now - lastChangeTS)
        severity error;
      lastChangeTS := now;

      -- check that at most one slave is allowed to be enabled
      assert CountOnes(not decodedChipSelects) <= 1
        report "more than one chip select signal asserted" severity error;
    end if;
  end process;

end test;
--synopsys translate_on

--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: mb_cpld_tb
-- Description:
-- Testbench for motherboard CPLD

--nisim --PreLoadCmd="vlog -work work ../../../../usrp3/top/x400/cpld/ip/oddr/oddr/altera_gpio_lite.sv"
--nisim --op1="-L altera_mf_ver -L fiftyfivenm_ver -L altera_ver -L lpm_ver +nowarnTFMPC"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgMB_CPLD_PL_REGMAP.all;
  use work.PkgMB_CPLD_PS_REGMAP.all;
  use work.PkgPL_CPLD_BASE_REGMAP.all;
  use work.PkgPS_CPLD_BASE_REGMAP.all;
  use work.PkgPS_POWER_REGMAP.all;
  use work.PkgSPI_REGMAP.all;
  use work.PkgJTAG_REGMAP.all;
  use work.PkgCONSTANTS_REGMAP.all;
  use work.PkgRECONFIG_REGMAP.all;
  use work.PkgI2cSlvApi.all;
  use work.PkgI2cMstrApi.all;
  use work.PkgByteArray.all;
library std;
  use std.env.all;

entity mb_cpld_tb is end mb_cpld_tb;

architecture test of mb_cpld_tb is

  component simple_spi_core
    generic (
      BASE     : integer := 0;
      WIDTH    : integer := 8;
      CLK_IDLE : integer := 0;
      SEN_IDLE : integer := 2#111111111111111111111111#);
    port (
      clock        : in  std_logic;
      reset        : in  std_logic;
      set_stb      : in  std_logic;
      set_addr     : in  std_logic_vector(7 downto 0);
      set_data     : in  std_logic_vector(31 downto 0);
      readback     : out std_logic_vector(31 downto 0);
      readback_stb : out std_logic;
      ready        : out std_logic;
      sen          : out std_logic_vector((WIDTH-1) downto 0);
      sclk         : out std_logic;
      mosi         : out std_logic;
      miso         : in  std_logic;
      debug        : out std_logic_vector(31 downto 0));
  end component;
  component spi_slave_to_ctrlport_master
    generic (
      CLK_FREQUENCY : integer := 50000000;
      SPI_FREQUENCY : integer := 10000000);
    port (
      ctrlport_clk           : in  std_logic;
      ctrlport_rst           : in  std_logic;
      m_ctrlport_req_wr      : out std_logic;
      m_ctrlport_req_rd      : out std_logic;
      m_ctrlport_req_addr    : out std_logic_vector(19 downto 0);
      m_ctrlport_req_data    : out std_logic_vector(31 downto 0);
      m_ctrlport_resp_ack    : in  std_logic;
      m_ctrlport_resp_status : in  std_logic_vector(1 downto 0);
      m_ctrlport_resp_data   : in  std_logic_vector(31 downto 0);
      sclk                   : in  std_logic;
      cs_n                   : in  std_logic;
      mosi                   : in  std_logic;
      miso                   : out std_logic);
  end component;
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
  signal clk_db_cs_n: std_logic;
  signal clk_db_miso: std_logic;
  signal clk_db_mosi: std_logic;
  signal clk_db_sclk: std_logic;
  signal ctrlport_spi_mosi: std_logic;
  signal ctrlport_spi_sclk: std_logic;
  signal ctrlport_spi_ss: std_logic_vector(1 downto 0);
  signal db_0_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal db_0_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal db_0_ctrlport_req_rd: std_logic;
  signal db_0_ctrlport_req_wr: std_logic;
  signal db_0_ctrlport_resp_ack: std_logic;
  signal db_0_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal db_0_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal db_1_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal db_1_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal db_1_ctrlport_req_rd: std_logic;
  signal db_1_ctrlport_req_wr: std_logic;
  signal db_1_ctrlport_resp_ack: std_logic;
  signal db_1_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal db_1_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal DB_ARST: std_logic_vector(1 downto 0);
  signal DB_CALEEPROM_CS_N: std_logic_vector(1 downto 0);
  signal DB_CALEEPROM_MISO: std_logic_vector(1 downto 0);
  signal DB_CALEEPROM_MOSI: std_logic_vector(1 downto 0);
  signal DB_CALEEPROM_SCLK: std_logic_vector(1 downto 0);
  signal DB_CTRL_CS_N: std_logic_vector(1 downto 0);
  signal DB_CTRL_MISO: std_logic_vector(1 downto 0);
  signal DB_CTRL_MOSI: std_logic_vector(1 downto 0);
  signal DB_CTRL_SCLK: std_logic_vector(1 downto 0);
  signal DB_JTAG_TCK: std_logic_vector(1 downto 0);
  signal DB_JTAG_TDI: std_logic_vector(1 downto 0);
  signal DB_JTAG_TDO: std_logic_vector(1 downto 0);
  signal DB_JTAG_TMS: std_logic_vector(1 downto 0);
  signal DB_REF_CLK: std_logic_vector(1 downto 0);
  signal DIO_DIRECTION_A: std_logic_vector(11 downto 0);
  signal DIO_DIRECTION_B: std_logic_vector(11 downto 0);
  signal IPASS_POWER_DISABLE: std_logic;
  signal IPASS_POWER_EN_FAULT: std_logic_vector(1 downto 0);
  signal IPASS_PRESENT_N: std_logic_vector(1 downto 0);
  signal IPASS_SCL: std_logic_vector(1 downto 0);
  signal IPASS_SDA: std_logic_vector(1 downto 0);
  signal lmk32_cs_n: std_logic;
  signal lmk32_miso: std_logic;
  signal lmk32_mosi: std_logic;
  signal lmk32_sclk: std_logic;
  signal mosi: std_logic;
  signal PCIE_RESET: std_logic;
  signal phase_dac_cs_n: std_logic;
  signal phase_dac_mosi: std_logic;
  signal phase_dac_sclk: std_logic;
  signal phaseDacReceivedData: std_logic_vector(15 downto 0);
  signal pl_cpld_cs_n: std_logic_vector(1 downto 0);
  signal PL_CPLD_IRQ: std_logic;
  signal pl_cpld_miso: std_logic;
  signal pl_cpld_mosi: std_logic;
  signal pl_cpld_sclk: std_logic;
  signal pl_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal pl_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal pl_ctrlport_req_rd: std_logic;
  signal pl_ctrlport_req_wr: std_logic;
  signal pl_ctrlport_resp_ack: std_logic;
  signal pl_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal pl_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal PS_CLK_ON_CPLD: std_logic;
  signal PS_CPLD_CS_N: std_logic_vector(3 downto 0);
  signal ps_cpld_miso: std_logic;
  signal PS_CPLD_MOSI: std_logic;
  signal PS_CPLD_SCLK: std_logic;
  signal ps_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal ps_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal ps_ctrlport_req_rd: std_logic;
  signal ps_ctrlport_req_wr: std_logic;
  signal ps_ctrlport_resp_ack: std_logic;
  signal ps_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal ps_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal ps_spi_reset: std_logic;
  signal PWR_EN_5V_OSC_100: std_logic;
  signal PWR_EN_5V_OSC_122_88: std_logic;
  signal pwr_supply_clk_0p9v: std_logic;
  signal pwr_supply_clk_1p8v: std_logic;
  signal pwr_supply_clk_2p5v: std_logic;
  signal pwr_supply_clk_3p3v: std_logic;
  signal pwr_supply_clk_3p6v: std_logic;
  signal pwr_supply_clk_core: std_logic;
  signal pwr_supply_clk_ddr4_n: std_logic;
  signal pwr_supply_clk_ddr4_s: std_logic;
  signal QSFP0_LED_ACTIVE: std_logic_vector(3 downto 0);
  signal QSFP0_LED_LINK: std_logic_vector(3 downto 0);
  signal QSFP1_LED_ACTIVE: std_logic_vector(3 downto 0);
  signal QSFP1_LED_LINK: std_logic_vector(3 downto 0);
  signal readback: std_logic_vector(31 downto 0);
  signal readback_stb: std_logic;
  signal sclk: std_logic;
  signal sen: std_logic_vector(0 downto 0);
  signal set_addr: std_logic_vector(7 downto 0);
  signal set_data: std_logic_vector(31 downto 0);
  signal set_stb: std_logic;
  signal spi_master_reset: std_logic;
  signal TestName: TestStatusString_t;
  signal TestStatus: TestStatusString_t;
  signal TestStatus2: TestStatusString_t;
  signal TestStatus3: TestStatusString_t;
  signal TestStatus4: TestStatusString_t;
  signal tpm_cs_n: std_logic;
  signal tpm_miso: std_logic;
  signal tpm_mosi: std_logic;
  signal TPM_RESET_n: std_logic;
  signal tpm_sclk: std_logic;
  --vhook_sigend

  signal StopSim : boolean;
  constant kReliableClkPer : time := 10 ns;  -- 100 MHz
  constant kPrcPer : time := 16 ns;  -- 62,5 MHz

  constant kDb0AddressOffset : integer := 2**15;
  constant kDb1AddressOffset : integer := 2**(15+1);

  signal useSimpleSpi : boolean := false;
  signal spiBinarySlaveSelect : std_logic_vector(2 downto 0) := (others => '0');

  type tJtag is array (0 to 1) of std_logic_vector(15 downto 0);
  signal jtagTmsReceivedData : tJtag := (others => (others => '0'));

  signal CLK_100: std_logic := '0';
  signal pll_ref_clk: std_logic := '0';

  -- addresses of simple_spi_core
  constant kSpiCoreDividerAddress       : std_logic_vector(7 downto 0) := X"00";
  constant kSpiCoreConfigurationAddress : std_logic_vector(7 downto 0) := X"01";
  constant kSpiCoreDataAddress          : std_logic_vector(7 downto 0) := X"02";

  -- unique IDs of SPI slaves (randomly picked numbers, IDLE not assigned)
  type tUniqueId is array(kSPI_ENDPOINTSize-2 downto 0) of std_logic_vector(7 downto 0);
  constant kSpiUniqueIds : tUniqueId := (X"38", X"A7", X"9F", X"04", X"04", X"55", X"CE");

  -- random generators
  shared variable Random : Random_t;

  -- CMI constants
  constant kSlaveId : natural := 0;
  constant kMasterId : natural := 0;
  constant kSerialNumber : std_logic_vector(39 downto 0) := x"ABC31DDCC6";

  -- Test intermediate variables
  signal tempVar : std_logic_vector(31 downto 0) := (others => '0');

  -- Hold expected reset value
  signal aExpectedDbReset: std_logic_vector(1 downto 0) := (others => '-');

begin

  CLK_100 <= not CLK_100 after kReliableClkPer/2 when not StopSim else '0';
  pll_ref_clk <= not pll_ref_clk after kPrcPer/2 when not StopSim else '0';

  --vhook mb_cpld dutx
  --vhook_a SIMULATION 1
  dutx: mb_cpld
    generic map (SIMULATION => 1)  --integer:=0
    port map (
      PLL_REF_CLK           => PLL_REF_CLK,            --in  wire
      CLK_100               => CLK_100,                --in  wire
      PWR_SUPPLY_CLK_CORE   => PWR_SUPPLY_CLK_CORE,    --out wire
      PWR_SUPPLY_CLK_DDR4_S => PWR_SUPPLY_CLK_DDR4_S,  --out wire
      PWR_SUPPLY_CLK_DDR4_N => PWR_SUPPLY_CLK_DDR4_N,  --out wire
      PWR_SUPPLY_CLK_0P9V   => PWR_SUPPLY_CLK_0P9V,    --out wire
      PWR_SUPPLY_CLK_1P8V   => PWR_SUPPLY_CLK_1P8V,    --out wire
      PWR_SUPPLY_CLK_2P5V   => PWR_SUPPLY_CLK_2P5V,    --out wire
      PWR_SUPPLY_CLK_3P3V   => PWR_SUPPLY_CLK_3P3V,    --out wire
      PWR_SUPPLY_CLK_3P6V   => PWR_SUPPLY_CLK_3P6V,    --out wire
      PWR_EN_5V_OSC_100     => PWR_EN_5V_OSC_100,      --out wire
      PWR_EN_5V_OSC_122_88  => PWR_EN_5V_OSC_122_88,   --out wire
      IPASS_POWER_DISABLE   => IPASS_POWER_DISABLE,    --out wire
      IPASS_POWER_EN_FAULT  => IPASS_POWER_EN_FAULT,   --in  wire[1:0]
      PL_CPLD_SCLK          => PL_CPLD_SCLK,           --in  wire
      PL_CPLD_MOSI          => PL_CPLD_MOSI,           --in  wire
      PL_CPLD_MISO          => PL_CPLD_MISO,           --out wire
      PL_CPLD_CS_N          => PL_CPLD_CS_N,           --in  wire[1:0]
      PL_CPLD_IRQ           => PL_CPLD_IRQ,            --out wire
      PS_CPLD_SCLK          => PS_CPLD_SCLK,           --in  wire
      PS_CPLD_MOSI          => PS_CPLD_MOSI,           --in  wire
      PS_CPLD_MISO          => PS_CPLD_MISO,           --out wire
      PS_CPLD_CS_N          => PS_CPLD_CS_N,           --in  wire[3:0]
      CLK_DB_SCLK           => CLK_DB_SCLK,            --out wire
      CLK_DB_MOSI           => CLK_DB_MOSI,            --out wire
      CLK_DB_MISO           => CLK_DB_MISO,            --in  wire
      CLK_DB_CS_N           => CLK_DB_CS_N,            --out wire
      QSFP0_LED_ACTIVE      => QSFP0_LED_ACTIVE,       --out wire[3:0]
      QSFP0_LED_LINK        => QSFP0_LED_LINK,         --out wire[3:0]
      QSFP1_LED_ACTIVE      => QSFP1_LED_ACTIVE,       --out wire[3:0]
      QSFP1_LED_LINK        => QSFP1_LED_LINK,         --out wire[3:0]
      DB_CTRL_SCLK          => DB_CTRL_SCLK,           --out wire[1:0]
      DB_CTRL_MOSI          => DB_CTRL_MOSI,           --out wire[1:0]
      DB_CTRL_MISO          => DB_CTRL_MISO,           --in  wire[1:0]
      DB_CTRL_CS_N          => DB_CTRL_CS_N,           --out wire[1:0]
      DB_REF_CLK            => DB_REF_CLK,             --out wire[1:0]
      DB_ARST               => DB_ARST,                --out wire[1:0]
      DB_JTAG_TCK           => DB_JTAG_TCK,            --out wire[1:0]
      DB_JTAG_TDI           => DB_JTAG_TDI,            --out wire[1:0]
      DB_JTAG_TDO           => DB_JTAG_TDO,            --in  wire[1:0]
      DB_JTAG_TMS           => DB_JTAG_TMS,            --out wire[1:0]
      LMK32_SCLK            => LMK32_SCLK,             --out wire
      LMK32_MOSI            => LMK32_MOSI,             --out wire
      LMK32_MISO            => LMK32_MISO,             --in  wire
      LMK32_CS_N            => LMK32_CS_N,             --out wire
      TPM_SCLK              => TPM_SCLK,               --out wire
      TPM_MOSI              => TPM_MOSI,               --out wire
      TPM_MISO              => TPM_MISO,               --in  wire
      TPM_CS_N              => TPM_CS_N,               --out wire
      PHASE_DAC_SCLK        => PHASE_DAC_SCLK,         --out wire
      PHASE_DAC_MOSI        => PHASE_DAC_MOSI,         --out wire
      PHASE_DAC_CS_N        => PHASE_DAC_CS_N,         --out wire
      DIO_DIRECTION_A       => DIO_DIRECTION_A,        --out wire[11:0]
      DIO_DIRECTION_B       => DIO_DIRECTION_B,        --out wire[11:0]
      DB_CALEEPROM_SCLK     => DB_CALEEPROM_SCLK,      --out wire[1:0]
      DB_CALEEPROM_MOSI     => DB_CALEEPROM_MOSI,      --out wire[1:0]
      DB_CALEEPROM_MISO     => DB_CALEEPROM_MISO,      --in  wire[1:0]
      DB_CALEEPROM_CS_N     => DB_CALEEPROM_CS_N,      --out wire[1:0]
      PS_CLK_ON_CPLD        => PS_CLK_ON_CPLD,         --out wire
      IPASS_PRESENT_N       => IPASS_PRESENT_N,        --in  wire[1:0]
      IPASS_SCL             => IPASS_SCL,              --inout wire[1:0]
      IPASS_SDA             => IPASS_SDA,              --inout wire[1:0]
      PCIE_RESET            => PCIE_RESET,             --out wire
      TPM_RESET_n           => TPM_RESET_n);           --out wire

  --vhook_e ctrlport_spi_master ps_spi_master
  --vhook_a CPLD_ADDRESS_WIDTH 15
  --vhook_a MB_CPLD_BASE_ADDRESS 0
  --vhook_a DB_0_CPLD_BASE_ADDRESS X"10000"
  --vhook_a DB_1_CPLD_BASE_ADDRESS X"18000"
  --vhook_a ctrlport_clk pll_ref_clk
  --vhook_a ctrlport_rst spi_master_reset
  --vhook_a {s_ctrlport_(.*)} ps_ctrlport_$1
  --vhook_a ss ctrlport_spi_ss
  --vhook_a sclk ctrlport_spi_sclk
  --vhook_a mosi ctrlport_spi_mosi
  --vhook_a miso ps_cpld_miso
  --vhook_a MB_clock_divider X"0006"
  --vhook_a DB_clock_divider X"FFFF"
  ps_spi_master: entity work.ctrlport_spi_master (rtl)
    generic map (
      CPLD_ADDRESS_WIDTH     => 15,        --integer:=15
      MB_CPLD_BASE_ADDRESS   => 0,         --integer:=2#1000000000000000#
      DB_0_CPLD_BASE_ADDRESS => X"10000",  --integer:=2#10000000000000000#
      DB_1_CPLD_BASE_ADDRESS => X"18000")  --integer:=2#11000000000000000#
    port map (
      ctrlport_clk           => pll_ref_clk,              --in  wire
      ctrlport_rst           => spi_master_reset,         --in  wire
      s_ctrlport_req_wr      => ps_ctrlport_req_wr,       --in  wire
      s_ctrlport_req_rd      => ps_ctrlport_req_rd,       --in  wire
      s_ctrlport_req_addr    => ps_ctrlport_req_addr,     --in  wire[19:0]
      s_ctrlport_req_data    => ps_ctrlport_req_data,     --in  wire[31:0]
      s_ctrlport_resp_ack    => ps_ctrlport_resp_ack,     --out wire
      s_ctrlport_resp_status => ps_ctrlport_resp_status,  --out wire[1:0]
      s_ctrlport_resp_data   => ps_ctrlport_resp_data,    --out wire[31:0]
      ss                     => ctrlport_spi_ss,          --out wire[1:0]
      sclk                   => ctrlport_spi_sclk,        --out wire
      mosi                   => ctrlport_spi_mosi,        --out wire
      miso                   => ps_cpld_miso,             --in  wire
      mb_clock_divider       => X"0006",                  --in  wire[15:0]
      db_clock_divider       => X"FFFF");                 --in  wire[15:0]


  --vhook_e ctrlport_spi_master pl_spi_master
  --vhook_a CPLD_ADDRESS_WIDTH 15
  --vhook_a MB_CPLD_BASE_ADDRESS 0
  --vhook_a DB_0_CPLD_BASE_ADDRESS kDb0AddressOffset
  --vhook_a DB_1_CPLD_BASE_ADDRESS kDb1AddressOffset
  --vhook_a ctrlport_clk pll_ref_clk
  --vhook_a ctrlport_rst spi_master_reset
  --vhook_a {s_ctrlport_(.*)} pl_ctrlport_$1
  --vhook_a ss pl_cpld_cs_n
  --vhook_a sclk pl_cpld_sclk
  --vhook_a mosi pl_cpld_mosi
  --vhook_a miso pl_cpld_miso
  --vhook_a MB_clock_divider X"0002"
  --vhook_a DB_clock_divider X"0004"
  pl_spi_master: entity work.ctrlport_spi_master (rtl)
    generic map (
      CPLD_ADDRESS_WIDTH     => 15,                 --integer:=15
      MB_CPLD_BASE_ADDRESS   => 0,                  --integer:=2#1000000000000000#
      DB_0_CPLD_BASE_ADDRESS => kDb0AddressOffset,  --integer:=2#10000000000000000#
      DB_1_CPLD_BASE_ADDRESS => kDb1AddressOffset)  --integer:=2#11000000000000000#
    port map (
      ctrlport_clk           => pll_ref_clk,              --in  wire
      ctrlport_rst           => spi_master_reset,         --in  wire
      s_ctrlport_req_wr      => pl_ctrlport_req_wr,       --in  wire
      s_ctrlport_req_rd      => pl_ctrlport_req_rd,       --in  wire
      s_ctrlport_req_addr    => pl_ctrlport_req_addr,     --in  wire[19:0]
      s_ctrlport_req_data    => pl_ctrlport_req_data,     --in  wire[31:0]
      s_ctrlport_resp_ack    => pl_ctrlport_resp_ack,     --out wire
      s_ctrlport_resp_status => pl_ctrlport_resp_status,  --out wire[1:0]
      s_ctrlport_resp_data   => pl_ctrlport_resp_data,    --out wire[31:0]
      ss                     => pl_cpld_cs_n,             --out wire[1:0]
      sclk                   => pl_cpld_sclk,             --out wire
      mosi                   => pl_cpld_mosi,             --out wire
      miso                   => pl_cpld_miso,             --in  wire
      mb_clock_divider       => X"0002",                  --in  wire[15:0]
      db_clock_divider       => X"0004");                 --in  wire[15:0]

  --vhook_e spi_memory_model db_0_eeprom
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_DB0_CAL_EEPROM)
  --vhook_a receivedData open
  --vhook_a {(.*)} db_caleeprom_$1(0)
  db_0_eeprom: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_DB0_CAL_EEPROM))  --std_logic_vector(7:0)
    port map (
      sclk         => db_caleeprom_sclk(0),  --in  std_logic
      mosi         => db_caleeprom_mosi(0),  --in  std_logic
      miso         => db_caleeprom_miso(0),  --out std_logic
      cs_n         => db_caleeprom_cs_n(0),  --in  std_logic
      receivedData => open);                 --out std_logic_vector(15:0)

  --vhook_e spi_memory_model db_1_eeprom
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_DB1_CAL_EEPROM)
  --vhook_a receivedData open
  --vhook_a {(.*)} db_caleeprom_$1(1)
  db_1_eeprom: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_DB1_CAL_EEPROM))  --std_logic_vector(7:0)
    port map (
      sclk         => db_caleeprom_sclk(1),  --in  std_logic
      mosi         => db_caleeprom_mosi(1),  --in  std_logic
      miso         => db_caleeprom_miso(1),  --out std_logic
      cs_n         => db_caleeprom_cs_n(1),  --in  std_logic
      receivedData => open);                 --out std_logic_vector(15:0)

  --vhook_e spi_memory_model lmk_32
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_LMK32)
  --vhook_a receivedData open
  --vhook_a {(.*)} lmk32_$1
  lmk_32: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_LMK32))  --std_logic_vector(7:0)
    port map (
      sclk         => lmk32_sclk,  --in  std_logic
      mosi         => lmk32_mosi,  --in  std_logic
      miso         => lmk32_miso,  --out std_logic
      cs_n         => lmk32_cs_n,  --in  std_logic
      receivedData => open);       --out std_logic_vector(15:0)

  --vhook_e spi_memory_model tpm
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_TPM)
  --vhook_a receivedData open
  --vhook_a {(.*)} tpm_$1
  tpm: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_TPM))  --std_logic_vector(7:0)
    port map (
      sclk         => tpm_sclk,  --in  std_logic
      mosi         => tpm_mosi,  --in  std_logic
      miso         => tpm_miso,  --out std_logic
      cs_n         => tpm_cs_n,  --in  std_logic
      receivedData => open);     --out std_logic_vector(15:0)

  --vhook_e spi_memory_model phase_dac
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_PHASE_DAC)
  --vhook_a receivedData phaseDacReceivedData
  --vhook_a miso open
  --vhook_a {(.*)} phase_dac_$1
  phase_dac: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_PHASE_DAC))  --std_logic_vector(7:0)
    port map (
      sclk         => phase_dac_sclk,        --in  std_logic
      mosi         => phase_dac_mosi,        --in  std_logic
      miso         => open,                  --out std_logic
      cs_n         => phase_dac_cs_n,        --in  std_logic
      receivedData => phaseDacReceivedData); --out std_logic_vector(15:0)

  --vhook_e spi_memory_model clk_db
  --vhook_a kUniqueId kSpiUniqueIds(kPS_CS_CLK_AUX_DB)
  --vhook_a receivedData open
  --vhook_a {(.*)} clk_db_$1
  clk_db: entity work.spi_memory_model (sim)
    generic map (kUniqueId => kSpiUniqueIds(kPS_CS_CLK_AUX_DB))  --std_logic_vector(7:0)
    port map (
      sclk         => clk_db_sclk,  --in  std_logic
      mosi         => clk_db_mosi,  --in  std_logic
      miso         => clk_db_miso,  --out std_logic
      cs_n         => clk_db_cs_n,  --in  std_logic
      receivedData => open);        --out std_logic_vector(15:0)

  ------------------------------------------------------------------------------
  -- Emulate JTAG by two spi memories
  ------------------------------------------------------------------------------
  jtag_gen : for i in 0 to 1 generate
    --vhook_e spi_memory_model jtag_tms_inst
    --vhook_a kUniqueId std_logic_vector(to_unsigned(16#60# + 2*i, 8))
    --vhook_a receivedData jtagTmsReceivedData(i)
    --vhook_a sclk db_jtag_tck(i)
    --vhook_a mosi db_jtag_tms(i)
    --vhook_a miso open
    --vhook_a cs_n '0'
    jtag_tms_inst: entity work.spi_memory_model (sim)
      generic map (kUniqueId => std_logic_vector(to_unsigned(16#60# + 2*i, 8)))  --std_logic_vector(7:0)
      port map (
        sclk         => db_jtag_tck(i),          --in  std_logic
        mosi         => db_jtag_tms(i),          --in  std_logic
        miso         => open,                    --out std_logic
        cs_n         => '0',                     --in  std_logic
        receivedData => jtagTmsReceivedData(i)); --out std_logic_vector(15:0)

    --vhook_e spi_memory_model jtag_tdi_inst
    --vhook_a kUniqueId std_logic_vector(to_unsigned(16#60# + 2*i + 1, 8))
    --vhook_a receivedData open
    --vhook_a sclk db_jtag_tck(i)
    --vhook_a mosi db_jtag_tdi(i)
    --vhook_a miso db_jtag_tdo(i)
    --vhook_a cs_n '0'
    jtag_tdi_inst: entity work.spi_memory_model (sim)
      generic map (kUniqueId => std_logic_vector(to_unsigned(16#60# + 2*i + 1, 8)))  --std_logic_vector(7:0)
      port map (
        sclk         => db_jtag_tck(i),  --in  std_logic
        mosi         => db_jtag_tdi(i),  --in  std_logic
        miso         => db_jtag_tdo(i),  --out std_logic
        cs_n         => '0',             --in  std_logic
        receivedData => open);           --out std_logic_vector(15:0)
  end generate;

  --vhook spi_slave_to_ctrlport_master db_0
  --vhook_a CLK_FREQUENCY 100000000
  --vhook_a SPI_FREQUENCY 32000000
  --vhook_a ctrlport_clk db_ref_clk(0)
  --vhook_a ctrlport_rst db_arst(0)
  --vhook_a  {m_ctrlport_(.*)} db_0_ctrlport_$1
  --vhook_a  {(....)} db_ctrl_$1(0)
  db_0: spi_slave_to_ctrlport_master
    generic map (
      CLK_FREQUENCY => 100000000,  --integer:=50000000
      SPI_FREQUENCY => 32000000)   --integer:=10000000
    port map (
      ctrlport_clk           => db_ref_clk(0),              --in  wire
      ctrlport_rst           => db_arst(0),                 --in  wire
      m_ctrlport_req_wr      => db_0_ctrlport_req_wr,       --out wire
      m_ctrlport_req_rd      => db_0_ctrlport_req_rd,       --out wire
      m_ctrlport_req_addr    => db_0_ctrlport_req_addr,     --out wire[19:0]
      m_ctrlport_req_data    => db_0_ctrlport_req_data,     --out wire[31:0]
      m_ctrlport_resp_ack    => db_0_ctrlport_resp_ack,     --in  wire
      m_ctrlport_resp_status => db_0_ctrlport_resp_status,  --in  wire[1:0]
      m_ctrlport_resp_data   => db_0_ctrlport_resp_data,    --in  wire[31:0]
      sclk                   => db_ctrl_sclk(0),            --in  wire
      cs_n                   => db_ctrl_cs_n(0),            --in  wire
      mosi                   => db_ctrl_mosi(0),            --in  wire
      miso                   => db_ctrl_miso(0));           --out wire

  --vhook spi_slave_to_ctrlport_master db_1
  --vhook_a CLK_FREQUENCY 100000000
  --vhook_a SPI_FREQUENCY 32000000
  --vhook_a ctrlport_clk db_ref_clk(1)
  --vhook_a ctrlport_rst db_arst(1)
  --vhook_a  {m_ctrlport_(.*)} db_1_ctrlport_$1
  --vhook_a  {(....)} db_ctrl_$1(1)
  db_1: spi_slave_to_ctrlport_master
    generic map (
      CLK_FREQUENCY => 100000000,  --integer:=50000000
      SPI_FREQUENCY => 32000000)   --integer:=10000000
    port map (
      ctrlport_clk           => db_ref_clk(1),              --in  wire
      ctrlport_rst           => db_arst(1),                 --in  wire
      m_ctrlport_req_wr      => db_1_ctrlport_req_wr,       --out wire
      m_ctrlport_req_rd      => db_1_ctrlport_req_rd,       --out wire
      m_ctrlport_req_addr    => db_1_ctrlport_req_addr,     --out wire[19:0]
      m_ctrlport_req_data    => db_1_ctrlport_req_data,     --out wire[31:0]
      m_ctrlport_resp_ack    => db_1_ctrlport_resp_ack,     --in  wire
      m_ctrlport_resp_status => db_1_ctrlport_resp_status,  --in  wire[1:0]
      m_ctrlport_resp_data   => db_1_ctrlport_resp_data,    --in  wire[31:0]
      sclk                   => db_ctrl_sclk(1),            --in  wire
      cs_n                   => db_ctrl_cs_n(1),            --in  wire
      mosi                   => db_ctrl_mosi(1),            --in  wire
      miso                   => db_ctrl_miso(1));           --out wire

  --vhook simple_spi_core simple_spi
  --vhook_a WIDTH 1
  --vhook_a BASE 0
  --vhook_a CLK_IDLE 0
  --vhook_a SEN_IDLE 16#F#
  --vhook_a clock CLK_100
  --vhook_a reset ps_spi_reset
  --vhook_a miso ps_cpld_miso
  --vhook_a debug open
  --vhook_a ready open
  simple_spi: simple_spi_core
    generic map (
      BASE     => 0,      --integer:=0
      WIDTH    => 1,      --integer:=8
      CLK_IDLE => 0,      --integer:=0
      SEN_IDLE => 16#F#)  --integer:=2#111111111111111111111111#
    port map (
      clock        => CLK_100,       --in  wire
      reset        => ps_spi_reset,  --in  wire
      set_stb      => set_stb,       --in  wire
      set_addr     => set_addr,      --in  wire[7:0]
      set_data     => set_data,      --in  wire[31:0]
      readback     => readback,      --out wire[31:0]
      readback_stb => readback_stb,  --out wire
      ready        => open,          --out wire
      sen          => sen,           --out wire[(WIDTH-1):0]
      sclk         => sclk,          --out wire
      mosi         => mosi,          --out wire
      miso         => ps_cpld_miso,  --in  wire
      debug        => open);         --out wire[31:0]


  -- drive PS interface from two interfaces based on switch
  ps_cpld_mosi    <= mosi   when useSimpleSpi else ctrlport_spi_mosi;
  ps_cpld_sclk    <= sclk   when useSimpleSpi else ctrlport_spi_sclk;
  ps_cpld_cs_n(3) <= '1';
  ps_cpld_cs_n(2 downto 0) <= spiBinarySlaveSelect when (useSimpleSpi and sen(0) /= '1') or
                                (not useSimpleSpi and ctrlport_spi_ss /= "11") else
                              (others => '1');

  -- pull ups on CS signals
  LMK32_CS_N <= 'H';
  TPM_CS_N <= 'H';
  PHASE_DAC_CS_N <= 'H';
  DB_CALEEPROM_CS_N <= "HH";

  -- pull on I²C interfaces
  IPASS_SDA <= "HH";
  IPASS_SCL <= "HH";

  --Upstream I²C slave
  --vhook_e I2cSlaveBfm
  --vhook_a kId kSlaveId
  --vhook_a Clk CLK_100
  --vhook_a aSda IPASS_SDA(0)
  --vhook_a aScl IPASS_SCL(0)
  I2cSlaveBfmx: entity work.I2cSlaveBfm (test)
    generic map (kId => kSlaveId)  --natural:=0
    port map (
      Clk  => CLK_100,       --in  std_logic
      aSda => IPASS_SDA(0),  --inout std_logic
      aScl => IPASS_SCL(0)); --inout std_logic

  --Upstream I²C master
  --vhook_e I2cMasterBfm
  --vhook_a kId kMasterId
  --vhook_a kQuarterPeriod 2.5 us
  --vhook_a Clk CLK_100
  --vhook_a aSda IPASS_SDA(0)
  --vhook_a aScl IPASS_SCL(0)
  I2cMasterBfmx: entity work.I2cMasterBfm (test)
    generic map (
      kId            => kMasterId,  --natural:=0
      kQuarterPeriod => 2.5 us)     --time:=550ns
    port map (
      Clk  => CLK_100,       --in  std_logic
      aSda => IPASS_SDA(0),  --inout std_logic
      aScl => IPASS_SCL(0)); --inout std_logic

  --vhook_e TestStatusModel
  TestStatusModelx: entity work.TestStatusModel (test)
    port map (
      StopSim     => StopSim,      --in  boolean
      TestName    => TestName,     --out TestStatusString_t
      TestStatus  => TestStatus,   --out TestStatusString_t
      TestStatus2 => TestStatus2,  --out TestStatusString_t
      TestStatus3 => TestStatus3,  --out TestStatusString_t
      TestStatus4 => TestStatus4); --out TestStatusString_t

  VPrint(TestName);
  VPrint(TestStatus);
  VPrint(TestStatus2);
  VPrint(TestStatus3);
  VPrint(TestStatus4);

  dbReceiver : process(db_ref_clk)
  begin
    -- DB 0
    if rising_edge(db_ref_clk(0)) then
      db_0_ctrlport_resp_data <= (others => 'X');
      db_0_ctrlport_resp_status <= (others => '0');
      db_0_ctrlport_resp_ack <= '0';

      -- acknowledge each write access
      if db_0_ctrlport_req_wr = '1' then
        db_0_ctrlport_resp_ack <= '1';
        db_0_ctrlport_resp_status <= "00";
        db_0_ctrlport_resp_data <= db_0_ctrlport_req_data;
      elsif db_0_ctrlport_req_rd = '1' then
        db_0_ctrlport_resp_ack <= '1';
        db_0_ctrlport_resp_status <= "00";
        db_0_ctrlport_resp_data <= X"ABC" & db_0_ctrlport_req_addr;
      end if;
    end if;

    -- DB 1
    if rising_edge(db_ref_clk(1)) then
      db_1_ctrlport_resp_data <= (others => 'X');
      db_1_ctrlport_resp_status <= (others => '0');
      db_1_ctrlport_resp_ack <= '0';

      -- acknowledge each write access
      if db_1_ctrlport_req_wr = '1' then
        db_1_ctrlport_resp_ack <= '1';
        db_1_ctrlport_resp_status <= "00";
        db_1_ctrlport_resp_data <= db_1_ctrlport_req_data;
      elsif db_1_ctrlport_req_rd = '1' then
        db_1_ctrlport_resp_ack <= '1';
        db_1_ctrlport_resp_status <= "00";
        db_1_ctrlport_resp_data <= X"987" & db_1_ctrlport_req_addr;
      end if;
    end if;
  end process;

  dbResetCheck : process(db_arst, aExpectedDbReset)
  begin
    for i in 1 downto 0 loop
      assert std_match(db_arst(i), aExpectedDbReset(i))
        report "DB reset reflects incorrect value"
        severity error;
    end loop;

  end process;

  unusedSignalCheck: process
  begin
    continiousCheck : while not StopSim loop
      wait for 1 ns;
      assert tpm_reset_n = '1' report "tpm_reset_n changed!" severity error;
      assert pl_cpld_irq = '0' report "pl_cpld_irq changed!" severity error;
      assert ps_clk_on_cpld = '0' report "ps_clk_on_cpld changed!" severity error;
    end loop continiousCheck;
    wait;
  end process;

  main: process
    -- function for Controlport requests
    procedure PlSendControlPortRequest(address : natural; data : in std_logic_vector(31 downto 0); write : in boolean) is
      constant slvAddress : std_logic_vector(pl_ctrlport_req_addr'range) := std_logic_vector(to_unsigned(address, pl_ctrlport_req_addr'length));
    begin
      -- issue request
      wait until falling_edge(pll_ref_clk);
      pl_ctrlport_req_addr <= slvAddress;
      pl_ctrlport_req_data <= data;
      if write then
        pl_ctrlport_req_wr <= '1';
        pl_ctrlport_req_rd <= '0';
      else
        pl_ctrlport_req_wr <= '0';
        pl_ctrlport_req_rd <= '1';
      end if;

      -- deassert signals
      wait until falling_edge(pll_ref_clk);
      pl_ctrlport_req_addr <= (others => 'X');
      pl_ctrlport_req_data <= (others => 'X');
      pl_ctrlport_req_wr <= '0';
      pl_ctrlport_req_rd <= '0';
    end procedure PlSendControlPortRequest;

    -- check for expexted controlport response
    procedure PlCheckControlPortResponse(isError : in boolean; checkData : in boolean; expectedData : in std_logic_vector(31 downto 0)) is
      variable expectedStatus : std_logic_vector(1 downto 0);
    begin
      -- set expected status
      if isError then
        expectedStatus := "01";
      else
        expectedStatus := "00";
      end if;

      -- wait for acknowledge in case not jet asserted
      if pl_ctrlport_resp_ack = '0' then
        -- timeout after 100 us
        wait until pl_ctrlport_resp_ack = '1' for 100 us;
        wait until falling_edge(pll_ref_clk);
      end if;
      -- generate error if no match
      assert pl_ctrlport_resp_ack = '1' report "no response received" severity error;
      assert pl_ctrlport_resp_status = expectedStatus report "received response does not match expectation" severity error;
      if checkData then
        assert pl_ctrlport_resp_data = expectedData report "received response does not match expectation" severity error;
      end if;
    end procedure PlCheckControlPortResponse;

    -- Wrapper function for the above two methods to simplify code.
    procedure PlVerifyRead(constant Address : natural;
                           constant ExpectedData : in std_logic_vector(31 downto 0)) is
    begin
      PlSendControlPortRequest(address, X"00000000", false);
      PlCheckControlPortResponse(false, true, ExpectedData);
    end procedure PlVerifyRead;

    -- wrapper for PL ctrlport write requests
    procedure PlControlPortWriteRequest(address : natural; data : in std_logic_vector(31 downto 0); isError : in boolean := false) is
    begin
      PlSendControlPortRequest(address, data, true);
      PlCheckControlPortResponse(isError, false, Zeros(32));
    end procedure PlControlPortWriteRequest;

    -- function for Controlport requests
    procedure PsSendControlPortRequest(address : natural; data : in std_logic_vector(31 downto 0); write : in boolean) is
      constant slvAddress : std_logic_vector(ps_ctrlport_req_addr'range) := std_logic_vector(to_unsigned(address, ps_ctrlport_req_addr'length));
    begin
      -- select MB CPLD as SPI slave
      spiBinarySlaveSelect <= std_logic_vector(to_unsigned(kPS_CS_MB_CPLD, spiBinarySlaveSelect'length));
      -- use controlport SPI transaction
      useSimpleSpi <= false;

      -- issue request
      wait until falling_edge(pll_ref_clk);
      ps_ctrlport_req_addr <= slvAddress;
      ps_ctrlport_req_data <= data;
      if write then
        ps_ctrlport_req_wr <= '1';
        ps_ctrlport_req_rd <= '0';
      else
        ps_ctrlport_req_wr <= '0';
        ps_ctrlport_req_rd <= '1';
      end if;

      -- deassert signals
      wait until falling_edge(pll_ref_clk);
      ps_ctrlport_req_addr <= (others => 'X');
      ps_ctrlport_req_data <= (others => 'X');
      ps_ctrlport_req_wr <= '0';
      ps_ctrlport_req_rd <= '0';
    end procedure PsSendControlPortRequest;

    -- check for expexted controlport response
    procedure PsCheckControlPortResponse(isError : in boolean; checkData : in boolean; expectedData : in std_logic_vector(31 downto 0)) is
      variable expectedStatus : std_logic_vector(1 downto 0);
    begin
      -- set expected status
      if isError then
        expectedStatus := "01";
      else
        expectedStatus := "00";
      end if;

      -- wait for acknowledge in case not yet asserted
      if ps_ctrlport_resp_ack = '0' then
        -- timeout after 100 us
        wait until ps_ctrlport_resp_ack = '1' for 100 us;
        wait until falling_edge(pll_ref_clk);
      end if;
      -- generate error if no match
      assert ps_ctrlport_resp_ack = '1' report "no response received" severity error;
      assert ps_ctrlport_resp_status = expectedStatus report "received response does not match expectation" severity error;
      if checkData then
        assert ps_ctrlport_resp_data = expectedData report "received response does not match expectation" severity error;
      end if;
    end procedure PsCheckControlPortResponse;

    -- Wrapper function for the above two methods to simplify code.
    procedure PsVerifyRead(constant Address : natural;
                           constant ExpectedData : in std_logic_vector(31 downto 0)) is
    begin
      PsSendControlPortRequest(address, X"00000000", false);
      PsCheckControlPortResponse(false, true, ExpectedData);
    end procedure PsVerifyRead;

    -- wrapper for PS ctrlport write requests
    procedure PsControlPortWriteRequest(address : natural; data : in std_logic_vector(31 downto 0); isError : in boolean := false) is
    begin
      PsSendControlPortRequest(address, data, true);
      PsCheckControlPortResponse(isError, false, Zeros(32));
    end procedure PsControlPortWriteRequest;

    -- start SPI transaction
    procedure PsStartSpiTransaction(ss : in natural; numBits : in natural; data : std_logic_vector(31 downto 0)) is
    begin
      -- check data length
      assert numBits <= 32 report "up to 32 bits supported only" severity error;
      -- set slave select
      wait until falling_edge(CLK_100);
      spiBinarySlaveSelect <= std_logic_vector(to_unsigned(ss, spiBinarySlaveSelect'length));
      -- use simple SPI core
      useSimpleSpi <= true;
      -- configure SPI core
      set_stb  <= '1';
      set_addr <= kSpiCoreConfigurationAddress;
      -- SPI mode (capture on rising edge, launch on falling edge), num bits,
      -- 1 as slave select output enable
      set_data <= "01" & std_logic_vector(to_unsigned(numBits,6)) & X"000001";
      wait until falling_edge(CLK_100);
      -- write data to SPI core, this triggers transmission as well
      -- keep set_stb high as the interface can consume requests each clock cycle
      set_stb <= '1';
      set_addr <= kSpiCoreDataAddress;
      set_data <= data;
      wait until falling_edge(CLK_100);
      set_stb <= '0';
    end procedure PsStartSpiTransaction;

    -- read SPI transaction data
    procedure PsCheckSpiTransactionData(numBits : in natural; expectedData : std_logic_vector(31 downto 0)) is
    begin
       -- wait for data to be transferred
      wait until readback_stb = '1' for 100 us;
      assert readback_stb = '1' report "SPI readback not asserted" severity error;
      wait until falling_edge(CLK_100);
      assert readback(numBits-1 downto 0) = expectedData(numBits-1 downto 0) report "SPI readback mismatch" severity error;
    end procedure PsCheckSpiTransactionData;

    -- check PS SPI slave connection
    procedure CheckPsSpiSlave(slave : in natural) is
      variable address : std_logic_vector(6 downto 0);
      variable data    : std_logic_vector(7 downto 0);
      variable expData : std_logic_vector(7 downto 0) := X"00";
      constant numBits : natural := 16; -- required by spi_memory_model
    begin
      -- generate random address and data
      address := Random.GetStdLogicVector(address'length);
      data    := Random.GetStdLogicVector(data'length);

      -- start writing to random address (MSBs to be transmitted)
      PsStartSpiTransaction(slave, numBits, '1' & address & data & X"0000");
      -- expect unique ID and zeros from SPI slave (data in LSBs)
      PsCheckSpiTransactionData(numBits, X"0000" & kSpiUniqueIds(slave) & expData);

      -- data should now be written to SPI slave's memory
      expData := data;

      -- check with read that data is written correctly
      PsStartSpiTransaction(slave, numBits, '0' & address & X"00" & X"0000");
      -- expect unique ID data written in first transaction
      PsCheckSpiTransactionData(numBits, X"0000" & kSpiUniqueIds(slave) & expData);
    end procedure CheckPsSpiSlave;

    -- start SPI transaction
    procedure PlStartSpiTransaction(baseAddress : in natural; divider : in natural; ss : in natural; numBits : in natural; data : std_logic_vector(31 downto 0)) is
    begin
      -- check data length
      assert numBits <= 32 report "up to 32 bits supported only" severity error;
      -- write data
      PlControlPortWriteRequest(baseAddress + kTX_DATA_LOW, data);
      -- config registers
      PlControlPortWriteRequest(baseAddress + kCLOCK_DIVIDER, std_logic_vector(to_unsigned(divider, ps_ctrlport_req_data'length)));
      PlControlPortWriteRequest(baseAddress + kSLAVE_SELECT, std_logic_vector(shift_left(to_unsigned(1, ps_ctrlport_req_data'length), ss)));
      PlControlPortWriteRequest(baseAddress + work.PkgSPI_REGMAP.kCONTROL, std_logic_vector(to_unsigned(1024+numBits, ps_ctrlport_req_data'length)));
      PlControlPortWriteRequest(baseAddress + work.PkgSPI_REGMAP.kCONTROL, std_logic_vector(to_unsigned(1024+256+numBits, ps_ctrlport_req_data'length)));
    end procedure PlStartSpiTransaction;

    -- read SPI transaction data
    procedure PlCheckSpiTransactionData(baseAddress : in natural; expectedData : std_logic_vector(31 downto 0)) is
    begin
      -- check config for transmission end
      l1: for i in 0 to 1000 loop
        PlSendControlPortRequest(baseAddress + work.PkgSPI_REGMAP.kCONTROL, X"00000000", false);
        PlCheckControlPortResponse(false, false, X"00000000");
        exit l1 when pl_ctrlport_resp_data(8) = '0';
      end loop l1;

      -- read data
      PlVerifyRead(baseAddress + kRX_DATA_LOW, expectedData);
    end procedure PlCheckSpiTransactionData;

    function reverseBits (data : std_logic_vector) return std_logic_vector is
      variable result : std_logic_vector(data'range);
    begin
      for i in data'range loop
        result(i) := data(data'length-i-1);
      end loop;
      return result;
    end function reverseBits;

    -- expected bytes to read for CMI interface
    variable readBytes : ByteArray_t(4 downto 0);

    -- procedures for CMI interface
    procedure WaitForI2CBusIdle is
      variable Success : boolean;
    begin
      -- wait for bus stays idle for 20 us (period at 100kHz = 10 us)
      Success := false;
      while (not Success) loop
        wait until falling_edge(IPASS_SCL(0)) for 20 us;
        Success := to_Boolean(IPASS_SCL(0));
      end loop;
    end WaitForI2CBusIdle;

    procedure WaitForI2CTransactionToStart is
    begin
      -- wait for clock change
      wait until falling_edge(IPASS_SCL(0)) for 1 ms;
      assert not to_Boolean(IPASS_SCL(0)) report "core did not get active after cable became present" severity error;
    end WaitForI2CTransactionToStart;

    -- This padding will be used to complete the 32-but response for DB SPI transactions.
    -- 12-bits in use for constant padding.
  variable DbSpiAddress : std_logic_vector(19 downto 0);

  begin
    -- startup assignments
    IPASS_POWER_EN_FAULT <= "11";
    IPASS_PRESENT_N <= "11";
    aExpectedDbReset <= "11";

    -- reset spi master
    wait until falling_edge(pll_ref_clk);
    spi_master_reset <= '1';
    wait until falling_edge(pll_ref_clk);
    spi_master_reset <= '0';
    wait for 100 us;

    -- configure simple spi
    wait until falling_edge(CLK_100);
    ps_spi_reset <= '1';
    wait until falling_edge(CLK_100);
    ps_spi_reset <= '0';
    -- set divider to 20 to get from 100 MHz to 5 MHz
    set_stb <= '1';
    set_addr <= kSpiCoreDividerAddress;
    set_data <= std_logic_vector(to_unsigned(20,32));
    wait until falling_edge(CLK_100);
    set_stb <= '0';

    -- wait until internal reset has been done -> see power clocks toggling
    wait until pwr_supply_clk_core for 100 us;

    ----------------------------------------------------------------------------
    -- PS Basic Registers
    ----------------------------------------------------------------------------
    -- check Singature
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kSIGNATURE_REGISTER,
                 SetField(0, kPS_CPLD_SIGNATURE));

    -- check Revision
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kREVISION_REGISTER,
                 SetField(0, kCPLD_REVISION));

    -- check oldest Revision
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kOLDEST_COMPATIBLE_REVISION_REGISTER,
                 SetField(0, kOLDEST_CPLD_REVISION));

    -- check Scratch default
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kSCRATCH_REGISTER, Zeros(32));

    -- Overwrite and read-back
    PsControlPortWriteRequest(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kSCRATCH_REGISTER, X"A5A5A5A5");
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kSCRATCH_REGISTER,  X"A5A5A5A5");

    -- Check Git-hash register(default value)
    PsVerifyRead(kPS_REGISTERS + work.PkgPS_CPLD_BASE_REGMAP.kGIT_HASH_REGISTER, X"DEADBEEF");

    ----------------------------------------------------------------------------
    -- PLL reference clock
    ----------------------------------------------------------------------------
    -- check PLL ref clock disabled
    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDB0_RESET_ASSERTED, kDB1_RESET_ASSERTED)));
    -- enable PLL reference clock
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBit(kENABLE_PLL_REF_CLOCK));
    -- check clock enabled
    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDB0_RESET_ASSERTED, kDB1_RESET_ASSERTED, kPLL_REF_CLOCK_ENABLED)));

    ----------------------------------------------------------------------------
    -- Random access to invalid address space
    ----------------------------------------------------------------------------
    for i in 0 to 100 loop
      PsSendControlPortRequest(Random.GetNatural(2**15 - kRECONFIG - kRECONFIGSize) + kRECONFIG + kRECONFIGSize, Zeros(32), false);
      PsCheckControlPortResponse(true, false, Zeros(32));
    end loop;

    for i in 0 to 100 loop
      PlSendControlPortRequest(Random.GetNatural(2**15 - kJTAG_DB1 - kJTAG_DB1Size) + kJTAG_DB1 + kJTAG_DB1Size, Zeros(32), false);
      PlCheckControlPortResponse(true, false, Zeros(32));
    end loop;

    ----------------------------------------------------------------------------
    -- Power control
    ----------------------------------------------------------------------------
    IpassPowerLoop: for i in 0 to 3 loop
      IPASS_POWER_EN_FAULT <= std_logic_vector(to_unsigned(i, 2));
      -- get status
      PsSendControlPortRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32), false);
      PsCheckControlPortResponse(false, true,
        SetBit(kIPASS_POWER_FAULT0, not IPASS_POWER_EN_FAULT(0)) or
        SetBit(kIPASS_POWER_FAULT1, not IPASS_POWER_EN_FAULT(1))
      );
      -- release signal and test if status sticks
      tempVar(1 downto 0) <= IPASS_POWER_EN_FAULT;
      IPASS_POWER_EN_FAULT <= (others => '1');
      PsSendControlPortRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32), false);
      PsCheckControlPortResponse(false, true,
        SetBit(kIPASS_POWER_FAULT0, not tempVar(0)) or
        SetBit(kIPASS_POWER_FAULT1, not tempVar(1))
      );
      -- clear status bit 0 and recheck
      PsControlPortWriteRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, SetBit(kIPASS_CLEAR_POWER_FAULT0));
      PsSendControlPortRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32), false);
      PsCheckControlPortResponse(false, true,
        SetBit(kIPASS_POWER_FAULT1, not tempVar(1))
      );
      -- clear status bit 1 and check all sticky bits are gone
      PsControlPortWriteRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, SetBit(kIPASS_CLEAR_POWER_FAULT1));
      PsSendControlPortRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32), false);
      PsCheckControlPortResponse(false, true, Zeros(32));
    end loop;

    -- test power disabling status
    assert IPASS_POWER_DISABLE = '0' report "ipass power should be enabled on startup" severity error;

    -- set bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, SetBit(kIPASS_DISABLE_POWER_BIT));
    assert IPASS_POWER_DISABLE = '1' report "ipass power should be disabled after register change" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kIPASS_POWER_REG, SetBit(kIPASS_DISABLE_POWER_BIT));

    -- clear bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32));
    assert IPASS_POWER_DISABLE = '0' report "ipass power should be enabled after deasserting bit" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kIPASS_POWER_REG, Zeros(32));

    -- test oscillator bits
    -- bit 100 MHz
    assert PWR_EN_5V_OSC_100 = '0' report "100 MHz osc power should be disabled on startup" severity error;
    -- set bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kOSC_POWER_REG, SetBit(kOSC_100));
    assert PWR_EN_5V_OSC_100 = '1' report "100 MHz osc power should be enabled after register change" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kOSC_POWER_REG,SetBit(kOSC_100));
    -- clear bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kOSC_POWER_REG, Zeros(32));
    assert PWR_EN_5V_OSC_100 = '0' report "100 MHz osc power should be disabled after deasserting bit" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kOSC_POWER_REG, Zeros(32));

    -- bit 122.88 MHz
    assert PWR_EN_5V_OSC_122_88 = '0' report "122.88 MHz osc power should be disabled on startup" severity error;
    -- set bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kOSC_POWER_REG, SetBit(kOSC_122_88));
    assert PWR_EN_5V_OSC_122_88 = '1' report "122.88 MHz osc power should be enabled after register change" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kOSC_POWER_REG, SetBit(kOSC_122_88));

    -- clear bit, test signal and read back
    PsControlPortWriteRequest(kPOWER_REGISTERS + kOSC_POWER_REG, Zeros(32));
    assert PWR_EN_5V_OSC_122_88 = '0' report "122.88 MHz osc power should be disabled after deasserting bit" severity error;
    PsVerifyRead(kPOWER_REGISTERS + kOSC_POWER_REG, Zeros(32));


    ----------------------------------------------------------------------------
    -- PL Basic Registers
    ----------------------------------------------------------------------------

    -- check Singature
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kSIGNATURE_REGISTER,
                 SetField(0, kPL_CPLD_SIGNATURE));

    -- check Revision
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kREVISION_REGISTER,
                 SetField(0, kCPLD_REVISION));

    -- check oldest Revision
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kOLDEST_COMPATIBLE_REVISION_REGISTER,
                 SetField(0, kOLDEST_CPLD_REVISION));

    -- check Scratch default
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kSCRATCH_REGISTER, Zeros(32));

    -- Overwrite and read-back
    PlControlPortWriteRequest(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kSCRATCH_REGISTER, X"A5A5A5A5");
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kSCRATCH_REGISTER,  X"A5A5A5A5");

    -- Check Git-hash register(default value)
    PlVerifyRead(kPL_REGISTERS + work.PkgPL_CPLD_BASE_REGMAP.kGIT_HASH_REGISTER, X"DEADBEEF");

    ----------------------------------------------------------------------------
    -- PCI-Express CMI (I²C interface) check
    ----------------------------------------------------------------------------
    -- init BFM models
    -- init upstream slave
    I2cSlvSetAddress(16#A6#/2, false, kSlaveId);
    I2cSlvSetDataTiming(0 ns, 0 ns, 0 ns, 0 ns, kSlaveId, false);
    -- init upstream master
    I2cMstrSetAddress(16#A4#/2, false, 1, kMasterId);
    I2cMstrSetDataTiming(0 ns, 0 ns, 1 ns, 0 ns, kMasterId); -- tco_min and max have to be different

    -- attach a cable (replicated status information from FPGA)
    PlControlPortWriteRequest(kPL_REGISTERS + kCABLE_PRESENT_REG, SetBit(kIPASS0_CABLE_PRESENT));
    PlVerifyRead(kPL_REGISTERS + kCABLE_PRESENT_REG, SetBit(kIPASS0_CABLE_PRESENT));

    -- The I2C transaction contents are depending on the netlist. Therefore
    -- hard-coding the sequence here. The contents are specified in the
    -- PCI-Express external cabling specification:
    -- \\monsoon\VXIproj\Specifications\PCI Express\PCIe_Cable3.0\PCI_Express_External_Cabling_R3.0_v1.0_09112019_NCB.pd

    -- Wait for initial transmission of core.
    I2cSlvExpectWriteExp(0, (x"14", x"00", x"00", x"b1"), true, kSlaveId);
    WaitForI2CTransactionToStart;
    WaitForI2CBusIdle;

    -- Get ready and check transfer (check updated CMI_CLP_READY bit).
    PsControlPortWriteRequest(kPS_REGISTERS + kCMI_CONTROL_STATUS, SetBit(kCMI_READY));
    I2cSlvExpectWriteExp(0, (x"1c", x"00", x"00", x"e0"), true, kSlaveId);
    WaitForI2CTransactionToStart;
    WaitForI2CBusIdle;

    -- Write reset from host to device (set CMI_RESET bit).
    I2cMstrWrite(0, kMasterId, SetBit(0, 8), false);
    wait until PCIE_RESET = '1' for 10 ms;
    assert PCIE_RESET = '1' report "reset from host not present" severity error;

    -- Release reset from host to device.
    I2cMstrWrite(0, kMasterId, Zeros(8), false);
    wait until PCIE_RESET = '0' for 10 ms;
    assert PCIE_RESET = '0' report "reset from host not present" severity error;

    -- Read serial number from MB CPLD. Contents of the register map have been
    -- checked in netlist export already. The serial number connected to the PS
    -- regmap. To verify this connection the check is repeated here.
    PsControlPortWriteRequest(kPS_REGISTERS + kSERIAL_NUM_LOW_REG, kSerialNumber(31 downto 0));
    PsControlPortWriteRequest(kPS_REGISTERS + kSERIAL_NUM_HIGH_REG, Zeros(24) & kSerialNumber(39 downto 32));
    I2cMstrRead(CLK_100, readBytes'length, 11, kMasterId, readBytes, false);
    assert to_StdLogicVector(readBytes) = kSerialNumber
      report "serial number mismatch" severity error;

    --Verify register readback
    PsVerifyRead(kPS_REGISTERS + kSERIAL_NUM_LOW_REG, kSerialNumber(31 downto 0));
    PsVerifyRead(kPS_REGISTERS + kSERIAL_NUM_HIGH_REG, Zeros(24) & kSerialNumber(39 downto 32));

    -- Check if other side detection is marked active.
    PsVerifyRead(kPS_REGISTERS + kCMI_CONTROL_STATUS, SetBits((kOTHER_SIDE_DETECTED, kCMI_READY)));

    -- Detach cable.
    PlControlPortWriteRequest(kPL_REGISTERS + kCABLE_PRESENT_REG, Zeros(32));

    ----------------------------------------------------------------------------
    -- LED check
    ----------------------------------------------------------------------------
    assert qsfp0_led_active = "0000" report "QSFP0 active LEDs should be inactive after startup" severity error;
    assert qsfp1_led_active = "0000" report "QSFP1 active LEDs should be inactive after startup" severity error;
    assert qsfp0_led_link = "0000" report "QSFP0 link LEDs should be inactive after startup" severity error;
    assert qsfp1_led_link = "0000" report "QSFP1 link LEDs should be inactive after startup" severity error;
    PlControlPortWriteRequest(kPL_REGISTERS + kLED_REGISTER, X"456789AB");
    PlSendControlPortRequest(kPL_REGISTERS + kLED_REGISTER, X"00000000", false);
    PlCheckControlPortResponse(false, true, X"000089AB");
    assert qsfp0_led_active = pl_ctrlport_resp_data(kQSFP0_LED_ACTIVEMsb downto kQSFP0_LED_ACTIVE) report "QSFP0 active LEDs mismatch" severity error;
    assert qsfp1_led_active = pl_ctrlport_resp_data(kQSFP1_LED_ACTIVEMsb downto kQSFP1_LED_ACTIVE) report "QSFP1 active LEDs mismatch" severity error;
    assert qsfp0_led_link = pl_ctrlport_resp_data(kQSFP0_LED_LINKMsb downto kQSFP0_LED_LINK) report "QSFP0 link LEDs mismatch" severity error;
    assert qsfp1_led_link = pl_ctrlport_resp_data(kQSFP1_LED_LINKMsb downto kQSFP1_LED_LINK) report "QSFP1 link LEDs mismatch" severity error;

    ----------------------------------------------------------------------------
    -- DB SPI passthrough paths
    ----------------------------------------------------------------------------
    -- DB 0
    wait until db_ref_clk(0) = '1' for 1 us;
    assert db_ref_clk(0) = '0' report "DB 0 reference clock should be deactivated" severity error;
    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDB0_RESET_ASSERTED, kDB1_RESET_ASSERTED, kPLL_REF_CLOCK_ENABLED)));

    -- activate clock and deassert reset
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBit(kENABLE_CLOCK_DB0));
    aExpectedDbReset(0) <= '-';
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBit(kRELEASE_RESET_DB0));
    aExpectedDbReset(0) <= '0';

    -- write & read access
    PlControlPortWriteRequest(kDb0AddressOffset, X"456789AB");
    for i in 1 to 100 loop
      DbSpiAddress := std_logic_vector(to_unsigned(Random.GetNatural(kDb1AddressOffset-kDb0AddressOffset), DbSpiAddress'length));
      -- Validate transactions to different addresses(slave model will return constant x"ABC" & address when in address range)
      PlVerifyRead(kDb0AddressOffset + to_integer(unsigned(DbSpiAddress)), X"ABC" & DbSpiAddress);
    end loop;

    -- DB 1
    wait until db_ref_clk(1) = '1' for 1 us;
    assert db_ref_clk(1) = '0' report "DB 1 reference clock should be deactivated" severity error;
    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDB0_CLOCK_ENABLED, kDB1_RESET_ASSERTED, kPLL_REF_CLOCK_ENABLED)));

    -- activate clock and deassert reset
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBit(kENABLE_CLOCK_DB1));
    aExpectedDbReset(1) <= '-';
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBit(kRELEASE_RESET_DB1));
    aExpectedDbReset(0) <= '0';

    -- write & read access
    PlControlPortWriteRequest(kDb1AddressOffset, X"01234567");
    for i in 1 to 100 loop
      -- Randomize within max CPLD range
      DbSpiAddress := std_logic_vector(to_unsigned(Random.GetNatural(2**15-1), DbSpiAddress'length));
      -- Validate different to different addresses(slave model will return constant x"ABC" & address when in address range)
      PlVerifyRead(kDb1AddressOffset + to_integer(unsigned(DbSpiAddress)), X"987" & DbSpiAddress);
    end loop;


    -- check final status
    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDB0_CLOCK_ENABLED, kDB1_CLOCK_ENABLED, kPLL_REF_CLOCK_ENABLED)));
    -- Test reassertion of resets
    aExpectedDbReset <= "--";
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kASSERT_RESET_DB1, kASSERT_RESET_DB0)));
    aExpectedDbReset <= "11";

    -- Test clock enable de-assertion
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kDISABLE_CLOCK_DB0, kDISABLE_CLOCK_DB1)));

    PsVerifyRead(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kPLL_REF_CLOCK_ENABLED, kDB0_RESET_ASSERTED, kDB1_RESET_ASSERTED)));

    -- Restore clocks/resets for functional validation
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kENABLE_CLOCK_DB0, kENABLE_CLOCK_DB1)));
    aExpectedDbReset <= "--";
    PsControlPortWriteRequest(kPS_REGISTERS + kPL_DB_REGISTER, SetBits((kRELEASE_RESET_DB0, kRELEASE_RESET_DB1)));
    aExpectedDbReset <= "00";

    ----------------------------------------------------------------------------
    -- PS SPI pass-through test
    ----------------------------------------------------------------------------
    CheckPsSpiSlave(kPS_CS_CLK_AUX_DB);
    CheckPsSpiSlave(kPS_CS_DB0_CAL_EEPROM);
    CheckPsSpiSlave(kPS_CS_DB1_CAL_EEPROM);
    CheckPsSpiSlave(kPS_CS_LMK32);
    CheckPsSpiSlave(kPS_CS_TPM);
    -- special handling for Phase DAC as there is no MISO signal
    PsStartSpiTransaction(kPS_CS_PHASE_DAC, 16, X"15680000");
    -- wait for data to be transferred
    wait until readback_stb = '1' for 100 us;
    assert readback_stb = '1' report "SPI readback not asserted" severity error;
    assert phaseDacReceivedData = X"1568" report "Phase DAC data mismatch" severity error;

    ----------------------------------------------------------------------------
    -- PS SPI - malformed MB CPLD request
    ----------------------------------------------------------------------------
    PsStartSpiTransaction(kPS_CS_MB_CPLD, 16, X"12345678");
    -- wait for data to be transferred
    wait until readback_stb = '1' for 100 us;
    assert readback_stb = '1' report "SPI readback not asserted" severity error;

    -- there is no special check here if the request was successful
    -- further PS SPI transactions have to pass to complete the test

    ----------------------------------------------------------------------------
    -- DB 0 JTAG
    ----------------------------------------------------------------------------
    PlControlPortWriteRequest(kJTAG_DB0 + work.PkgJTAG_REGMAP.kCONTROL, X"80000000");
    PlControlPortWriteRequest(kJTAG_DB0 + kTX_DATA, X"0000E279");
    PlControlPortWriteRequest(kJTAG_DB0 + kSTB_DATA, X"0000A145");
    PlControlPortWriteRequest(kJTAG_DB0 + work.PkgJTAG_REGMAP.kCONTROL, X"00000F07");
    Db0Jtag: for i in 0 to 100 loop
      PlSendControlPortRequest(kJTAG_DB0 + work.PkgJTAG_REGMAP.kCONTROL, X"00000000", false);
      PlCheckControlPortResponse(false, false, X"00000000");
      exit Db0Jtag when pl_ctrlport_resp_data(kready) = '1';
    end loop;
    assert jtagTmsReceivedData(0) = reverseBits(X"A145") report "DB 0 JTAG TMS data incorrect" severity error;
    PlVerifyRead(kJTAG_DB0 + kRX_DATA,  X"0000" & reverseBits(X"6100"));

    ----------------------------------------------------------------------------
    -- DB 1 JTAG
    ----------------------------------------------------------------------------
    PlControlPortWriteRequest(kJTAG_DB1 + work.PkgJTAG_REGMAP.kCONTROL, X"80000000");
    PlControlPortWriteRequest(kJTAG_DB1 + kTX_DATA, X"0000AD52");
    PlControlPortWriteRequest(kJTAG_DB1 + kSTB_DATA, X"000084F1");
    PlControlPortWriteRequest(kJTAG_DB1 + work.PkgJTAG_REGMAP.kCONTROL, X"00000F07");
    Db1Jtag: for i in 0 to 100 loop
      PlSendControlPortRequest(kJTAG_DB1 + work.PkgJTAG_REGMAP.kCONTROL, X"00000000", false);
      PlCheckControlPortResponse(false, false, X"00000000");
      exit Db1Jtag when pl_ctrlport_resp_data(kready) = '1';
    end loop;
    assert jtagTmsReceivedData(1) = reverseBits(X"84F1") report "DB 1 JTAG TMS data incorrect" severity error;
    PlVerifyRead(kJTAG_DB1 + kRX_DATA,  X"0000" & reverseBits(X"6300"));

    -- --------------------------------------------------------------------------
    -- DIO direction
    -- ----------------------------------------------------------------------------
    assert DIO_DIRECTION_A = X"000" report "DIO A should startup as input" severity error;
    assert DIO_DIRECTION_B = X"000" report "DIO B should startup as input" severity error;
    PsControlPortWriteRequest(kPS_REGISTERS + kDIO_DIRECTION_REGISTER, X"0ABC0123");
    PsVerifyRead(kPS_REGISTERS + kDIO_DIRECTION_REGISTER, X"0ABC0123");
    assert DIO_DIRECTION_A = X"123" report "DIO A direction assignment incorrect" severity error;
    assert DIO_DIRECTION_B = X"ABC" report "DIO B direction assignment incorrect" severity error;

    PsControlPortWriteRequest(kPS_REGISTERS + kDIO_DIRECTION_REGISTER, X"E89C33F0");
    PsVerifyRead(kPS_REGISTERS + kDIO_DIRECTION_REGISTER, X"089C03F0");
    assert DIO_DIRECTION_A = X"3F0" report "DIO A direction assignment incorrect" severity error;
    assert DIO_DIRECTION_B = X"89C" report "DIO B direction assignment incorrect" severity error;

    ----------------------------------------------------------------------------
    -- Flash
    ----------------------------------------------------------------------------
    -- Check start address.
    -- For the MB CPLD memory initialization is disabled.
    -- Internal device configuration set to Single Compressed Image.
    PsVerifyRead(kRECONFIG + kFLASH_CFM0_START_ADDR_REG,
                 std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_START_ADDR,32)));

    PsVerifyRead(kRECONFIG + kFLASH_CFM0_END_ADDR_REG,
                 std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_END_ADDR,32)));

    -- check idle
    PsVerifyRead(kRECONFIG + kFLASH_STATUS_REG,
                 SetBits((kFLASH_WRITE_IDLE,
                          kFLASH_ERASE_IDLE,
                          kFLASH_READ_IDLE,
                          kFLASH_WP_ENABLED)));

    -- erase memory
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_DISABLE_WP_STB));

    PsVerifyRead(kRECONFIG + kFLASH_STATUS_REG,
                 SetBits((kFLASH_WRITE_IDLE,
                          kFLASH_ERASE_IDLE,
                          kFLASH_READ_IDLE)));

    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_ERASE_STB) or SetField(kFLASH_ERASE_SECTOR, 4));
    FlashEraseCheck: for i in 0 to 1000 loop
      -- check data without trigerring an error
      PsSendControlPortRequest(kRECONFIG + kFLASH_STATUS_REG, X"00000000", false);
      PsCheckControlPortResponse(false, false, X"00000000");
      exit FlashEraseCheck when ps_ctrlport_resp_data(kFLASH_ERASE_IDLE) = '1';
    end loop;
    assert ps_ctrlport_resp_data(kFLASH_ERASE_IDLE) = '1' report "erase still ongoing" severity error;
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_ENABLE_WP_STB));

    -- check empty memory
    PsControlPortWriteRequest(kRECONFIG + kFLASH_ADDR_REG, std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_START_ADDR,32)));
    PsVerifyRead(kRECONFIG + kFLASH_ADDR_REG,
                 std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_START_ADDR,32)));

    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_READ_STB));

    PsVerifyRead(kRECONFIG + kFLASH_STATUS_REG,
                 SetBits((kFLASH_WRITE_IDLE,
                          kFLASH_ERASE_IDLE,
                          kFLASH_READ_IDLE,
                          kFLASH_WP_ENABLED)));

    PsVerifyRead(kRECONFIG + kFLASH_READ_DATA_REG, Ones(32));

    -- write data
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_DISABLE_WP_STB));
    PsControlPortWriteRequest(kRECONFIG + kFLASH_WRITE_DATA_REG, X"12345678");
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_WRITE_STB));
    PollWriteIdle: for i in 0 to 1000 loop
      -- check data without trigerring an error
      PsSendControlPortRequest(kRECONFIG + kFLASH_STATUS_REG, X"00000000", false);
      PsCheckControlPortResponse(false, false, X"00000000");
      exit PollWriteIdle when ps_ctrlport_resp_data(kFLASH_WRITE_IDLE) = '1';
    end loop;
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_ENABLE_WP_STB));
    PsVerifyRead(kRECONFIG + kFLASH_STATUS_REG,
                 SetBits((kFLASH_WRITE_IDLE,
                          kFLASH_ERASE_IDLE,
                          kFLASH_READ_IDLE,
                          kFLASH_WP_ENABLED)));


    -- verify data
    PsControlPortWriteRequest(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_READ_STB));

    PsVerifyRead(kRECONFIG + kFLASH_STATUS_REG,
                 SetBits((kFLASH_WRITE_IDLE,
                          kFLASH_ERASE_IDLE,
                          kFLASH_READ_IDLE,
                          kFLASH_WP_ENABLED)));

    PsSendControlPortRequest(kRECONFIG + kFLASH_READ_DATA_REG, X"00000000", false);

    PsVerifyRead(kRECONFIG + kFLASH_READ_DATA_REG, X"12345678");

    -- end of simulation
    StopSim <= true;

    -- check scoreboard results
    gScoreboard.PrintResults;
    assert gScoreboard.IsCovered("*")
      report "Some cover points not hit; see transcript to determine which"
      severity ERROR;

    -- simulation does not end automatically
    Finish(1);
    wait;
  end process;

  ------------------------------------------------------------------------------
  -- Check of power supply clocks
  ------------------------------------------------------------------------------
  --vhook_e clock_period_check core_clk_check
  --vhook_a clk pwr_supply_clk_core
  --vhook_a expectedClockPeriod 2 us
  --vhook_a checkFallingEdges false
  core_clk_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 2 us,   --time:=0us
      checkFallingEdges   => false)  --boolean:=false
    port map (clk => pwr_supply_clk_core); --in  std_logic

  --vhook_e clock_period_check ddr_n_clk_check
  --vhook_a clk pwr_supply_clk_ddr4_n
  --vhook_a expectedClockPeriod 2.22 us
  --vhook_a checkFallingEdges false
  ddr_n_clk_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 2.22 us,  --time:=0us
      checkFallingEdges   => false)    --boolean:=false
    port map (clk => pwr_supply_clk_ddr4_n); --in  std_logic

  --vhook_e clock_period_check ddr_s_clk_check
  --vhook_a clk pwr_supply_clk_ddr4_s
  --vhook_a expectedClockPeriod 2.22 us
  --vhook_a checkFallingEdges false
  ddr_s_clk_check: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 2.22 us,  --time:=0us
      checkFallingEdges   => false)    --boolean:=false
    port map (clk => pwr_supply_clk_ddr4_s); --in  std_logic

  --vhook_e clock_period_check clk_check_0p9v
  --vhook_a clk pwr_supply_clk_0p9v
  --vhook_a expectedClockPeriod 2.857 us
  --vhook_a checkFallingEdges false
  clk_check_0p9v: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 2.857 us,  --time:=0us
      checkFallingEdges   => false)     --boolean:=false
    port map (clk => pwr_supply_clk_0p9v); --in  std_logic

  --vhook_e clock_period_check clk_check_1p8v
  --vhook_a clk pwr_supply_clk_1p8v
  --vhook_a expectedClockPeriod 1.667 us
  --vhook_a checkFallingEdges false
  clk_check_1p8v: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 1.667 us,  --time:=0us
      checkFallingEdges   => false)     --boolean:=false
    port map (clk => pwr_supply_clk_1p8v); --in  std_logic

  --vhook_e clock_period_check clk_check_2p5v
  --vhook_a clk pwr_supply_clk_2p5v
  --vhook_a expectedClockPeriod 1.25 us
  --vhook_a checkFallingEdges false
  clk_check_2p5v: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 1.25 us,  --time:=0us
      checkFallingEdges   => false)    --boolean:=false
    port map (clk => pwr_supply_clk_2p5v); --in  std_logic

  --vhook_e clock_period_check clk_check_3p3v
  --vhook_a clk pwr_supply_clk_3p3v
  --vhook_a expectedClockPeriod 1 us
  --vhook_a checkFallingEdges false
  clk_check_3p3v: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 1 us,   --time:=0us
      checkFallingEdges   => false)  --boolean:=false
    port map (clk => pwr_supply_clk_3p3v); --in  std_logic

  --vhook_e clock_period_check clk_check_3p6v
  --vhook_a clk pwr_supply_clk_3p6v
  --vhook_a expectedClockPeriod 1 us
  --vhook_a checkFallingEdges false
  clk_check_3p6v: entity work.clock_period_check (test)
    generic map (
      expectedClockPeriod => 1 us,   --time:=0us
      checkFallingEdges   => false)  --boolean:=false
    port map (clk => pwr_supply_clk_3p6v); --in  std_logic

  ------------------------------------------------------------------------------
  -- Check only one active PS SPI slave
  ------------------------------------------------------------------------------
  ps_spi_check: process
  begin
    -- Wait on CS signals for running the check.
    -- Clock added to sensitivity list to ensure this check is executed even if
    -- all CS signals are stuck.
    wait on LMK32_CS_N, TPM_CS_N, PHASE_DAC_CS_N, DB_CALEEPROM_CS_N, PS_CPLD_SCLK;
    assert CountOnes(LMK32_CS_N & TPM_CS_N & PHASE_DAC_CS_N & DB_CALEEPROM_CS_N) >= 4
      report "more than one chip selected on decoded PS SPI bus" severity error;
  end process;

end test;
--synopsys translate_on

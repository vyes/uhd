--
-- Copyright 2020 Ettus Research, A National Instruments Brand
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_db_gpio_latency
-- Description:
-- Testbench for DB GPIO connection to ensure up to date documentation on the
-- latencies.

--nisim --op1="-L altera_mf_ver +nowarnTFMPC -L fiftyfivenm_ver -L lpm_ver"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgCtrlPortTester.all;
  use work.PkgDB_CONTROL_REGMAP.all;
  use work.PkgBASIC_REGS_REGMAP.all;
  use work.PkgDSA_SETUP_REGMAP.all;
  use work.PkgGPIO_REGMAP.all;
  use work.PkgATR_REGMAP.all;
  use work.PkgPOWER_REGS_REGMAP.all;
  use work.PkgSPI_REGMAP.all;
library std;
  use std.env.all;
library modelsim_lib;
  use modelsim_lib.util.all;

entity tb_db_gpio_latency is
end tb_db_gpio_latency;

architecture test of tb_db_gpio_latency is

  component db_gpio_reordering
    port (
      db0_gpio_in_int     : out std_logic_vector(19 downto 0);
      db0_gpio_out_int    : in  std_logic_vector(19 downto 0);
      db0_gpio_out_en_int : in  std_logic_vector(19 downto 0);
      db1_gpio_in_int     : out std_logic_vector(19 downto 0);
      db1_gpio_out_int    : in  std_logic_vector(19 downto 0);
      db1_gpio_out_en_int : in  std_logic_vector(19 downto 0);
      db0_gpio_in_ext     : in  std_logic_vector(19 downto 0);
      db0_gpio_out_ext    : out std_logic_vector(19 downto 0);
      db0_gpio_out_en_ext : out std_logic_vector(19 downto 0);
      db1_gpio_in_ext     : in  std_logic_vector(19 downto 0);
      db1_gpio_out_ext    : out std_logic_vector(19 downto 0);
      db1_gpio_out_en_ext : out std_logic_vector(19 downto 0));
  end component;
  component db_gpio_interface
    port (
      radio_clk               : in  std_logic;
      pll_ref_clk             : in  std_logic;
      db_state                : in  std_logic_vector(3 downto 0);
      radio_time              : in  std_logic_vector(63 downto 0);
      radio_time_stb          : in  std_logic;
      time_ignore_bits        : in  std_logic_vector(3 downto 0);
      ctrlport_rst            : in  std_logic;
      s_ctrlport_req_wr       : in  std_logic;
      s_ctrlport_req_rd       : in  std_logic;
      s_ctrlport_req_addr     : in  std_logic_vector(19 downto 0);
      s_ctrlport_req_data     : in  std_logic_vector(31 downto 0);
      s_ctrlport_req_byte_en  : in  std_logic_vector(3 downto 0);
      s_ctrlport_req_has_time : in  std_logic;
      s_ctrlport_req_time     : in  std_logic_vector(63 downto 0);
      s_ctrlport_resp_ack     : out std_logic;
      s_ctrlport_resp_status  : out std_logic_vector(1 downto 0);
      s_ctrlport_resp_data    : out std_logic_vector(31 downto 0);
      gpio_in                 : in  std_logic_vector(19 downto 0);
      gpio_out                : out std_logic_vector(19 downto 0);
      gpio_out_en             : out std_logic_vector(19 downto 0);
      version_info            : out std_logic_vector(95 downto 0));
  end component;

  --vhook_sigstart
  signal CTRL_REG_ARST: std_logic;
  signal CTRL_REG_CLK: std_logic := '0';
  signal db_state: std_logic_vector(3 downto 0);
  signal gpio_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal gpio_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal gpio_ctrlport_req_rd: std_logic;
  signal gpio_ctrlport_req_wr: std_logic;
  signal gpio_ctrlport_resp_ack: std_logic;
  signal gpio_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal gpio_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal gpio_in_ext: std_logic_vector(19 downto 0);
  signal gpio_in_int: std_logic_vector(19 downto 0);
  signal gpio_out_en_ext: std_logic_vector(19 downto 0);
  signal gpio_out_en_int: std_logic_vector(19 downto 0);
  signal gpio_out_ext: std_logic_vector(19 downto 0);
  signal gpio_out_int: std_logic_vector(19 downto 0);
  signal MB_CTRL_CS: std_logic;
  signal MB_CTRL_MISO: std_logic;
  signal MB_CTRL_MOSI: std_logic;
  signal MB_CTRL_SCK: std_logic;
  signal radio_time_stb: std_logic;
  signal spi_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal spi_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal spi_ctrlport_req_rd: std_logic;
  signal spi_ctrlport_req_wr: std_logic;
  signal spi_ctrlport_resp_ack: std_logic;
  signal spi_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal spi_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal ss: std_logic_vector(1 downto 0);
  signal TX0_DSA1: std_logic_vector(6 downto 2);
  --vhook_sigend

  -- clocking
  signal StopSim : boolean;
  constant kClockMultiplier : integer := 4; -- worst case as defined in TOO
  constant kRadioPer : time := 10 ns;
  constant kPrcPer : time := kClockMultiplier * kRadioPer;
  constant kCtrlPort50MhzPeriod : time := 20 ns;  -- 50 MHz

  signal pll_ref_clk : std_logic := '1';
  signal radio_clk : std_logic := '1';

  -- reset
  signal reset_rc : std_logic := '0';

  -- gpio wires
  type tIntArray is array (13 downto 0) of integer;
  -- Subset of GPIO port mappings from fpga/usrp3/top/x400/db_gpio_reordering.v
  -- Accounted for ZBX specific wire assignment of
  -- 5 unused, 10 used, 1 unused and 4 used signals out of the 20 FPGA GPIOs.
  -- The 6 unused indices are deleted from list.
  constant port0FpgaIndices : tIntArray := (10,4,5,16,18,8,6,1,9,2,11,7,13,12);
  signal gpio_mb : std_logic_vector(19 downto 0);
  signal gpio_db : std_logic_vector(13 downto 0);

  -- timestamps for ctrlport request
  signal radio_time: std_logic_vector(63 downto 0) := (others => '0');
  signal gpio_ctrlport_req_has_time : std_logic := '0';
  signal gpio_ctrlport_req_time : std_logic_vector(63 downto 0) := (others => '0');

  -- status reporting
  signal TestStatus : TestStatusString_t;

  -- time measurement
  signal measurementActive : boolean := false;
  signal measurementDone : boolean := false;
  signal measuredTime : time := 0 ns;

  -- Ctrlport thread ID
  constant kSpiThreadId : natural := 1;

  ------------------------------------------------------------------------------
  -- Signals replicated from inside the design using modelsim spy
  ------------------------------------------------------------------------------
  -- ignore warning for duplicate signals as there is no source known to vsmake
  --vhook_nowarn id=CP14 msg={dup_}
  signal dup_atr_option_rf1 : std_logic_vector(kRF1_OPTIONSize-1 downto 0);
  signal dup_atr_rd : std_logic;

  signal dup_atr_rd_filtered : std_logic;
  signal dup_atr_rd_enabled : boolean := false;

  ------------------------------------------------------------------------------
  -- Expected Latencies
  ------------------------------------------------------------------------------
  -- DO NOT CHANGE THESE VALUES WITHOUT CHANGING THE DOCUMENTATION
  -- The LV FPGA implementation contains an additional ctrlport combiner, which
  -- is not covered in the checks below but listed in the documentation.

  -- write request latency
  constant kWriteRequestLatency : time := 13 * kPrcPer + 5 * kRadioPer;
  -- write request + reponse latency
  constant kWriteRoundtripLatency : time := 8 * kPrcPer + 2 * kRadioPer + kWriteRequestLatency;
  -- read request latency
  constant kReadRequestLatency : time := 8 * kPrcPer + 5 * kRadioPer;
  -- read request + reponse latency
  constant kReadResponseLatency : time := 13 * kPrcPer + 2 * kRadioPer;
  constant kReadRoundtripLatency : time := kReadResponseLatency + kReadRequestLatency;
  -- extended read request + reponse latency
  constant kExtendedReadRequestLatency : time := kReadRequestLatency + 2 * kPrcPer;
  constant kExtendedReadRoundtripLatency : time := kReadResponseLatency + kExtendedReadRequestLatency;
  -- output change after DSA register write
  constant kExtendedWriteRequestLatency : time := kWriteRequestLatency + 2 * kPrcPer;
  constant kAtrValueRegisterWriteLatency : time := 3 * kPrcPer + kExtendedWriteRequestLatency;
  -- output change after SW defined ATR
  constant kAtrSwDefinedRequestLatency : time := 3 * kPrcPer + kWriteRequestLatency;
  ---- output change after FPGA state change
  constant kFpgaStateLatency : time := 4 * kPrcPer;

begin

  ------------------------------------------------------------------------------
  -- clock generation
  ------------------------------------------------------------------------------
  pll_ref_clk <= not pll_ref_clk after kPrcPer/2 when not StopSim else '0';
  radio_clk <= not radio_clk after kRadioPer/2 when not StopSim else '0';
  CTRL_REG_CLK <= not CTRL_REG_CLK after kCtrlPort50MhzPeriod/2 when not StopSim else '0';

  ------------------------------------------------------------------------------
  -- DUTs
  ------------------------------------------------------------------------------
  --vhook_e CtrlPortMasterModel
  --vhook_a kThreadId         0
  --vhook_a kHoldAccess       true
  --vhook_a kClkCycleTimeout  1000
  --vhook_a ctrlport_clk      radio_clk
  --vhook_a ctrlport_rst      to_Boolean(reset_rc)
  --vhook_a {m_ctrlport_(.*)} gpio_ctrlport_$1
  CtrlPortMasterModelx: entity work.CtrlPortMasterModel (behav)
    generic map (
      kThreadId        => 0,     --natural:=0
      kHoldAccess      => true,  --boolean:=true
      kClkCycleTimeout => 1000)  --natural:=1000
    port map (
      ctrlport_rst           => to_Boolean(reset_rc),       --in  boolean
      ctrlport_clk           => radio_clk,                  --in  std_logic
      m_ctrlport_req_wr      => gpio_ctrlport_req_wr,       --out std_logic
      m_ctrlport_req_rd      => gpio_ctrlport_req_rd,       --out std_logic
      m_ctrlport_req_addr    => gpio_ctrlport_req_addr,     --out std_logic_vector(19:0)
      m_ctrlport_req_data    => gpio_ctrlport_req_data,     --out std_logic_vector(31:0)
      m_ctrlport_resp_ack    => gpio_ctrlport_resp_ack,     --in  std_logic
      m_ctrlport_resp_status => gpio_ctrlport_resp_status,  --in  std_logic_vector(1 :0)
      m_ctrlport_resp_data   => gpio_ctrlport_resp_data);   --in  std_logic_vector(31:0)

  --vhook db_gpio_interface
  --vhook_a time_ignore_bits x"0"
  --vhook_a s_ctrlport_req_byte_en (others => '0')
  --vhook_a {s_ctrlport_(.*)} gpio_ctrlport_$1
  --vhook_a {^gpio(.*)} gpio$1_int
  --vhook_a ctrlport_rst reset_rc
  --vhook_a version_info open
  db_gpio_interfacex: db_gpio_interface
    port map (
      radio_clk               => radio_clk,                   --in  wire
      pll_ref_clk             => pll_ref_clk,                 --in  wire
      db_state                => db_state,                    --in  wire[3:0]
      radio_time              => radio_time,                  --in  wire[63:0]
      radio_time_stb          => radio_time_stb,              --in  wire
      time_ignore_bits        => x"0",                        --in  wire[3:0]
      ctrlport_rst            => reset_rc,                    --in  wire
      s_ctrlport_req_wr       => gpio_ctrlport_req_wr,        --in  wire
      s_ctrlport_req_rd       => gpio_ctrlport_req_rd,        --in  wire
      s_ctrlport_req_addr     => gpio_ctrlport_req_addr,      --in  wire[19:0]
      s_ctrlport_req_data     => gpio_ctrlport_req_data,      --in  wire[31:0]
      s_ctrlport_req_byte_en  => (others => '0'),             --in  wire[3:0]
      s_ctrlport_req_has_time => gpio_ctrlport_req_has_time,  --in  wire
      s_ctrlport_req_time     => gpio_ctrlport_req_time,      --in  wire[63:0]
      s_ctrlport_resp_ack     => gpio_ctrlport_resp_ack,      --out wire
      s_ctrlport_resp_status  => gpio_ctrlport_resp_status,   --out wire[1:0]
      s_ctrlport_resp_data    => gpio_ctrlport_resp_data,     --out wire[31:0]
      gpio_in                 => gpio_in_int,                 --in  wire[19:0]
      gpio_out                => gpio_out_int,                --out wire[19:0]
      gpio_out_en             => gpio_out_en_int,             --out wire[19:0]
      version_info            => open);                       --out wire[95:0]

  --vhook db_gpio_reordering
  --vhook_a {db1_(.*)} {open} mode=out
  --vhook_a {db1_(.*)} (others => '0') mode=in
  --vhook_a {db0_(.*)} {$1}
  db_gpio_reorderingx: db_gpio_reordering
    port map (
      db0_gpio_in_int     => gpio_in_int,      --out wire[19:0]
      db0_gpio_out_int    => gpio_out_int,     --in  wire[19:0]
      db0_gpio_out_en_int => gpio_out_en_int,  --in  wire[19:0]
      db1_gpio_in_int     => open,             --out wire[19:0]
      db1_gpio_out_int    => (others => '0'),  --in  wire[19:0]
      db1_gpio_out_en_int => (others => '0'),  --in  wire[19:0]
      db0_gpio_in_ext     => gpio_in_ext,      --in  wire[19:0]
      db0_gpio_out_ext    => gpio_out_ext,     --out wire[19:0]
      db0_gpio_out_en_ext => gpio_out_en_ext,  --out wire[19:0]
      db1_gpio_in_ext     => (others => '0'),  --in  wire[19:0]
      db1_gpio_out_ext    => open,             --out wire[19:0]
      db1_gpio_out_en_ext => open);            --out wire[19:0]

  --vhook_e CtrlPortMasterModel ctrlportSpiSource
  --vhook_a kThreadId         kSpiThreadId
  --vhook_a kHoldAccess       true
  --vhook_a kClkCycleTimeout  1000
  --vhook_a ctrlport_clk      CTRL_REG_CLK
  --vhook_a ctrlport_rst      to_boolean(CTRL_REG_ARST)
  --vhook_a {m_ctrlport_(.*)} spi_ctrlport_$1
  ctrlportSpiSource: entity work.CtrlPortMasterModel (behav)
    generic map (
      kThreadId        => kSpiThreadId,  --natural:=0
      kHoldAccess      => true,          --boolean:=true
      kClkCycleTimeout => 1000)          --natural:=1000
    port map (
      ctrlport_rst           => to_boolean(CTRL_REG_ARST),  --in  boolean
      ctrlport_clk           => CTRL_REG_CLK,               --in  std_logic
      m_ctrlport_req_wr      => spi_ctrlport_req_wr,        --out std_logic
      m_ctrlport_req_rd      => spi_ctrlport_req_rd,        --out std_logic
      m_ctrlport_req_addr    => spi_ctrlport_req_addr,      --out std_logic_vector(19:0)
      m_ctrlport_req_data    => spi_ctrlport_req_data,      --out std_logic_vector(31:0)
      m_ctrlport_resp_ack    => spi_ctrlport_resp_ack,      --in  std_logic
      m_ctrlport_resp_status => spi_ctrlport_resp_status,   --in  std_logic_vector(1 :0)
      m_ctrlport_resp_data   => spi_ctrlport_resp_data);    --in  std_logic_vector(31:0)

  --vhook_e ctrlport_spi_master     db_cpld_spi_master
  --vhook_a CPLD_ADDRESS_WIDTH      15
  --vhook_a MB_CPLD_BASE_ADDRESS    0
  --vhook_a DB_0_CPLD_BASE_ADDRESS  X"0"
  --vhook_a DB_1_CPLD_BASE_ADDRESS  X"10000"
  --vhook_a ctrlport_clk            CTRL_REG_CLK
  --vhook_a ctrlport_rst            CTRL_REG_ARST
  --vhook_a {s_ctrlport_(.*)}       spi_ctrlport_$1
  --vhook_a sclk                    MB_CTRL_SCK
  --vhook_a mosi                    MB_CTRL_MOSI
  --vhook_a miso                    MB_CTRL_MISO
  --vhook_a MB_clock_divider        X"0003"
  --vhook_a DB_clock_divider        X"FFFF"
  db_cpld_spi_master: entity work.ctrlport_spi_master (rtl)
    generic map (
      CPLD_ADDRESS_WIDTH     => 15,        --integer:=15
      MB_CPLD_BASE_ADDRESS   => 0,         --integer:=2#1000000000000000#
      DB_0_CPLD_BASE_ADDRESS => X"0",      --integer:=2#10000000000000000#
      DB_1_CPLD_BASE_ADDRESS => X"10000")  --integer:=2#11000000000000000#
    port map (
      ctrlport_clk           => CTRL_REG_CLK,              --in  wire
      ctrlport_rst           => CTRL_REG_ARST,             --in  wire
      s_ctrlport_req_wr      => spi_ctrlport_req_wr,       --in  wire
      s_ctrlport_req_rd      => spi_ctrlport_req_rd,       --in  wire
      s_ctrlport_req_addr    => spi_ctrlport_req_addr,     --in  wire[19:0]
      s_ctrlport_req_data    => spi_ctrlport_req_data,     --in  wire[31:0]
      s_ctrlport_resp_ack    => spi_ctrlport_resp_ack,     --out wire
      s_ctrlport_resp_status => spi_ctrlport_resp_status,  --out wire[1:0]
      s_ctrlport_resp_data   => spi_ctrlport_resp_data,    --out wire[31:0]
      ss                     => ss,                        --out wire[1:0]
      sclk                   => MB_CTRL_SCK,               --out wire
      mosi                   => MB_CTRL_MOSI,              --out wire
      miso                   => MB_CTRL_MISO,              --in  wire
      mb_clock_divider       => X"0003",                   --in  wire[15:0]
      db_clock_divider       => X"FFFF");                  --in  wire[15:0]

  MB_CTRL_CS <= ss(0);

  ------------------------------------------------------------------------------
  -- FPGA Mapping to GPIO signal
  ------------------------------------------------------------------------------
  --gpio_in_ext <= gpio_mb;
  fpga_gen: for i in gpio_mb'range generate
    gpio_mb(i) <= gpio_out_ext(i) when gpio_out_en_ext(i) else 'Z';
  end generate;

  ------------------------------------------------------------------------------
  -- Motherboard trace connections
  ------------------------------------------------------------------------------
  -- map according to DB 0 mapping on Rev B X400 motherboard
  -- see definition of port0FpgaIndices for details
  mapping_gen: for i in port0FpgaIndices'range generate
    gpio_db(i) <= gpio_mb(port0FpgaIndices(i));
    gpio_in_ext(port0FpgaIndices(i)) <= gpio_db(i);
  end generate;

  --vhook_e zr_top_cpld dutx
  --vhook_a MB_FPGA_GPIO gpio_db
  --vhook_a CPLD_REFCLK pll_ref_clk
  --vhook_a CTRL_REG_CLK CTRL_REG_CLK
  --vhook_a TX0_DSA1 TX0_DSA1
  --vhook_a CTRL_REG_ARST CTRL_REG_ARST
  --vhook_a {(MB_CTRL_*)} $1
  --vhook_a * open mode=out
  --vhook_a * '0' mode=in type=std_logic
  dutx: entity work.zr_top_cpld (rtl)
    port map (
      CPLD_REFCLK      => pll_ref_clk,    --in  wire
      MB_SYNTH_SYNC    => '0',            --in  wire
      CTRL_REG_CLK     => CTRL_REG_CLK,   --in  wire
      CTRL_REG_ARST    => CTRL_REG_ARST,  --in  wire
      MB_CTRL_SCK      => MB_CTRL_SCK,    --in  wire
      MB_CTRL_MOSI     => MB_CTRL_MOSI,   --in  wire
      MB_CTRL_MISO     => MB_CTRL_MISO,   --out wire
      MB_CTRL_CS       => MB_CTRL_CS,     --in  wire
      MB_FPGA_GPIO     => gpio_db,        --inout wire[13:0]
      P7V_ENABLE_A     => open,           --out wire
      P7V_ENABLE_B     => open,           --out wire
      P3D3VA_ENABLE    => open,           --out wire
      P7V_PG_A         => '0',            --in  wire
      P7V_PG_B         => '0',            --in  wire
      TX0_LO1_SYNC     => open,           --out wire
      TX0_LO1_MUXOUT   => '0',            --in  wire
      TX0_LO1_CSB      => open,           --out wire
      TX0_LO1_SCK      => open,           --out wire
      TX0_LO1_SDI      => open,           --out wire
      TX0_LO2_SYNC     => open,           --out wire
      TX0_LO2_MUXOUT   => '0',            --in  wire
      TX0_LO2_CSB      => open,           --out wire
      TX0_LO2_SCK      => open,           --out wire
      TX0_LO2_SDI      => open,           --out wire
      TX0_SW1_SW2_CTRL => open,           --out wire
      TX0_SW3_A        => open,           --out wire
      TX0_SW3_B        => open,           --out wire
      TX0_SW4_A        => open,           --out wire
      TX0_SW4_B        => open,           --out wire
      TX0_SW5_A        => open,           --out wire
      TX0_SW5_B        => open,           --out wire
      TX0_SW6_A        => open,           --out wire
      TX0_SW6_B        => open,           --out wire
      TX0_SW7_A        => open,           --out wire
      TX0_SW7_B        => open,           --out wire
      TX0_SW8_V1       => open,           --out wire
      TX0_SW8_V2       => open,           --out wire
      TX0_SW8_V3       => open,           --out wire
      TX0_SW9_A        => open,           --out wire
      TX0_SW9_B        => open,           --out wire
      TX0_SW10_A       => open,           --out wire
      TX0_SW10_B       => open,           --out wire
      TX0_SW11_A       => open,           --out wire
      TX0_SW11_B       => open,           --out wire
      TX0_SW13_V1      => open,           --out wire
      TX0_SW14_V1      => open,           --out wire
      TX0_DSA1         => TX0_DSA1,       --out wire[6:2]
      TX0_DSA2         => open,           --out wire[6:2]
      TX1_LO1_SYNC     => open,           --out wire
      TX1_LO1_MUXOUT   => '0',            --in  wire
      TX1_LO1_CSB      => open,           --out wire
      TX1_LO1_SCK      => open,           --out wire
      TX1_LO1_SDI      => open,           --out wire
      TX1_LO2_SYNC     => open,           --out wire
      TX1_LO2_MUXOUT   => '0',            --in  wire
      TX1_LO2_CSB      => open,           --out wire
      TX1_LO2_SCK      => open,           --out wire
      TX1_LO2_SDI      => open,           --out wire
      TX1_SW1_SW2_CTRL => open,           --out wire
      TX1_SW3_A        => open,           --out wire
      TX1_SW3_B        => open,           --out wire
      TX1_SW4_A        => open,           --out wire
      TX1_SW4_B        => open,           --out wire
      TX1_SW5_A        => open,           --out wire
      TX1_SW5_B        => open,           --out wire
      TX1_SW6_A        => open,           --out wire
      TX1_SW6_B        => open,           --out wire
      TX1_SW7_A        => open,           --out wire
      TX1_SW7_B        => open,           --out wire
      TX1_SW8_V1       => open,           --out wire
      TX1_SW8_V2       => open,           --out wire
      TX1_SW8_V3       => open,           --out wire
      TX1_SW9_A        => open,           --out wire
      TX1_SW9_B        => open,           --out wire
      TX1_SW10_A       => open,           --out wire
      TX1_SW10_B       => open,           --out wire
      TX1_SW11_A       => open,           --out wire
      TX1_SW11_B       => open,           --out wire
      TX1_SW13_V1      => open,           --out wire
      TX1_SW14_V1      => open,           --out wire
      TX1_DSA1         => open,           --out wire[6:2]
      TX1_DSA2         => open,           --out wire[6:2]
      RX0_LO1_SYNC     => open,           --out wire
      RX0_LO1_MUXOUT   => '0',            --in  wire
      RX0_LO1_CSB      => open,           --out wire
      RX0_LO1_SCK      => open,           --out wire
      RX0_LO1_SDI      => open,           --out wire
      RX0_LO2_SYNC     => open,           --out wire
      RX0_LO2_MUXOUT   => '0',            --in  wire
      RX0_LO2_CSB      => open,           --out wire
      RX0_LO2_SCK      => open,           --out wire
      RX0_LO2_SDI      => open,           --out wire
      RX0_SW1_A        => open,           --out wire
      RX0_SW1_B        => open,           --out wire
      RX0_SW2_A        => open,           --out wire
      RX0_SW3_V1       => open,           --out wire
      RX0_SW3_V2       => open,           --out wire
      RX0_SW3_V3       => open,           --out wire
      RX0_SW4_A        => open,           --out wire
      RX0_SW5_A        => open,           --out wire
      RX0_SW5_B        => open,           --out wire
      RX0_SW6_A        => open,           --out wire
      RX0_SW6_B        => open,           --out wire
      RX0_SW7_SW8_CTRL => open,           --out wire
      RX0_SW9_V1       => open,           --out wire
      RX0_SW10_V1      => open,           --out wire
      RX0_SW11_V3      => open,           --out wire
      RX0_SW11_V2      => open,           --out wire
      RX0_SW11_V1      => open,           --out wire
      RX0_DSA1_n       => open,           --out wire[1:4]
      RX0_DSA2_n       => open,           --out wire[1:4]
      RX0_DSA3_A_n     => open,           --out wire[1:4]
      RX0_DSA3_B_n     => open,           --out wire[1:4]
      RX1_LO1_SYNC     => open,           --out wire
      RX1_LO1_MUXOUT   => '0',            --in  wire
      RX1_LO1_CSB      => open,           --out wire
      RX1_LO1_SCK      => open,           --out wire
      RX1_LO1_SDI      => open,           --out wire
      RX1_LO2_SYNC     => open,           --out wire
      RX1_LO2_MUXOUT   => '0',            --in  wire
      RX1_LO2_CSB      => open,           --out wire
      RX1_LO2_SCK      => open,           --out wire
      RX1_LO2_SDI      => open,           --out wire
      RX1_SW1_A        => open,           --out wire
      RX1_SW1_B        => open,           --out wire
      RX1_SW2_A        => open,           --out wire
      RX1_SW3_V1       => open,           --out wire
      RX1_SW3_V2       => open,           --out wire
      RX1_SW3_V3       => open,           --out wire
      RX1_SW4_A        => open,           --out wire
      RX1_SW5_A        => open,           --out wire
      RX1_SW5_B        => open,           --out wire
      RX1_SW6_A        => open,           --out wire
      RX1_SW6_B        => open,           --out wire
      RX1_SW7_SW8_CTRL => open,           --out wire
      RX1_SW9_V1       => open,           --out wire
      RX1_SW10_V1      => open,           --out wire
      RX1_SW11_V3      => open,           --out wire
      RX1_SW11_V2      => open,           --out wire
      RX1_SW11_V1      => open,           --out wire
      RX1_DSA1_n       => open,           --out wire[1:4]
      RX1_DSA2_n       => open,           --out wire[1:4]
      RX1_DSA3_A_n     => open,           --out wire[1:4]
      RX1_DSA3_B_n     => open,           --out wire[1:4]
      CH0_RX2_LED      => open,           --out wire
      CH0_TX_LED       => open,           --out wire
      CH0_RX_LED       => open,           --out wire
      CH1_RX2_LED      => open,           --out wire
      CH1_TX_LED       => open,           --out wire
      CH1_RX_LED       => open);          --out wire


-- Display the value of the TestStatus string
VPrint(TestStatus);

------------------------------------------------------------------------------
-- internal signal replication
------------------------------------------------------------------------------
-- In order to be able to measure the latency of requests until reaching
-- internal registers one signal for read requests and one for write request is
-- replicated to the toplevel. This is necessary as debug signals can't be
-- exposed on the toplevel of the CPLD.
spy_process : process
begin
  init_signal_spy("/dutx/zr_cpld_core_i/atr_controller_i/option_rf1",
    "dup_atr_option_rf1",
    kRF1_OPTIONSize);
  init_signal_spy("/dutx/zr_cpld_core_i/atr_controller_i/s_ctrlport_req_rd",
    "dup_atr_rd",
    1);
  wait;
end process spy_process;

-- filter internal read signal
dup_atr_rd_filtered <= dup_atr_rd and to_StdLogic(dup_atr_rd_enabled);

timekeeper: process
begin
  radio_time_stb <= '0';
  wait until falling_edge(pll_ref_clk);
  radio_time_stb <= '1';
  radio_time <= std_logic_vector(unsigned(radio_time) + 1);
  wait until falling_edge(pll_ref_clk);
end process timekeeper;

measure: process
  variable startTimeStamp : time;
begin
  wait until measurementActive;
  -- wait until changes in the potential sources are detected
  wait on gpio_ctrlport_req_rd, gpio_ctrlport_req_wr, db_state;
  startTimeStamp := now;
  measuredTime <= 0 ns;
  measurementDone <= false;

  -- wait until changes on potential sinks are detected
  wait on gpio_ctrlport_resp_ack, TX0_DSA1, dup_atr_option_rf1, dup_atr_rd_filtered;
  measuredTime <= now - startTimeStamp;
  measurementDone <= true;

  -- wait for restart
  wait until not measurementActive;
end process measure;

main: process
  --vhook_nowarn id=CP14 msg={readData|regStatus|regAck}
  variable readData  : std_logic_vector(31 downto 0) := (others=>'0');
  variable regStatus : std_logic_vector(1  downto 0) := (others=>'0');
  variable regAck    : std_logic;

  procedure checkTiming(constant kExpectedTime : in time) is begin
    -- check for measurement to be done
    assert measurementDone report "Measurement is not yet done" severity error;

    -- allow the measured value in range of t < x <= t + kPrcPer
    -- as there is up to one PRC period of delay in the CDC
    assert (measuredTime > kExpectedTime) and (measuredTime <= kExpectedTime + kPrcPer)
    report "Time measurement out of range." & LF &
      "Allowed time: " & time'image(kExpectedTime) & LF &
      "Measured time: " & time'image(measuredTime)
    severity error;

    -- disable measurement
    measurementActive <= false;
  end procedure checkTiming;

  procedure prepareMeasurement(constant kNumRadioCyclesDelay : in integer) is begin
    -- ensure measurement is inactive before starting a new one
    if measurementActive then
      -- measurements should have been done long before 1 ms has passed
      wait until not measurementActive for 1 ms;
    end if;
    assert not measurementActive report "measurement still active" severity error;

    -- set measurement active
    measurementActive <= true;

    -- align with rising edge of clock (slower clock) as reference
    wait until rising_edge(pll_ref_clk);
    -- wait for desired number of cycles for testing various shifting of clocks
    wait for kNumRadioCyclesDelay * kRadioPer;
  end procedure prepareMeasurement;
begin
  -- initial values
  db_state <= (others => '0');

  -- initial reset
  reset_rc <= '1';
  CTRL_REG_ARST <= '1';
  -- keep reset asserted for a "long" time (randomly chosen)
  wait for 1 us;

  wait until rising_edge(radio_clk);
  reset_rc <= '0';
  CTRL_REG_ARST <= '0';

  -- wait for at least 2*10 clock cycles to release handshakes from reset
  wait for 2*kPrcPer*10;

  -- enable PRC
  CtrlPortWrite(kPOWER_REGS + kPRC_CONTROL, SetBit(kPLL_REF_CLOCK_ENABLE), kSpiThreadId);

  -- repeat tests for each data clock cycle within PLL ref clk period
  for i in 1 to kClockMultiplier loop
    TestStatus <= rs("Testing data clock cycle " & integer'image(i)); wait for 0 ns;

    TestStatus <= rs("Measure write request latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG, SetField(kRF1_OPTION, 1));
    checkTiming(kWriteRequestLatency);

    -- reset options to zeros
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG, Zeros(32));

    TestStatus <= rs("Measure write roundtrip latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG, Zeros(32));
    checkTiming(kWriteRoundtripLatency);

    TestStatus <= rs("Measure read request latency"); wait for 0 ns;
    dup_atr_rd_enabled <= true;
    prepareMeasurement(i);
    CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kCURRENT_CONFIG_REG, readData, regStatus, regAck);
    checkTiming(kReadRequestLatency);
    dup_atr_rd_enabled <= false;

    TestStatus <= rs("Measure read roundtrip latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kCURRENT_CONFIG_REG, readData, regStatus, regAck);
    checkTiming(kReadRoundtripLatency);

    TestStatus <= rs("Measure extended read roundtrip latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_ATR(0), readData, regStatus, regAck);
    checkTiming(kExtendedReadRoundtripLatency);

    TestStatus <= rs("ATR value register write to output latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_ATR(i-1), SetField(kTX_DSA1, i));
    checkTiming(kAtrValueRegisterWriteLatency);

    TestStatus <= rs("ATR configuration register write to output latency"); wait for 0 ns;
    prepareMeasurement(i);
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG, SetField(kSW_RF0_DSA_CONFIG, i));
    checkTiming(kAtrSwDefinedRequestLatency);

    TestStatus <= rs("Measure FPGA state to output latency"); wait for 0 ns;
    CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG, SetField(kRF0_DSA_OPTION, kFPGA_STATE));
    prepareMeasurement(i);
    db_state <= std_logic_vector(to_unsigned(i, 4));
    wait until measurementDone for 1 ms;
    checkTiming(kFpgaStateLatency);
  end loop;

  StopSim <= true;
  -- simulation does not end automatically
  Finish(1);
end process main;

end test;

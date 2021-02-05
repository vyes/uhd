--
-- Copyright 2020 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_zr_top_cpld
-- Description:
-- Testbench for top level CPLD

--nisim --op1="-L altera_mf_ver +nowarnTFMPC -L fiftyfivenm_ver -L lpm_ver"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgCtrlPortTester.all;
  use work.PkgSpiMaster.all;
  use work.PkgDB_CONTROL_REGMAP.all;
  use work.PkgBASIC_REGS_REGMAP.all;
  use work.PkgPOWER_REGS_REGMAP.all;
  use work.PkgLED_SETUP_REGMAP.all;
  use work.PkgDSA_SETUP_REGMAP.all;
  use work.PkgSWITCH_SETUP_REGMAP.all;
  use work.PkgLO_CONTROL_REGMAP.all;
  use work.PkgRECONFIG_REGMAP.all;
  use work.PkgSPI_REGMAP.all;
  use work.PkgGPIO_REGMAP.all;
  use work.PkgATR_REGMAP.all;
library std;
  use std.env.all;


entity tb_zr_top_cpld is

end tb_zr_top_cpld;

architecture test of tb_zr_top_cpld is

  --vhook_sigstart
  signal CH0_RX2_LED: std_logic;
  signal CH0_RX_LED: std_logic;
  signal CH0_TX_LED: std_logic;
  signal CH1_RX2_LED: std_logic;
  signal CH1_RX_LED: std_logic;
  signal CH1_TX_LED: std_logic;
  signal CTRL_REG_ARST: std_logic;
  signal CTRL_REG_CLK: std_logic := '0';
  signal gpio_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal gpio_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal gpio_ctrlport_req_rd: std_logic;
  signal gpio_ctrlport_req_wr: std_logic;
  signal gpio_ctrlport_resp_ack: std_logic;
  signal gpio_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal gpio_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal gpio_data_out: std_logic_vector(7 downto 0);
  signal gpio_direction: std_logic;
  signal gpio_output_enable: std_logic;
  signal gpio_valid_out: std_logic;
  signal m_ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal m_ctrlport_req_data: std_logic_vector(31 downto 0);
  signal m_ctrlport_req_rd: std_logic;
  signal m_ctrlport_req_wr: std_logic;
  signal m_ctrlport_resp_ack: std_logic;
  signal m_ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal m_ctrlport_resp_status: std_logic_vector(1 downto 0);
  signal MB_CTRL_CS: std_logic;
  signal MB_CTRL_MISO: std_logic;
  signal MB_CTRL_MOSI: std_logic;
  signal MB_CTRL_SCK: std_logic;
  signal MB_FPGA_GPIO: std_logic_vector(13 downto 0);
  signal P3D3VA_ENABLE: std_logic;
  signal P7V_ENABLE_A: std_logic;
  signal P7V_ENABLE_B: std_logic;
  signal P7V_PG_A: std_logic;
  signal P7V_PG_B: std_logic;
  signal RefClk: std_logic := '0';
  signal RX0_DSA1_n: std_logic_vector(1 to 4);
  signal RX0_DSA2_n: std_logic_vector(1 to 4);
  signal RX0_DSA3_A_n: std_logic_vector(1 to 4);
  signal RX0_DSA3_B_n: std_logic_vector(1 to 4);
  signal RX0_LO1_SYNC: std_logic;
  signal RX0_LO2_SYNC: std_logic;
  signal RX0_SW10_V1: std_logic;
  signal RX0_SW11_V1: std_logic;
  signal RX0_SW11_V2: std_logic;
  signal RX0_SW11_V3: std_logic;
  signal RX0_SW1_A: std_logic;
  signal RX0_SW1_B: std_logic;
  signal RX0_SW2_A: std_logic;
  signal RX0_SW3_V1: std_logic;
  signal RX0_SW3_V2: std_logic;
  signal RX0_SW3_V3: std_logic;
  signal RX0_SW4_A: std_logic;
  signal RX0_SW5_A: std_logic;
  signal RX0_SW5_B: std_logic;
  signal RX0_SW6_A: std_logic;
  signal RX0_SW6_B: std_logic;
  signal RX0_SW7_SW8_CTRL: std_logic;
  signal RX0_SW9_V1: std_logic;
  signal RX1_DSA1_n: std_logic_vector(1 to 4);
  signal RX1_DSA2_n: std_logic_vector(1 to 4);
  signal RX1_DSA3_A_n: std_logic_vector(1 to 4);
  signal RX1_DSA3_B_n: std_logic_vector(1 to 4);
  signal RX1_LO1_SYNC: std_logic;
  signal RX1_LO2_SYNC: std_logic;
  signal RX1_SW10_V1: std_logic;
  signal RX1_SW11_V1: std_logic;
  signal RX1_SW11_V2: std_logic;
  signal RX1_SW11_V3: std_logic;
  signal RX1_SW1_A: std_logic;
  signal RX1_SW1_B: std_logic;
  signal RX1_SW2_A: std_logic;
  signal RX1_SW3_V1: std_logic;
  signal RX1_SW3_V2: std_logic;
  signal RX1_SW3_V3: std_logic;
  signal RX1_SW4_A: std_logic;
  signal RX1_SW5_A: std_logic;
  signal RX1_SW5_B: std_logic;
  signal RX1_SW6_A: std_logic;
  signal RX1_SW6_B: std_logic;
  signal RX1_SW7_SW8_CTRL: std_logic;
  signal RX1_SW9_V1: std_logic;
  signal ss: std_logic_vector(1 downto 0);
  signal TX0_DSA1: std_logic_vector(6 downto 2);
  signal TX0_DSA2: std_logic_vector(6 downto 2);
  signal TX0_LO1_SYNC: std_logic;
  signal TX0_LO2_SYNC: std_logic;
  signal TX0_SW10_A: std_logic;
  signal TX0_SW10_B: std_logic;
  signal TX0_SW11_A: std_logic;
  signal TX0_SW11_B: std_logic;
  signal TX0_SW13_V1: std_logic;
  signal TX0_SW14_V1: std_logic;
  signal TX0_SW1_SW2_CTRL: std_logic;
  signal TX0_SW3_A: std_logic;
  signal TX0_SW3_B: std_logic;
  signal TX0_SW4_A: std_logic;
  signal TX0_SW4_B: std_logic;
  signal TX0_SW5_A: std_logic;
  signal TX0_SW5_B: std_logic;
  signal TX0_SW6_A: std_logic;
  signal TX0_SW6_B: std_logic;
  signal TX0_SW7_A: std_logic;
  signal TX0_SW7_B: std_logic;
  signal TX0_SW8_V1: std_logic;
  signal TX0_SW8_V2: std_logic;
  signal TX0_SW8_V3: std_logic;
  signal TX0_SW9_A: std_logic;
  signal TX0_SW9_B: std_logic;
  signal TX1_DSA1: std_logic_vector(6 downto 2);
  signal TX1_DSA2: std_logic_vector(6 downto 2);
  signal TX1_LO1_SYNC: std_logic;
  signal TX1_LO2_SYNC: std_logic;
  signal TX1_SW10_A: std_logic;
  signal TX1_SW10_B: std_logic;
  signal TX1_SW11_A: std_logic;
  signal TX1_SW11_B: std_logic;
  signal TX1_SW13_V1: std_logic;
  signal TX1_SW14_V1: std_logic;
  signal TX1_SW1_SW2_CTRL: std_logic;
  signal TX1_SW3_A: std_logic;
  signal TX1_SW3_B: std_logic;
  signal TX1_SW4_A: std_logic;
  signal TX1_SW4_B: std_logic;
  signal TX1_SW5_A: std_logic;
  signal TX1_SW5_B: std_logic;
  signal TX1_SW6_A: std_logic;
  signal TX1_SW6_B: std_logic;
  signal TX1_SW7_A: std_logic;
  signal TX1_SW7_B: std_logic;
  signal TX1_SW8_V1: std_logic;
  signal TX1_SW8_V2: std_logic;
  signal TX1_SW8_V3: std_logic;
  signal TX1_SW9_A: std_logic;
  signal TX1_SW9_B: std_logic;
  --vhook_sigend

  type SpiDataArray_t is array (kLO_CHIP_SELECTSize-1 downto 0) of std_logic_vector(31 downto 0);
  signal sLoMisoData: SpiDataArray_t;
  signal sLoMosiData: SpiDataArray_t;

  signal sLoSlaveCs : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0);
  signal sLoSlaveSclk : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0);
  signal sLoSlaveSdi : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0);
  signal sLoSlaveMuxout : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0);

  shared variable Rand : Random_t;
  signal StopSim : boolean := false;
  constant kCtrlPort50MhzPeriod : time := 20 ns;  -- 50 MHz
  constant kPrcPeriod : time := 16 ns;  -- 62,5 MHz
  signal TestStatus : TestStatusString_t;
  signal prcReset : boolean := true;

  -- The OSS reset_sync module has 10 register stages. Let's just reset for
  -- twice this time with the longest clock period.
  constant resetDuration : time := 2*10*kCtrlPort50MhzPeriod;

  -- GPIO controlport has to be called with this thread ID.
  constant kGpioThreadId : integer := 1;

  -- Reconfig engine sector start addresses (first address of each sector in bytes).
  -- Can be calculated from Table 1 in
  -- https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/hb/max-10/ug_m10_ufm.pdf
  -- IP creation wizard provides these numbers during configuration.
  constant kSectorStartAddresses : IntegerVector(2 downto 0) := (16#4000#, 16#18880#, 16#27000#);

  --Register test signals
  signal rLedControlReg  : std_logic_vector(31 downto 0) := (others => '0');
  signal rLed0ControlReg : std_logic_vector(31 downto 0) := (others => '0');
  signal rLed1ControlReg : std_logic_vector(31 downto 0) := (others => '0');
  signal cScratchReg : std_logic_vector(31 downto 0) := (others => '0'); --unused, except for placeholder for procedure

  -- Auxiliary signals to bundle inidividual signals together.
  signal rTx0PathControlArray : std_logic_vector(31 downto 0) := (others => '0');
  signal rTx1PathControlArray : std_logic_vector(31 downto 0) := (others => '0');
  signal rRx0PathControlArray : std_logic_vector(31 downto 0) := (others => '0');
  signal rRx1PathControlArray : std_logic_vector(31 downto 0) := (others => '0');
  signal cRfPowerControlArray : std_logic_vector(31 downto 0) := (others => '0');

  signal rTx0DsaControlArray  : std_logic_vector(31 downto 0) := (others => '0');
  signal rTx1DsaControlArray  : std_logic_vector(31 downto 0) := (others => '0');
  signal rRx0DsaControlArray  : std_logic_vector(31 downto 0) := (others => '0');
  signal rRx1DsaControlArray  : std_logic_vector(31 downto 0) := (others => '0');

  signal MB_SYNTH_SYNC: std_logic:= '0';
  signal rLoSyncArray         : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0) := (others => '0');
  signal ExpectedLoSync       : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0) := (others => '0');
  signal SyncIsPulse          : boolean := false;
  signal CheckSyncDeassertion : boolean := false;
  signal EnableChecks         : boolean := false;

  -- Random for test data generation
  shared variable Random : Random_t;

  constant kLoSpiSlaveModel : SpiSlaveModel_t := (
    Bidirectional => false,
    MosiFirst     => false,
    MosiCount     => 24,
    MisoCount     => 24,
    TxMisoFE      => true,  --Slave updates MISO on the falling edge of CLK.
    RxMosiFE      => false, --Slave latches MOSI on the falling edge of CLK.
    CsActiveHigh  => false, --True when '1' is assert.
    Sclk_Period   => 120 ns,--CLK pulse width from "read" edge to "read" edge.
    Sclk_High     => 5 ns, --Clk pulse width high.
    Sclk_Low      => 5 ns, --CLK pulse width low.
    DataSetup     => 10 ns, --Setup time between data and "read" edge of CLK.
    DataHold      => 10 ns, --Hold time between data and "read" edge of CLK.
    DataTcoMin    => 0 ns,  --Data clock to out (MISO).
    DataTcoMax    => 30 ns, --Data clock to out (MISO).
    CsSetup       => 10 ns, --Setup time- CS assert to first "read" CLK edge.
    CsHold        => 0 ns,  --Hold time- CLK last edge to CS deassert.
    CsIdle        => 0 ns,  --Deasserted time between transactions.
    SdioEn        => 0 ns,  --Time required for SDIO switch from in to out.
    SdioDis       => 0 ns); --Time required for SDIO switch from out to in.

begin

  CTRL_REG_CLK <= not CTRL_REG_CLK after kCtrlPort50MhzPeriod/2 when not StopSim else '0';
  RefClk <= not RefClk after kPrcPeriod/2 when not StopSim else '0';

  --vhook_e CtrlPortMasterModel ctrlportSpiSource
  --vhook_a kThreadId         0
  --vhook_a kHoldAccess       true
  --vhook_a kClkCycleTimeout  1000
  --vhook_a ctrlport_clk      CTRL_REG_CLK
  --vhook_a ctrlport_rst      to_boolean(CTRL_REG_ARST)
  ctrlportSpiSource: entity work.CtrlPortMasterModel (behav)
    generic map (
      kThreadId        => 0,     --natural:=0
      kHoldAccess      => true,  --boolean:=true
      kClkCycleTimeout => 1000)  --natural:=1000
    port map (
      ctrlport_rst           => to_boolean(CTRL_REG_ARST),  --in  boolean
      ctrlport_clk           => CTRL_REG_CLK,               --in  std_logic
      m_ctrlport_req_wr      => m_ctrlport_req_wr,          --out std_logic
      m_ctrlport_req_rd      => m_ctrlport_req_rd,          --out std_logic
      m_ctrlport_req_addr    => m_ctrlport_req_addr,        --out std_logic_vector(19:0)
      m_ctrlport_req_data    => m_ctrlport_req_data,        --out std_logic_vector(31:0)
      m_ctrlport_resp_ack    => m_ctrlport_resp_ack,        --in  std_logic
      m_ctrlport_resp_status => m_ctrlport_resp_status,     --in  std_logic_vector(1 :0)
      m_ctrlport_resp_data   => m_ctrlport_resp_data);      --in  std_logic_vector(31:0)

  --vhook_e ctrlport_spi_master     db_cpld_spi_master
  --vhook_a CPLD_ADDRESS_WIDTH      15
  --vhook_a MB_CPLD_BASE_ADDRESS    0
  --vhook_a DB_0_CPLD_BASE_ADDRESS  X"0"
  --vhook_a DB_1_CPLD_BASE_ADDRESS  X"10000"
  --vhook_a ctrlport_clk            CTRL_REG_CLK
  --vhook_a ctrlport_rst            CTRL_REG_ARST
  --vhook_a {s_ctrlport_(.*)}       m_ctrlport_$1
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
      ctrlport_clk           => CTRL_REG_CLK,            --in  wire
      ctrlport_rst           => CTRL_REG_ARST,           --in  wire
      s_ctrlport_req_wr      => m_ctrlport_req_wr,       --in  wire
      s_ctrlport_req_rd      => m_ctrlport_req_rd,       --in  wire
      s_ctrlport_req_addr    => m_ctrlport_req_addr,     --in  wire[19:0]
      s_ctrlport_req_data    => m_ctrlport_req_data,     --in  wire[31:0]
      s_ctrlport_resp_ack    => m_ctrlport_resp_ack,     --out wire
      s_ctrlport_resp_status => m_ctrlport_resp_status,  --out wire[1:0]
      s_ctrlport_resp_data   => m_ctrlport_resp_data,    --out wire[31:0]
      ss                     => ss,                      --out wire[1:0]
      sclk                   => MB_CTRL_SCK,             --out wire
      mosi                   => MB_CTRL_MOSI,            --out wire
      miso                   => MB_CTRL_MISO,            --in  wire
      mb_clock_divider       => X"0003",                 --in  wire[15:0]
      db_clock_divider       => X"FFFF");                --in  wire[15:0]

  MB_CTRL_CS <= ss(0);

  --vhook_e CtrlPortMasterModel ctrlportGpioSource
  --vhook_a kThreadId         1
  --vhook_a kHoldAccess       true
  --vhook_a kClkCycleTimeout  1000
  --vhook_a ctrlport_clk      RefClk
  --vhook_a ctrlport_rst      prcReset
  --vhook_a {m_ctrlport_(.*)} gpio_ctrlport_$1
  ctrlportGpioSource: entity work.CtrlPortMasterModel (behav)
    generic map (
      kThreadId        => 1,     --natural:=0
      kHoldAccess      => true,  --boolean:=true
      kClkCycleTimeout => 1000)  --natural:=1000
    port map (
      ctrlport_rst           => prcReset,                   --in  boolean
      ctrlport_clk           => RefClk,                     --in  std_logic
      m_ctrlport_req_wr      => gpio_ctrlport_req_wr,       --out std_logic
      m_ctrlport_req_rd      => gpio_ctrlport_req_rd,       --out std_logic
      m_ctrlport_req_addr    => gpio_ctrlport_req_addr,     --out std_logic_vector(19:0)
      m_ctrlport_req_data    => gpio_ctrlport_req_data,     --out std_logic_vector(31:0)
      m_ctrlport_resp_ack    => gpio_ctrlport_resp_ack,     --in  std_logic
      m_ctrlport_resp_status => gpio_ctrlport_resp_status,  --in  std_logic_vector(1 :0)
      m_ctrlport_resp_data   => gpio_ctrlport_resp_data);   --in  std_logic_vector(31:0)

  --vhook_e ctrlport_byte_serializer
  --vhook_a ctrlport_clk RefClk
  --vhook_a ctrlport_rst to_StdLogic(prcReset)
  --vhook_a {s_ctrlport_(.*)} gpio_ctrlport_$1
  --vhook_a bytestream_data_in MB_FPGA_GPIO(11 downto 4)
  --vhook_a bytestream_valid_in MB_FPGA_GPIO(12)
  --vhook_a {^bytestream(.*)} {gpio$1}
  ctrlport_byte_serializerx: entity work.ctrlport_byte_serializer (rtl)
    port map (
      ctrlport_clk             => RefClk,                     --in  wire
      ctrlport_rst             => to_StdLogic(prcReset),      --in  wire
      s_ctrlport_req_wr        => gpio_ctrlport_req_wr,       --in  wire
      s_ctrlport_req_rd        => gpio_ctrlport_req_rd,       --in  wire
      s_ctrlport_req_addr      => gpio_ctrlport_req_addr,     --in  wire[19:0]
      s_ctrlport_req_data      => gpio_ctrlport_req_data,     --in  wire[31:0]
      s_ctrlport_resp_ack      => gpio_ctrlport_resp_ack,     --out wire
      s_ctrlport_resp_status   => gpio_ctrlport_resp_status,  --out wire[1:0]
      s_ctrlport_resp_data     => gpio_ctrlport_resp_data,    --out wire[31:0]
      bytestream_data_in       => MB_FPGA_GPIO(11 downto 4),  --in  wire[7:0]
      bytestream_valid_in      => MB_FPGA_GPIO(12),           --in  wire
      bytestream_data_out      => gpio_data_out,              --out wire[7:0]
      bytestream_valid_out     => gpio_valid_out,             --out wire
      bytestream_direction     => gpio_direction,             --out wire
      bytestream_output_enable => gpio_output_enable);        --out wire

  MB_FPGA_GPIO(13) <= gpio_direction;
  MB_FPGA_GPIO(12) <= gpio_valid_out when gpio_output_enable else 'Z';
  gpio_gen: for i in gpio_data_out'range generate
    MB_FPGA_GPIO(i+4) <= gpio_data_out(i) when gpio_output_enable else 'Z';
  end generate;

  --vhook_e zr_top_cpld dutx
  --vhook_a {(R|T)X([0-9]+)_LO([0-9]+)_CSB}     sLoSlaveCs(k$1X$2_LO$3)
  --vhook_a {(R|T)X([0-9]+)_LO([0-9]+)_MUXOUT}  sLoSlaveMuxout(k$1X$2_LO$3)
  --vhook_a {(R|T)X([0-9]+)_LO([0-9]+)_SDI}     sLoSlaveSdi(k$1X$2_LO$3)
  --vhook_a {(R|T)X([0-9]+)_LO([0-9]+)_SCK}     sLoSlaveSclk(k$1X$2_LO$3)
  --vhook_a CPLD_REFCLK RefClk
  dutx: entity work.zr_top_cpld (rtl)
    port map (
      CPLD_REFCLK      => RefClk,                    --in  wire
      MB_SYNTH_SYNC    => MB_SYNTH_SYNC,             --in  wire
      CTRL_REG_CLK     => CTRL_REG_CLK,              --in  wire
      CTRL_REG_ARST    => CTRL_REG_ARST,             --in  wire
      MB_CTRL_SCK      => MB_CTRL_SCK,               --in  wire
      MB_CTRL_MOSI     => MB_CTRL_MOSI,              --in  wire
      MB_CTRL_MISO     => MB_CTRL_MISO,              --out wire
      MB_CTRL_CS       => MB_CTRL_CS,                --in  wire
      MB_FPGA_GPIO     => MB_FPGA_GPIO,              --inout wire[13:0]
      P7V_ENABLE_A     => P7V_ENABLE_A,              --out wire
      P7V_ENABLE_B     => P7V_ENABLE_B,              --out wire
      P3D3VA_ENABLE    => P3D3VA_ENABLE,             --out wire
      P7V_PG_A         => P7V_PG_A,                  --in  wire
      P7V_PG_B         => P7V_PG_B,                  --in  wire
      TX0_LO1_SYNC     => TX0_LO1_SYNC,              --out wire
      TX0_LO1_MUXOUT   => sLoSlaveMuxout(kTX0_LO1),  --in  wire
      TX0_LO1_CSB      => sLoSlaveCs(kTX0_LO1),      --out wire
      TX0_LO1_SCK      => sLoSlaveSclk(kTX0_LO1),    --out wire
      TX0_LO1_SDI      => sLoSlaveSdi(kTX0_LO1),     --out wire
      TX0_LO2_SYNC     => TX0_LO2_SYNC,              --out wire
      TX0_LO2_MUXOUT   => sLoSlaveMuxout(kTX0_LO2),  --in  wire
      TX0_LO2_CSB      => sLoSlaveCs(kTX0_LO2),      --out wire
      TX0_LO2_SCK      => sLoSlaveSclk(kTX0_LO2),    --out wire
      TX0_LO2_SDI      => sLoSlaveSdi(kTX0_LO2),     --out wire
      TX0_SW1_SW2_CTRL => TX0_SW1_SW2_CTRL,          --out wire
      TX0_SW3_A        => TX0_SW3_A,                 --out wire
      TX0_SW3_B        => TX0_SW3_B,                 --out wire
      TX0_SW4_A        => TX0_SW4_A,                 --out wire
      TX0_SW4_B        => TX0_SW4_B,                 --out wire
      TX0_SW5_A        => TX0_SW5_A,                 --out wire
      TX0_SW5_B        => TX0_SW5_B,                 --out wire
      TX0_SW6_A        => TX0_SW6_A,                 --out wire
      TX0_SW6_B        => TX0_SW6_B,                 --out wire
      TX0_SW7_A        => TX0_SW7_A,                 --out wire
      TX0_SW7_B        => TX0_SW7_B,                 --out wire
      TX0_SW8_V1       => TX0_SW8_V1,                --out wire
      TX0_SW8_V2       => TX0_SW8_V2,                --out wire
      TX0_SW8_V3       => TX0_SW8_V3,                --out wire
      TX0_SW9_A        => TX0_SW9_A,                 --out wire
      TX0_SW9_B        => TX0_SW9_B,                 --out wire
      TX0_SW10_A       => TX0_SW10_A,                --out wire
      TX0_SW10_B       => TX0_SW10_B,                --out wire
      TX0_SW11_A       => TX0_SW11_A,                --out wire
      TX0_SW11_B       => TX0_SW11_B,                --out wire
      TX0_SW13_V1      => TX0_SW13_V1,               --out wire
      TX0_SW14_V1      => TX0_SW14_V1,               --out wire
      TX0_DSA1         => TX0_DSA1,                  --out wire[6:2]
      TX0_DSA2         => TX0_DSA2,                  --out wire[6:2]
      TX1_LO1_SYNC     => TX1_LO1_SYNC,              --out wire
      TX1_LO1_MUXOUT   => sLoSlaveMuxout(kTX1_LO1),  --in  wire
      TX1_LO1_CSB      => sLoSlaveCs(kTX1_LO1),      --out wire
      TX1_LO1_SCK      => sLoSlaveSclk(kTX1_LO1),    --out wire
      TX1_LO1_SDI      => sLoSlaveSdi(kTX1_LO1),     --out wire
      TX1_LO2_SYNC     => TX1_LO2_SYNC,              --out wire
      TX1_LO2_MUXOUT   => sLoSlaveMuxout(kTX1_LO2),  --in  wire
      TX1_LO2_CSB      => sLoSlaveCs(kTX1_LO2),      --out wire
      TX1_LO2_SCK      => sLoSlaveSclk(kTX1_LO2),    --out wire
      TX1_LO2_SDI      => sLoSlaveSdi(kTX1_LO2),     --out wire
      TX1_SW1_SW2_CTRL => TX1_SW1_SW2_CTRL,          --out wire
      TX1_SW3_A        => TX1_SW3_A,                 --out wire
      TX1_SW3_B        => TX1_SW3_B,                 --out wire
      TX1_SW4_A        => TX1_SW4_A,                 --out wire
      TX1_SW4_B        => TX1_SW4_B,                 --out wire
      TX1_SW5_A        => TX1_SW5_A,                 --out wire
      TX1_SW5_B        => TX1_SW5_B,                 --out wire
      TX1_SW6_A        => TX1_SW6_A,                 --out wire
      TX1_SW6_B        => TX1_SW6_B,                 --out wire
      TX1_SW7_A        => TX1_SW7_A,                 --out wire
      TX1_SW7_B        => TX1_SW7_B,                 --out wire
      TX1_SW8_V1       => TX1_SW8_V1,                --out wire
      TX1_SW8_V2       => TX1_SW8_V2,                --out wire
      TX1_SW8_V3       => TX1_SW8_V3,                --out wire
      TX1_SW9_A        => TX1_SW9_A,                 --out wire
      TX1_SW9_B        => TX1_SW9_B,                 --out wire
      TX1_SW10_A       => TX1_SW10_A,                --out wire
      TX1_SW10_B       => TX1_SW10_B,                --out wire
      TX1_SW11_A       => TX1_SW11_A,                --out wire
      TX1_SW11_B       => TX1_SW11_B,                --out wire
      TX1_SW13_V1      => TX1_SW13_V1,               --out wire
      TX1_SW14_V1      => TX1_SW14_V1,               --out wire
      TX1_DSA1         => TX1_DSA1,                  --out wire[6:2]
      TX1_DSA2         => TX1_DSA2,                  --out wire[6:2]
      RX0_LO1_SYNC     => RX0_LO1_SYNC,              --out wire
      RX0_LO1_MUXOUT   => sLoSlaveMuxout(kRX0_LO1),  --in  wire
      RX0_LO1_CSB      => sLoSlaveCs(kRX0_LO1),      --out wire
      RX0_LO1_SCK      => sLoSlaveSclk(kRX0_LO1),    --out wire
      RX0_LO1_SDI      => sLoSlaveSdi(kRX0_LO1),     --out wire
      RX0_LO2_SYNC     => RX0_LO2_SYNC,              --out wire
      RX0_LO2_MUXOUT   => sLoSlaveMuxout(kRX0_LO2),  --in  wire
      RX0_LO2_CSB      => sLoSlaveCs(kRX0_LO2),      --out wire
      RX0_LO2_SCK      => sLoSlaveSclk(kRX0_LO2),    --out wire
      RX0_LO2_SDI      => sLoSlaveSdi(kRX0_LO2),     --out wire
      RX0_SW1_A        => RX0_SW1_A,                 --out wire
      RX0_SW1_B        => RX0_SW1_B,                 --out wire
      RX0_SW2_A        => RX0_SW2_A,                 --out wire
      RX0_SW3_V1       => RX0_SW3_V1,                --out wire
      RX0_SW3_V2       => RX0_SW3_V2,                --out wire
      RX0_SW3_V3       => RX0_SW3_V3,                --out wire
      RX0_SW4_A        => RX0_SW4_A,                 --out wire
      RX0_SW5_A        => RX0_SW5_A,                 --out wire
      RX0_SW5_B        => RX0_SW5_B,                 --out wire
      RX0_SW6_A        => RX0_SW6_A,                 --out wire
      RX0_SW6_B        => RX0_SW6_B,                 --out wire
      RX0_SW7_SW8_CTRL => RX0_SW7_SW8_CTRL,          --out wire
      RX0_SW9_V1       => RX0_SW9_V1,                --out wire
      RX0_SW10_V1      => RX0_SW10_V1,               --out wire
      RX0_SW11_V3      => RX0_SW11_V3,               --out wire
      RX0_SW11_V2      => RX0_SW11_V2,               --out wire
      RX0_SW11_V1      => RX0_SW11_V1,               --out wire
      RX0_DSA1_n       => RX0_DSA1_n,                --out wire[1:4]
      RX0_DSA2_n       => RX0_DSA2_n,                --out wire[1:4]
      RX0_DSA3_A_n     => RX0_DSA3_A_n,              --out wire[1:4]
      RX0_DSA3_B_n     => RX0_DSA3_B_n,              --out wire[1:4]
      RX1_LO1_SYNC     => RX1_LO1_SYNC,              --out wire
      RX1_LO1_MUXOUT   => sLoSlaveMuxout(kRX1_LO1),  --in  wire
      RX1_LO1_CSB      => sLoSlaveCs(kRX1_LO1),      --out wire
      RX1_LO1_SCK      => sLoSlaveSclk(kRX1_LO1),    --out wire
      RX1_LO1_SDI      => sLoSlaveSdi(kRX1_LO1),     --out wire
      RX1_LO2_SYNC     => RX1_LO2_SYNC,              --out wire
      RX1_LO2_MUXOUT   => sLoSlaveMuxout(kRX1_LO2),  --in  wire
      RX1_LO2_CSB      => sLoSlaveCs(kRX1_LO2),      --out wire
      RX1_LO2_SCK      => sLoSlaveSclk(kRX1_LO2),    --out wire
      RX1_LO2_SDI      => sLoSlaveSdi(kRX1_LO2),     --out wire
      RX1_SW1_A        => RX1_SW1_A,                 --out wire
      RX1_SW1_B        => RX1_SW1_B,                 --out wire
      RX1_SW2_A        => RX1_SW2_A,                 --out wire
      RX1_SW3_V1       => RX1_SW3_V1,                --out wire
      RX1_SW3_V2       => RX1_SW3_V2,                --out wire
      RX1_SW3_V3       => RX1_SW3_V3,                --out wire
      RX1_SW4_A        => RX1_SW4_A,                 --out wire
      RX1_SW5_A        => RX1_SW5_A,                 --out wire
      RX1_SW5_B        => RX1_SW5_B,                 --out wire
      RX1_SW6_A        => RX1_SW6_A,                 --out wire
      RX1_SW6_B        => RX1_SW6_B,                 --out wire
      RX1_SW7_SW8_CTRL => RX1_SW7_SW8_CTRL,          --out wire
      RX1_SW9_V1       => RX1_SW9_V1,                --out wire
      RX1_SW10_V1      => RX1_SW10_V1,               --out wire
      RX1_SW11_V3      => RX1_SW11_V3,               --out wire
      RX1_SW11_V2      => RX1_SW11_V2,               --out wire
      RX1_SW11_V1      => RX1_SW11_V1,               --out wire
      RX1_DSA1_n       => RX1_DSA1_n,                --out wire[1:4]
      RX1_DSA2_n       => RX1_DSA2_n,                --out wire[1:4]
      RX1_DSA3_A_n     => RX1_DSA3_A_n,              --out wire[1:4]
      RX1_DSA3_B_n     => RX1_DSA3_B_n,              --out wire[1:4]
      CH0_RX2_LED      => CH0_RX2_LED,               --out wire
      CH0_TX_LED       => CH0_TX_LED,                --out wire
      CH0_RX_LED       => CH0_RX_LED,                --out wire
      CH1_RX2_LED      => CH1_RX2_LED,               --out wire
      CH1_TX_LED       => CH1_TX_LED,                --out wire
      CH1_RX_LED       => CH1_RX_LED);               --out wire


  GenLoSlaves: for i in 0 to kLO_CHIP_SELECTSize-1 generate
    --LO SPI slave models
    --vhook_e SpiSlaveModel             LoSlave
    --vhook_c kChipName                 "Tx0Lo1"
    --vhook_c kMaxSpiTransactionWidth   32
    --vhook_c kNeverCheckCsTiming       true
    --vhook_c kCheckSpiClkPeriodAlways  false
    --vhook_a sRunSlaveModel            false
    --vhook_a sSkipAssertChecks         true
    --vhook_a aReset                    to_boolean(CTRL_REG_ARST)
    --vhook_a sSpiSlaveModel            kLoSpiSlaveModel
    --vhook_a sSpiMiso                  sLoSlaveMuxout(i)
    --vhook_a sSpiCs                    sLoSlaveCs(i)
    --vhook_a SpiClk                    sLoSlaveSclk(i)
    --vhook_a sSpiMosi                  sLoSlaveSdi(i)
    --vhook_a sMisoData                 sLoMisoData(i)
    --vhook_a sMosiData                 sLoMosiData(i)
    --vhook_a sTransactionWidth         24
    LoSlave: entity work.SpiSlaveModel (model)
      generic map (
        kChipName                => "Tx0Lo1",  --string:="GenericSpiChip"
        kMaxSpiTransactionWidth  => 32,        --integer:=64
        kNeverCheckCsTiming      => true,      --boolean:=false
        kCheckSpiClkPeriodAlways => false)     --boolean:=true
      port map (
        sRunSlaveModel    => false,                      --in  boolean
        sSkipAssertChecks => true,                       --in  boolean
        aReset            => to_boolean(CTRL_REG_ARST),  --in  boolean
        sSpiSlaveModel    => kLoSpiSlaveModel,           --in  SpiSlaveModel_t
        sSpiCs            => sLoSlaveCs(i),              --in  std_logic
        SpiClk            => sLoSlaveSclk(i),            --in  std_logic
        sSpiMosi          => sLoSlaveSdi(i),             --in  std_logic
        sSpiMiso          => sLoSlaveMuxout(i),          --out std_logic
        sMisoData         => sLoMisoData(i),             --in  std_logic_vector(kMaxSpiTransactionWidth-1:0)
        sMosiData         => sLoMosiData(i),             --out std_logic_vector(kMaxSpiTransactionWidth-1:0)
        sTransactionWidth => 24);                        --in  integer

  end generate;


  -----------------------------------------------------------------------------------
  --Switch signals
  -----------------------------------------------------------------------------------
  rTx0PathControlArray(kTX_SWITCH_1_2)                          <= TX0_SW1_SW2_CTRL;
  rTx0PathControlArray(kTX_SWITCH_3msb  downto kTX_SWITCH_3)    <= TX0_SW3_B  & TX0_SW3_A;
  rTx0PathControlArray(kTX_SWITCH_4msb  downto kTX_SWITCH_4)    <= TX0_SW4_B  & TX0_SW4_A;
  rTx0PathControlArray(kTX_SWITCH_5msb  downto kTX_SWITCH_5)    <= TX0_SW5_B  & TX0_SW5_A;
  rTx0PathControlArray(kTX_SWITCH_6msb  downto kTX_SWITCH_6)    <= TX0_SW6_B  & TX0_SW6_A;
  rTx0PathControlArray(kTX_SWITCH_7msb  downto kTX_SWITCH_7)    <= TX0_SW7_B  & TX0_SW7_A;
  rTx0PathControlArray(kTX_SWITCH_8msb  downto kTX_SWITCH_8)    <= TX0_SW8_V3 & TX0_SW8_V2 & TX0_SW8_V1;
  rTx0PathControlArray(kTX_SWITCH_9msb  downto kTX_SWITCH_9)    <= TX0_SW9_B  & TX0_SW9_A;
  rTx0PathControlArray(kTX_SWITCH_10msb downto kTX_SWITCH_10)   <= TX0_SW10_B & TX0_SW10_A;
  rTx0PathControlArray(kTX_SWITCH_11msb downto kTX_SWITCH_11)   <= TX0_SW11_B & TX0_SW11_A;
  rTx0PathControlArray(kTX_SWITCH_13)                           <= TX0_SW13_V1;
  rTx0PathControlArray(kTX_SWITCH_14)                           <= TX0_SW14_V1;

  rTx1PathControlArray(kTX_SWITCH_1_2)                          <= TX1_SW1_SW2_CTRL;
  rTx1PathControlArray(kTX_SWITCH_3msb  downto kTX_SWITCH_3)    <= TX1_SW3_B  & TX1_SW3_A;
  rTx1PathControlArray(kTX_SWITCH_4msb  downto kTX_SWITCH_4)    <= TX1_SW4_B  & TX1_SW4_A;
  rTx1PathControlArray(kTX_SWITCH_5msb  downto kTX_SWITCH_5)    <= TX1_SW5_B  & TX1_SW5_A;
  rTx1PathControlArray(kTX_SWITCH_6msb  downto kTX_SWITCH_6)    <= TX1_SW6_B  & TX1_SW6_A;
  rTx1PathControlArray(kTX_SWITCH_7msb  downto kTX_SWITCH_7)    <= TX1_SW7_B  & TX1_SW7_A;
  rTx1PathControlArray(kTX_SWITCH_8msb  downto kTX_SWITCH_8)    <= TX1_SW8_V3 & TX1_SW8_V2 & TX1_SW8_V1;
  rTx1PathControlArray(kTX_SWITCH_9msb  downto kTX_SWITCH_9)    <= TX1_SW9_B  & TX1_SW9_A;
  rTx1PathControlArray(kTX_SWITCH_10msb downto kTX_SWITCH_10)   <= TX1_SW10_B & TX1_SW10_A;
  rTx1PathControlArray(kTX_SWITCH_11msb downto kTX_SWITCH_11)   <= TX1_SW11_B & TX1_SW11_A;
  rTx1PathControlArray(kTX_SWITCH_13)                           <= TX1_SW13_V1;
  rTx1PathControlArray(kTX_SWITCH_14)                           <= TX1_SW14_V1;

  rRx0PathControlArray(kRX_SWITCH_1msb downto kRX_SWITCH_1)     <= RX0_SW1_B  & RX0_SW1_A;
  rRx0PathControlArray(kRX_SWITCH_2)                            <= RX0_SW2_A;
  rRx0PathControlArray(kRX_SWITCH_3msb downto kRX_SWITCH_3)     <= RX0_SW3_V3 & RX0_SW3_V2 & RX0_SW3_V1;
  rRx0PathControlArray(kRX_SWITCH_4)                            <= RX0_SW4_A;
  rRx0PathControlArray(kRX_SWITCH_5msb downto kRX_SWITCH_5)     <= RX0_SW5_B  & RX0_SW5_A;
  rRx0PathControlArray(kRX_SWITCH_6msb downto kRX_SWITCH_6)     <= RX0_SW6_B  & RX0_SW6_A;
  rRx0PathControlArray(kRX_SWITCH_7_8)                          <= RX0_SW7_SW8_CTRL;
  rRx0PathControlArray(kRX_SWITCH_9)                            <= RX0_SW9_V1;
  rRx0PathControlArray(kRX_SWITCH_10)                           <= RX0_SW10_V1;
  rRx0PathControlArray(kRX_SWITCH_11msb downto kRX_SWITCH_11)   <= RX0_SW11_V3 & RX0_SW11_V2 & RX0_SW11_V1;

  rRx1PathControlArray(kRX_SWITCH_1msb downto kRX_SWITCH_1)     <= RX1_SW1_B  & RX1_SW1_A;
  rRx1PathControlArray(kRX_SWITCH_2)                            <= RX1_SW2_A;
  rRx1PathControlArray(kRX_SWITCH_3msb downto kRX_SWITCH_3)     <= RX1_SW3_V3 & RX1_SW3_V2   & RX1_SW3_V1;
  rRx1PathControlArray(kRX_SWITCH_4)                            <= RX1_SW4_A;
  rRx1PathControlArray(kRX_SWITCH_5msb downto kRX_SWITCH_5)     <= RX1_SW5_B  & RX1_SW5_A;
  rRx1PathControlArray(kRX_SWITCH_6msb downto kRX_SWITCH_6)     <= RX1_SW6_B  & RX1_SW6_A;
  rRx1PathControlArray(kRX_SWITCH_7_8)                          <= RX1_SW7_SW8_CTRL;
  rRx1PathControlArray(kRX_SWITCH_9)                            <= RX1_SW9_V1;
  rRx1PathControlArray(kRX_SWITCH_10)                           <= RX1_SW10_V1;
  rRx1PathControlArray(kRX_SWITCH_11msb downto kRX_SWITCH_11)   <= RX1_SW11_V3 & RX1_SW11_V2 & RX1_SW11_V1;

  cRfPowerControlArray(kENABLE_TX_7V0) <= P7V_ENABLE_A;
  cRfPowerControlArray(kENABLE_RX_7V0) <= P7V_ENABLE_B;
  cRfPowerControlArray(kENABLE_3v3)    <= P3D3VA_ENABLE;

  -----------------------------------------------------------------------------------
  --DSA signals
  -----------------------------------------------------------------------------------
  rTx0DsaControlArray(kTX_DSA1Msb downto kTX_DSA1) <= TX0_DSA1(6) & TX0_DSA1(5) & TX0_DSA1(4) & TX0_DSA1(3) & TX0_DSA1(2);
  rTx0DsaControlArray(kTX_DSA2Msb downto kTX_DSA2) <= TX0_DSA2(6) & TX0_DSA2(5) & TX0_DSA2(4) & TX0_DSA2(3) & TX0_DSA2(2);

  rTx1DsaControlArray(kTX_DSA1Msb downto kTX_DSA1) <= TX1_DSA1(6) & TX1_DSA1(5) & TX1_DSA1(4) & TX1_DSA1(3) & TX1_DSA1(2);
  rTx1DsaControlArray(kTX_DSA2Msb downto kTX_DSA2) <= TX1_DSA2(6) & TX1_DSA2(5) & TX1_DSA2(4) & TX1_DSA2(3) & TX1_DSA2(2);

  rRx0DsaControlArray(  kRX_DSA1Msb downto kRX_DSA1)   <= not(RX0_DSA1_n(1)   & RX0_DSA1_n(2)   & RX0_DSA1_n(3)   & RX0_DSA1_n(4));
  rRx0DsaControlArray(  kRX_DSA2Msb downto kRX_DSA2)   <= not(RX0_DSA2_n(1)   & RX0_DSA2_n(2)   & RX0_DSA2_n(3)   & RX0_DSA2_n(4));
  rRx0DsaControlArray(kRX_DSA3_BMsb downto kRX_DSA3_B) <= not(RX0_DSA3_B_n(1) & RX0_DSA3_B_n(2) & RX0_DSA3_B_n(3) & RX0_DSA3_B_n(4));
  rRx0DsaControlArray(kRX_DSA3_AMsb downto kRX_DSA3_A) <= not(RX0_DSA3_A_n(1) & RX0_DSA3_A_n(2) & RX0_DSA3_A_n(3) & RX0_DSA3_A_n(4));

  rRx1DsaControlArray(  kRX_DSA1Msb downto kRX_DSA1)   <= not(RX1_DSA1_n(1)   & RX1_DSA1_n(2)   & RX1_DSA1_n(3)   & RX1_DSA1_n(4));
  rRx1DsaControlArray(  kRX_DSA2Msb downto kRX_DSA2)   <= not(RX1_DSA2_n(1)   & RX1_DSA2_n(2)   & RX1_DSA2_n(3)   & RX1_DSA2_n(4));
  rRx1DsaControlArray(kRX_DSA3_BMsb downto kRX_DSA3_B) <= not(RX1_DSA3_B_n(1) & RX1_DSA3_B_n(2) & RX1_DSA3_B_n(3) & RX1_DSA3_B_n(4));
  rRx1DsaControlArray(kRX_DSA3_AMsb downto kRX_DSA3_A) <= not(RX1_DSA3_A_n(1) & RX1_DSA3_A_n(2) & RX1_DSA3_A_n(3) & RX1_DSA3_A_n(4));

  -----------------------------------------------------------------------------------
  --LED signals
  -----------------------------------------------------------------------------------
  rLedControlReg(kCH0_RX2_LED_EN) <= CH0_RX2_LED;
  rLedControlReg(kCH0_TRX1_LED_ENMsb downto kCH0_TRX1_LED_EN)  <= CH0_TX_LED & CH0_RX_LED;

  rLedControlReg(kCH1_RX2_LED_EN) <= CH1_RX2_LED;
  rLedControlReg(kCH1_TRX1_LED_ENMsb downto kCH1_TRX1_LED_EN)  <= CH1_TX_LED & CH1_RX_LED;

  rLed0ControlReg <= rLedControlReg and x"0000FFFF";
  rLed1ControlReg <= rLedControlReg and x"FFFF0000";

  rLoSyncArray(kTX0_LO1) <= TX0_LO1_SYNC;
  rLoSyncArray(kTX0_LO2) <= TX0_LO2_SYNC;
  rLoSyncArray(kTX1_LO1) <= TX1_LO1_SYNC;
  rLoSyncArray(kTX1_LO2) <= TX1_LO2_SYNC;
  rLoSyncArray(kRX0_LO1) <= RX0_LO1_SYNC;
  rLoSyncArray(kRX0_LO2) <= RX0_LO2_SYNC;
  rLoSyncArray(kRX1_LO1) <= RX1_LO1_SYNC;
  rLoSyncArray(kRX1_LO2) <= RX1_LO2_SYNC;

  LoSyncChecker: process(RefClk, ExpectedLoSync)
    variable LoSyncCompare        : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0) := (others => '0');
    variable ValueChecked         : boolean := true;
  begin
    if EnableChecks then

      -- Update comparison value when a new value is expected. Check that any previous expected value
      -- was met at some point.
      if ExpectedLoSync'event  then
        assert ValueChecked report "Previous SYNC value was never checked" severity note;
        if LoSyncCompare /= ExpectedLoSync then
          LoSyncCompare := ExpectedLoSync;
          ValueChecked  := false;
        end if;
      end if;

      -- Comparison done at falling edge to discard combinatorial logic delays
      if falling_edge(RefClk) then
        -- once the outpus signal updates, compare to local comparison value
        if rLoSyncArray /= rLoSyncArray'delayed(kPrcPeriod) then
          assert rLoSyncArray = LoSyncCompare
            report "LO SYNC signals driven to incorrect value"
            severity error;
          ValueChecked := true;
          -- If registered sync pulses have just asserted, schedule a "pulse cleared" check
          -- for the falling edge of the following clock cycle.
          if SyncIsPulse and rLoSyncArray /= zeros(kLO_CHIP_SELECTSize) then
            CheckSyncDeassertion  <= true;
            LoSyncCompare         := (others => '0');
          end if;
        end if;

        -- Check that sync pulses were cleared one rising edge(+ combinatorial delay)
        -- after assertion
        if CheckSyncDeassertion then
          assert rLoSyncArray = zeros(kLO_CHIP_SELECTSize)
            report "LO SYNC should only pulse for a single clock cycle"
            severity error;
            CheckSyncDeassertion <= false;
        end if;

      end if;
    end if;
  end process;

  main: process
    variable writeData : std_logic_vector(31 downto 0) := (others=>'0');
    variable readData  : std_logic_vector(31 downto 0) := (others=>'0');
    variable regStatus : std_logic_vector(1  downto 0) := (others=>'0');
    variable regAck    : std_logic;

    --vhook_nowarn regStatus regAck

    procedure CheckLoSpiReady is
    begin

      -- Wait for all LO chip selects to assert.
      wait until sLoSlaveCs = ones(kLO_CHIP_SELECTSize) for 5 us;
      assert sLoSlaveCs = ones(kLO_CHIP_SELECTSize)
        report "Expected CSb assertion"
        severity error;

      CtrlPortRead(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_SPI_STATUS, readData, regStatus, regAck);

      -- Check ready signal
      assert readData(kLO_SPI_READY)
        report "SPI failed to be ready"
        severity error;

    end procedure CheckLoSpiReady;

    procedure testLoSpiRdWt is
      variable Data   : std_logic_vector(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA);
      variable Addr   : std_logic_vector(kLO_SPI_WT_ADDRMsb downto kLO_SPI_WT_ADDR);

    begin
      -- Run 10 iterations of spi write/readbacks, alternating between LOs.
      for j in 0 to 9 loop
        --loop for all 8 LOs
        for i in 0 to 7 loop
          CheckLoSpiReady;

          sLoMisoData(i) <= zeros(sLoMisoData(i)'length);

          Data   := Rand.GetStdLogicVector(kLO_SPI_WT_DATASize);
          Addr   := Rand.GetStdLogicVector(kLO_SPI_WT_ADDRSize);

          writeData                                               := (others=>'0');
          writeData(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA)    := Data;
          writeData(kLO_SPI_WT_ADDRMsb   downto kLO_SPI_WT_ADDR)  := Addr;
          writeData(kLO_SPI_RD)                                   := '0';
          writeData(kLO_SELECTMsb    downto kLO_SELECT)           := std_logic_vector(to_unsigned(i,3));
          writeData(kLO_SPI_START_TRANSACTION)                    := '1';
          CtrlPortWrite(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_SPI_SETUP, writeData);

          CheckLoSpiReady;

          --test that data was successfully read by the LO
          assert sLoMosiData(i) = x"00" & '0' & Addr & Data
            report "SPI write data doesn't match for LO " & image(i) & LF &
                   " : Expected " & heximage(x"00" & '0' & Addr & Data) &
                   " : Received " & heximage(sLoMosiData(i))
            severity warning;
          --Check data valid

          CtrlPortRead(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_SPI_STATUS, readData, regStatus, regAck);
          assert readData(kLO_SPI_DATA_VALID) = '0'
            report "DataValid assert when not suppose to for LO " & image(i)
            severity warning;

          --read from SPI device
          sLoMisoData(i) <= std_logic_vector(resize(unsigned(Data), sLoMisoData(i)'length));

          writeData                                               := (others=>'0');
          writeData(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA)    := Data;
          writeData(kLO_SPI_RD_ADDRMsb downto kLO_SPI_RD_ADDR)    := Addr;
          writeData(kLO_SPI_RD)                                   := '1';
          writeData(kLO_SELECTMsb    downto kLO_SELECT)           := std_logic_vector(to_unsigned(i,3));
          writeData(kLO_SPI_START_TRANSACTION)                    := '1';
          CtrlPortWrite(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_SPI_SETUP, writeData);

          CheckLoSpiReady;

          --test that data isn't written in the data field during reads
          assert sLoMosiData(i) = x"00" & '1' & Addr & Data
            report "SPI write data doesn't match for LO " & image(i) & LF &
                   " : Expected " & heximage(x"00" & '1' & Addr & Data) &
                   " : Received " & heximage(sLoMosiData(i))
            severity warning;

          CtrlPortRead(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_SPI_STATUS, readData, regStatus, regAck);
          --compare data
          assert sLoMisoData(i)(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA) = readData(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA)
            report "SPI data did not read correctly during read to LO " & image(i) & LF &
                   " : Expected " & heximage(readData(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA)) &
                   " : Received " & heximage(sLoMisoData(i)(kLO_SPI_WT_DATAMsb downto kLO_SPI_WT_DATA))
            severity warning;
          --Check data valid
          assert readData(kLO_SPI_DATA_VALID) = '1'
            report "DataValid did not assert correctly for LO " & image(i)
            severity warning;

        end loop;
      end loop;

    end procedure testLoSpiRdWt;

    procedure testLoSync is
      variable Data     : std_logic_vector(kLO_CHIP_SELECTSize-1 downto 0);
      variable RandSync : std_logic;

    begin

      -- Test register based propagation
      for j in 0 to 2**kLO_CHIP_SELECTSize - 1 loop --validate all posible combinations

          Data   := std_logic_vector(to_unsigned(j, kLO_CHIP_SELECTSize));

          writeData                             := (others=>'0');
          writeData(kRX1_LO2 downto kTX0_LO1)   := Data;
          writeData(kBYPASS_SYNC_REGISTER)      := '0' ;
          ExpectedLoSync <= Data;
          SyncIsPulse    <= true;
          CtrlPortWrite(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_PULSE_SYNC, writeData);

      end loop;

      SyncIsPulse    <= false;
      ExpectedLoSync <= (others => '0');

      -- Test Bypass propagation
      --------------------------------------------------------------------------------
      -- Verify registered pulses are ignored when bypass is selected
      for j in 0 to 2**kLO_CHIP_SELECTSize - 1 loop --validate all posible combinations

        Data   := std_logic_vector(to_unsigned(j, kLO_CHIP_SELECTSize));

        writeData                             := (others=>'0');
        writeData(kRX1_LO2 downto kTX0_LO1)   := Data;
        writeData(kBYPASS_SYNC_REGISTER)      := '1' ;
        CtrlPortWrite(kDB_CONTROL_WINDOW_SPI + kLO_CONTROL_REGS + kLO_PULSE_SYNC, writeData);

      end loop;

      -- Verify MB_SYNTH_SYNC distribution to LO SYNC signals
      for j in 0 to 10 loop

        -- Assign value to validate.
        RandSync := Rand.GetStdLogic;
        MB_SYNTH_SYNC <= RandSync;
        wait until rising_edge(RefClk);
        -- Value will be compared on falling edge
        ExpectedLoSync <= (others => RandSync);

      end loop;

    end procedure testLoSync;
    -- Validate RF_POWER_STATUS read capabilities
    procedure CheckPG is
      variable PgData : std_logic_vector(1 downto 0);
    begin
      -- test all PG combinations
      for i in 0 to 3 loop
        PgData   := std_logic_vector(to_unsigned(i, 2));
        P7V_PG_A <= PgData(0);
        P7V_PG_B <= PgData(1);
        CheckExpectedCtrlPortRead(kPOWER_REGS + kRF_POWER_STATUS,
                                    SetBit(kP7V_A_STATUS, PgData(0)) or
                                    SetBit(kP7V_B_STATUS, PgData(1)));
      end loop;

    end procedure CheckPG;

    function getRfOptionOffset (
      constant kIsRf0          : in boolean;
      constant kIsDsa          : in boolean
    ) return natural is
    begin
      if kIsDsa then
        if kIsRf0 then
          return kRF0_DSA_OPTION;
        else
          return kRF1_DSA_OPTION;
        end if;
      else
        if kIsRf0 then
          return kRF0_OPTION;
        else
          return kRF1_OPTION;
        end if;
      end if;
    end function getRfOptionOffset;


    procedure checkAtrRegister(
      constant kRegName        : in string;
      constant kRegisterOffset : in natural;
      constant kRegisterStep   : in natural;
      constant kRegisterMask   : in std_logic_vector(31 downto 0);
      constant kIsRf0          : in boolean;
      constant kIsDsa          : in boolean;
      signal   registerOutput  : in std_logic_vector(31 downto 0)
    ) is
      variable dataArray : Slv32Ary_t(0 to 255) := (others => (others => '0'));
      variable rfOptionOffset : natural := getRfOptionOffset(kIsRf0, kIsDsa);
      variable expectedData : std_logic_vector(31 downto 0);
    begin
      -- fill all ATR configurations with data
      for i in dataArray'range loop
        dataArray(i) := Random.GetStdLogicVector(32) and kRegisterMask;
        CtrlPortWrite(kRegisterOffset + i*kRegisterStep, dataArray(i), kGpioThreadId);
      end loop;

      -- check all configurations read-back
      for i in 0 to 255 loop
        CtrlPortRead(kRegisterOffset + i*kRegisterStep, readData, regStatus, regAck, kGpioThreadId);
        CheckExpectedCtrlPortRead(kRegisterOffset + i*kRegisterStep, dataArray(i));
      end loop;

      -- check classical ATR behavior
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kCLASSIC_ATR),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
                                SetField(rfOptionOffset, kCLASSIC_ATR),
                                kGpioThreadId);

      -- try all ATR state combinations
      for i in 0 to 15 loop
        MB_FPGA_GPIO(3 downto 0) <= std_logic_vector(to_unsigned(i, 4));

        CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kCURRENT_CONFIG_REG,
          readData, regStatus, regAck, kGpioThreadId);

        if kIsRf0 then
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i mod 4, kCURRENT_RF0_CONFIGSize))
            report "current classic ATR configuration 0 incorrect" & LF &
              "ATR FPGA state : " & image(i)
            severity error;
          expectedData := dataArray(i mod 4);
        else
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i / 4, kCURRENT_RF1_CONFIGSize))
            report "current classic ATR configuration 1 incorrect" & LF &
              "ATR FPGA state : " & image(i)
            severity error;
          expectedData := dataArray(i / 4);
        end if;

        assert registerOutput = expectedData
          report "classic ATR configuration check failed" & LF &
            "register : " & kRegName & LF &
            "ATR configuration : " & image(i) & LF &
            "expected : " & HexImage(expectedData) & LF &
            "received : " & HexImage(readData)
          severity error;
      end loop;

      -- check combined ATR behavior
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kFPGA_STATE),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
                                SetField(rfOptionOffset, kFPGA_STATE),
                                kGpioThreadId);

      -- try all ATR state combinations
      for i in 0 to 15 loop
        MB_FPGA_GPIO(3 downto 0) <= std_logic_vector(to_unsigned(i, 4));

        CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kCURRENT_CONFIG_REG,
          readData, regStatus, regAck, kGpioThreadId);

        if kIsRf0 then
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i, kCURRENT_RF0_CONFIGSize))
            report "current combined ATR configuration 0 incorrect" & LF &
              "ATR FPGA state : " & image(i)
            severity error;
        else
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i, kCURRENT_RF1_CONFIGSize))
            report "current combined ATR configuration 1 incorrect" & LF &
              "ATR FPGA state : " & image(i)
            severity error;
        end if;

        assert registerOutput = dataArray(i)
          report "combined ATR configuration check failed" & LF &
            "register : " & kRegName & LF &
            "ATR configuration : " & image(i) & LF &
            "expected : " & HexImage(dataArray(i)) & LF &
            "received : " & HexImage(registerOutput)
          severity error;
      end loop;

      -- check SW defined ATR
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
                                SetField(rfOptionOffset, kSW_DEFINED),
                                kGpioThreadId);

      -- try all ATR state combinations
      for i in dataArray'range loop
        -- just assign values to check there is no interaction
        MB_FPGA_GPIO(3 downto 0) <= std_logic_vector(to_unsigned(i/16, 4));

        CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG,
          SetField(rfOptionOffset, i),
          kGpioThreadId);
        CtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kCURRENT_CONFIG_REG,
          readData, regStatus, regAck, kGpioThreadId);

        if kIsRf0 then
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i, kCURRENT_RF0_CONFIGSize))
            report "current SW defined ATR configuration for RF 0 incorrect"
            severity error;
        else
          assert readData(rfOptionOffset+7 downto rfOptionOffset) =
            std_logic_vector(to_unsigned(i, kCURRENT_RF1_CONFIGSize))
            report "current SW defined ATR configuration for RF 1 incorrect"
            severity error;
        end if;

        assert registerOutput = dataArray(i)
          report "SW defined ATR configuration check failed" & LF &
            "register : " & kRegName & LF &
            "ATR configuration : " & image(i) & LF &
            "expected : " & HexImage(dataArray(i)) & LF &
            "received : " & HexImage(registerOutput)
          severity error;
      end loop;

      -- reset to fixed SW config 0 for further testing
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG,
          SetField(rfOptionOffset, 0),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, 0),
          kGpioThreadId);

      MB_FPGA_GPIO(3 downto 0) <= (others => '0');

    end procedure checkAtrRegister;

    procedure checkGainTable(
      constant kTableName         : in string;
      constant kTableOffset       : in natural;
      constant kTableSelectOffset : in natural;
      constant kRegisterOffset    : in natural;
      constant kStep              : in natural;
      constant kMask              : in std_logic_vector(31 downto 0);
      constant kIsRf0             : in boolean;
      signal   registerOutput     : in std_logic_vector(31 downto 0)
    ) is
      variable dataArray : Slv32Ary_t(0 to 255) := (others => (others => '0'));
      variable rfOptionOffset : natural := getRfOptionOffset(kIsRf0, true);
      variable targetAtrIndex : natural;
    begin
      -- fill all gain table entries with data
      for i in dataArray'range loop
        dataArray(i) := Random.GetStdLogicVector(32) and kMask;
        CtrlPortWrite(kTableOffset + i*kStep, dataArray(i), kGpioThreadId);
      end loop;

      -- check gain table read-back
      for i in 0 to 255 loop

        CheckExpectedCtrlPortRead(kTableOffset + i*kStep, dataArray(i));

      end loop;

      -- switch to SW defined ATR
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      -- write each gain table entry to one ATR configuration, select this
      -- configuration and check output.
      for i in dataArray'range loop
        targetAtrIndex := Random.GetNatural(256);
        CtrlPortWrite(kTableSelectOffset + kStep*targetAtrIndex,
          SetField(kTABLE_INDEX, i),
          kGpioThreadId);
        CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG,
          SetField(rfOptionOffset, targetAtrIndex),
          kGpioThreadId);
        CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG,
          SetField(rfOptionOffset, targetAtrIndex),
          kGpioThreadId);

        assert registerOutput = dataArray(i)
          report "gain table ATR configuration check failed" & LF &
            "table : " & kTableName & LF &
            "index : " & image(i) & LF &
            "ATR configuration : " & image(targetAtrIndex) & LF &
            "expected : " & HexImage(dataArray(i)) & LF &
            "received : " & HexImage(registerOutput) & LF &
            "debug : " & image(kStep) & " " & image(rfOptionOffset)
          severity error;
      end loop;

      -- reset to fixed SW config 0 for further testing
      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, kSW_DEFINED),
          kGpioThreadId);

      CtrlPortWrite(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kSW_CONFIG_REG,
          SetField(rfOptionOffset, 0),
          kGpioThreadId);

      CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_GPIO + kATR_CONTROLLER_REGS + kOPTION_REG,
          SetField(rfOptionOffset, 0),
          kGpioThreadId);
      MB_FPGA_GPIO(3 downto 0) <= (others => '0');
    end procedure checkGainTable;

  begin

    -- Display the value of the TestStatus string
    VPrint(TestStatus);

    --initialize CPLD
    CTRL_REG_ARST <= '1';
    wait for resetDuration;

    wait until rising_edge(CTRL_REG_CLK);
    CTRL_REG_ARST <= '0';

    wait until rising_edge(RefClk);
    prcReset <= false;
    EnableChecks <= true;

    sLoMisoData <= (others=>x"00000000");

    --out of reset scratch check
    CheckExpectedCtrlPortRead(kBASE_WINDOW_SPI + kSLAVE_SCRATCH, x"00000000");

    -- check remainder of constant registers
    CheckExpectedCtrlPortRead(kBASE_WINDOW_SPI + kSLAVE_SIGNATURE,
        std_logic_vector(to_unsigned(kBOARD_ID_VALUE,readData'length)));

    CheckExpectedCtrlPortRead(kBASE_WINDOW_SPI + kSLAVE_REVISION,
        std_logic_vector(to_unsigned(kCPLD_REVISION,readData'length)));

    CheckExpectedCtrlPortRead(kBASE_WINDOW_SPI + kSLAVE_OLDEST_REVISION,
        std_logic_vector(to_unsigned(kOLDEST_CPLD_REVISION,readData'length)));

    -- Check default git has value and register propagation
    CheckExpectedCtrlPortRead(kBASE_WINDOW_SPI + kGIT_HASH_REGISTER,x"DEADBEEF");

    --issue reset once more to make sure the SPI slave functionality is not
    --affected by an additional reset
    wait until rising_edge(CTRL_REG_CLK);
    CTRL_REG_ARST <= '1';
    wait for resetDuration;
    wait until rising_edge(CTRL_REG_CLK);
    CTRL_REG_ARST <= '0';
    wait for resetDuration;

    -- check GPIO access with PLL ref clock disable -> PkgScoreboard to allow
    -- for one error due to expected timeout on slave side
    gScoreboard.SetExpectedNumHits("*ReponseStatus", 1, 1);
    CtrlPortRead(kBASE_WINDOW_GPIO + kSLAVE_SCRATCH, readData, regStatus, regAck, kGpioThreadId);
    assert regStatus = "01" report "GPIO access without PRC is expected to fail with CTRL_STS_CMDERR" severity error;

    -- enable PLL ref clock for further testing
    CtrlPortWrite(kPOWER_REGS + kPRC_CONTROL, SetBit(kPLL_REF_CLOCK_ENABLE));
    -- validate read-back

    CheckExpectedCtrlPortRead(kPOWER_REGS + kPRC_CONTROL, SetBit(kPLL_REF_CLOCK_ENABLE));

    --out of reset led check
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kLED_SETUP_REGS + kLED_CONTROL(0), x"00000000");

    --out of reset Switch check
    TestStatus <= rs("Gain Control Check..."); wait for 0 ns;
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kTX0_PATH_CONTROL(0), x"00000000");
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kTX1_PATH_CONTROL(0), x"00000000");
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kRX0_PATH_CONTROL(0), x"00000000");
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kRX1_PATH_CONTROL(0), x"00000000");

    -- -- out of reset DSA check
    -- -- out of reset value should read 0 to not power the control lines before
    -- -- enable power to the switches
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kTX0_DSA_ATR(0), kTX_DSA_CONTROLMask);
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kTX1_DSA_ATR(0), kTX_DSA_CONTROLMask);
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kRX0_DSA_ATR(0), kRX_DSA_CONTROLMask);
    CheckExpectedCtrlPortRead(kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kRX1_DSA_ATR(0), kRX_DSA_CONTROLMask);

    -- check GPIO -> base regs connection
    CtrlPortWrite(kBASE_WINDOW_GPIO + kSLAVE_SCRATCH, X"02468ACE", kGpioThreadId);
    CheckExpectedCtrlPortRead(kBASE_WINDOW_GPIO + kSLAVE_SCRATCH, X"02468ACE", kGpioThreadId);

    -- PowerGood validation
    CheckPG;

    ----------------------------------------------------------------------------
    -- gain table check
    ----------------------------------------------------------------------------
    checkGainTable (
      kTableName         => "TX0",
      kRegisterOffset    => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_ATR(0),
      kTableOffset       => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_TABLE(0),
      kTableSelectOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_TABLE_SELECT(0),
      kStep              => kTX0_DSA_ATR(1) - kTX0_DSA_ATR(0),
      kMask              => kTX_DSA_CONTROLMask,
      RegisterOutput     => rTx0DsaControlArray,
      kIsRf0             => true);
    checkGainTable (
      kTableName         => "TX1",
      kRegisterOffset    => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX1_DSA_ATR(0),
      kTableOffset       => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX1_DSA_TABLE(0),
      kTableSelectOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX1_DSA_TABLE_SELECT(0),
      kStep              => kTX1_DSA_ATR(1) - kTX1_DSA_ATR(0),
      kMask              => kTX_DSA_CONTROLMask,
      RegisterOutput     => rTx1DsaControlArray,
      kIsRf0             => false);
    checkGainTable (
      kTableName         => "RX0",
      kRegisterOffset    => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX0_DSA_ATR(0),
      kTableOffset       => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX0_DSA_TABLE(0),
      kTableSelectOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX0_DSA_TABLE_SELECT(0),
      kStep              => kRX0_DSA_ATR(1) - kRX0_DSA_ATR(0),
      kMask              => kRX_DSA_CONTROLMask,
      RegisterOutput     => rRx0DsaControlArray,
      kIsRf0             => true);
    checkGainTable (
      kTableName         => "RX1",
      kRegisterOffset    => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX1_DSA_ATR(0),
      kTableOffset       => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX1_DSA_TABLE(0),
      kTableSelectOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX1_DSA_TABLE_SELECT(0),
      kStep              => kRX1_DSA_ATR(1) - kRX1_DSA_ATR(0),
      kMask              => kRX_DSA_CONTROLMask,
      RegisterOutput     => rRx1DsaControlArray,
      kIsRf0             => false);


    ----------------------------------------------------------------------------
    -- ATR Register checks
    ----------------------------------------------------------------------------
    checkAtrRegister (
      kRegName        => "TX0_DSA_ATR",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX0_DSA_ATR(0),
      kRegisterStep   => kTX0_DSA_ATR(1) - kTX0_DSA_ATR(0),
      kRegisterMask   => kTX_DSA_CONTROLMask,
      RegisterOutput  => rTx0DsaControlArray,
      kIsRf0          => true,
      kIsDsa          => true);
    checkAtrRegister (
      kRegName        => "RX0_DSA_ATR",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX0_DSA_ATR(0),
      kRegisterStep   => kRX0_DSA_ATR(1) - kRX0_DSA_ATR(0),
      kRegisterMask   => kRX_DSA_CONTROLMask,
      RegisterOutput  => rRx0DsaControlArray,
      kIsRf0          => true,
      kIsDsa          => true);
    checkAtrRegister (
      kRegName        => "TX1_DSA_ATR",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kTX1_DSA_ATR(0),
      kRegisterStep   => kTX1_DSA_ATR(1) - kTX1_DSA_ATR(0),
      kRegisterMask   => kTX_DSA_CONTROLMask,
      RegisterOutput  => rTx1DsaControlArray,
      kIsRf0          => false,
      kIsDsa          => true);
    checkAtrRegister (
      kRegName        => "RX1_DSA_ATR",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kDSA_SETUP_REGS + kRX1_DSA_ATR(0),
      kRegisterStep   => kRX1_DSA_ATR(1) - kRX1_DSA_ATR(0),
      kRegisterMask   => kRX_DSA_CONTROLMask,
      RegisterOutput  => rRx1DsaControlArray,
      kIsRf0          => false,
      kIsDsa          => true);

    checkAtrRegister (
      kRegName        => "TX0_PATH_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kSWITCH_SETUP_REGS + kTX0_PATH_CONTROL(0),
      kRegisterStep   => kTX0_PATH_CONTROL(1) - kTX0_PATH_CONTROL(0),
      kRegisterMask   => kTX_PATH_CONTROLMask,
      RegisterOutput  => rTx0PathControlArray,
      kIsRf0          => true,
      kIsDsa          => false);
    checkAtrRegister (
      kRegName        => "RX0_PATH_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kSWITCH_SETUP_REGS + kRX0_PATH_CONTROL(0),
      kRegisterStep   => kRX0_PATH_CONTROL(1) - kRX0_PATH_CONTROL(0),
      kRegisterMask   => (kRX_PATH_CONTROLMask),
      RegisterOutput  => rRx0PathControlArray,
      kIsRf0          => true,
      kIsDsa          => false);
    checkAtrRegister (
      kRegName        => "TX1_PATH_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kSWITCH_SETUP_REGS + kTX1_PATH_CONTROL(0),
      kRegisterStep   => kTX1_PATH_CONTROL(1) - kTX1_PATH_CONTROL(0),
      kRegisterMask   => kTX_PATH_CONTROLMask,
      RegisterOutput  => rTx1PathControlArray,
      kIsRf0          => false,
      kIsDsa          => false);
    checkAtrRegister (
      kRegName        => "RX1_PATH_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kSWITCH_SETUP_REGS + kRX1_PATH_CONTROL(0),
      kRegisterStep   => kRX1_PATH_CONTROL(1) - kRX1_PATH_CONTROL(0),
      kRegisterMask   => (kRX_PATH_CONTROLMask),
      RegisterOutput  => rRx1PathControlArray,
      kIsRf0          => false,
      kIsDsa          => false);

    -- apply 2 different masks to test RF1 and RF0 behavior separately
    checkAtrRegister (
      kRegName        => "LED_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kLED_SETUP_REGS + kLED_CONTROL(0),
      kRegisterStep   => kLED_CONTROL(1) - kLED_CONTROL(0),
      kRegisterMask   => kLED_CONTROL_TYPEMask and x"0000FFFF",
      RegisterOutput  => rLed0ControlReg,
      kIsRf0          => true,
      kIsDsa          => false);
    checkAtrRegister (
      kRegName        => "LED_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_GPIO + kLED_SETUP_REGS + kLED_CONTROL(0),
      kRegisterStep   => kLED_CONTROL(1) - kLED_CONTROL(0),
      kRegisterMask   => kLED_CONTROL_TYPEMask and x"FFFF0000",
      RegisterOutput  => rLed1ControlReg,
      kIsRf0          => false,
      kIsDsa          => false);

    ----------------------------------------------------------------------------
    -- LO CONTROL
    ----------------------------------------------------------------------------

    -- test SPI Masters
    testLoSpiRdWt;

    -- Validate LO_SYNC signals propagation
    testLoSync;

    ----------------------------------------------------------------------------
    -- Bit assignment checks
    ----------------------------------------------------------------------------
    --Test LED Reg
    TestStatus <= rs("LED Regs..."); wait for 0 ns;
    TestCtrlPortReg (
      kRegName        => "LED_CONTROL",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kLED_SETUP_REGS + kLED_CONTROL(0),
      kRegisterMask   => kLED_CONTROL_TYPEMask,
      RegisterOutput  => rLedControlReg,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestStatus <= rs("CPLD Status Regs..."); wait for 0 ns;

    --Test Scratch Reg
    TestCtrlPortReg (
      kRegName        => "ScratchReg ",
      kRegisterOffset => kBASE_WINDOW_SPI + kSLAVE_SCRATCH,
      kRegisterMask   => kSLAVE_SCRATCHMask,
      RegisterOutput  => cScratchReg,
      kCheckRegOutput => false,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestStatus <= rs("PS Control Check..."); wait for 0 ns;
    TestCtrlPortReg (
      kRegName        => "RF_POWER_CONTROL ",
      kRegisterOffset => kPOWER_REGS + kRF_POWER_CONTROL,
      kRegisterMask   => kRF_POWER_CONTROLMask,
      RegisterOutput  => cRfPowerControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    --Test switch and power registers
    TestStatus <= rs("Gain Control Check..."); wait for 0 ns;
    TestCtrlPortReg (
      kRegName        => "TX0_PATH_CONTROL ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kTX0_PATH_CONTROL(0),
      kRegisterMask   => kTX_PATH_CONTROLMask,
      RegisterOutput  => rTx0PathControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "TX1_PATH_CONTROL ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kTX1_PATH_CONTROL(0),
      kRegisterMask   => kTX_PATH_CONTROLMask,
      RegisterOutput  => rTx1PathControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "RX0_PATH_CONTROL ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kRX0_PATH_CONTROL(0),
      kRegisterMask   => (kRX_PATH_CONTROLMask),
      RegisterOutput  => rRx0PathControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "RX1_PATH_CONTROL ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kSWITCH_SETUP_REGS + kRX1_PATH_CONTROL(0),
      kRegisterMask   => (kRX_PATH_CONTROLMask),
      RegisterOutput  => rRx1PathControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    --Test DSA registers
    TestCtrlPortReg (
      kRegName        => "TX0_DSA_ATR ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kTX0_DSA_ATR(0),
      kRegisterMask   => kTX_DSA_CONTROLMask,
      RegisterOutput  => rTx0DsaControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "TX1_DSA_ATR ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kTX1_DSA_ATR(0),
      kRegisterMask   => kTX_DSA_CONTROLMask,
      RegisterOutput  => rTx1DsaControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "RX0_DSA_ATR ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kRX0_DSA_ATR(0),
      kRegisterMask   => kRX_DSA_CONTROLMask,
      RegisterOutput  => rRx0DsaControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    TestCtrlPortReg (
      kRegName        => "RX1_DSA_ATR ",
      kRegisterOffset => kDB_CONTROL_WINDOW_SPI + kDSA_SETUP_REGS + kRX1_DSA_ATR(0),
      kRegisterMask   => kRX_DSA_CONTROLMask,
      RegisterOutput  => rRx1DsaControlArray,
      kCheckRegOutput => true,
      kWaitTimeout    => kCtrlPort50MhzPeriod);

    -- simple flash test - for more detailed test see MB CPLD test, which uses
    -- the same reconfiguration engine:
    -- fpga\nitools\x400\mb_cpld\sim\mb_cpld_tb.vhd

    -- check initial status
    CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_STATUS_REG,
                              SetBits((kFLASH_MEM_INIT_ENABLED,
                                       kFLASH_WRITE_IDLE,
                                       kFLASH_ERASE_IDLE,
                                       kFLASH_READ_IDLE,
                                       kFLASH_WP_ENABLED)));

    -- Check start address.
    -- For the ZBX CPLD memory initialization is enabled.
    -- Internal Configuration set to Single Compressed Image with Memory Initialization.
    CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_CFM0_START_ADDR_REG,
        std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_START_ADDR_MEM_INIT, readData'length)));

    CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_CFM0_END_ADDR_REG,
        std_logic_vector(to_unsigned(kFLASH_PRIMARY_IMAGE_END_ADDR, readData'length)));

    -- issue read which should be done when reading from status register
    -- expecting all ones as initial value of flash
    CtrlPortWrite(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_READ_STB));

    CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_STATUS_REG,
                              SetBits((kFLASH_MEM_INIT_ENABLED,
                                       kFLASH_WRITE_IDLE,
                                       kFLASH_ERASE_IDLE,
                                       kFLASH_READ_IDLE,
                                       kFLASH_WP_ENABLED)));

    CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_READ_DATA_REG, Ones(readData'length));

    -- write to start address of each sector once
    for i in kSectorStartAddresses'range loop
      -- write data
      CtrlPortWrite(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_DISABLE_WP_STB));
      CtrlPortWrite(kRECONFIG + kFLASH_ADDR_REG, SetField(0, kSectorStartAddresses(i)/4));
      CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_ADDR_REG, SetField(0, kSectorStartAddresses(i)/4));

      CtrlPortWrite(kRECONFIG + kFLASH_WRITE_DATA_REG, SetField(0,16#12345678#+i));
      CtrlPortWrite(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_WRITE_STB));
      l1: for j in 0 to 1000 loop
        CtrlPortRead(kRECONFIG + kFLASH_STATUS_REG, readData, regStatus, regAck);
        exit l1 when readData(kFLASH_WRITE_IDLE) = '1';
      end loop;
      CtrlPortWrite(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_ENABLE_WP_STB));

      -- Flash should go back to Idle after a write
      CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_STATUS_REG,
      SetBits((kFLASH_MEM_INIT_ENABLED,
               kFLASH_WRITE_IDLE,
               kFLASH_ERASE_IDLE,
               kFLASH_READ_IDLE,
               kFLASH_WP_ENABLED)));

      -- verify data
      CtrlPortWrite(kRECONFIG + kFLASH_CONTROL_REG, SetBit(kFLASH_READ_STB));
      -- Flash should go back to Idle after a read
      CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_STATUS_REG,
      SetBits((kFLASH_MEM_INIT_ENABLED,
               kFLASH_WRITE_IDLE,
               kFLASH_ERASE_IDLE,
               kFLASH_READ_IDLE,
               kFLASH_WP_ENABLED)));
      --Verify data read
      CheckExpectedCtrlPortRead(kRECONFIG + kFLASH_READ_DATA_REG, SetField(0,16#12345678#+i));
    end loop;

    -- end of simulation
    StopSim <= true;

    -- simulation does not end automatically (on-chip flash sim model keeps generating stimulus)
    Finish(1);
    wait;

  end process;
end test;

//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: mb_cpld
// Description:
// Top level file for the X4xx motherboard CPLD.

//XmlParse xml_on
//<top name="X4XX_MB_CPLD">
//  <regmapcfg readablestrobes="false">
//    <map name="MB_CPLD_PS_REGMAP"/>
//    <map name="MB_CPLD_PL_REGMAP"/>
//  </regmapcfg>
//</top>
//<regmap name="MB_CPLD_PS_REGMAP" readablestrobes="false" markdown="true" generatevhdl="true" ettusguidelines="true">
//  <info>
//    This register map is available using the PS CPLD SPI interface.
//  </info>
//  <group name="MB_CPLD_PS_WINDOWS">
//    <window name="PS_REGISTERS"    offset="0x00" size="0x40" targetregmap="PS_CPLD_BASE_REGMAP"/>
//    <window name="RECONFIG"        offset="0x40" size="0x20" targetregmap="RECONFIG_REGMAP"/>
//    <window name="POWER_REGISTERS" offset="0x60" size="0x20" targetregmap="PS_POWER_REGMAP"/>
//  </group>
//  <group name="PS_SPI_ENDPOINTS">
//    <enumeratedtype name="SPI_ENDPOINT">
//      <value name="PS_CS_MB_CPLD"        integer="0"/>
//      <value name="PS_CS_LMK32"          integer="1"/>
//      <value name="PS_CS_TPM"            integer="2"/>
//      <value name="PS_CS_PHASE_DAC"      integer="3"/>
//      <value name="PS_CS_DB0_CAL_EEPROM" integer="4"/>
//      <value name="PS_CS_DB1_CAL_EEPROM" integer="5"/>
//      <value name="PS_CS_CLK_AUX_DB"     integer="6"/>
//      <value name="PS_CS_IDLE"           integer="7"/>
//    </enumeratedtype>
//  </group>
//</regmap>
//<regmap name="MB_CPLD_PL_REGMAP" readablestrobes="false" markdown="true" generatevhdl="true" ettusguidelines="true">
//  <info>
//    This register map is available using the PL CPLD SPI interface.
//    All protocol masters controller by this register map are running with a clock frequency of 50 MHz.
//  </info>
//  <group name="MB_CPLD_PL_WINDOWS">
//    <window name="PL_REGISTERS" offset="0x0" size="0x40" targetregmap="PL_CPLD_BASE_REGMAP"/>
//    <window name="JTAG_DB0" offset="0x60" size="0x20" targetregmap="JTAG_REGMAP">
//      <info>
//        JTAG Master connected to first daugherboard's CPLD JTAG interface.
//
//        **Use minimum value of 1 for @.JTAG_REGMAP.prescalar because the DB CPLD JTAG interface maximum clock frequency is 20 MHz.**
//      </info>
//    </window>
//    <window name="JTAG_DB1" offset="0x80" size="0x20" targetregmap="JTAG_REGMAP">
//      <info>
//        JTAG Master connected to second daugherboard's CPLD JTAG interface.
//
//        **Use minimum value of 1 for @.JTAG_REGMAP.prescalar because the DB CPLD JTAG interface maximum clock frequency is 20 MHz.**
//      </info>
//    </window>
//  </group>
//</regmap>
//<regmap name="CONSTANTS_REGMAP" readablestrobes="false" generatevhdl="true" ettusguidelines="true">
//  <group name="CONSTANTS_GROUP">
//    <info>
//      Basic registers containing version and capabilities information.
//    </info>

//    <enumeratedtype name="CONSTANTS_ENUM" showhexvalue="true">
//      <info>
//        This enumeration is used to create the constants held in the basic registers.
//      </info>
//      <value name="PS_CPLD_SIGNATURE"     integer="0x0A522D27"/>
//      <value name="PL_CPLD_SIGNATURE"     integer="0x3FDC5C47"/>
//      <value name="CPLD_REVISION"         integer="0x21012015"/>
//      <value name="OLDEST_CPLD_REVISION"  integer="0x20122114"/>
//    </enumeratedtype>
//  </group>
//</regmap>
//XmlParse xml_off

module mb_cpld #(
  parameter SIMULATION = 0 // set to 1 to speedup simulation
)(
  //---------------------------------------------------------------
  // Clocking
  //---------------------------------------------------------------
  // CPLD's PLL reference clock (differential input - abbreviation: pclk)
  input  wire PLL_REF_CLK,

  // Reliable clock (100 MHz; differential input)
  input  wire CLK_100,

  //---------------------------------------------------------------
  // Power supplies
  //---------------------------------------------------------------
  // Power supply clocks
  output wire PWR_SUPPLY_CLK_CORE,
  output wire PWR_SUPPLY_CLK_DDR4_S,
  output wire PWR_SUPPLY_CLK_DDR4_N,
  output wire PWR_SUPPLY_CLK_0P9V,
  output wire PWR_SUPPLY_CLK_1P8V,
  output wire PWR_SUPPLY_CLK_2P5V,
  output wire PWR_SUPPLY_CLK_3P3V,
  output wire PWR_SUPPLY_CLK_3P6V,

  // Power supply control
  output wire       PWR_EN_5V_OSC_100,
  output wire       PWR_EN_5V_OSC_122_88,
  output wire       IPASS_POWER_DISABLE,
  input  wire [1:0] IPASS_POWER_EN_FAULT,

  //---------------------------------------------------------------
  // Interfaces from/to RFSoC
  //---------------------------------------------------------------
  // PL SPI slave interface
  input  wire       PL_CPLD_SCLK,
  input  wire       PL_CPLD_MOSI,
  output reg        PL_CPLD_MISO,
  input  wire [1:0] PL_CPLD_CS_N,

  // IRQ to PL
  output wire       PL_CPLD_IRQ,

  // PS SPI slave interface
  // Chip Selects:
  //   PS_CPLD_CS_N(2:0) -> binary encoded chip select
  //   PS_CPLD_CS_N(3) -> chip select "enable"
  input  wire       PS_CPLD_SCLK,
  input  wire       PS_CPLD_MOSI,
  output wire       PS_CPLD_MISO,
  input  wire [3:0] PS_CPLD_CS_N,

  //---------------------------------------------------------------
  // PL Interfaces to/from motherboard
  //---------------------------------------------------------------
  // Clocking AUX board SPI master interface
  output wire CLK_DB_SCLK,
  output wire CLK_DB_MOSI,
  input  wire CLK_DB_MISO,
  output wire CLK_DB_CS_N,

  // QSFP LEDs
  // Port 0
  output wire  [3:0] QSFP0_LED_ACTIVE,
  output wire  [3:0] QSFP0_LED_LINK,
  // Port 1
  output wire  [3:0] QSFP1_LED_ACTIVE,
  output wire  [3:0] QSFP1_LED_LINK,

  // Daughterboard control interface
  // 1 -> DB1 / 0 -> DB0
  output reg  [ 1:0] DB_CTRL_SCLK,
  output reg  [ 1:0] DB_CTRL_MOSI,
  input  wire [ 1:0] DB_CTRL_MISO,
  output reg  [ 1:0] DB_CTRL_CS_N,
  output wire [ 1:0] DB_REF_CLK,
  output wire [ 1:0] DB_ARST,

  // Daughterboards' JTAG master interfaces.
  // 1 -> DB1 / 0 -> DB0
  output wire [1:0] DB_JTAG_TCK,
  output wire [1:0] DB_JTAG_TDI, // from CPLD to DB
  input  wire [1:0] DB_JTAG_TDO, // from DB to CPLD
  output wire [1:0] DB_JTAG_TMS,

  //---------------------------------------------------------------
  // PS Interfaces to/from motherboard
  //---------------------------------------------------------------
  // LMK04832 SPI master interface
  output wire LMK32_SCLK,
  output wire LMK32_MOSI,
  input  wire LMK32_MISO,
  output wire LMK32_CS_N,

  // TPM 2.0 SPI master interface
  output wire TPM_SCLK,
  output wire TPM_MOSI,
  input  wire TPM_MISO,
  output wire TPM_CS_N,

  // Phase DAC SPI master interface
  output wire PHASE_DAC_SCLK,
  output wire PHASE_DAC_MOSI,
  output wire PHASE_DAC_CS_N,

  // DIO direction control
  output wire [11:0] DIO_DIRECTION_A,
  output wire [11:0] DIO_DIRECTION_B,

  // Daughterboard calibration EEPROM SPI
  // 1 -> DB1 / 0 -> DB0
  output wire [ 1:0] DB_CALEEPROM_SCLK,
  output wire [ 1:0] DB_CALEEPROM_MOSI,
  input  wire [ 1:0] DB_CALEEPROM_MISO,
  output wire [ 1:0] DB_CALEEPROM_CS_N,

  //---------------------------------------------------------------
  // Miscellaneous
  //---------------------------------------------------------------
  // This signal enables the 1.8 V and 3.3 V power supply clocks.
  output wire PS_CLK_ON_CPLD,

  // iPASS control interface
  //vhook_nowarn id=CP14 msg={IPASS_PRESENT_N}
  input  wire [1:0] IPASS_PRESENT_N,
  inout  wire [1:0] IPASS_SCL,
  inout  wire [1:0] IPASS_SDA,

  // PCIe reset to FPGA
  output wire PCIE_RESET,

  // TPM reset
  output wire TPM_RESET_n
);

// SPI masters (spi_top) are limited to 64 bit transmission length
`define SPI_MAX_CHAR_64

`include "../../../lib/rfnoc/core/ctrlport.vh"
`include "regmap/mb_cpld_ps_regmap_utils.vh"
`include "regmap/mb_cpld_pl_regmap_utils.vh"

//---------------------------------------------------------------
// Clocks and reset
//---------------------------------------------------------------
wire clk40, clk50, clk250;
wire pll_ref_clk_int;

wire reset_clk50;
wire reset_clk40;
wire power_on_reset_clk100;

wire [0:0] pll_locked_async;
wire [0:0] pll_locked_clk50;
wire [0:0] pll_locked_clk40;

wire pll_ref_clk_en_clk50;
wire pll_ref_clk_en_pclk;

//vhook reset_generator reliable_reset_gen_inst
//vhook_a clk CLK_100
//vhook_a power_on_reset power_on_reset_clk100
reset_generator
  reliable_reset_gen_inst (
    .clk             (CLK_100),                 //in  wire
    .power_on_reset  (power_on_reset_clk100));  //out wire

// Divide reliable clock by 2 since the design is not capable of running at
// 100 MHz. Multiple by 2.5 to get a fast clock to handle PS SPI chip select
// decoding.
//vhook pll pll_inst
//vhook_a inclk0 CLK_100
//vhook_a c0 clk50
//vhook_a c1 clk250
//vhook_a c2 clk40
//vhook_a locked pll_locked_async
pll
  pll_inst (
    .inclk0  (CLK_100),            //in  wire
    .c0      (clk50),              //out wire
    .c1      (clk250),             //out wire
    .c2      (clk40),              //out wire
    .locked  (pll_locked_async));  //out wire

// Bring pll_ref_clk enable signal to the same clock domain.
//vhook synchronizer pll_ref_clk_en_sync
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk PLL_REF_CLK
//vhook_a rst 1'b0
//vhook_a in pll_ref_clk_en_clk50
//vhook_a out pll_ref_clk_en_pclk
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  pll_ref_clk_en_sync (
    .clk  (PLL_REF_CLK),           //in  wire
    .rst  (1'b0),                  //in  wire
    .in   (pll_ref_clk_en_clk50),  //in  wire[(WIDTH-1):0]
    .out  (pll_ref_clk_en_pclk));  //out wire[(WIDTH-1):0]

// Enable clock using ALTCLKCTRL IP.
clkctrl pll_ref_clk_ctrl_inst (
  .inclk  (PLL_REF_CLK),
  .ena    (pll_ref_clk_en_pclk),
  .outclk (pll_ref_clk_int)
);

// use locked signal as reset for clk50 and clk40 clock domain
//vhook synchronizer clk50_reset_sync
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk clk50
//vhook_a rst 1'b0
//vhook_a in pll_locked_async
//vhook_a out pll_locked_clk50
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  clk50_reset_sync (
    .clk  (clk50),              //in  wire
    .rst  (1'b0),               //in  wire
    .in   (pll_locked_async),   //in  wire[(WIDTH-1):0]
    .out  (pll_locked_clk50));  //out wire[(WIDTH-1):0]

assign reset_clk50 = ~pll_locked_clk50;

//vhook synchronizer clk40_reset_sync
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk clk40
//vhook_a rst 1'b0
//vhook_a in pll_locked_async
//vhook_a out pll_locked_clk40
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  clk40_reset_sync (
    .clk  (clk40),              //in  wire
    .rst  (1'b0),               //in  wire
    .in   (pll_locked_async),   //in  wire[(WIDTH-1):0]
    .out  (pll_locked_clk40));  //out wire[(WIDTH-1):0]

assign reset_clk40 = ~pll_locked_clk40;

//---------------------------------------------------------------
// Power supply clock
//---------------------------------------------------------------
// Frequency definition
localparam SOUCE_CLOCK_FREQUENCY = 100_000_000;
localparam TARGET_FREQUENCY_350k =     350_000;
localparam TARGET_FREQUENCY_450k =     450_000;
localparam TARGET_FREQUENCY_500k =     500_000;
localparam TARGET_FREQUENCY_600k =     600_000;
localparam TARGET_FREQUENCY_800k =     800_000;
localparam TARGET_FREQUENCY_1M   =   1_000_000;

//vhook pwr_supply_clk_gen freq_gen_350k
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_350k
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk PWR_SUPPLY_CLK_0P9V
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_350k))   //integer:=100000
  freq_gen_350k (
    .clk             (CLK_100),               //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (PWR_SUPPLY_CLK_0P9V));  //out wire

wire pwr_supply_clk_450k;
//vhook pwr_supply_clk_gen freq_gen_450k
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_450k
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk pwr_supply_clk_450k
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_450k))   //integer:=100000
  freq_gen_450k (
    .clk             (CLK_100),               //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (pwr_supply_clk_450k));  //out wire
assign PWR_SUPPLY_CLK_DDR4_S = pwr_supply_clk_450k;
assign PWR_SUPPLY_CLK_DDR4_N = pwr_supply_clk_450k;

//vhook pwr_supply_clk_gen freq_gen_500k
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_500k
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk PWR_SUPPLY_CLK_CORE
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_500k))   //integer:=100000
  freq_gen_500k (
    .clk             (CLK_100),               //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (PWR_SUPPLY_CLK_CORE));  //out wire

//vhook pwr_supply_clk_gen freq_gen_600k
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_600k
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk PWR_SUPPLY_CLK_1P8V
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_600k))   //integer:=100000
  freq_gen_600k (
    .clk             (CLK_100),               //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (PWR_SUPPLY_CLK_1P8V));  //out wire

//vhook pwr_supply_clk_gen freq_gen_800k
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_800k
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk PWR_SUPPLY_CLK_2P5V
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_800k))   //integer:=100000
  freq_gen_800k (
    .clk             (CLK_100),               //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (PWR_SUPPLY_CLK_2P5V));  //out wire

wire pwr_supply_clk_1M;
//vhook pwr_supply_clk_gen freq_gen_1M
//vhook_a SOURCE_CLK_FREQ SOUCE_CLOCK_FREQUENCY
//vhook_a TARGET_CLK_FREQ TARGET_FREQUENCY_1M
//vhook_a clk CLK_100
//vhook_a rst power_on_reset_clk100
//vhook_a pwr_supply_clk pwr_supply_clk_1M
pwr_supply_clk_gen
  # (
    .SOURCE_CLK_FREQ  (SOUCE_CLOCK_FREQUENCY),   //integer:=100000000
    .TARGET_CLK_FREQ  (TARGET_FREQUENCY_1M))     //integer:=100000
  freq_gen_1M (
    .clk             (CLK_100),             //in  wire
    .rst             (power_on_reset_clk100), //in  wire
    .pwr_supply_clk  (pwr_supply_clk_1M));  //out wire

assign PWR_SUPPLY_CLK_3P3V = pwr_supply_clk_1M;
assign PWR_SUPPLY_CLK_3P6V = pwr_supply_clk_1M;

//---------------------------------------------------------------
// PL Interfaces
//---------------------------------------------------------------
wire [1:0] db_clk_enable;
wire [1:0] db_reset;
wire [1:0] ipass_cable_present;

// Clocks and reset
oddr
  db0_clk_out (
    .outclock  (clk50),
    .din       ({1'b0, db_clk_enable[0]}),
    .pad_out   (DB_REF_CLK[0]),
    .aclr      (reset_clk50));

oddr
  db1_clk_out (
    .outclock  (clk50),
    .din       ({1'b0, db_clk_enable[1]}),
    .pad_out   (DB_REF_CLK[1]),
    .aclr      (reset_clk50));

assign DB_ARST[0] = db_reset[0];
assign DB_ARST[1] = db_reset[1];

// PL SPI FPGA -> DB CPLD
reg mb_cpld_sclk, mb_cpld_mosi, mb_cpld_cs_n;
wire mb_cpld_miso;

// PL SPI chip select decoding
localparam PL_CS_MB_CPLD = 2'b00;
localparam PL_CS_DB0     = 2'b10;
localparam PL_CS_DB1     = 2'b01;
localparam PL_CS_IDLE    = 2'b11;

// PL SPI registers do not have a separate reset.
// SW is expected to properly setup the DBs before issuing SPI transactions.
always @(posedge pll_ref_clk_int) begin : to_db
  // default chip selects
  DB_CTRL_CS_N[0] <= 1'b1;
  DB_CTRL_CS_N[1] <= 1'b1;
  mb_cpld_cs_n    <= 1'b1;

  // DB 0
  DB_CTRL_SCLK[0] <= PL_CPLD_SCLK;
  DB_CTRL_MOSI[0] <= PL_CPLD_MOSI;
  if (PL_CPLD_CS_N == PL_CS_DB0) begin
    DB_CTRL_CS_N[0] <= 1'b0;
  end

  //DB 1
  DB_CTRL_SCLK[1] <= PL_CPLD_SCLK;
  DB_CTRL_MOSI[1] <= PL_CPLD_MOSI;
  if (PL_CPLD_CS_N == PL_CS_DB1) begin
    DB_CTRL_CS_N[1] <= 1'b0;
  end

  // MB CPLD
  mb_cpld_sclk <= PL_CPLD_SCLK;
  mb_cpld_mosi <= PL_CPLD_MOSI;
  if (PL_CPLD_CS_N == PL_CS_MB_CPLD) begin
    mb_cpld_cs_n <= 1'b0;
  end
end

// SPI DB CPLD -> FPGA
always @(posedge pll_ref_clk_int) begin : from_db
  case (PL_CPLD_CS_N)
    PL_CS_MB_CPLD: PL_CPLD_MISO <= mb_cpld_miso; // MB CPLD
    PL_CS_DB1:     PL_CPLD_MISO <= DB_CTRL_MISO[1]; // DB 1
    PL_CS_DB0:     PL_CPLD_MISO <= DB_CTRL_MISO[0]; // DB 0
    PL_CS_IDLE:    PL_CPLD_MISO <= 1'bz; // inactive
    //vhook_nowarn id=Misc10 msg={tri-state assignment in clocked process}
  endcase
end

// Local PL SPI target
wire [19:0] pl_ctrlport_req_addr;
wire [31:0] pl_ctrlport_req_data;
wire        pl_ctrlport_req_rd;
wire        pl_ctrlport_req_wr;
wire        pl_ctrlport_resp_ack;
wire [31:0] pl_ctrlport_resp_data;
wire [ 1:0] pl_ctrlport_resp_status;
//vhook spi_slave_to_ctrlport_master pl_spi_endpoint
//vhook_a CLK_FREQUENCY 50_000_000
//vhook_a SPI_FREQUENCY 10_666_667
//vhook_a sclk mb_cpld_sclk
//vhook_a cs_n mb_cpld_cs_n
//vhook_a mosi mb_cpld_mosi
//vhook_a miso mb_cpld_miso
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {m_ctrlport_(.*)} pl_ctrlport_$1
spi_slave_to_ctrlport_master
  # (
    .CLK_FREQUENCY  (50_000_000),   //integer:=50000000
    .SPI_FREQUENCY  (10_666_667))   //integer:=10000000
  pl_spi_endpoint (
    .ctrlport_clk            (clk50),                     //in  wire
    .ctrlport_rst            (reset_clk50),               //in  wire
    .m_ctrlport_req_wr       (pl_ctrlport_req_wr),        //out wire
    .m_ctrlport_req_rd       (pl_ctrlport_req_rd),        //out wire
    .m_ctrlport_req_addr     (pl_ctrlport_req_addr),      //out wire[19:0]
    .m_ctrlport_req_data     (pl_ctrlport_req_data),      //out wire[31:0]
    .m_ctrlport_resp_ack     (pl_ctrlport_resp_ack),      //in  wire
    .m_ctrlport_resp_status  (pl_ctrlport_resp_status),   //in  wire[1:0]
    .m_ctrlport_resp_data    (pl_ctrlport_resp_data),     //in  wire[31:0]
    .sclk                    (mb_cpld_sclk),              //in  wire
    .cs_n                    (mb_cpld_cs_n),              //in  wire
    .mosi                    (mb_cpld_mosi),              //in  wire
    .miso                    (mb_cpld_miso));             //out wire

// Split up the PL control port
wire [19:0] pl_regs_ctrlport_req_addr;
wire [31:0] pl_regs_ctrlport_req_data;
wire        pl_regs_ctrlport_req_rd;
wire        pl_regs_ctrlport_req_wr;
wire        pl_regs_ctrlport_resp_ack;
wire [31:0] pl_regs_ctrlport_resp_data;
wire [ 1:0] pl_regs_ctrlport_resp_status;

wire [19:0] pl_term_ctrlport_req_addr;
wire [31:0] pl_term_ctrlport_req_data;
wire        pl_term_ctrlport_req_rd;
wire        pl_term_ctrlport_req_wr;
wire        pl_term_ctrlport_resp_ack;
wire [31:0] pl_term_ctrlport_resp_data;
wire [ 1:0] pl_term_ctrlport_resp_status;

wire        pl_jtag0_ctrlport_req_rd;
wire        pl_jtag0_ctrlport_req_wr;
wire        pl_jtag0_ctrlport_resp_ack;
wire [31:0] pl_jtag0_ctrlport_resp_data;
wire [ 1:0] pl_jtag0_ctrlport_resp_status;
wire [19:0] pl_jtag0_ctrlport_req_addr;
wire [31:0] pl_jtag0_ctrlport_req_data;

wire [19:0] pl_jtag1_ctrlport_req_addr;
wire [31:0] pl_jtag1_ctrlport_req_data;
wire        pl_jtag1_ctrlport_req_rd;
wire        pl_jtag1_ctrlport_req_wr;
wire        pl_jtag1_ctrlport_resp_ack;
wire [31:0] pl_jtag1_ctrlport_resp_data;
wire [1:0]  pl_jtag1_ctrlport_resp_status;

//vhook ctrlport_splitter pl_ctrlport_splitter
//vhook_a NUM_SLAVES 4
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {._ctrlport_(.*)time} {}
//vhook_a {._ctrlport_(.*)byte_en} {}
//vhook_a {s_ctrlport_(.*)} pl_ctrlport_$1
//vhook_a {m_ctrlport_(.*)} \{pl_regs_ctrlport_$1, pl_term_ctrlport_$1, pl_jtag0_ctrlport_$1, pl_jtag1_ctrlport_$1\}
ctrlport_splitter
  # (.NUM_SLAVES(4))   //integer:=2
  pl_ctrlport_splitter (
    .ctrlport_clk             (clk50),                                                                                                                       //in  wire
    .ctrlport_rst             (reset_clk50),                                                                                                                 //in  wire
    .s_ctrlport_req_wr        (pl_ctrlport_req_wr),                                                                                                          //in  wire
    .s_ctrlport_req_rd        (pl_ctrlport_req_rd),                                                                                                          //in  wire
    .s_ctrlport_req_addr      (pl_ctrlport_req_addr),                                                                                                        //in  wire[19:0]
    .s_ctrlport_req_data      (pl_ctrlport_req_data),                                                                                                        //in  wire[31:0]
    .s_ctrlport_req_byte_en   (),                                                                                                                            //in  wire[3:0]
    .s_ctrlport_req_has_time  (),                                                                                                                            //in  wire
    .s_ctrlport_req_time      (),                                                                                                                            //in  wire[63:0]
    .s_ctrlport_resp_ack      (pl_ctrlport_resp_ack),                                                                                                        //out wire
    .s_ctrlport_resp_status   (pl_ctrlport_resp_status),                                                                                                     //out wire[1:0]
    .s_ctrlport_resp_data     (pl_ctrlport_resp_data),                                                                                                       //out wire[31:0]
    .m_ctrlport_req_wr        ({pl_regs_ctrlport_req_wr, pl_term_ctrlport_req_wr, pl_jtag0_ctrlport_req_wr, pl_jtag1_ctrlport_req_wr}),                      //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_rd        ({pl_regs_ctrlport_req_rd, pl_term_ctrlport_req_rd, pl_jtag0_ctrlport_req_rd, pl_jtag1_ctrlport_req_rd}),                      //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_addr      ({pl_regs_ctrlport_req_addr, pl_term_ctrlport_req_addr, pl_jtag0_ctrlport_req_addr, pl_jtag1_ctrlport_req_addr}),              //out wire[((20*NUM_SLAVES)-1):0]
    .m_ctrlport_req_data      ({pl_regs_ctrlport_req_data, pl_term_ctrlport_req_data, pl_jtag0_ctrlport_req_data, pl_jtag1_ctrlport_req_data}),              //out wire[((32*NUM_SLAVES)-1):0]
    .m_ctrlport_req_byte_en   (),                                                                                                                            //out wire[((4*NUM_SLAVES)-1):0]
    .m_ctrlport_req_has_time  (),                                                                                                                            //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_time      (),                                                                                                                            //out wire[((64*NUM_SLAVES)-1):0]
    .m_ctrlport_resp_ack      ({pl_regs_ctrlport_resp_ack, pl_term_ctrlport_resp_ack, pl_jtag0_ctrlport_resp_ack, pl_jtag1_ctrlport_resp_ack}),              //in  wire[(NUM_SLAVES-1):0]
    .m_ctrlport_resp_status   ({pl_regs_ctrlport_resp_status, pl_term_ctrlport_resp_status, pl_jtag0_ctrlport_resp_status, pl_jtag1_ctrlport_resp_status}),  //in  wire[((2*NUM_SLAVES)-1):0]
    .m_ctrlport_resp_data     ({pl_regs_ctrlport_resp_data, pl_term_ctrlport_resp_data, pl_jtag0_ctrlport_resp_data, pl_jtag1_ctrlport_resp_data}));         //in  wire[((32*NUM_SLAVES)-1):0]

//vhook pl_cpld_regs pl_regs
//vhook_a BASE_ADDRESS PL_REGISTERS
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a qsfp0_led_active QSFP0_LED_ACTIVE
//vhook_a qsfp1_led_active QSFP1_LED_ACTIVE
//vhook_a qsfp0_led_link QSFP0_LED_LINK
//vhook_a qsfp1_led_link QSFP1_LED_LINK
//vhook_a {s_ctrlport_(.*)} pl_regs_ctrlport_$1
pl_cpld_regs
  # (.BASE_ADDRESS(PL_REGISTERS))   //integer:=0
  pl_regs (
    .ctrlport_clk            (clk50),                          //in  wire
    .ctrlport_rst            (reset_clk50),                    //in  wire
    .s_ctrlport_req_wr       (pl_regs_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (pl_regs_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (pl_regs_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (pl_regs_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (pl_regs_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (pl_regs_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (pl_regs_ctrlport_resp_data),     //out wire[31:0]
    .qsfp0_led_active        (QSFP0_LED_ACTIVE),               //out wire[3:0]
    .qsfp0_led_link          (QSFP0_LED_LINK),                 //out wire[3:0]
    .qsfp1_led_active        (QSFP1_LED_ACTIVE),               //out wire[3:0]
    .qsfp1_led_link          (QSFP1_LED_LINK),                 //out wire[3:0]
    .ipass_cable_present     (ipass_cable_present));           //out wire[1:0]

//vhook ctrlport_to_jtag db0_jtag
//vhook_a BASE_ADDRESS JTAG_DB0
//vhook_a DEFAULT_PRESCALAR 1
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} pl_jtag0_ctrlport_$1
//vhook_a tck DB_JTAG_TCK[0]
//vhook_a tdi DB_JTAG_TDI[0]
//vhook_a tdo DB_JTAG_TDO[0]
//vhook_a tms DB_JTAG_TMS[0]
ctrlport_to_jtag
  # (
    .BASE_ADDRESS       (JTAG_DB0), //integer:=0
    .DEFAULT_PRESCALAR  (1))     //integer:=0
  db0_jtag (
    .ctrlport_clk            (clk50),                           //in  wire
    .ctrlport_rst            (reset_clk50),                     //in  wire
    .s_ctrlport_req_wr       (pl_jtag0_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (pl_jtag0_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (pl_jtag0_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (pl_jtag0_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (pl_jtag0_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (pl_jtag0_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (pl_jtag0_ctrlport_resp_data),     //out wire[31:0]
    .tck                     (DB_JTAG_TCK[0]),                  //out wire
    .tdi                     (DB_JTAG_TDI[0]),                  //out wire
    .tdo                     (DB_JTAG_TDO[0]),                  //in  wire
    .tms                     (DB_JTAG_TMS[0]));                 //out wire

//vhook ctrlport_to_jtag db1_jtag
//vhook_a BASE_ADDRESS JTAG_DB1
//vhook_a DEFAULT_PRESCALAR 1
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} pl_jtag1_ctrlport_$1
//vhook_a tck DB_JTAG_TCK[1]
//vhook_a tdi DB_JTAG_TDI[1]
//vhook_a tdo DB_JTAG_TDO[1]
//vhook_a tms DB_JTAG_TMS[1]
ctrlport_to_jtag
  # (
    .BASE_ADDRESS       (JTAG_DB1), //integer:=0
    .DEFAULT_PRESCALAR  (1))     //integer:=0
  db1_jtag (
    .ctrlport_clk            (clk50),                           //in  wire
    .ctrlport_rst            (reset_clk50),                     //in  wire
    .s_ctrlport_req_wr       (pl_jtag1_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (pl_jtag1_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (pl_jtag1_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (pl_jtag1_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (pl_jtag1_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (pl_jtag1_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (pl_jtag1_ctrlport_resp_data),     //out wire[31:0]
    .tck                     (DB_JTAG_TCK[1]),                  //out wire
    .tdi                     (DB_JTAG_TDI[1]),                  //out wire
    .tdo                     (DB_JTAG_TDO[1]),                  //in  wire
    .tms                     (DB_JTAG_TMS[1]));                 //out wire

// Termination of ctrlport request
//vhook ctrlport_terminator pl_terminator
//vhook_a START_ADDRESS JTAG_DB1 + JTAG_DB1_SIZE
//vhook_a LAST_ADDRESS 2**CTRLPORT_ADDR_W-1
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} pl_term_ctrlport_$1
ctrlport_terminator
  # (
    .START_ADDRESS  (JTAG_DB1 + JTAG_DB1_SIZE),   //integer:=0
    .LAST_ADDRESS   (2**CTRLPORT_ADDR_W-1))       //integer:=32
  pl_terminator (
    .ctrlport_clk            (clk50),                          //in  wire
    .ctrlport_rst            (reset_clk50),                    //in  wire
    .s_ctrlport_req_wr       (pl_term_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (pl_term_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (pl_term_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (pl_term_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (pl_term_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (pl_term_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (pl_term_ctrlport_resp_data));    //out wire[31:0]

//---------------------------------------------------------------
// PS Interfaces
//---------------------------------------------------------------
// Local PS SPI target
wire [19:0] ps_ctrlport_req_addr;
wire [31:0] ps_ctrlport_req_data;
wire        ps_ctrlport_req_rd;
wire        ps_ctrlport_req_wr;
wire        ps_ctrlport_resp_ack;
wire [31:0] ps_ctrlport_resp_data;
wire [ 1:0] ps_ctrlport_resp_status;

wire ps_spi_endpoint_sclk;
wire ps_spi_endpoint_mosi;
wire ps_spi_endpoint_miso;
wire ps_spi_endpoint_cs_n;
//vhook spi_slave_to_ctrlport_master ps_spi_endpoint
//vhook_a CLK_FREQUENCY 50_000_000
//vhook_a SPI_FREQUENCY  5_000_000
//vhook_a sclk ps_spi_endpoint_sclk
//vhook_a cs_n ps_spi_endpoint_cs_n
//vhook_a mosi ps_spi_endpoint_mosi
//vhook_a miso ps_spi_endpoint_miso
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {m_ctrlport_(.*)} ps_ctrlport_$1
spi_slave_to_ctrlport_master
  # (
    .CLK_FREQUENCY  (50_000_000),   //integer:=50000000
    .SPI_FREQUENCY  (5_000_000))    //integer:=10000000
  ps_spi_endpoint (
    .ctrlport_clk            (clk50),                     //in  wire
    .ctrlport_rst            (reset_clk50),               //in  wire
    .m_ctrlport_req_wr       (ps_ctrlport_req_wr),        //out wire
    .m_ctrlport_req_rd       (ps_ctrlport_req_rd),        //out wire
    .m_ctrlport_req_addr     (ps_ctrlport_req_addr),      //out wire[19:0]
    .m_ctrlport_req_data     (ps_ctrlport_req_data),      //out wire[31:0]
    .m_ctrlport_resp_ack     (ps_ctrlport_resp_ack),      //in  wire
    .m_ctrlport_resp_status  (ps_ctrlport_resp_status),   //in  wire[1:0]
    .m_ctrlport_resp_data    (ps_ctrlport_resp_data),     //in  wire[31:0]
    .sclk                    (ps_spi_endpoint_sclk),      //in  wire
    .cs_n                    (ps_spi_endpoint_cs_n),      //in  wire
    .mosi                    (ps_spi_endpoint_mosi),      //in  wire
    .miso                    (ps_spi_endpoint_miso));     //out wire

// The PS SPI chip select signals are binary encoded.
// The internal SPI slaves as well as external slaves like the LMK04832 trigger
// actions or resets based on edges of the chip select signal. Therefore this
// implementation has to avoid glitches on the chip select signal although the
// SPI protocol is synchronous.
// The chip signals are double synchronized to make sure there is no
// meta-stability. Due to different traces lengths there is no guarantee for the
// chip select signals to change at the same time. To overcome this issue
// register stage 2 and 3 are compared. Only in case of matching values the
// change is propagated to the slaves' chip select lines. Once the IDLE state
// (all ones) is detected in register stage 2 the slaves' chip select lines will
// be deasserted.

// input sync registers (3 stages)
wire [3:0] ps_cpld_cs_n_shift2;              // resolving meta-stability, reset on IDLE
reg  [3:0] ps_cpld_cs_n_shift3 = {4 {1'b1}}; // stable state detection
//vhook synchronizer ps_spi_input_sync_inst
//vhook_a WIDTH 4
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 4'b1111
//vhook_a FALSE_PATH_TO_IN 0
//vhook_a clk clk250
//vhook_a rst 1'b0
//vhook_a in PS_CPLD_CS_N
//vhook_a out ps_cpld_cs_n_shift2
synchronizer
  # (
    .WIDTH             (4),    //integer:=1
    .STAGES            (2),    //integer:=2
    .INITIAL_VAL       (4'b1111), //integer:=0
    .FALSE_PATH_TO_IN  (0))    //integer:=1
  ps_spi_input_sync_inst (
    .clk  (clk250),                //in  wire
    .rst  (1'b0),                  //in  wire
    .in   (PS_CPLD_CS_N),          //in  wire[(WIDTH-1):0]
    .out  (ps_cpld_cs_n_shift2));  //out wire[(WIDTH-1):0]
always @(posedge clk250) begin
  ps_cpld_cs_n_shift3 <= ps_cpld_cs_n_shift2;
end

// SPI binary decoding
//vhook_nowarn id=Misc11 msg={'ps_spi_cs_n_decoded' does not match initial value}
reg [SPI_ENDPOINT_SIZE-2:0] ps_spi_cs_n_decoded = {SPI_ENDPOINT_SIZE-1 {1'b1}};
always @(posedge clk250) begin
  // reset in case of IDLE state
  if (ps_cpld_cs_n_shift2[2:0] == PS_CS_IDLE) begin
    ps_spi_cs_n_decoded <= {SPI_ENDPOINT_SIZE-1 {1'b1}};
  // only apply changes when stable state is detected
  end else if (ps_cpld_cs_n_shift3[2:0] == ps_cpld_cs_n_shift2[2:0]) begin
    ps_spi_cs_n_decoded[PS_CS_MB_CPLD]        <= ps_cpld_cs_n_shift3[2:0] != PS_CS_MB_CPLD;
    ps_spi_cs_n_decoded[PS_CS_LMK32]          <= ps_cpld_cs_n_shift3[2:0] != PS_CS_LMK32;
    ps_spi_cs_n_decoded[PS_CS_TPM]            <= ps_cpld_cs_n_shift3[2:0] != PS_CS_TPM;
    ps_spi_cs_n_decoded[PS_CS_PHASE_DAC]      <= ps_cpld_cs_n_shift3[2:0] != PS_CS_PHASE_DAC;
    ps_spi_cs_n_decoded[PS_CS_DB0_CAL_EEPROM] <= ps_cpld_cs_n_shift3[2:0] != PS_CS_DB0_CAL_EEPROM;
    ps_spi_cs_n_decoded[PS_CS_DB1_CAL_EEPROM] <= ps_cpld_cs_n_shift3[2:0] != PS_CS_DB1_CAL_EEPROM;
    ps_spi_cs_n_decoded[PS_CS_CLK_AUX_DB]     <= ps_cpld_cs_n_shift3[2:0] != PS_CS_CLK_AUX_DB;
  end
end

// local SPI slave
assign ps_spi_endpoint_sclk = PS_CPLD_SCLK;
assign ps_spi_endpoint_mosi = PS_CPLD_MOSI;
assign ps_spi_endpoint_cs_n = ps_spi_cs_n_decoded[PS_CS_MB_CPLD];

// LMK04832 SPI signals
assign LMK32_SCLK = PS_CPLD_SCLK;
assign LMK32_MOSI = PS_CPLD_MOSI;
assign LMK32_CS_N = ps_spi_cs_n_decoded[PS_CS_LMK32];

// TPM SPI signals
assign TPM_SCLK = PS_CPLD_SCLK;
assign TPM_MOSI = PS_CPLD_MOSI;
assign TPM_CS_N = ps_spi_cs_n_decoded[PS_CS_TPM];

// Phase DAC SPI signals
assign PHASE_DAC_SCLK = PS_CPLD_SCLK;
assign PHASE_DAC_MOSI = PS_CPLD_MOSI;
assign PHASE_DAC_CS_N = ps_spi_cs_n_decoded[PS_CS_PHASE_DAC];

// DB EEPROM 0 SPI signals
assign DB_CALEEPROM_SCLK[0] = PS_CPLD_SCLK;
assign DB_CALEEPROM_MOSI[0] = PS_CPLD_MOSI;
assign DB_CALEEPROM_CS_N[0] = ps_spi_cs_n_decoded[PS_CS_DB0_CAL_EEPROM];

// DB EEPROM 1 SPI signals
assign DB_CALEEPROM_SCLK[1] = PS_CPLD_SCLK;
assign DB_CALEEPROM_MOSI[1] = PS_CPLD_MOSI;
assign DB_CALEEPROM_CS_N[1] = ps_spi_cs_n_decoded[PS_CS_DB1_CAL_EEPROM];

// CLK AUX DB SPI signals
assign CLK_DB_SCLK = PS_CPLD_SCLK;
assign CLK_DB_MOSI = PS_CPLD_MOSI;
assign CLK_DB_CS_N = ps_spi_cs_n_decoded[PS_CS_CLK_AUX_DB];

// Combine SPI responses based on inputs only as this path is captured
// synchronously to PS_CPLD_SCLK by the SPI master.
assign PS_CPLD_MISO = (PS_CPLD_CS_N[2:0] == PS_CS_MB_CPLD)        ? ps_spi_endpoint_miso :
                      (PS_CPLD_CS_N[2:0] == PS_CS_LMK32)          ? LMK32_MISO           :
                      (PS_CPLD_CS_N[2:0] == PS_CS_TPM)            ? TPM_MISO             :
                      (PS_CPLD_CS_N[2:0] == PS_CS_DB0_CAL_EEPROM) ? DB_CALEEPROM_MISO[0] :
                      (PS_CPLD_CS_N[2:0] == PS_CS_DB1_CAL_EEPROM) ? DB_CALEEPROM_MISO[1] :
                      (PS_CPLD_CS_N[2:0] == PS_CS_CLK_AUX_DB)     ? CLK_DB_MISO          :
                      1'bz; // default case and PHASE_DAC

// Split up the PS control port
wire [19:0] ps_regs_ctrlport_req_addr;
wire [31:0] ps_regs_ctrlport_req_data;
wire        ps_regs_ctrlport_req_rd;
wire        ps_regs_ctrlport_req_wr;
wire        ps_regs_ctrlport_resp_ack;
wire [31:0] ps_regs_ctrlport_resp_data;
wire [ 1:0] ps_regs_ctrlport_resp_status;

wire [19:0] ps_term_ctrlport_req_addr;
wire [31:0] ps_term_ctrlport_req_data;
wire        ps_term_ctrlport_req_rd;
wire        ps_term_ctrlport_req_wr;
wire        ps_term_ctrlport_resp_ack;
wire [31:0] ps_term_ctrlport_resp_data;
wire [ 1:0] ps_term_ctrlport_resp_status;

wire [19:0] ps_reconfig_ctrlport_req_addr;
wire [31:0] ps_reconfig_ctrlport_req_data;
wire        ps_reconfig_ctrlport_req_rd;
wire        ps_reconfig_ctrlport_req_wr;
wire        ps_reconfig_ctrlport_resp_ack;
wire [31:0] ps_reconfig_ctrlport_resp_data;
wire [ 1:0] ps_reconfig_ctrlport_resp_status;

wire [19:0] ps_power_ctrlport_req_addr;
wire [31:0] ps_power_ctrlport_req_data;
wire        ps_power_ctrlport_req_rd;
wire        ps_power_ctrlport_req_wr;
wire        ps_power_ctrlport_resp_ack;
wire [31:0] ps_power_ctrlport_resp_data;
wire [ 1:0] ps_power_ctrlport_resp_status;
//vhook ctrlport_splitter ps_ctrlport_splitter
//vhook_a NUM_SLAVES 4
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {._ctrlport_(.*)time} {}
//vhook_a {._ctrlport_(.*)byte_en} {}
//vhook_a {s_ctrlport_(.*)} ps_ctrlport_$1
//vhook_a {m_ctrlport_(.*)} \{ps_power_ctrlport_$1, ps_regs_ctrlport_$1, ps_term_ctrlport_$1, ps_reconfig_ctrlport_$1\}
ctrlport_splitter
  # (.NUM_SLAVES(4))   //integer:=2
  ps_ctrlport_splitter (
    .ctrlport_clk             (clk50),                                                                                                                          //in  wire
    .ctrlport_rst             (reset_clk50),                                                                                                                    //in  wire
    .s_ctrlport_req_wr        (ps_ctrlport_req_wr),                                                                                                             //in  wire
    .s_ctrlport_req_rd        (ps_ctrlport_req_rd),                                                                                                             //in  wire
    .s_ctrlport_req_addr      (ps_ctrlport_req_addr),                                                                                                           //in  wire[19:0]
    .s_ctrlport_req_data      (ps_ctrlport_req_data),                                                                                                           //in  wire[31:0]
    .s_ctrlport_req_byte_en   (),                                                                                                                               //in  wire[3:0]
    .s_ctrlport_req_has_time  (),                                                                                                                               //in  wire
    .s_ctrlport_req_time      (),                                                                                                                               //in  wire[63:0]
    .s_ctrlport_resp_ack      (ps_ctrlport_resp_ack),                                                                                                           //out wire
    .s_ctrlport_resp_status   (ps_ctrlport_resp_status),                                                                                                        //out wire[1:0]
    .s_ctrlport_resp_data     (ps_ctrlport_resp_data),                                                                                                          //out wire[31:0]
    .m_ctrlport_req_wr        ({ps_power_ctrlport_req_wr, ps_regs_ctrlport_req_wr, ps_term_ctrlport_req_wr, ps_reconfig_ctrlport_req_wr}),                      //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_rd        ({ps_power_ctrlport_req_rd, ps_regs_ctrlport_req_rd, ps_term_ctrlport_req_rd, ps_reconfig_ctrlport_req_rd}),                      //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_addr      ({ps_power_ctrlport_req_addr, ps_regs_ctrlport_req_addr, ps_term_ctrlport_req_addr, ps_reconfig_ctrlport_req_addr}),              //out wire[((20*NUM_SLAVES)-1):0]
    .m_ctrlport_req_data      ({ps_power_ctrlport_req_data, ps_regs_ctrlport_req_data, ps_term_ctrlport_req_data, ps_reconfig_ctrlport_req_data}),              //out wire[((32*NUM_SLAVES)-1):0]
    .m_ctrlport_req_byte_en   (),                                                                                                                               //out wire[((4*NUM_SLAVES)-1):0]
    .m_ctrlport_req_has_time  (),                                                                                                                               //out wire[(NUM_SLAVES-1):0]
    .m_ctrlport_req_time      (),                                                                                                                               //out wire[((64*NUM_SLAVES)-1):0]
    .m_ctrlport_resp_ack      ({ps_power_ctrlport_resp_ack, ps_regs_ctrlport_resp_ack, ps_term_ctrlport_resp_ack, ps_reconfig_ctrlport_resp_ack}),              //in  wire[(NUM_SLAVES-1):0]
    .m_ctrlport_resp_status   ({ps_power_ctrlport_resp_status, ps_regs_ctrlport_resp_status, ps_term_ctrlport_resp_status, ps_reconfig_ctrlport_resp_status}),  //in  wire[((2*NUM_SLAVES)-1):0]
    .m_ctrlport_resp_data     ({ps_power_ctrlport_resp_data, ps_regs_ctrlport_resp_data, ps_term_ctrlport_resp_data, ps_reconfig_ctrlport_resp_data}));         //in  wire[((32*NUM_SLAVES)-1):0]

wire [39:0] serial_num_clk50;
wire        cmi_ready_clk50;
wire        cmi_other_side_detected_clk50;
//vhook ps_cpld_regs ps_regs
//vhook_a BASE_ADDRESS PS_REGISTERS
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} ps_regs_ctrlport_$1
//vhook_a db_clk_enable db_clk_enable
//vhook_a db_reset db_reset
//vhook_a pll_ref_clk_enable pll_ref_clk_en_clk50
//vhook_a dio_direction_a DIO_DIRECTION_A
//vhook_a dio_direction_b DIO_DIRECTION_B
//vhook_a serial_num serial_num_clk50
//vhook_a cmi_ready cmi_ready_clk50
//vhook_a cmi_other_side_detected cmi_other_side_detected_clk50
ps_cpld_regs
  # (.BASE_ADDRESS(PS_REGISTERS))   //integer:=0
  ps_regs (
    .ctrlport_clk             (clk50),                           //in  wire
    .ctrlport_rst             (reset_clk50),                     //in  wire
    .s_ctrlport_req_wr        (ps_regs_ctrlport_req_wr),         //in  wire
    .s_ctrlport_req_rd        (ps_regs_ctrlport_req_rd),         //in  wire
    .s_ctrlport_req_addr      (ps_regs_ctrlport_req_addr),       //in  wire[19:0]
    .s_ctrlport_req_data      (ps_regs_ctrlport_req_data),       //in  wire[31:0]
    .s_ctrlport_resp_ack      (ps_regs_ctrlport_resp_ack),       //out wire
    .s_ctrlport_resp_status   (ps_regs_ctrlport_resp_status),    //out wire[1:0]
    .s_ctrlport_resp_data     (ps_regs_ctrlport_resp_data),      //out wire[31:0]
    .db_clk_enable            (db_clk_enable),                   //out wire[1:0]
    .db_reset                 (db_reset),                        //out wire[1:0]
    .pll_ref_clk_enable       (pll_ref_clk_en_clk50),            //out wire
    .dio_direction_a          (DIO_DIRECTION_A),                 //out wire[11:0]
    .dio_direction_b          (DIO_DIRECTION_B),                 //out wire[11:0]
    .serial_num               (serial_num_clk50),                //out wire[39:0]
    .cmi_ready                (cmi_ready_clk50),                 //out wire
    .cmi_other_side_detected  (cmi_other_side_detected_clk50));  //in  wire

//vhook ps_power_regs ps_power_regs_inst
//vhook_a BASE_ADDRESS        POWER_REGISTERS
//vhook_a NUM_ADDRESSES       POWER_REGISTERS_SIZE
//vhook_a ctrlport_clk        clk50
//vhook_a ctrlport_rst        reset_clk50
//vhook_a {s_ctrlport_(.*)}   ps_power_ctrlport_$1
//vhook_a ipass_power_disable IPASS_POWER_DISABLE
//vhook_a ipass_power_fault_n IPASS_POWER_EN_FAULT
//vhook_a osc_100_en          PWR_EN_5V_OSC_100
//vhook_a osc_122_88_en       PWR_EN_5V_OSC_122_88
ps_power_regs
  # (
    .BASE_ADDRESS   (POWER_REGISTERS),        //integer:=0
    .NUM_ADDRESSES  (POWER_REGISTERS_SIZE))   //integer:=32
  ps_power_regs_inst (
    .ctrlport_clk            (clk50),                           //in  wire
    .ctrlport_rst            (reset_clk50),                     //in  wire
    .s_ctrlport_req_wr       (ps_power_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (ps_power_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (ps_power_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (ps_power_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (ps_power_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (ps_power_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (ps_power_ctrlport_resp_data),     //out wire[31:0]
    .ipass_power_disable     (IPASS_POWER_DISABLE),             //out wire
    .ipass_power_fault_n     (IPASS_POWER_EN_FAULT),            //in  wire[1:0]
    .osc_100_en              (PWR_EN_5V_OSC_100),               //out wire
    .osc_122_88_en           (PWR_EN_5V_OSC_122_88));           //out wire

// Termination of ctrlport request
//vhook ctrlport_terminator ps_terminator
//vhook_a START_ADDRESS POWER_REGISTERS + POWER_REGISTERS_SIZE
//vhook_a LAST_ADDRESS 2**CTRLPORT_ADDR_W-1
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} ps_term_ctrlport_$1
ctrlport_terminator
  # (
    .START_ADDRESS  (POWER_REGISTERS + POWER_REGISTERS_SIZE),   //integer:=0
    .LAST_ADDRESS   (2**CTRLPORT_ADDR_W-1))                     //integer:=32
  ps_terminator (
    .ctrlport_clk            (clk50),                          //in  wire
    .ctrlport_rst            (reset_clk50),                    //in  wire
    .s_ctrlport_req_wr       (ps_term_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (ps_term_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (ps_term_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (ps_term_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (ps_term_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (ps_term_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (ps_term_ctrlport_resp_data));    //out wire[31:0]


//---------------------------------------------------------------
// Reconfiguration
//---------------------------------------------------------------
// on chip flash interface
// (naming according to Avalon Memory-Mapped Interfaces -
// https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf)
wire        csr_addr;
wire        csr_read;
wire [31:0] csr_readdata;
wire        csr_write;
wire [31:0] csr_writedata;
wire [16:0] data_addr;
wire        data_read;
wire [31:0] data_readdata;
wire        data_readdatavalid;
wire        data_waitrequest;
wire        data_write;
wire [31:0] data_writedata;
// reset
wire        reset_clk50_n;

assign reset_clk50_n = ~reset_clk50;
//vhook on_chip_flash flash_inst
//vhook_a clock clk50
//vhook_a reset_n reset_clk50_n
//vhook_a avmm_data_burstcount 4'b0001
//vhook_a {avmm_(.*)} $1
on_chip_flash
  flash_inst (
    .clock                    (clk50),                //in  wire
    .avmm_csr_addr            (csr_addr),             //in  wire
    .avmm_csr_read            (csr_read),             //in  wire
    .avmm_csr_writedata       (csr_writedata),        //in  wire[31:0]
    .avmm_csr_write           (csr_write),            //in  wire
    .avmm_csr_readdata        (csr_readdata),         //out wire[31:0]
    .avmm_data_addr           (data_addr),            //in  wire[16:0]
    .avmm_data_read           (data_read),            //in  wire
    .avmm_data_writedata      (data_writedata),       //in  wire[31:0]
    .avmm_data_write          (data_write),           //in  wire
    .avmm_data_readdata       (data_readdata),        //out wire[31:0]
    .avmm_data_waitrequest    (data_waitrequest),     //out wire
    .avmm_data_readdatavalid  (data_readdatavalid),   //out wire
    .avmm_data_burstcount     (4'b0001),              //in  wire[3:0]
    .reset_n                  (reset_clk50_n));       //in  wire

//vhook reconfig_engine reconfig_engine_inst
//vhook_a BASE_ADDRESS RECONFIG
//vhook_a NUM_ADDRESSES RECONFIG_SIZE
//vhook_a MEM_INIT 0
//vhook_a ctrlport_clk clk50
//vhook_a ctrlport_rst reset_clk50
//vhook_a {s_ctrlport_(.*)} ps_reconfig_ctrlport_$1
reconfig_engine
  # (
    .BASE_ADDRESS   (RECONFIG),        //integer:=0
    .NUM_ADDRESSES  (RECONFIG_SIZE),   //integer:=32
    .MEM_INIT       (0))               //integer:=0
  reconfig_engine_inst (
    .ctrlport_clk            (clk50),                              //in  wire
    .ctrlport_rst            (reset_clk50),                        //in  wire
    .s_ctrlport_req_wr       (ps_reconfig_ctrlport_req_wr),        //in  wire
    .s_ctrlport_req_rd       (ps_reconfig_ctrlport_req_rd),        //in  wire
    .s_ctrlport_req_addr     (ps_reconfig_ctrlport_req_addr),      //in  wire[19:0]
    .s_ctrlport_req_data     (ps_reconfig_ctrlport_req_data),      //in  wire[31:0]
    .s_ctrlport_resp_ack     (ps_reconfig_ctrlport_resp_ack),      //out wire
    .s_ctrlport_resp_status  (ps_reconfig_ctrlport_resp_status),   //out wire[1:0]
    .s_ctrlport_resp_data    (ps_reconfig_ctrlport_resp_data),     //out wire[31:0]
    .csr_addr                (csr_addr),                           //out wire
    .csr_read                (csr_read),                           //out wire
    .csr_writedata           (csr_writedata),                      //out wire[31:0]
    .csr_write               (csr_write),                          //out wire
    .csr_readdata            (csr_readdata),                       //in  wire[31:0]
    .data_addr               (data_addr),                          //out wire[16:0]
    .data_read               (data_read),                          //out wire
    .data_writedata          (data_writedata),                     //out wire[31:0]
    .data_write              (data_write),                         //out wire
    .data_readdata           (data_readdata),                      //in  wire[31:0]
    .data_waitrequest        (data_waitrequest),                   //in  wire
    .data_readdatavalid      (data_readdatavalid));                //in  wire

//---------------------------------------------------------------
// CMI Interface
//---------------------------------------------------------------
// Control and status information clock transition
wire [39:0] serial_num_clk40;
wire        cmi_ready_clk40;
wire        cmi_other_side_detected_clk40;

//vhook handshake cmi_control_hs
//vhook_a WIDTH 41
//vhook_a clk_a clk50
//vhook_a rst_a reset_clk50
//vhook_a clk_b clk40
//vhook_a valid_a 1'b1
//vhook_a busy_a {}
//vhook_a valid_b {}
//vhook_a data_a \{cmi_ready_clk50, serial_num_clk50\}
//vhook_a data_b \{cmi_ready_clk40, serial_num_clk40\}
handshake
  # (.WIDTH(41))   //integer:=32
  cmi_control_hs (
    .clk_a    (clk50),                                //in  wire
    .rst_a    (reset_clk50),                          //in  wire
    .valid_a  (1'b1),                                 //in  wire
    .data_a   ({cmi_ready_clk50, serial_num_clk50}),  //in  wire[(WIDTH-1):0]
    .busy_a   (),                                     //out wire
    .clk_b    (clk40),                                //in  wire
    .valid_b  (),                                     //out wire
    .data_b   ({cmi_ready_clk40, serial_num_clk40})); //out wire[(WIDTH-1):0]

//vhook synchronizer cmi_status_sync
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk clk50
//vhook_a rst reset_clk50
//vhook_a in cmi_other_side_detected_clk40
//vhook_a out cmi_other_side_detected_clk50
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  cmi_status_sync (
    .clk  (clk50),                           //in  wire
    .rst  (reset_clk50),                     //in  wire
    .in   (cmi_other_side_detected_clk40),   //in  wire[(WIDTH-1):0]
    .out  (cmi_other_side_detected_clk50));  //out wire[(WIDTH-1):0]

wire scl_out;
wire sda_out;
wire [1:0] ipass_cable_present_n = ~ipass_cable_present;
//vhook PcieCmiWrapper pcie_cmi_inst
//vhook_a kSimulation SIMULATION
//vhook_a Clk clk40
//vhook_a acReset reset_clk40
//vhook_a aCblPrsnt_n ipass_cable_present_n[0]
//vhook_a cCmiReset PCIE_RESET
//vhook_a aSdaIn IPASS_SDA[0]
//vhook_a aSclIn IPASS_SCL[0]
//vhook_a aSdaOut sda_out
//vhook_a aSclOut scl_out
//vhook_a cSerialNumber serial_num_clk40
//vhook_a cOtherSideDetected cmi_other_side_detected_clk40
//vhook_a cBoardIsReady cmi_ready_clk40
PcieCmiWrapper
  # (.kSimulation(SIMULATION))   //natural:=0
  pcie_cmi_inst (
    .Clk                 (clk40),                           //in  std_logic
    .acReset             (reset_clk40),                     //in  std_logic
    .cSerialNumber       (serial_num_clk40),                //in  std_logic_vector(39:0)
    .cBoardIsReady       (cmi_ready_clk40),                 //in  std_logic
    .cCmiReset           (PCIE_RESET),                      //out std_logic
    .cOtherSideDetected  (cmi_other_side_detected_clk40),   //out std_logic
    .aCblPrsnt_n         (ipass_cable_present_n[0]),        //in  std_logic
    .aSdaIn              (IPASS_SDA[0]),                    //in  std_logic
    .aSdaOut             (sda_out),                         //out std_logic
    .aSclIn              (IPASS_SCL[0]),                    //in  std_logic
    .aSclOut             (scl_out));                        //out std_logic

// external pullups are used to drive the signal high
assign IPASS_SDA[0] = sda_out ? 1'bz : 1'b0;
assign IPASS_SCL[0] = scl_out ? 1'bz : 1'b0;

// no CMI controller for second interface
assign IPASS_SCL[1] = 1'bz;
assign IPASS_SDA[1] = 1'bz;

//---------------------------------------------------------------
// Miscellaneous
//---------------------------------------------------------------
// constants
assign PS_CLK_ON_CPLD = 1'b0; // low active driving of PS clocks
assign TPM_RESET_n = 1'b1;

// currently unused ports
assign PL_CPLD_IRQ = 1'b0;

endmodule

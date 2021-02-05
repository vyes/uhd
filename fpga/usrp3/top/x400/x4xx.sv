///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: x4xx
//
// Description: Top Level for X4xx devices
//
///////////////////////////////////////////////////////////////////////////////


module x4xx (

  ///////////////////////////////////
  //
  // RF block signals
  //
  ///////////////////////////////////

  // Clocking and sync
  input        SYSREF_RF_P,
  input        SYSREF_RF_N,
  input  [3:0] ADC_CLK_P,
  input  [3:0] ADC_CLK_N,
  input  [1:0] DAC_CLK_P,
  input  [1:0] DAC_CLK_N,

  // Analog ports
  input  [1:0] DB0_RX_P,
  input  [1:0] DB0_RX_N,
  input  [1:0] DB1_RX_P,
  input  [1:0] DB1_RX_N,
  output [1:0] DB0_TX_P,
  output [1:0] DB0_TX_N,
  output [1:0] DB1_TX_P,
  output [1:0] DB1_TX_N,


  ///////////////////////////////////
  //
  // MGTs (Quad 128-131)
  //
  //     Quad    |    Connector
  //   Bank 128  |  QSFP28 (1)
  //   Bank 129  |  iPass+zHD (1)
  //   Bank 130  |  iPass+zHD (0)
  //   Bank 131  |  QSFP28 (0)
  //
  ///////////////////////////////////

  // Clock references
  input [3:0] MGT_REFCLK_LMK_P,
  input [3:0] MGT_REFCLK_LMK_N,

  // Quad 128 transceivers: QSFP28 (1)
  `ifdef PORT1_LANES
  input  [`PORT1_LANES-1:0] QSFP1_RX_P,
  input  [`PORT1_LANES-1:0] QSFP1_RX_N,
  output [`PORT1_LANES-1:0] QSFP1_TX_P,
  output [`PORT1_LANES-1:0] QSFP1_TX_N,
  `endif

  // Quad 129 transceivers: iPass+zHD (1)
  `ifdef IPASS1_LANES
  input  [`IPASS1_LANES-1:0] IPASS1_RX_P,
  input  [`IPASS1_LANES-1:0] IPASS1_RX_N,
  output [`IPASS1_LANES-1:0] IPASS1_TX_P,
  output [`IPASS1_LANES-1:0] IPASS1_TX_N,
  `endif

  // Quad 130 transceivers: iPass+zHD (0)
  `ifdef IPASS0_LANES
  input  [`IPASS0_LANES-1:0] IPASS0_RX_P,
  input  [`IPASS0_LANES-1:0] IPASS0_RX_N,
  output [`IPASS0_LANES-1:0] IPASS0_TX_P,
  output [`IPASS0_LANES-1:0] IPASS0_TX_N,
  `endif

  // Quad 131 transceivers: QSFP28 (0)
  `ifdef PORT0_LANES
  input  [`PORT0_LANES-1:0] QSFP0_RX_P,
  input  [`PORT0_LANES-1:0] QSFP0_RX_N,
  output [`PORT0_LANES-1:0] QSFP0_TX_P,
  output [`PORT0_LANES-1:0] QSFP0_TX_N,
  `endif



  ///////////////////////////////////
  //
  // DRAM controllers
  //
  ///////////////////////////////////

  // Controller 0
  // input         DRAM0_REFCLK_P,
  // input         DRAM0_REFCLK_N,
  // output        DRAM0_ACT_n,
  // output [16:0] DRAM0_ADDR,
  // output [ 1:0] DRAM0_BA,
  // output [ 0:0] DRAM0_BG,
  // output [ 0:0] DRAM0_CKE,
  // output [ 0:0] DRAM0_ODT,
  // output [ 0:0] DRAM0_CS_n,
  // output [ 0:0] DRAM0_CLK_P,
  // output [ 0:0] DRAM0_CLK_N,
  // output        DRAM0_RESET_n,
  // inout  [ 7:0] DRAM0_DM_n,
  // inout  [63:0] DRAM0_DQ,
  // inout  [ 7:0] DRAM0_DQS_p,
  // inout  [ 7:0] DRAM0_DQS_n,

  // Controller 1
  // input         DRAM1_REFCLK_P,
  // input         DRAM1_REFCLK_N,
  // output        DRAM1_ACT_n,
  // output [16:0] DRAM1_ADDR,
  // output [ 1:0] DRAM1_BA,
  // output [ 0:0] DRAM1_BG,
  // output [ 0:0] DRAM1_CKE,
  // output [ 0:0] DRAM1_ODT,
  // output [ 0:0] DRAM1_CS_n,
  // output [ 0:0] DRAM1_CLK_P,
  // output [ 0:0] DRAM1_CLK_N,
  // output        DRAM1_RESET_n,
  // inout  [ 7:0] DRAM1_DM_n,
  // inout  [63:0] DRAM1_DQ,
  // inout  [ 7:0] DRAM1_DQS_p,
  // inout  [ 7:0] DRAM1_DQS_n,


  ///////////////////////////////////
  //
  // HD banks
  //
  ///////////////////////////////////

  inout  [19:0] DB0_GPIO,
  output reg    DB0_SYNTH_SYNC,
  inout  [19:0] DB1_GPIO,
  output reg    DB1_SYNTH_SYNC,

  output        LMK_SYNC,
  input         PPS_IN,
  output        PL_CPLD_SCLK, // Dual-purpose CPLD JTAG TCK
  output        PL_CPLD_MOSI, // Dual-purpose CPLD JTAG TDI
  input         PL_CPLD_MISO, // Dual-purpose CPLD JTAG TDO


  ///////////////////////////////////
  //
  // Misc HP banks
  //
  ///////////////////////////////////

  input         PLL_REFCLK_FPGA_P,
  input         PLL_REFCLK_FPGA_N,
  // input         WR_20M_REF,
  input         BASE_REFCLK_FPGA_P,
  input         BASE_REFCLK_FPGA_N,

  input         SYSREF_FABRIC_P,
  input         SYSREF_FABRIC_N,


  input         QSFP0_MODPRS_n,
  input         QSFP0_INTR_n,
  output        QSFP0_RESET_n,
  output        QSFP0_LPMODE_n,

  input         QSFP1_MODPRS_n,
  input         QSFP1_INTR_n,
  output        QSFP1_RESET_n,
  output        QSFP1_LPMODE_n,

  // input         PCIE_RESET,

  inout  [11:0] DIOA_FPGA,
  inout  [11:0] DIOB_FPGA,

  output        CPLD_JTAG_OE_n,

  output        PPS_LED,
  // inout         CRYPTO_SDA,
  inout         TRIG_IO,
  output        PL_CPLD_JTAGEN,
  // input  [ 1:0] IPASS_SIDEBAND,
  // input         PL_CPLD_IRQ,
  output        PL_CPLD_CS0_n, // Dual-purpose CPLD JTAG TMS
  output        PL_CPLD_CS1_n,
  // output        TDC_SPARE_0,
  // output        TDC_SPARE_1
  output        FPGA_TEST

);

  `include "regmap/global_regs_regmap_utils.vh"

  // These RFNoC parameters are defined in global_regs_regmap_utils.vh,
  // which is auto-generated by XmlParse.
  // To update the parameters' value, refer to the XmlParse section
  // in x4xx_global_regs.v
  localparam RFNOC_PROTOVER = {RFNOC_VERSION_MAJOR[RFNOC_PROTO_MAJOR_SIZE-1:0],
                               RFNOC_VERSION_MINOR[RFNOC_PROTO_MINOR_SIZE-1:0]};
  localparam CHDR_CLK_RATE  = CHDR_CLK_VALUE[CHDR_CLK_SIZE-1:0];
  //vhook_warn TODO: move the defintion of CHDR_W to a define from a header file
  //                 that comes from the image builder tool
  `ifdef BUILD_100G
    localparam CHDR_W         = 512;
  `else
    localparam CHDR_W         = 64;
  `endif
  localparam CHDR_USER_W    = $clog2(CHDR_W/8);
  localparam CPU_W          = 64;
  localparam CPU_USER_W     = $clog2(CPU_W/8)+1;

  localparam NUM_CHANNELS   = 4;
  localparam REG_AWIDTH     = 15;
  localparam REG_DWIDTH     = 32;

  //vhook_warn TODO: Remove vhook pragmas.
  //vhook_sigstart
  logic adc_data_out_resetn_dclk;
  logic adc_enable_data_rclk;
  logic adc_rfdc_axi_resetn_rclk;
  logic [39:0] axi_eth_dma0_araddr;
  logic [0:0] axi_eth_dma0_arready;
  logic [0:0] axi_eth_dma0_arvalid;
  logic [39:0] axi_eth_dma0_awaddr;
  logic [0:0] axi_eth_dma0_awready;
  logic [0:0] axi_eth_dma0_awvalid;
  logic [0:0] axi_eth_dma0_bready;
  logic [1:0] axi_eth_dma0_bresp;
  logic [0:0] axi_eth_dma0_bvalid;
  logic [31:0] axi_eth_dma0_rdata;
  logic [0:0] axi_eth_dma0_rready;
  logic [1:0] axi_eth_dma0_rresp;
  logic [0:0] axi_eth_dma0_rvalid;
  logic [31:0] axi_eth_dma0_wdata;
  logic [0:0] axi_eth_dma0_wready;
  logic [0:0] axi_eth_dma0_wvalid;
  logic [39:0] axi_gp0_araddr;
  logic [1:0] axi_gp0_arburst;
  logic [3:0] axi_gp0_arcache;
  logic [4:0] axi_gp0_arid;
  logic [7:0] axi_gp0_arlen;
  logic [0:0] axi_gp0_arlock;
  logic [2:0] axi_gp0_arprot;
  logic [3:0] axi_gp0_arqos;
  logic axi_gp0_arready;
  logic [2:0] axi_gp0_arsize;
  logic axi_gp0_arvalid;
  logic [39:0] axi_gp0_awaddr;
  logic [1:0] axi_gp0_awburst;
  logic [3:0] axi_gp0_awcache;
  logic [4:0] axi_gp0_awid;
  logic [7:0] axi_gp0_awlen;
  logic [0:0] axi_gp0_awlock;
  logic [2:0] axi_gp0_awprot;
  logic [3:0] axi_gp0_awqos;
  logic axi_gp0_awready;
  logic [2:0] axi_gp0_awsize;
  logic axi_gp0_awvalid;
  logic axi_gp0_bready;
  logic [1:0] axi_gp0_bresp;
  logic axi_gp0_bvalid;
  logic [31:0] axi_gp0_rdata;
  logic axi_gp0_rlast;
  logic axi_gp0_rready;
  logic [1:0] axi_gp0_rresp;
  logic axi_gp0_rvalid;
  logic [31:0] axi_gp0_wdata;
  logic axi_gp0_wlast;
  logic axi_gp0_wready;
  logic [3:0] axi_gp0_wstrb;
  logic axi_gp0_wvalid;
  logic [39:0] axi_hp0_araddr;
  logic [1:0] axi_hp0_arburst;
  logic [3:0] axi_hp0_arcache;
  logic [4:0] axi_hp0_arid;
  logic [7:0] axi_hp0_arlen;
  logic [0:0] axi_hp0_arlock;
  logic [2:0] axi_hp0_arprot;
  logic [3:0] axi_hp0_arqos;
  logic axi_hp0_arready;
  logic [2:0] axi_hp0_arsize;
  logic axi_hp0_arvalid;
  logic [39:0] axi_hp0_awaddr;
  logic [1:0] axi_hp0_awburst;
  logic [3:0] axi_hp0_awcache;
  logic [4:0] axi_hp0_awid;
  logic [7:0] axi_hp0_awlen;
  logic [0:0] axi_hp0_awlock;
  logic [2:0] axi_hp0_awprot;
  logic [3:0] axi_hp0_awqos;
  logic axi_hp0_awready;
  logic [2:0] axi_hp0_awsize;
  logic axi_hp0_awvalid;
  logic axi_hp0_bready;
  logic [1:0] axi_hp0_bresp;
  logic axi_hp0_bvalid;
  logic [63:0] axi_hp0_rdata;
  logic axi_hp0_rlast;
  logic axi_hp0_rready;
  logic [1:0] axi_hp0_rresp;
  logic axi_hp0_rvalid;
  logic [63:0] axi_hp0_wdata;
  logic axi_hp0_wlast;
  logic axi_hp0_wready;
  logic [7:0] axi_hp0_wstrb;
  logic axi_hp0_wvalid;
  logic dac_data_in_resetn_dclk;
  logic dac_data_in_resetn_rclk;
  logic dac_data_in_resetn_rclk2x;

  logic data_clk_2x;
  logic fir_resetn_rclk2x;
  logic [31:0] gpio_0_tri_i;
  logic [39:0] m_axi_app_araddr;
  logic [2:0] m_axi_app_arprot;
  logic [0:0] m_axi_app_arready;
  logic [0:0] m_axi_app_arvalid;
  logic [39:0] m_axi_app_awaddr;
  logic [2:0] m_axi_app_awprot;
  logic [0:0] m_axi_app_awready;
  logic [0:0] m_axi_app_awvalid;
  logic [0:0] m_axi_app_bready;
  logic [1:0] m_axi_app_bresp;
  logic [0:0] m_axi_app_bvalid;
  logic [31:0] m_axi_app_rdata;
  logic [0:0] m_axi_app_rready;
  logic [1:0] m_axi_app_rresp;
  logic [0:0] m_axi_app_rvalid;
  logic [31:0] m_axi_app_wdata;
  logic [0:0] m_axi_app_wready;
  logic [3:0] m_axi_app_wstrb;
  logic [0:0] m_axi_app_wvalid;
  logic [39:0] m_axi_mpm_ep_araddr;
  logic [0:0] m_axi_mpm_ep_arready;
  logic [0:0] m_axi_mpm_ep_arvalid;
  logic [39:0] m_axi_mpm_ep_awaddr;
  logic [0:0] m_axi_mpm_ep_awready;
  logic [0:0] m_axi_mpm_ep_awvalid;
  logic [0:0] m_axi_mpm_ep_bready;
  logic [1:0] m_axi_mpm_ep_bresp;
  logic [0:0] m_axi_mpm_ep_bvalid;
  logic [31:0] m_axi_mpm_ep_rdata;
  logic [0:0] m_axi_mpm_ep_rready;
  logic [1:0] m_axi_mpm_ep_rresp;
  logic [0:0] m_axi_mpm_ep_rvalid;
  logic [31:0] m_axi_mpm_ep_wdata;
  logic [0:0] m_axi_mpm_ep_wready;
  logic [3:0] m_axi_mpm_ep_wstrb;
  logic [0:0] m_axi_mpm_ep_wvalid;
  logic [7:0] pl_ps_irq0;
  logic [63:0] radio_time;
  logic radio_time_stb;

  //vhook_sigend

  //------------------------------------------------------------------
  // Clocks and resets
  //------------------------------------------------------------------

  // Clocking and sync signals for RFDC
  logic pll_ref_clk_in, pll_ref_clk;
  logic sysref_pl;
  logic base_ref_clk;

  // Buffer the incoming RFDC PLL clock
  IBUFGDS pll_ref_clk_ibuf (
    .O(pll_ref_clk_in),
    .I(PLL_REFCLK_FPGA_P),
    .IB(PLL_REFCLK_FPGA_N)
  );
  //vhook_nowarn PLL_REFCLK_FPGA_* pll_ref_clk_in

  //vhook_warn This is a placeholder to help with developing timing constraints.
  always_ff @(posedge pll_ref_clk) begin
    DB0_SYNTH_SYNC <= ~ DB0_SYNTH_SYNC;
    DB1_SYNTH_SYNC <= ~ DB1_SYNTH_SYNC;
  end

  // Buffer the incoming RFDC PL SYSREF
  IBUFGDS pl_sysref_ibuf (
    .O(sysref_pl),
    .I(SYSREF_FABRIC_P),
    .IB(SYSREF_FABRIC_N)
  );
  //vhook_nowarn SYSREF_FABRIC_* sysref_pl

  // Buffer the incoming base reference clock
  IBUFGDS base_ref_clk_ibuf (
    .O(base_ref_clk),
    .I(BASE_REFCLK_FPGA_P),
    .IB(BASE_REFCLK_FPGA_N)
  );
  //vhook_nowarn BASE_REFCLK_FPGA_* base_ref_clk

  // Clocking signals for RF data processing/moving.
  logic rfdc_clk, rfdc_clk_2x;
  logic data_clk;
  logic radio_clk;

  // Low-power output clocks from PS to PL.
  logic clk100; // 100.000 MHz
  logic clk40;  //  40.000 MHz
  logic clk200; // 200.000 MHz

  // Asynchronous resets from PS to PL.
  logic pl_resetn0;
  logic areset;

  assign areset = ~pl_resetn0;

  // Synchronous reset for the clk40 domain, derived from the PS reset 0.
  logic clk40_rst, clk40_rstn;
  logic clk200_rst, clk200_rstn;
  logic radio_rst;
  logic brc_rst;
  logic prc_rst;


  // AXI Lite Interfaces
  `include "../../../../lib/axi4lite_sv/axi_lite.vh"
  `include "../../../../lib/axi4s_sv/axi4s.vh"
  AxiLiteIf_v #(.DATA_WIDTH(REG_DWIDTH),.ADDR_WIDTH(REG_AWIDTH))
    axi_net0_v (clk40, clk40_rst);

  reset_sync reset_gen_clk40 (
    .clk       (clk40),
    .reset_in  (areset),
    .reset_out (clk40_rst)
  );

  reset_sync reset_gen_clk200 (
    .clk       (clk200),
    .reset_in  (areset),
    .reset_out (clk200_rst)
  );

  reset_sync reset_gen_radio (
    .clk       (radio_clk),
    .reset_in  (areset),
    .reset_out (radio_rst)
  );

  reset_sync reset_gen_brc (
    .clk       (base_ref_clk),
    .reset_in  (areset),
    .reset_out (brc_rst)
  );

  reset_sync reset_gen_prc (
    .clk       (pll_ref_clk),
    .reset_in  (areset),
    .reset_out (prc_rst)
  );

  // Invert reset for various modules.
  assign clk40_rstn = ~clk40_rst;
  assign clk200_rstn = ~clk200_rst;

  // PPS handling
  logic        pps_refclk;
  logic        pps_radioclk;
  logic [ 1:0] pps_select;
  logic        pll_sync_trigger;
  logic        pll_sync_done;
  logic [ 7:0] pll_sync_delay;
  logic [ 7:0] pps_brc_delay;
  logic [25:0] pps_prc_delay;
  logic [ 1:0] prc_rc_divider;
  logic        pps_rc_enabled;
  //vhook x4xx_pps_sync pps_sync_inst hidegeneric=true
  //vhook_a ctrl_clk clk40
  //vhook_a radio_clk data_clk
  //vhook_a pps_in PPS_IN
  //vhook_a pps_out_brc pps_refclk
  //vhook_a pps_out_rc pps_radioclk
  //vhook_a sync LMK_SYNC
  //vhook_a debug {}
  x4xx_pps_sync
    pps_sync_inst (
      .base_ref_clk      (base_ref_clk),       //in  wire
      .pll_ref_clk       (pll_ref_clk),        //in  wire
      .ctrl_clk          (clk40),              //in  wire
      .radio_clk         (data_clk),           //in  wire
      .brc_rst           (brc_rst),            //in  wire
      .pps_in            (PPS_IN),             //in  wire
      .pps_out_brc       (pps_refclk),         //out wire
      .pps_out_rc        (pps_radioclk),       //out wire
      .sync              (LMK_SYNC),           //out wire
      .pps_select        (pps_select),         //in  wire[1:0]
      .pll_sync_trigger  (pll_sync_trigger),   //in  wire
      .pll_sync_delay    (pll_sync_delay),     //in  wire[7:0]
      .pll_sync_done     (pll_sync_done),      //out wire
      .pps_brc_delay     (pps_brc_delay),      //in  wire[7:0]
      .pps_prc_delay     (pps_prc_delay),      //in  wire[25:0]
      .prc_rc_divider    (prc_rc_divider),     //in  wire[1:0]
      .pps_rc_enabled    (pps_rc_enabled),     //in  wire
      .debug             ());                  //out wire[1:0]

  // Synchronize trigger io configuration to base reference clock.
  // Derive the information if the PPS trigger is activated.
  logic [1:0] trig_io_select_clk40;
  logic [1:0] trig_io_select_refclk;
  synchronizer #(
    .FALSE_PATH_TO_IN(1),
    .WIDTH(2)
  ) trig_io_select_dsync (
    .clk(base_ref_clk), .rst(1'b0), .in(trig_io_select_clk40), .out(trig_io_select_refclk)
  );

  assign TRIG_IO = (trig_io_select_refclk == TRIG_IO_PPS_OUTPUT) ? pps_refclk : 1'bz;
  assign PPS_LED = pps_refclk;

  //------------------------------------------------------------------
  // Processor System (PS) + RF Data Converter (RFDC)
  //------------------------------------------------------------------

  logic        eth0_link_up;
  logic [31:0] gpio_0_tri_o;

  // RFDC AXI4-Stream interfaces.
  // All these signals/vectors are in the rfdc_clk domain.
  // ADC
  // I/Q data comes from the RFDC in two vectors: I and Q.
  // Each vector contains up to 8 SPC depending upon the decimation
  // performed by the RFDC. When lower data rates are used (higher
  // decimation), the LSBs will contain the valid samples.
  // The data is packed in each vector as follows:
  //             ____________              ____________              _
  //  rfdc_clk _|            |____________|            |____________|
  //           _ _________________________ _________________________ _
  // *_i_tdata _X_i7,i6,i5,i4,i3,i2,i1,i0_X_______i15,...,i8________X_
  //           _ _________________________ _________________________ _
  // *_q_tdata _X_q7,q6,q5,q4,q3,q2,q1,q0_X_______q15,...,q8________X_
  //
  logic [127:0] adc_tile_dout_i_tdata  [0:3]; // Up to 8 SPC (I)
  logic [127:0] adc_tile_dout_q_tdata  [0:3]; // Up to 8 SPC (Q)
  logic [3:0]   adc_tile_dout_i_tready;
  logic [3:0]   adc_tile_dout_q_tready;
  logic [3:0]   adc_tile_dout_i_tvalid;
  logic [3:0]   adc_tile_dout_q_tvalid;
  //
  // DAC
  // I/Q data is interleaved to the RFDC in a single vector.
  // This vector contains up to 8 SPC depending upon the interpolation
  // performed by the RFDC. When lower data rates are used (higher
  // interpolation), valid samples need to be in the LSBs.
  // The data is packed in the vector as follows:
  //            ____________              ____________              _
  // rfdc_clk _|            |____________|            |____________|
  //          _ _________________________ _________________________ _
  //  *_tdata _X__q7,i7,q6,i6,...,q0,i0__X____q15,i15,...,q8,i8____X_
  //
  logic [255:0] dac_tile_din_tdata     [0:3]; // Up to 8 SPC (I + Q)
  logic [3:0]   dac_tile_din_tready;
  logic [3:0]   dac_tile_din_tvalid;

  // Control/status vectors to rf_core_100m (clk40 domain)
  //vhook_warn TODO: split these vectors into different registers per dboard.
  logic [31:0] rf_dsp_info_clk40;
  logic [31:0] rf_axi_status_clk40;
  // Invert controls to rf_core_100m (rfdc_clk_2x domain)
  logic [7:0]  invert_adc_iq_rclk2;
  logic [7:0]  invert_dac_iq_rclk2;

  // AXI4-Lite control bus in the clk40 domain.
  logic [            39:0] axi_core_awaddr;
  logic                    axi_core_awvalid;
  logic                    axi_core_awready;
  logic [  REG_DWIDTH-1:0] axi_core_wdata;
  logic [REG_DWIDTH/8-1:0] axi_core_wstrb;
  logic                    axi_core_wvalid;
  logic                    axi_core_wready;
  logic [             1:0] axi_core_bresp;
  logic                    axi_core_bvalid;
  logic                    axi_core_bready;
  logic [            39:0] axi_core_araddr;
  logic                    axi_core_arvalid;
  logic                    axi_core_arready;
  logic [  REG_DWIDTH-1:0] axi_core_rdata;
  logic [             1:0] axi_core_rresp;
  logic                    axi_core_rvalid;
  logic                    axi_core_rready;

  // AXI4-Lite Ethernet internal control bus (clk40 domain).
  logic [            39:0] axi_eth_internal_awaddr;
  logic                    axi_eth_internal_awvalid;
  logic                    axi_eth_internal_awready;
  logic [  REG_DWIDTH-1:0] axi_eth_internal_wdata;
  logic [REG_DWIDTH/8-1:0] axi_eth_internal_wstrb;
  logic                    axi_eth_internal_wvalid;
  logic                    axi_eth_internal_wready;
  logic [             1:0] axi_eth_internal_bresp;
  logic                    axi_eth_internal_bvalid;
  logic                    axi_eth_internal_bready;
  logic [            39:0] axi_eth_internal_araddr;
  logic                    axi_eth_internal_arvalid;
  logic                    axi_eth_internal_arready;
  logic [  REG_DWIDTH-1:0] axi_eth_internal_rdata;
  logic [             1:0] axi_eth_internal_rresp;
  logic                    axi_eth_internal_rvalid;
  logic                    axi_eth_internal_rready;

  // Internal Ethernet xport adapter to PS (clk200 domain)
  logic [63:0] e2h_dma_tdata;
  logic [ 7:0] e2h_dma_tkeep;
  logic        e2h_dma_tlast;
  logic        e2h_dma_tready;
  logic        e2h_dma_tvalid;
  logic [63:0] h2e_dma_tdata;
  logic [ 7:0] h2e_dma_tkeep;
  logic        h2e_dma_tlast;
  logic        h2e_dma_tready;
  logic        h2e_dma_tvalid;

  logic eth0_rx_irq;
  logic eth0_tx_irq;

  // Unused AXI signals
  assign axi_hp0_arid   = 0;
  assign axi_hp0_arlock = 0;
  assign axi_hp0_arqos  = 0;
  assign axi_hp0_awid   = 0;
  assign axi_hp0_awlock = 0;
  assign axi_hp0_awqos  = 0;
  //
  assign axi_gp0_arid   = 0;
  assign axi_gp0_arlock = 0;
  assign axi_gp0_arqos  = 0;
  assign axi_gp0_awid   = 0;
  assign axi_gp0_awlock = 0;
  assign axi_gp0_awqos  = 0;

  // Interrupt mapping
  assign pl_ps_irq0[0] = eth0_rx_irq;
  assign pl_ps_irq0[1] = eth0_tx_irq;
  assign pl_ps_irq0[2] = QSFP0_INTR_n;
  assign pl_ps_irq0[3] = QSFP1_INTR_n;

  // GPIO inputs (assigned from 31 decreasing)
  // Make the current PPS signal available to the PS.
  assign gpio_0_tri_i[31]   = pps_refclk;
  assign gpio_0_tri_i[30]   = eth0_link_up;
  //QSFP+ module present signals
  assign gpio_0_tri_i[29]   = QSFP1_MODPRS_n;
  assign gpio_0_tri_i[28]   = QSFP0_MODPRS_n;
  assign gpio_0_tri_i[27:0] = 0;

  // GPIO outputs (assigned from 0 increasing)
  // Drive the JTAG level translator enable line (active low) with GPIO[0] from PS.
  assign CPLD_JTAG_OE_n = gpio_0_tri_o[0];
  // Drive the CPLD JTAG enable line (active high) with GPIO[1] from PS.
  assign PL_CPLD_JTAGEN = gpio_0_tri_o[1];
  //vhook_warn TODO: connect resets from RFNoC radio to RFDC

  //vhook_e   x4xx_ps_rfdc_bd      inst_x4xx_ps_rfdc_bd
  //vhook_# ----------------------------------------------------------
  //vhook_#     Processor System
  //vhook_# ----------------------------------------------------------
  //vhook_# -- Clocking and resets -----------------------------------
  //vhook_a   {^pl_clk(.*)}                    clk$1
  //vhook_a   pl_clk166                        {}
  //vhook_a   pl_resetn0                       pl_resetn0
  //vhook_a   {^pl_resetn([1-3])}              {}
  //vhook_a   bus_clk                          clk200
  //vhook_a   bus_rstn                         clk200_rstn
  //vhook_# -- 10GigE DMA --------------------------------------------
  //vhook_a   {^s_axi_gp0_(.*)}                {axi_gp0_$1}
  //vhook_a   s_axi_gp0_bid                    {}
  //vhook_a   s_axi_gp0_rid                    {}
  //vhook_a   {^s_axi_hp0_(.*)}                {axi_hp0_$1}
  //vhook_a   s_axi_hp0_aclk                   clk40
  //vhook_a   s_axi_hp0_aresetn                clk40_rstn
  //vhook_a   s_axi_hp0_bid                    {}
  //vhook_a   s_axi_hp0_rid                    {}
  //vhook_# TODO: Port 1 is currently unused
  //vhook_a   {^s_axi_gp1_(.*)}                {}
  //vhook_a   {^s_axi_hp1_(.*)}                {}
  //vhook_# -- HPC0 and RPU IRQs are not used ------------------------
  //vhook_a   {^s_axi_hpc0_(.*)}               {}
  //vhook_a   {^irq.*rpu_n}                    {1'b1}
  //vhook_# -- Internal Ethernet AXI DMA -----------------------------
  //vhook_a   {^s_axis_eth_dma_(.*)}           {e2h_dma_$1}
  //vhook_a   {^m_axis_eth_dma_(.*)}           {h2e_dma_$1}
  //vhook_# -- Other AXI-Lite master ifcs ----------------------------
  //vhook_a   {^m_axi_eth_internal_(.*)prot}   {}
  //vhook_a   {^m_axi_eth_internal_(.*)}       {axi_eth_internal_$1}
  //vhook_a   {^m_axi_mpm_ep_(.*)prot}         {}
  //vhook_a   {^m_axi_core_(.*)}               {axi_core_$1}
  //vhook_a   m_axi_core_arprot                {}
  //vhook_a   m_axi_core_awprot                {}
  //vhook_a   {^m_axi_rpu_(.*)}                {}
  //vhook_a   m_axi_rpu_arprot                 {}
  //vhook_a   m_axi_rpu_awprot                 {}
  //vhook_# -- Misc. -------------------------------------------------
  //vhook_# CPLD JTAG Engine
  //vhook_a   {jtag0_.*}                       {}
  //vhook_# GPIO signals
  //vhook_a   gpio_0_tri_t                     {}
  //vhook_# ----------------------------------------------------------
  //vhook_#     RF Data Converter
  //vhook_# ----------------------------------------------------------
  //vhook_# -- ADC Tile Ports ----------------------------------------
  //vhook_a   {^adc(.)_clk_clk_(.)}            ADC__CLK__$2[$1]  convertcase=_
  //vhook_a   {^adc_tile224_ch(.)_vin_v_(.)}   DB0__RX__$2[$1]   convertcase=_
  //vhook_a   {^adc_tile226_ch(.)_vin_v_(.)}   DB1__RX__$2[$1]   convertcase=_
  //vhook_# -- DAC Tile Ports ----------------------------------------
  //vhook_a   {^dac(.)_clk_clk_(.)}            DAC__CLK__$2[$1]  convertcase=_
  //vhook_a   {^dac_tile228_ch(.)_vout_v_(.)}  DB0__TX__$2[$1]   convertcase=_
  //vhook_a   {^dac_tile229_ch(.)_vout_v_(.)}  DB1__TX__$2[$1]   convertcase=_
  //vhook_# -- Synchronization (SYSREF) ------------------------------
  //vhook_a   {^sysref_rf_in_diff_(.)}         SYSREF__RF__$1    convertcase=_
  //vhook_a   sysref_pl_in                     sysref_pl
  //vhook_a   sysref_out_pclk                  {}
  //vhook_a   sysref_out_rclk                  {}
  //vhook_a   enable_sysref_rclk               1'b1
  //vhook_# -- Clocking ----------------------------------------------
  //vhook_a   pll_ref_clk_out                  pll_ref_clk
  //vhook_a   data_clock_locked                {}
  //vhook_# -- Data Interfaces (Raw from tiles) ----------------------
  //vhook_a   {^adc_tile224_ch0_dout_(.)_(.*)} adc_tile_dout_$1_$2[0]
  //vhook_a   {^adc_tile224_ch1_dout_(.)_(.*)} adc_tile_dout_$1_$2[1]
  //vhook_a   {^adc_tile226_ch0_dout_(.)_(.*)} adc_tile_dout_$1_$2[2]
  //vhook_a   {^adc_tile226_ch1_dout_(.)_(.*)} adc_tile_dout_$1_$2[3]
  //vhook_a   {^dac_tile228_ch0_din_(.*)}      dac_tile_din_$1[0]
  //vhook_a   {^dac_tile228_ch1_din_(.*)}      dac_tile_din_$1[1]
  //vhook_a   {^dac_tile229_ch0_din_(.*)}      dac_tile_din_$1[2]
  //vhook_a   {^dac_tile229_ch1_din_(.*)}      dac_tile_din_$1[3]
  //vhook_# -- Misc. -------------------------------------------------
  //vhook_a   rfdc_irq                         {}
  //vhook_# -- Real-time NCO reset signals----------------------------
  //vhook_a nco_reset_done_dclk                {}
  //vhook_a start_nco_reset_dclk               1'b0
  //vhook_a dac_data_in_resetn_dclk2x          {}
  x4xx_ps_rfdc_bd
    inst_x4xx_ps_rfdc_bd (
      .adc_data_out_resetn_dclk       (adc_data_out_resetn_dclk),    //out STD_LOGIC
      .adc_enable_data_rclk           (adc_enable_data_rclk),        //out STD_LOGIC
      .adc_rfdc_axi_resetn_rclk       (adc_rfdc_axi_resetn_rclk),    //out STD_LOGIC
      .bus_clk                        (clk200),                      //in  STD_LOGIC
      .bus_rstn                       (clk200_rstn),                 //in  STD_LOGIC
      .clk40                          (clk40),                       //in  STD_LOGIC
      .clk40_rstn                     (clk40_rstn),                  //in  STD_LOGIC
      .dac_data_in_resetn_dclk        (dac_data_in_resetn_dclk),     //out STD_LOGIC
      .dac_data_in_resetn_dclk2x      (),                            //out STD_LOGIC
      .dac_data_in_resetn_rclk        (dac_data_in_resetn_rclk),     //out STD_LOGIC
      .dac_data_in_resetn_rclk2x      (dac_data_in_resetn_rclk2x),   //out STD_LOGIC
      .data_clk                       (data_clk),                    //out STD_LOGIC
      .data_clk_2x                    (data_clk_2x),                 //out STD_LOGIC
      .data_clock_locked              (),                            //out STD_LOGIC
      .enable_sysref_rclk             (1'b1),                        //in  STD_LOGIC
      .fir_resetn_rclk2x              (fir_resetn_rclk2x),           //out STD_LOGIC
      .invert_adc_iq_rclk2            (invert_adc_iq_rclk2),         //out STD_LOGIC_VECTOR(7:0)
      .invert_dac_iq_rclk2            (invert_dac_iq_rclk2),         //out STD_LOGIC_VECTOR(7:0)
      .jtag0_tck                      (),                            //inout STD_LOGIC
      .jtag0_tdi                      (),                            //inout STD_LOGIC
      .jtag0_tdo                      (),                            //in  STD_LOGIC
      .jtag0_tms                      (),                            //inout STD_LOGIC
      .nco_reset_done_dclk            (),                            //out STD_LOGIC
      .irq0_lpd_rpu_n                 (1'b1),                        //in  STD_LOGIC
      .irq1_lpd_rpu_n                 (1'b1),                        //in  STD_LOGIC
      .pl_clk40                       (clk40),                       //out STD_LOGIC
      .pl_clk100                      (clk100),                      //out STD_LOGIC
      .pl_clk166                      (),                            //out STD_LOGIC
      .pl_clk200                      (clk200),                      //out STD_LOGIC
      .pl_ps_irq0                     (pl_ps_irq0),                  //in  STD_LOGIC_VECTOR(7:0)
      .pl_resetn0                     (pl_resetn0),                  //out STD_LOGIC
      .pl_resetn1                     (),                            //out STD_LOGIC
      .pl_resetn2                     (),                            //out STD_LOGIC
      .pl_resetn3                     (),                            //out STD_LOGIC
      .pll_ref_clk_in                 (pll_ref_clk_in),              //in  STD_LOGIC
      .pll_ref_clk_out                (pll_ref_clk),                 //out STD_LOGIC
      .rf_axi_status_clk40            (rf_axi_status_clk40),         //in  STD_LOGIC_VECTOR(31:0)
      .rf_dsp_info_clk40              (rf_dsp_info_clk40),           //in  STD_LOGIC_VECTOR(31:0)
      .rfdc_clk                       (rfdc_clk),                    //out STD_LOGIC
      .rfdc_clk_2x                    (rfdc_clk_2x),                 //out STD_LOGIC
      .rfdc_irq                       (),                            //out STD_LOGIC
      .s_axi_hp0_aclk                 (clk40),                       //in  STD_LOGIC
      .s_axi_hp0_aresetn              (clk40_rstn),                  //in  STD_LOGIC
      .s_axi_hp1_aclk                 (),                            //in  STD_LOGIC
      .s_axi_hp1_aresetn              (),                            //in  STD_LOGIC
      .s_axi_hpc0_aclk                (),                            //in  STD_LOGIC
      .start_nco_reset_dclk           (1'b0),                        //in  STD_LOGIC
      .sysref_out_pclk                (),                            //out STD_LOGIC
      .sysref_out_rclk                (),                            //out STD_LOGIC
      .sysref_pl_in                   (sysref_pl),                   //in  STD_LOGIC
      .s_axi_hp0_awaddr               (axi_hp0_awaddr),              //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_hp0_awlen                (axi_hp0_awlen),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp0_awsize               (axi_hp0_awsize),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp0_awburst              (axi_hp0_awburst),             //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hp0_awlock               (axi_hp0_awlock),              //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_hp0_awcache              (axi_hp0_awcache),             //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp0_awprot               (axi_hp0_awprot),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp0_awqos                (axi_hp0_awqos),               //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp0_awvalid              (axi_hp0_awvalid),             //in  STD_LOGIC
      .s_axi_hp0_awready              (axi_hp0_awready),             //out STD_LOGIC
      .s_axi_hp0_wdata                (axi_hp0_wdata),               //in  STD_LOGIC_VECTOR(63:0)
      .s_axi_hp0_wstrb                (axi_hp0_wstrb),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp0_wlast                (axi_hp0_wlast),               //in  STD_LOGIC
      .s_axi_hp0_wvalid               (axi_hp0_wvalid),              //in  STD_LOGIC
      .s_axi_hp0_wready               (axi_hp0_wready),              //out STD_LOGIC
      .s_axi_hp0_bresp                (axi_hp0_bresp),               //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hp0_bvalid               (axi_hp0_bvalid),              //out STD_LOGIC
      .s_axi_hp0_bready               (axi_hp0_bready),              //in  STD_LOGIC
      .s_axi_hp0_araddr               (axi_hp0_araddr),              //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_hp0_arlen                (axi_hp0_arlen),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp0_arsize               (axi_hp0_arsize),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp0_arburst              (axi_hp0_arburst),             //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hp0_arlock               (axi_hp0_arlock),              //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_hp0_arcache              (axi_hp0_arcache),             //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp0_arprot               (axi_hp0_arprot),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp0_arqos                (axi_hp0_arqos),               //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp0_arvalid              (axi_hp0_arvalid),             //in  STD_LOGIC
      .s_axi_hp0_arready              (axi_hp0_arready),             //out STD_LOGIC
      .s_axi_hp0_rdata                (axi_hp0_rdata),               //out STD_LOGIC_VECTOR(63:0)
      .s_axi_hp0_rresp                (axi_hp0_rresp),               //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hp0_rlast                (axi_hp0_rlast),               //out STD_LOGIC
      .s_axi_hp0_rvalid               (axi_hp0_rvalid),              //out STD_LOGIC
      .s_axi_hp0_rready               (axi_hp0_rready),              //in  STD_LOGIC
      .s_axi_gp0_awid                 (axi_gp0_awid),                //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_gp0_awaddr               (axi_gp0_awaddr),              //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_gp0_awlen                (axi_gp0_awlen),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_gp0_awsize               (axi_gp0_awsize),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp0_awburst              (axi_gp0_awburst),             //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_gp0_awlock               (axi_gp0_awlock),              //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_gp0_awcache              (axi_gp0_awcache),             //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp0_awprot               (axi_gp0_awprot),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp0_awqos                (axi_gp0_awqos),               //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp0_awvalid              (axi_gp0_awvalid),             //in  STD_LOGIC
      .s_axi_gp0_awready              (axi_gp0_awready),             //out STD_LOGIC
      .s_axi_gp0_wdata                (axi_gp0_wdata),               //in  STD_LOGIC_VECTOR(31:0)
      .s_axi_gp0_wstrb                (axi_gp0_wstrb),               //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp0_wlast                (axi_gp0_wlast),               //in  STD_LOGIC
      .s_axi_gp0_wvalid               (axi_gp0_wvalid),              //in  STD_LOGIC
      .s_axi_gp0_wready               (axi_gp0_wready),              //out STD_LOGIC
      .s_axi_gp0_bid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_gp0_bresp                (axi_gp0_bresp),               //out STD_LOGIC_VECTOR(1:0)
      .s_axi_gp0_bvalid               (axi_gp0_bvalid),              //out STD_LOGIC
      .s_axi_gp0_bready               (axi_gp0_bready),              //in  STD_LOGIC
      .s_axi_gp0_arid                 (axi_gp0_arid),                //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_gp0_araddr               (axi_gp0_araddr),              //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_gp0_arlen                (axi_gp0_arlen),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_gp0_arsize               (axi_gp0_arsize),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp0_arburst              (axi_gp0_arburst),             //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_gp0_arlock               (axi_gp0_arlock),              //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_gp0_arcache              (axi_gp0_arcache),             //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp0_arprot               (axi_gp0_arprot),              //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp0_arqos                (axi_gp0_arqos),               //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp0_arvalid              (axi_gp0_arvalid),             //in  STD_LOGIC
      .s_axi_gp0_arready              (axi_gp0_arready),             //out STD_LOGIC
      .s_axi_gp0_rid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_gp0_rdata                (axi_gp0_rdata),               //out STD_LOGIC_VECTOR(31:0)
      .s_axi_gp0_rresp                (axi_gp0_rresp),               //out STD_LOGIC_VECTOR(1:0)
      .s_axi_gp0_rlast                (axi_gp0_rlast),               //out STD_LOGIC
      .s_axi_gp0_rvalid               (axi_gp0_rvalid),              //out STD_LOGIC
      .s_axi_gp0_rready               (axi_gp0_rready),              //in  STD_LOGIC
      .s_axis_eth_dma_tdata           (e2h_dma_tdata),               //in  STD_LOGIC_VECTOR(63:0)
      .s_axis_eth_dma_tkeep           (e2h_dma_tkeep),               //in  STD_LOGIC_VECTOR(7:0)
      .s_axis_eth_dma_tlast           (e2h_dma_tlast),               //in  STD_LOGIC
      .s_axis_eth_dma_tready          (e2h_dma_tready),              //out STD_LOGIC
      .s_axis_eth_dma_tvalid          (e2h_dma_tvalid),              //in  STD_LOGIC
      .s_axi_gp1_awid                 (),                            //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_gp1_awaddr               (),                            //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_gp1_awlen                (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_gp1_awsize               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp1_awburst              (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_gp1_awlock               (),                            //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_gp1_awcache              (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp1_awprot               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp1_awqos                (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp1_awvalid              (),                            //in  STD_LOGIC
      .s_axi_gp1_awready              (),                            //out STD_LOGIC
      .s_axi_gp1_wdata                (),                            //in  STD_LOGIC_VECTOR(31:0)
      .s_axi_gp1_wstrb                (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp1_wlast                (),                            //in  STD_LOGIC
      .s_axi_gp1_wvalid               (),                            //in  STD_LOGIC
      .s_axi_gp1_wready               (),                            //out STD_LOGIC
      .s_axi_gp1_bid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_gp1_bresp                (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_gp1_bvalid               (),                            //out STD_LOGIC
      .s_axi_gp1_bready               (),                            //in  STD_LOGIC
      .s_axi_gp1_arid                 (),                            //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_gp1_araddr               (),                            //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_gp1_arlen                (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_gp1_arsize               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp1_arburst              (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_gp1_arlock               (),                            //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_gp1_arcache              (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp1_arprot               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_gp1_arqos                (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_gp1_arvalid              (),                            //in  STD_LOGIC
      .s_axi_gp1_arready              (),                            //out STD_LOGIC
      .s_axi_gp1_rid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_gp1_rdata                (),                            //out STD_LOGIC_VECTOR(31:0)
      .s_axi_gp1_rresp                (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_gp1_rlast                (),                            //out STD_LOGIC
      .s_axi_gp1_rvalid               (),                            //out STD_LOGIC
      .s_axi_gp1_rready               (),                            //in  STD_LOGIC
      .s_axi_hp1_awaddr               (),                            //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_hp1_awlen                (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp1_awsize               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp1_awburst              (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hp1_awlock               (),                            //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_hp1_awcache              (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp1_awprot               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp1_awqos                (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp1_awvalid              (),                            //in  STD_LOGIC
      .s_axi_hp1_awready              (),                            //out STD_LOGIC
      .s_axi_hp1_wdata                (),                            //in  STD_LOGIC_VECTOR(63:0)
      .s_axi_hp1_wstrb                (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp1_wlast                (),                            //in  STD_LOGIC
      .s_axi_hp1_wvalid               (),                            //in  STD_LOGIC
      .s_axi_hp1_wready               (),                            //out STD_LOGIC
      .s_axi_hp1_bresp                (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hp1_bvalid               (),                            //out STD_LOGIC
      .s_axi_hp1_bready               (),                            //in  STD_LOGIC
      .s_axi_hp1_araddr               (),                            //in  STD_LOGIC_VECTOR(39:0)
      .s_axi_hp1_arlen                (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hp1_arsize               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp1_arburst              (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hp1_arlock               (),                            //in  STD_LOGIC_VECTOR(0:0)
      .s_axi_hp1_arcache              (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp1_arprot               (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hp1_arqos                (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hp1_arvalid              (),                            //in  STD_LOGIC
      .s_axi_hp1_arready              (),                            //out STD_LOGIC
      .s_axi_hp1_rdata                (),                            //out STD_LOGIC_VECTOR(63:0)
      .s_axi_hp1_rresp                (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hp1_rlast                (),                            //out STD_LOGIC
      .s_axi_hp1_rvalid               (),                            //out STD_LOGIC
      .s_axi_hp1_rready               (),                            //in  STD_LOGIC
      .s_axi_hpc0_aruser              (),                            //in  STD_LOGIC
      .s_axi_hpc0_awuser              (),                            //in  STD_LOGIC
      .s_axi_hpc0_awid                (),                            //in  STD_LOGIC_VECTOR(5:0)
      .s_axi_hpc0_awaddr              (),                            //in  STD_LOGIC_VECTOR(48:0)
      .s_axi_hpc0_awlen               (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hpc0_awsize              (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hpc0_awburst             (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hpc0_awlock              (),                            //in  STD_LOGIC
      .s_axi_hpc0_awcache             (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hpc0_awprot              (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hpc0_awvalid             (),                            //in  STD_LOGIC
      .s_axi_hpc0_awready             (),                            //out STD_LOGIC
      .s_axi_hpc0_wdata               (),                            //in  STD_LOGIC_VECTOR(127:0)
      .s_axi_hpc0_wstrb               (),                            //in  STD_LOGIC_VECTOR(15:0)
      .s_axi_hpc0_wlast               (),                            //in  STD_LOGIC
      .s_axi_hpc0_wvalid              (),                            //in  STD_LOGIC
      .s_axi_hpc0_wready              (),                            //out STD_LOGIC
      .s_axi_hpc0_bid                 (),                            //out STD_LOGIC_VECTOR(5:0)
      .s_axi_hpc0_bresp               (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hpc0_bvalid              (),                            //out STD_LOGIC
      .s_axi_hpc0_bready              (),                            //in  STD_LOGIC
      .s_axi_hpc0_arid                (),                            //in  STD_LOGIC_VECTOR(5:0)
      .s_axi_hpc0_araddr              (),                            //in  STD_LOGIC_VECTOR(48:0)
      .s_axi_hpc0_arlen               (),                            //in  STD_LOGIC_VECTOR(7:0)
      .s_axi_hpc0_arsize              (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hpc0_arburst             (),                            //in  STD_LOGIC_VECTOR(1:0)
      .s_axi_hpc0_arlock              (),                            //in  STD_LOGIC
      .s_axi_hpc0_arcache             (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hpc0_arprot              (),                            //in  STD_LOGIC_VECTOR(2:0)
      .s_axi_hpc0_arvalid             (),                            //in  STD_LOGIC
      .s_axi_hpc0_arready             (),                            //out STD_LOGIC
      .s_axi_hpc0_rid                 (),                            //out STD_LOGIC_VECTOR(5:0)
      .s_axi_hpc0_rdata               (),                            //out STD_LOGIC_VECTOR(127:0)
      .s_axi_hpc0_rresp               (),                            //out STD_LOGIC_VECTOR(1:0)
      .s_axi_hpc0_rlast               (),                            //out STD_LOGIC
      .s_axi_hpc0_rvalid              (),                            //out STD_LOGIC
      .s_axi_hpc0_rready              (),                            //in  STD_LOGIC
      .s_axi_hpc0_awqos               (),                            //in  STD_LOGIC_VECTOR(3:0)
      .s_axi_hpc0_arqos               (),                            //in  STD_LOGIC_VECTOR(3:0)
      .adc0_clk_clk_n                 (ADC_CLK_N[0]),                //in  STD_LOGIC
      .adc0_clk_clk_p                 (ADC_CLK_P[0]),                //in  STD_LOGIC
      .adc2_clk_clk_n                 (ADC_CLK_N[2]),                //in  STD_LOGIC
      .adc2_clk_clk_p                 (ADC_CLK_P[2]),                //in  STD_LOGIC
      .m_axi_app_awaddr               (m_axi_app_awaddr),            //out STD_LOGIC_VECTOR(39:0)
      .m_axi_app_awprot               (m_axi_app_awprot),            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_app_awvalid              (m_axi_app_awvalid),           //out STD_LOGIC_VECTOR(0:0)
      .m_axi_app_awready              (m_axi_app_awready),           //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_app_wdata                (m_axi_app_wdata),             //out STD_LOGIC_VECTOR(31:0)
      .m_axi_app_wstrb                (m_axi_app_wstrb),             //out STD_LOGIC_VECTOR(3:0)
      .m_axi_app_wvalid               (m_axi_app_wvalid),            //out STD_LOGIC_VECTOR(0:0)
      .m_axi_app_wready               (m_axi_app_wready),            //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_app_bresp                (m_axi_app_bresp),             //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_app_bvalid               (m_axi_app_bvalid),            //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_app_bready               (m_axi_app_bready),            //out STD_LOGIC_VECTOR(0:0)
      .m_axi_app_araddr               (m_axi_app_araddr),            //out STD_LOGIC_VECTOR(39:0)
      .m_axi_app_arprot               (m_axi_app_arprot),            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_app_arvalid              (m_axi_app_arvalid),           //out STD_LOGIC_VECTOR(0:0)
      .m_axi_app_arready              (m_axi_app_arready),           //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_app_rdata                (m_axi_app_rdata),             //in  STD_LOGIC_VECTOR(31:0)
      .m_axi_app_rresp                (m_axi_app_rresp),             //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_app_rvalid               (m_axi_app_rvalid),            //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_app_rready               (m_axi_app_rready),            //out STD_LOGIC_VECTOR(0:0)
      .dac0_clk_clk_n                 (DAC_CLK_N[0]),                //in  STD_LOGIC
      .dac0_clk_clk_p                 (DAC_CLK_P[0]),                //in  STD_LOGIC
      .dac1_clk_clk_n                 (DAC_CLK_N[1]),                //in  STD_LOGIC
      .dac1_clk_clk_p                 (DAC_CLK_P[1]),                //in  STD_LOGIC
      .gpio_0_tri_i                   (gpio_0_tri_i),                //in  STD_LOGIC_VECTOR(31:0)
      .gpio_0_tri_o                   (gpio_0_tri_o),                //out STD_LOGIC_VECTOR(31:0)
      .gpio_0_tri_t                   (),                            //out STD_LOGIC_VECTOR(31:0)
      .m_axi_eth_internal_awaddr      (axi_eth_internal_awaddr),     //out STD_LOGIC_VECTOR(39:0)
      .m_axi_eth_internal_awprot      (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_eth_internal_awvalid     (axi_eth_internal_awvalid),    //out STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_awready     (axi_eth_internal_awready),    //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_wdata       (axi_eth_internal_wdata),      //out STD_LOGIC_VECTOR(31:0)
      .m_axi_eth_internal_wstrb       (axi_eth_internal_wstrb),      //out STD_LOGIC_VECTOR(3:0)
      .m_axi_eth_internal_wvalid      (axi_eth_internal_wvalid),     //out STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_wready      (axi_eth_internal_wready),     //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_bresp       (axi_eth_internal_bresp),      //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_eth_internal_bvalid      (axi_eth_internal_bvalid),     //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_bready      (axi_eth_internal_bready),     //out STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_araddr      (axi_eth_internal_araddr),     //out STD_LOGIC_VECTOR(39:0)
      .m_axi_eth_internal_arprot      (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_eth_internal_arvalid     (axi_eth_internal_arvalid),    //out STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_arready     (axi_eth_internal_arready),    //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_rdata       (axi_eth_internal_rdata),      //in  STD_LOGIC_VECTOR(31:0)
      .m_axi_eth_internal_rresp       (axi_eth_internal_rresp),      //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_eth_internal_rvalid      (axi_eth_internal_rvalid),     //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_eth_internal_rready      (axi_eth_internal_rready),     //out STD_LOGIC_VECTOR(0:0)
      .m_axis_eth_dma_tdata           (h2e_dma_tdata),               //out STD_LOGIC_VECTOR(63:0)
      .m_axis_eth_dma_tkeep           (h2e_dma_tkeep),               //out STD_LOGIC_VECTOR(7:0)
      .m_axis_eth_dma_tlast           (h2e_dma_tlast),               //out STD_LOGIC
      .m_axis_eth_dma_tready          (h2e_dma_tready),              //in  STD_LOGIC
      .m_axis_eth_dma_tvalid          (h2e_dma_tvalid),              //out STD_LOGIC
      .m_axi_rpu_awaddr               (),                            //out STD_LOGIC_VECTOR(39:0)
      .m_axi_rpu_awprot               (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_rpu_awvalid              (),                            //out STD_LOGIC
      .m_axi_rpu_awready              (),                            //in  STD_LOGIC
      .m_axi_rpu_wdata                (),                            //out STD_LOGIC_VECTOR(31:0)
      .m_axi_rpu_wstrb                (),                            //out STD_LOGIC_VECTOR(3:0)
      .m_axi_rpu_wvalid               (),                            //out STD_LOGIC
      .m_axi_rpu_wready               (),                            //in  STD_LOGIC
      .m_axi_rpu_bresp                (),                            //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_rpu_bvalid               (),                            //in  STD_LOGIC
      .m_axi_rpu_bready               (),                            //out STD_LOGIC
      .m_axi_rpu_araddr               (),                            //out STD_LOGIC_VECTOR(39:0)
      .m_axi_rpu_arprot               (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_rpu_arvalid              (),                            //out STD_LOGIC
      .m_axi_rpu_arready              (),                            //in  STD_LOGIC
      .m_axi_rpu_rdata                (),                            //in  STD_LOGIC_VECTOR(31:0)
      .m_axi_rpu_rresp                (),                            //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_rpu_rvalid               (),                            //in  STD_LOGIC
      .m_axi_rpu_rready               (),                            //out STD_LOGIC
      .m_axi_core_awaddr              (axi_core_awaddr),             //out STD_LOGIC_VECTOR(39:0)
      .m_axi_core_awprot              (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_core_awvalid             (axi_core_awvalid),            //out STD_LOGIC_VECTOR(0:0)
      .m_axi_core_awready             (axi_core_awready),            //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_core_wdata               (axi_core_wdata),              //out STD_LOGIC_VECTOR(31:0)
      .m_axi_core_wstrb               (axi_core_wstrb),              //out STD_LOGIC_VECTOR(3:0)
      .m_axi_core_wvalid              (axi_core_wvalid),             //out STD_LOGIC_VECTOR(0:0)
      .m_axi_core_wready              (axi_core_wready),             //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_core_bresp               (axi_core_bresp),              //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_core_bvalid              (axi_core_bvalid),             //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_core_bready              (axi_core_bready),             //out STD_LOGIC_VECTOR(0:0)
      .m_axi_core_araddr              (axi_core_araddr),             //out STD_LOGIC_VECTOR(39:0)
      .m_axi_core_arprot              (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_core_arvalid             (axi_core_arvalid),            //out STD_LOGIC_VECTOR(0:0)
      .m_axi_core_arready             (axi_core_arready),            //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_core_rdata               (axi_core_rdata),              //in  STD_LOGIC_VECTOR(31:0)
      .m_axi_core_rresp               (axi_core_rresp),              //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_core_rvalid              (axi_core_rvalid),             //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_core_rready              (axi_core_rready),             //out STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_awaddr            (m_axi_mpm_ep_awaddr),         //out STD_LOGIC_VECTOR(39:0)
      .m_axi_mpm_ep_awprot            (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_mpm_ep_awvalid           (m_axi_mpm_ep_awvalid),        //out STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_awready           (m_axi_mpm_ep_awready),        //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_wdata             (m_axi_mpm_ep_wdata),          //out STD_LOGIC_VECTOR(31:0)
      .m_axi_mpm_ep_wstrb             (m_axi_mpm_ep_wstrb),          //out STD_LOGIC_VECTOR(3:0)
      .m_axi_mpm_ep_wvalid            (m_axi_mpm_ep_wvalid),         //out STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_wready            (m_axi_mpm_ep_wready),         //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_bresp             (m_axi_mpm_ep_bresp),          //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_mpm_ep_bvalid            (m_axi_mpm_ep_bvalid),         //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_bready            (m_axi_mpm_ep_bready),         //out STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_araddr            (m_axi_mpm_ep_araddr),         //out STD_LOGIC_VECTOR(39:0)
      .m_axi_mpm_ep_arprot            (),                            //out STD_LOGIC_VECTOR(2:0)
      .m_axi_mpm_ep_arvalid           (m_axi_mpm_ep_arvalid),        //out STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_arready           (m_axi_mpm_ep_arready),        //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_rdata             (m_axi_mpm_ep_rdata),          //in  STD_LOGIC_VECTOR(31:0)
      .m_axi_mpm_ep_rresp             (m_axi_mpm_ep_rresp),          //in  STD_LOGIC_VECTOR(1:0)
      .m_axi_mpm_ep_rvalid            (m_axi_mpm_ep_rvalid),         //in  STD_LOGIC_VECTOR(0:0)
      .m_axi_mpm_ep_rready            (m_axi_mpm_ep_rready),         //out STD_LOGIC_VECTOR(0:0)
      .adc_tile224_ch0_dout_i_tdata   (adc_tile_dout_i_tdata[0]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile224_ch0_dout_i_tready  (adc_tile_dout_i_tready[0]),   //in  STD_LOGIC
      .adc_tile224_ch0_dout_i_tvalid  (adc_tile_dout_i_tvalid[0]),   //out STD_LOGIC
      .adc_tile224_ch0_dout_q_tdata   (adc_tile_dout_q_tdata[0]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile224_ch0_dout_q_tready  (adc_tile_dout_q_tready[0]),   //in  STD_LOGIC
      .adc_tile224_ch0_dout_q_tvalid  (adc_tile_dout_q_tvalid[0]),   //out STD_LOGIC
      .adc_tile224_ch1_dout_i_tdata   (adc_tile_dout_i_tdata[1]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile224_ch1_dout_i_tready  (adc_tile_dout_i_tready[1]),   //in  STD_LOGIC
      .adc_tile224_ch1_dout_i_tvalid  (adc_tile_dout_i_tvalid[1]),   //out STD_LOGIC
      .adc_tile224_ch1_dout_q_tdata   (adc_tile_dout_q_tdata[1]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile224_ch1_dout_q_tready  (adc_tile_dout_q_tready[1]),   //in  STD_LOGIC
      .adc_tile224_ch1_dout_q_tvalid  (adc_tile_dout_q_tvalid[1]),   //out STD_LOGIC
      .adc_tile226_ch0_dout_i_tdata   (adc_tile_dout_i_tdata[2]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile226_ch0_dout_i_tready  (adc_tile_dout_i_tready[2]),   //in  STD_LOGIC
      .adc_tile226_ch0_dout_i_tvalid  (adc_tile_dout_i_tvalid[2]),   //out STD_LOGIC
      .adc_tile226_ch0_dout_q_tdata   (adc_tile_dout_q_tdata[2]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile226_ch0_dout_q_tready  (adc_tile_dout_q_tready[2]),   //in  STD_LOGIC
      .adc_tile226_ch0_dout_q_tvalid  (adc_tile_dout_q_tvalid[2]),   //out STD_LOGIC
      .adc_tile226_ch1_dout_i_tdata   (adc_tile_dout_i_tdata[3]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile226_ch1_dout_i_tready  (adc_tile_dout_i_tready[3]),   //in  STD_LOGIC
      .adc_tile226_ch1_dout_i_tvalid  (adc_tile_dout_i_tvalid[3]),   //out STD_LOGIC
      .adc_tile226_ch1_dout_q_tdata   (adc_tile_dout_q_tdata[3]),    //out STD_LOGIC_VECTOR(127:0)
      .adc_tile226_ch1_dout_q_tready  (adc_tile_dout_q_tready[3]),   //in  STD_LOGIC
      .adc_tile226_ch1_dout_q_tvalid  (adc_tile_dout_q_tvalid[3]),   //out STD_LOGIC
      .dac_tile228_ch0_vout_v_n       (DB0_TX_N[0]),                 //out STD_LOGIC
      .dac_tile228_ch0_vout_v_p       (DB0_TX_P[0]),                 //out STD_LOGIC
      .dac_tile228_ch1_vout_v_n       (DB0_TX_N[1]),                 //out STD_LOGIC
      .dac_tile228_ch1_vout_v_p       (DB0_TX_P[1]),                 //out STD_LOGIC
      .dac_tile229_ch0_vout_v_n       (DB1_TX_N[0]),                 //out STD_LOGIC
      .dac_tile229_ch0_vout_v_p       (DB1_TX_P[0]),                 //out STD_LOGIC
      .dac_tile229_ch1_vout_v_n       (DB1_TX_N[1]),                 //out STD_LOGIC
      .dac_tile229_ch1_vout_v_p       (DB1_TX_P[1]),                 //out STD_LOGIC
      .dac_tile228_ch0_din_tdata      (dac_tile_din_tdata[0]),       //in  STD_LOGIC_VECTOR(255:0)
      .dac_tile228_ch0_din_tready     (dac_tile_din_tready[0]),      //out STD_LOGIC
      .dac_tile228_ch0_din_tvalid     (dac_tile_din_tvalid[0]),      //in  STD_LOGIC
      .dac_tile228_ch1_din_tdata      (dac_tile_din_tdata[1]),       //in  STD_LOGIC_VECTOR(255:0)
      .dac_tile228_ch1_din_tready     (dac_tile_din_tready[1]),      //out STD_LOGIC
      .dac_tile228_ch1_din_tvalid     (dac_tile_din_tvalid[1]),      //in  STD_LOGIC
      .dac_tile229_ch0_din_tdata      (dac_tile_din_tdata[2]),       //in  STD_LOGIC_VECTOR(255:0)
      .dac_tile229_ch0_din_tready     (dac_tile_din_tready[2]),      //out STD_LOGIC
      .dac_tile229_ch0_din_tvalid     (dac_tile_din_tvalid[2]),      //in  STD_LOGIC
      .dac_tile229_ch1_din_tdata      (dac_tile_din_tdata[3]),       //in  STD_LOGIC_VECTOR(255:0)
      .dac_tile229_ch1_din_tready     (dac_tile_din_tready[3]),      //out STD_LOGIC
      .dac_tile229_ch1_din_tvalid     (dac_tile_din_tvalid[3]),      //in  STD_LOGIC
      .sysref_rf_in_diff_n            (SYSREF_RF_N),                 //in  STD_LOGIC
      .sysref_rf_in_diff_p            (SYSREF_RF_P),                 //in  STD_LOGIC
      .adc_tile224_ch0_vin_v_n        (DB0_RX_N[0]),                 //in  STD_LOGIC
      .adc_tile224_ch0_vin_v_p        (DB0_RX_P[0]),                 //in  STD_LOGIC
      .adc_tile224_ch1_vin_v_n        (DB0_RX_N[1]),                 //in  STD_LOGIC
      .adc_tile224_ch1_vin_v_p        (DB0_RX_P[1]),                 //in  STD_LOGIC
      .adc_tile226_ch0_vin_v_n        (DB1_RX_N[0]),                 //in  STD_LOGIC
      .adc_tile226_ch0_vin_v_p        (DB1_RX_P[0]),                 //in  STD_LOGIC
      .adc_tile226_ch1_vin_v_n        (DB1_RX_N[1]),                 //in  STD_LOGIC
      .adc_tile226_ch1_vin_v_p        (DB1_RX_P[1]),                 //in  STD_LOGIC
      .s_axi_hp0_arid                 (axi_hp0_arid),                //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_hp0_awid                 (axi_hp0_awid),                //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_hp0_bid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_hp0_rid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_hp1_arid                 (),                            //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_hp1_awid                 (),                            //in  STD_LOGIC_VECTOR(4:0)
      .s_axi_hp1_bid                  (),                            //out STD_LOGIC_VECTOR(4:0)
      .s_axi_hp1_rid                  ());                           //out STD_LOGIC_VECTOR(4:0)


  // Application-specific AXI4-Lite control interfaces.
  // ----------------------------------------------------------------
  axi_interconnect_app_bd
    axi_interconnect_app_bdx (
      .clk40               (clk40),                  //in  wire
      .clk40_rstn          (clk40_rstn),             //in  wire
      .m_axi_dma0_araddr   (axi_eth_dma0_araddr),    //out wire[39:0]
      .m_axi_dma0_arprot   (),                       //out wire[2:0]
      .m_axi_dma0_arready  (axi_eth_dma0_arready),   //in  wire[0:0]
      .m_axi_dma0_arvalid  (axi_eth_dma0_arvalid),   //out wire[0:0]
      .m_axi_dma0_awaddr   (axi_eth_dma0_awaddr),    //out wire[39:0]
      .m_axi_dma0_awprot   (),                       //out wire[2:0]
      .m_axi_dma0_awready  (axi_eth_dma0_awready),   //in  wire[0:0]
      .m_axi_dma0_awvalid  (axi_eth_dma0_awvalid),   //out wire[0:0]
      .m_axi_dma0_bready   (axi_eth_dma0_bready),    //out wire[0:0]
      .m_axi_dma0_bresp    (axi_eth_dma0_bresp),     //in  wire[1:0]
      .m_axi_dma0_bvalid   (axi_eth_dma0_bvalid),    //in  wire[0:0]
      .m_axi_dma0_rdata    (axi_eth_dma0_rdata),     //in  wire[31:0]
      .m_axi_dma0_rready   (axi_eth_dma0_rready),    //out wire[0:0]
      .m_axi_dma0_rresp    (axi_eth_dma0_rresp),     //in  wire[1:0]
      .m_axi_dma0_rvalid   (axi_eth_dma0_rvalid),    //in  wire[0:0]
      .m_axi_dma0_wdata    (axi_eth_dma0_wdata),     //out wire[31:0]
      .m_axi_dma0_wready   (axi_eth_dma0_wready),    //in  wire[0:0]
      .m_axi_dma0_wstrb    (),                       //out wire[3:0]
      .m_axi_dma0_wvalid   (axi_eth_dma0_wvalid),    //out wire[0:0]
      .m_axi_dma1_araddr   (),                       //out wire[39:0]
      .m_axi_dma1_arprot   (),                       //out wire[2:0]
      .m_axi_dma1_arready  (),                       //in  wire[0:0]
      .m_axi_dma1_arvalid  (),                       //out wire[0:0]
      .m_axi_dma1_awaddr   (),                       //out wire[39:0]
      .m_axi_dma1_awprot   (),                       //out wire[2:0]
      .m_axi_dma1_awready  (),                       //in  wire[0:0]
      .m_axi_dma1_awvalid  (),                       //out wire[0:0]
      .m_axi_dma1_bready   (),                       //out wire[0:0]
      .m_axi_dma1_bresp    (),                       //in  wire[1:0]
      .m_axi_dma1_bvalid   (),                       //in  wire[0:0]
      .m_axi_dma1_rdata    (),                       //in  wire[31:0]
      .m_axi_dma1_rready   (),                       //out wire[0:0]
      .m_axi_dma1_rresp    (),                       //in  wire[1:0]
      .m_axi_dma1_rvalid   (),                       //in  wire[0:0]
      .m_axi_dma1_wdata    (),                       //out wire[31:0]
      .m_axi_dma1_wready   (),                       //in  wire[0:0]
      .m_axi_dma1_wstrb    (),                       //out wire[3:0]
      .m_axi_dma1_wvalid   (),                       //out wire[0:0]
      .m_axi_dma2_araddr   (),                       //out wire[39:0]
      .m_axi_dma2_arprot   (),                       //out wire[2:0]
      .m_axi_dma2_arready  (),                       //in  wire[0:0]
      .m_axi_dma2_arvalid  (),                       //out wire[0:0]
      .m_axi_dma2_awaddr   (),                       //out wire[39:0]
      .m_axi_dma2_awprot   (),                       //out wire[2:0]
      .m_axi_dma2_awready  (),                       //in  wire[0:0]
      .m_axi_dma2_awvalid  (),                       //out wire[0:0]
      .m_axi_dma2_bready   (),                       //out wire[0:0]
      .m_axi_dma2_bresp    (),                       //in  wire[1:0]
      .m_axi_dma2_bvalid   (),                       //in  wire[0:0]
      .m_axi_dma2_rdata    (),                       //in  wire[31:0]
      .m_axi_dma2_rready   (),                       //out wire[0:0]
      .m_axi_dma2_rresp    (),                       //in  wire[1:0]
      .m_axi_dma2_rvalid   (),                       //in  wire[0:0]
      .m_axi_dma2_wdata    (),                       //out wire[31:0]
      .m_axi_dma2_wready   (),                       //in  wire[0:0]
      .m_axi_dma2_wstrb    (),                       //out wire[3:0]
      .m_axi_dma2_wvalid   (),                       //out wire[0:0]
      .m_axi_dma3_araddr   (),                       //out wire[39:0]
      .m_axi_dma3_arprot   (),                       //out wire[2:0]
      .m_axi_dma3_arready  (),                       //in  wire[0:0]
      .m_axi_dma3_arvalid  (),                       //out wire[0:0]
      .m_axi_dma3_awaddr   (),                       //out wire[39:0]
      .m_axi_dma3_awprot   (),                       //out wire[2:0]
      .m_axi_dma3_awready  (),                       //in  wire[0:0]
      .m_axi_dma3_awvalid  (),                       //out wire[0:0]
      .m_axi_dma3_bready   (),                       //out wire[0:0]
      .m_axi_dma3_bresp    (),                       //in  wire[1:0]
      .m_axi_dma3_bvalid   (),                       //in  wire[0:0]
      .m_axi_dma3_rdata    (),                       //in  wire[31:0]
      .m_axi_dma3_rready   (),                       //out wire[0:0]
      .m_axi_dma3_rresp    (),                       //in  wire[1:0]
      .m_axi_dma3_rvalid   (),                       //in  wire[0:0]
      .m_axi_dma3_wdata    (),                       //out wire[31:0]
      .m_axi_dma3_wready   (),                       //in  wire[0:0]
      .m_axi_dma3_wstrb    (),                       //out wire[3:0]
      .m_axi_dma3_wvalid   (),                       //out wire[0:0]
//
      `AXI4LITE_PORT_ASSIGN_NR(m_axi_net0,axi_net0_v)
//
      .m_axi_net0_arprot   (),                       //out wire[2:0]
      .m_axi_net0_awprot   (),                       //out wire[2:0]
      .m_axi_net1_araddr   (),                       //out wire[39:0]
      .m_axi_net1_arprot   (),                       //out wire[2:0]
      .m_axi_net1_arready  (),                       //in  wire[0:0]
      .m_axi_net1_arvalid  (),                       //out wire[0:0]
      .m_axi_net1_awaddr   (),                       //out wire[39:0]
      .m_axi_net1_awprot   (),                       //out wire[2:0]
      .m_axi_net1_awready  (),                       //in  wire[0:0]
      .m_axi_net1_awvalid  (),                       //out wire[0:0]
      .m_axi_net1_bready   (),                       //out wire[0:0]
      .m_axi_net1_bresp    (),                       //in  wire[1:0]
      .m_axi_net1_bvalid   (),                       //in  wire[0:0]
      .m_axi_net1_rdata    (),                       //in  wire[31:0]
      .m_axi_net1_rready   (),                       //out wire[0:0]
      .m_axi_net1_rresp    (),                       //in  wire[1:0]
      .m_axi_net1_rvalid   (),                       //in  wire[0:0]
      .m_axi_net1_wdata    (),                       //out wire[31:0]
      .m_axi_net1_wready   (),                       //in  wire[0:0]
      .m_axi_net1_wstrb    (),                       //out wire[3:0]
      .m_axi_net1_wvalid   (),                       //out wire[0:0]
      .m_axi_net2_araddr   (),                       //out wire[39:0]
      .m_axi_net2_arprot   (),                       //out wire[2:0]
      .m_axi_net2_arready  (),                       //in  wire[0:0]
      .m_axi_net2_arvalid  (),                       //out wire[0:0]
      .m_axi_net2_awaddr   (),                       //out wire[39:0]
      .m_axi_net2_awprot   (),                       //out wire[2:0]
      .m_axi_net2_awready  (),                       //in  wire[0:0]
      .m_axi_net2_awvalid  (),                       //out wire[0:0]
      .m_axi_net2_bready   (),                       //out wire[0:0]
      .m_axi_net2_bresp    (),                       //in  wire[1:0]
      .m_axi_net2_bvalid   (),                       //in  wire[0:0]
      .m_axi_net2_rdata    (),                       //in  wire[31:0]
      .m_axi_net2_rready   (),                       //out wire[0:0]
      .m_axi_net2_rresp    (),                       //in  wire[1:0]
      .m_axi_net2_rvalid   (),                       //in  wire[0:0]
      .m_axi_net2_wdata    (),                       //out wire[31:0]
      .m_axi_net2_wready   (),                       //in  wire[0:0]
      .m_axi_net2_wstrb    (),                       //out wire[3:0]
      .m_axi_net2_wvalid   (),                       //out wire[0:0]
      .m_axi_net3_araddr   (),                       //out wire[39:0]
      .m_axi_net3_arprot   (),                       //out wire[2:0]
      .m_axi_net3_arready  (),                       //in  wire[0:0]
      .m_axi_net3_arvalid  (),                       //out wire[0:0]
      .m_axi_net3_awaddr   (),                       //out wire[39:0]
      .m_axi_net3_awprot   (),                       //out wire[2:0]
      .m_axi_net3_awready  (),                       //in  wire[0:0]
      .m_axi_net3_awvalid  (),                       //out wire[0:0]
      .m_axi_net3_bready   (),                       //out wire[0:0]
      .m_axi_net3_bresp    (),                       //in  wire[1:0]
      .m_axi_net3_bvalid   (),                       //in  wire[0:0]
      .m_axi_net3_rdata    (),                       //in  wire[31:0]
      .m_axi_net3_rready   (),                       //out wire[0:0]
      .m_axi_net3_rresp    (),                       //in  wire[1:0]
      .m_axi_net3_rvalid   (),                       //in  wire[0:0]
      .m_axi_net3_wdata    (),                       //out wire[31:0]
      .m_axi_net3_wready   (),                       //in  wire[0:0]
      .m_axi_net3_wstrb    (),                       //out wire[3:0]
      .m_axi_net3_wvalid   (),                       //out wire[0:0]
      .s_axi_app_araddr    (m_axi_app_araddr),       //in  wire[39:0]
      .s_axi_app_arprot    (m_axi_app_arprot),       //in  wire[2:0]
      .s_axi_app_arready   (m_axi_app_arready),      //out wire[0:0]
      .s_axi_app_arvalid   (m_axi_app_arvalid),      //in  wire[0:0]
      .s_axi_app_awaddr    (m_axi_app_awaddr),       //in  wire[39:0]
      .s_axi_app_awprot    (m_axi_app_awprot),       //in  wire[2:0]
      .s_axi_app_awready   (m_axi_app_awready),      //out wire[0:0]
      .s_axi_app_awvalid   (m_axi_app_awvalid),      //in  wire[0:0]
      .s_axi_app_bready    (m_axi_app_bready),       //in  wire[0:0]
      .s_axi_app_bresp     (m_axi_app_bresp),        //out wire[1:0]
      .s_axi_app_bvalid    (m_axi_app_bvalid),       //out wire[0:0]
      .s_axi_app_rdata     (m_axi_app_rdata),        //out wire[31:0]
      .s_axi_app_rready    (m_axi_app_rready),       //in  wire[0:0]
      .s_axi_app_rresp     (m_axi_app_rresp),        //out wire[1:0]
      .s_axi_app_rvalid    (m_axi_app_rvalid),       //out wire[0:0]
      .s_axi_app_wdata     (m_axi_app_wdata),        //in  wire[31:0]
      .s_axi_app_wready    (m_axi_app_wready),       //out wire[0:0]
      .s_axi_app_wstrb     (m_axi_app_wstrb),        //in  wire[3:0]
      .s_axi_app_wvalid    (m_axi_app_wvalid));      //in  wire[0:0]

  //------------------------------------------------------------------
  // RF + Control Daughterboard Cores
  //------------------------------------------------------------------

  localparam num_dboards = 2;

  // User data interfaces (data_clk domain)
  // ADC
  logic [31:0] adc_data_out_tdata  [0:3]; // 1 SPC (I + Q)
  logic [3:0]  adc_data_out_tready;
  logic [3:0]  adc_data_out_tvalid;
  // DAC
  logic [31:0] dac_data_in_tdata   [0:3]; // 1 SPC (I + Q)
  logic [3:0]  dac_data_in_tready;
  logic [3:0]  dac_data_in_tvalid;

  // Tie flow control signals (not existent in downstream logic)
  //vhook_warn TODO: assert flow control bits streams for all ports (3->0)
  // RX chain always ready to receive, rf_core_100m detemines when data is valid
  assign adc_data_out_tready = {{2{1'b0}}, {2{1'b1}}};
  // TX chain always provides valid data when the rf_core_100m is ready to receive
  assign dac_data_in_tvalid  = {{2{1'b0}}, {2{1'b1}}};

  // Master resets from Radio (data_clk domain)
  logic [num_dboards-1:0] adc_enable_pulse_dclk;
  logic [num_dboards-1:0] adc_reset_pulse_dclk;
  logic [num_dboards-1:0] dac_enable_pulse_dclk;
  logic [num_dboards-1:0] dac_reset_pulse_dclk;
  //vhook_warn TODO: connect rf_core_100m resets to radio.
  assign adc_enable_pulse_dclk = {num_dboards{1'b0}};
  assign adc_reset_pulse_dclk  = {num_dboards{1'b0}};
  assign dac_enable_pulse_dclk = {num_dboards{1'b0}};
  assign dac_reset_pulse_dclk  = {num_dboards{1'b0}};

  // GPIO ctrlport interface
  logic        db_ctrlport_req_rd       [0:1];
  logic        db_ctrlport_req_wr       [0:1];
  logic [19:0] db_ctrlport_req_addr     [0:1];
  logic [31:0] db_ctrlport_req_data     [0:1];
  logic [ 3:0] db_ctrlport_req_byte_en  [0:1];
  logic        db_ctrlport_req_has_time [0:1];
  logic [63:0] db_ctrlport_req_time     [0:1];

  logic        db_ctrlport_resp_ack     [0:1];
  logic [31:0] db_ctrlport_resp_data    [0:1];
  logic [ 1:0] db_ctrlport_resp_status  [0:1];
  // GPIO interface
  logic [19:0] db_gpio_in_int [0:1];
  logic [19:0] db_gpio_out_int [0:1];
  logic [19:0] db_gpio_out_en_int [0:1];
  logic [19:0] db_gpio_out_ext [0:1];
  logic [19:0] db_gpio_out_en_ext [0:1];

  // GPIO states
  logic [ 3:0] rx_running;
  logic [ 3:0] tx_running;
  logic [ 3:0] db_state [0:1];

  assign db_state[0] = {tx_running[1], rx_running[1], tx_running[0], rx_running[0]};
  assign db_state[1] = {tx_running[3], rx_running[3], tx_running[2], rx_running[2]};

  // For 100 MHz of BW, only 2 SPC are valid out of the full RFDC's AXI-Stream
  // vectors. These constants defined the width of the valid data pipe.
  // Per Xilinx support, the valid samples for lower data rates (compared to
  // the capacity of the AXI-Stream pipes) will be located in the LSBs.
  localparam ADC_AXIS_W = 32;
  localparam DAC_AXIS_W = 64;

  genvar dboard_num;
  generate
  for (dboard_num=0; dboard_num < (num_dboards); dboard_num = dboard_num + 1)
    begin : rf_core_100m_gen
      //vhook   rf_core_100m                  rf_core_100m_gen
      //vhook_a   s_axi_config_clk            clk40
      //vhook_# RFDC Data Interfaces
      //vhook_a   {^adc_data_in_(.)_tdata_(.)} adc_tile_dout_$1_tdata[num_dboards*dboard_num+$2][ADC_AXIS_W-1:0]
      //vhook_a   {^adc_data_in_(.)_(.*)_([01])}  adc_tile_dout_$1_$2[num_dboards*dboard_num+$3]
      //vhook_a   {^dac_data_out_tdata_(.)}    dac_tile_din_tdata[num_dboards*dboard_num+$1][DAC_AXIS_W-1:0]
      //vhook_a   {^dac_data_out_(.*)_(.)}     dac_tile_din_$1[num_dboards*dboard_num+$2]
      //vhook_# User Data Interfaces
      //vhook_a   {^adc_data_out_(.*)_([01])}    adc_data_out_$1[num_dboards*dboard_num+$2]
      //vhook_a   {^dac_data_in_(.*)_([01])}     dac_data_in_$1[num_dboards*dboard_num+$2]
      //vhook_# Resets from radio block
      //vhook_a   {^invert_(.*)_iq_rclk2}     invert_$1_iq_rclk2[4*dboard_num+3:4*dboard_num]
      //vhook_# Control/status vectors
      //vhook_a   {^(.*)_sclk}                rf_$1_clk40[16*dboard_num+15:16*dboard_num]
      rf_core_100m
        rf_core_100m_gen (
          .rfdc_clk                   (rfdc_clk),                                                      //in  wire
          .rfdc_clk_2x                (rfdc_clk_2x),                                                   //in  wire
          .data_clk                   (data_clk),                                                      //in  wire
          .data_clk_2x                (data_clk_2x),                                                   //in  wire
          .s_axi_config_clk           (clk40),                                                         //in  wire
          .adc_data_in_i_tdata_0      (adc_tile_dout_i_tdata[num_dboards*dboard_num+0][ADC_AXIS_W-1:0]), //in  wire[31:0]
          .adc_data_in_i_tready_0     (adc_tile_dout_i_tready[num_dboards*dboard_num+0]),              //out wire
          .adc_data_in_i_tvalid_0     (adc_tile_dout_i_tvalid[num_dboards*dboard_num+0]),              //in  wire
          .adc_data_in_q_tdata_0      (adc_tile_dout_q_tdata[num_dboards*dboard_num+0][ADC_AXIS_W-1:0]), //in  wire[31:0]
          .adc_data_in_q_tready_0     (adc_tile_dout_q_tready[num_dboards*dboard_num+0]),              //out wire
          .adc_data_in_q_tvalid_0     (adc_tile_dout_q_tvalid[num_dboards*dboard_num+0]),              //in  wire
          .adc_data_in_i_tdata_1      (adc_tile_dout_i_tdata[num_dboards*dboard_num+1][ADC_AXIS_W-1:0]), //in  wire[31:0]
          .adc_data_in_i_tready_1     (adc_tile_dout_i_tready[num_dboards*dboard_num+1]),              //out wire
          .adc_data_in_i_tvalid_1     (adc_tile_dout_i_tvalid[num_dboards*dboard_num+1]),              //in  wire
          .adc_data_in_q_tdata_1      (adc_tile_dout_q_tdata[num_dboards*dboard_num+1][ADC_AXIS_W-1:0]), //in  wire[31:0]
          .adc_data_in_q_tready_1     (adc_tile_dout_q_tready[num_dboards*dboard_num+1]),              //out wire
          .adc_data_in_q_tvalid_1     (adc_tile_dout_q_tvalid[num_dboards*dboard_num+1]),              //in  wire
          .dac_data_out_tdata_0       (dac_tile_din_tdata[num_dboards*dboard_num+0][DAC_AXIS_W-1:0]),  //out wire[63:0]
          .dac_data_out_tready_0      (dac_tile_din_tready[num_dboards*dboard_num+0]),                 //in  wire
          .dac_data_out_tvalid_0      (dac_tile_din_tvalid[num_dboards*dboard_num+0]),                 //out wire
          .dac_data_out_tdata_1       (dac_tile_din_tdata[num_dboards*dboard_num+1][DAC_AXIS_W-1:0]),  //out wire[63:0]
          .dac_data_out_tready_1      (dac_tile_din_tready[num_dboards*dboard_num+1]),                 //in  wire
          .dac_data_out_tvalid_1      (dac_tile_din_tvalid[num_dboards*dboard_num+1]),                 //out wire
          .adc_data_out_tdata_0       (adc_data_out_tdata[num_dboards*dboard_num+0]),                  //out wire[31:0]
          .adc_data_out_tready_0      (adc_data_out_tready[num_dboards*dboard_num+0]),                 //in  wire
          .adc_data_out_tvalid_0      (adc_data_out_tvalid[num_dboards*dboard_num+0]),                 //out wire
          .adc_data_out_tdata_1       (adc_data_out_tdata[num_dboards*dboard_num+1]),                  //out wire[31:0]
          .adc_data_out_tready_1      (adc_data_out_tready[num_dboards*dboard_num+1]),                 //in  wire
          .adc_data_out_tvalid_1      (adc_data_out_tvalid[num_dboards*dboard_num+1]),                 //out wire
          .dac_data_in_tdata_0        (dac_data_in_tdata[num_dboards*dboard_num+0]),                   //in  wire[31:0]
          .dac_data_in_tready_0       (dac_data_in_tready[num_dboards*dboard_num+0]),                  //out wire
          .dac_data_in_tvalid_0       (dac_data_in_tvalid[num_dboards*dboard_num+0]),                  //in  wire
          .dac_data_in_tdata_1        (dac_data_in_tdata[num_dboards*dboard_num+1]),                   //in  wire[31:0]
          .dac_data_in_tready_1       (dac_data_in_tready[num_dboards*dboard_num+1]),                  //out wire
          .dac_data_in_tvalid_1       (dac_data_in_tvalid[num_dboards*dboard_num+1]),                  //in  wire
          .invert_adc_iq_rclk2        (invert_adc_iq_rclk2[4*dboard_num+3:4*dboard_num]),              //in  wire[3:0]
          .invert_dac_iq_rclk2        (invert_dac_iq_rclk2[4*dboard_num+3:4*dboard_num]),              //in  wire[3:0]
          .dsp_info_sclk              (rf_dsp_info_clk40[16*dboard_num+15:16*dboard_num]),             //out wire[15:0]
          .axi_status_sclk            (rf_axi_status_clk40[16*dboard_num+15:16*dboard_num]),           //out wire[15:0]
          .adc_data_out_resetn_dclk   (adc_data_out_resetn_dclk),                                      //in  wire
          .adc_enable_data_rclk       (adc_enable_data_rclk),                                          //in  wire
          .adc_rfdc_axi_resetn_rclk   (adc_rfdc_axi_resetn_rclk),                                      //in  wire
          .dac_data_in_resetn_dclk    (dac_data_in_resetn_dclk),                                       //in  wire
          .dac_data_in_resetn_rclk    (dac_data_in_resetn_rclk),                                       //in  wire
          .dac_data_in_resetn_rclk2x  (dac_data_in_resetn_rclk2x),                                     //in  wire
          .fir_resetn_rclk2x          (fir_resetn_rclk2x));                                            //in  wire
    end

    for (dboard_num=0; dboard_num < (num_dboards); dboard_num = dboard_num + 1)
    begin : db_gpio_gen
      //vhook db_gpio_interface db_gpio_interface_inst
      //vhook_a   {db_state}                 {db_state[dboard_num]}
      //vhook_a   {ctrlport_rst}             {radio_rst}
      //vhook_a   {s_ctrlport_(.*)}          {db_ctrlport_$1[dboard_num]}
      //vhook_a   {gpio_(.*)}                {db_gpio_$1_int[dboard_num]}
      db_gpio_interface
        db_gpio_interface_inst (
          .radio_clk                (radio_clk),                              //in  wire
          .pll_ref_clk              (pll_ref_clk),                            //in  wire
          .db_state                 (db_state[dboard_num]),                   //in  wire[3:0]
          .radio_time               (radio_time),                             //in  wire[63:0]
          .radio_time_stb           (radio_time_stb),                         //in  wire
          .ctrlport_rst             (radio_rst),                              //in  wire
          .s_ctrlport_req_wr        (db_ctrlport_req_wr[dboard_num]),         //in  wire
          .s_ctrlport_req_rd        (db_ctrlport_req_rd[dboard_num]),         //in  wire
          .s_ctrlport_req_addr      (db_ctrlport_req_addr[dboard_num]),       //in  wire[19:0]
          .s_ctrlport_req_data      (db_ctrlport_req_data[dboard_num]),       //in  wire[31:0]
          .s_ctrlport_req_byte_en   (db_ctrlport_req_byte_en[dboard_num]),    //in  wire[3:0]
          .s_ctrlport_req_has_time  (db_ctrlport_req_has_time[dboard_num]),   //in  wire
          .s_ctrlport_req_time      (db_ctrlport_req_time[dboard_num]),       //in  wire[63:0]
          .s_ctrlport_resp_ack      (db_ctrlport_resp_ack[dboard_num]),       //out wire
          .s_ctrlport_resp_status   (db_ctrlport_resp_status[dboard_num]),    //out wire[1:0]
          .s_ctrlport_resp_data     (db_ctrlport_resp_data[dboard_num]),      //out wire[31:0]
          .gpio_in                  (db_gpio_in_int[dboard_num]),             //in  wire[19:0]
          .gpio_out                 (db_gpio_out_int[dboard_num]),            //out wire[19:0]
          .gpio_out_en              (db_gpio_out_en_int[dboard_num]));        //out wire[19:0]
    end
  endgenerate

  //vhook db_gpio_reordering db_gpio_reordering_inst
  //vhook_a {db(.)_gpio_in_ext} {DB$1_GPIO}
  //vhook_a {db(.)_(.*)} {db_$2[$1]}
  db_gpio_reordering
    db_gpio_reordering_inst (
      .db0_gpio_in_int      (db_gpio_in_int[0]),       //out wire[19:0]
      .db0_gpio_out_int     (db_gpio_out_int[0]),      //in  wire[19:0]
      .db0_gpio_out_en_int  (db_gpio_out_en_int[0]),   //in  wire[19:0]
      .db1_gpio_in_int      (db_gpio_in_int[1]),       //out wire[19:0]
      .db1_gpio_out_int     (db_gpio_out_int[1]),      //in  wire[19:0]
      .db1_gpio_out_en_int  (db_gpio_out_en_int[1]),   //in  wire[19:0]
      .db0_gpio_in_ext      (DB0_GPIO),                //in  wire[19:0]
      .db0_gpio_out_ext     (db_gpio_out_ext[0]),      //out wire[19:0]
      .db0_gpio_out_en_ext  (db_gpio_out_en_ext[0]),   //out wire[19:0]
      .db1_gpio_in_ext      (DB1_GPIO),                //in  wire[19:0]
      .db1_gpio_out_ext     (db_gpio_out_ext[1]),      //out wire[19:0]
      .db1_gpio_out_en_ext  (db_gpio_out_en_ext[1]));  //out wire[19:0]

  // DB GPIO tristate buffers
  genvar j;
  generate for (j=0; j<20; j=j+1) begin: db_gpio_tristate_gen
    assign DB0_GPIO[j] = (db_gpio_out_en_ext[0][j]) ? db_gpio_out_ext[0][j] : 1'bz;
    assign DB1_GPIO[j] = (db_gpio_out_en_ext[1][j]) ? db_gpio_out_ext[1][j] : 1'bz;
  end endgenerate


  //------------------------------------------------------------------
  // QSFP Interfaces
  //------------------------------------------------------------------

  // Misc QSFP signals are currently unused
  assign QSFP0_RESET_n  = 1'b1;   // Module reset
  assign QSFP0_LPMODE_n = 1'b0;   // Low-power Mode

  assign QSFP1_RESET_n  = 1'b1;   // Module reset
  assign QSFP1_LPMODE_n = 1'b0;   // Low-power Mode

  logic [31:0] sfp_port_info;

  logic [15:0] device_id;



  AxiStreamIf #(.DATA_WIDTH(CHDR_W),.USER_WIDTH(CHDR_USER_W),
                .TKEEP(0),.TUSER(0))
    v2e    (clk200, clk200_rst);
  AxiStreamIf #(.DATA_WIDTH(CHDR_W),.USER_WIDTH(CHDR_USER_W),
                .TKEEP(0),.TUSER(0))
    e2v    (clk200, clk200_rst);


  //vhook_warn TODO: Why is Ethernet DMA using clk40? Seems slow.
  AxiStreamIf #(.DATA_WIDTH(CPU_W),.USER_WIDTH(CPU_USER_W),
                .TUSER(0))
    c2e    (clk40, clk40_rst);
  AxiStreamIf #(.DATA_WIDTH(CPU_W),.USER_WIDTH(CPU_USER_W),
                .TUSER(0))
    e2c    (clk40, clk40_rst);

  //AXIS translate from procedural to continuous
  AxiLiteIf #(.DATA_WIDTH(REG_DWIDTH),.ADDR_WIDTH(REG_AWIDTH))
    axi_net0 (clk40, clk40_rst);
  always_comb begin `AXI4LITE_ASSIGN(axi_net0_v,axi_net0) end

  x4xx_qsfp_wrapper #(
  `ifdef BUILD_100G
    .PROTOCOL     ("100GbE"),
  `elsif BUILD_10G
    .PROTOCOL     ("10GbE"),
  `else
    .PROTOCOL     ("Disabled"),
  `endif
    .CPU_W        (CPU_W),
    .CHDR_W       (CHDR_W),
    .DWIDTH       (REG_DWIDTH),
    .AWIDTH       (REG_AWIDTH),
    .PORTNUM      (0),
    .MDIO_EN      (0),
    .MDIO_PHYADDR (0)
  ) x4xx_qsfp_wrapper_0 (
    .areset          (areset),
    .refclk_p        (MGT_REFCLK_LMK_P[0]),
    .refclk_n        (MGT_REFCLK_LMK_N[0]),
    .bus_rst         (clk200_rst),
    .clk100          (clk100),             // IP configured for 100 MHz DClk
    .bus_clk         (clk200),
    .s_axi           (axi_net0),
    `ifdef PORT0_LANES
    .tx_p            (QSFP0_TX_P),
    .tx_n            (QSFP0_TX_N),
    .rx_p            (QSFP0_RX_P),
    .rx_n            (QSFP0_RX_N),
    `else
    .tx_p            (),
    .tx_n            (),
    .rx_p            (4'b0),
    .rx_n            (4'b1),
    `endif
    .e2v             (e2v),
    .v2e             (v2e),
    .e2c             (e2c),
    .c2e             (c2e),
    .device_id       (device_id),
    .port_info       (sfp_port_info),
    .link_up         (eth0_link_up),       //vhook_warn TODO: Need to connect link signal to CPLD SPI interface
    .activity        ()                    //vhook_warn TODO: Need to connect activity signal to CPLD SPI interface
  );

  //------------------------------------------------------------------
  // QSFP DMA
  //------------------------------------------------------------------

  axi_eth_dma axi_eth_dma_i0 (
    .s_axi_lite_aclk        (clk40),
    .m_axi_sg_aclk          (clk40),
    .m_axi_mm2s_aclk        (clk40),
    .m_axi_s2mm_aclk        (clk40),
    .axi_resetn             (clk40_rstn),
    .s_axi_lite_awaddr      (axi_eth_dma0_awaddr),
    .s_axi_lite_awvalid     (axi_eth_dma0_awvalid),
    .s_axi_lite_awready     (axi_eth_dma0_awready),
    .s_axi_lite_wdata       (axi_eth_dma0_wdata),
    .s_axi_lite_wvalid      (axi_eth_dma0_wvalid),
    .s_axi_lite_wready      (axi_eth_dma0_wready),
    .s_axi_lite_bresp       (axi_eth_dma0_bresp),
    .s_axi_lite_bvalid      (axi_eth_dma0_bvalid),
    .s_axi_lite_bready      (axi_eth_dma0_bready),
    .s_axi_lite_araddr      (axi_eth_dma0_araddr),
    .s_axi_lite_arvalid     (axi_eth_dma0_arvalid),
    .s_axi_lite_arready     (axi_eth_dma0_arready),
    .s_axi_lite_rdata       (axi_eth_dma0_rdata),
    .s_axi_lite_rresp       (axi_eth_dma0_rresp),
    .s_axi_lite_rvalid      (axi_eth_dma0_rvalid),
    .s_axi_lite_rready      (axi_eth_dma0_rready),
    .m_axi_sg_awaddr        (axi_gp0_awaddr),
    .m_axi_sg_awlen         (axi_gp0_awlen),
    .m_axi_sg_awsize        (axi_gp0_awsize),
    .m_axi_sg_awburst       (axi_gp0_awburst),
    .m_axi_sg_awprot        (axi_gp0_awprot),
    .m_axi_sg_awcache       (axi_gp0_awcache),
    .m_axi_sg_awvalid       (axi_gp0_awvalid),
    .m_axi_sg_awready       (axi_gp0_awready),
    .m_axi_sg_wdata         (axi_gp0_wdata),
    .m_axi_sg_wstrb         (axi_gp0_wstrb),
    .m_axi_sg_wlast         (axi_gp0_wlast),
    .m_axi_sg_wvalid        (axi_gp0_wvalid),
    .m_axi_sg_wready        (axi_gp0_wready),
    .m_axi_sg_bresp         (axi_gp0_bresp),
    .m_axi_sg_bvalid        (axi_gp0_bvalid),
    .m_axi_sg_bready        (axi_gp0_bready),
    .m_axi_sg_araddr        (axi_gp0_araddr),
    .m_axi_sg_arlen         (axi_gp0_arlen),
    .m_axi_sg_arsize        (axi_gp0_arsize),
    .m_axi_sg_arburst       (axi_gp0_arburst),
    .m_axi_sg_arprot        (axi_gp0_arprot),
    .m_axi_sg_arcache       (axi_gp0_arcache),
    .m_axi_sg_arvalid       (axi_gp0_arvalid),
    .m_axi_sg_arready       (axi_gp0_arready),
    .m_axi_sg_rdata         (axi_gp0_rdata),
    .m_axi_sg_rresp         (axi_gp0_rresp),
    .m_axi_sg_rlast         (axi_gp0_rlast),
    .m_axi_sg_rvalid        (axi_gp0_rvalid),
    .m_axi_sg_rready        (axi_gp0_rready),
    .m_axi_mm2s_araddr      (axi_hp0_araddr),
    .m_axi_mm2s_arlen       (axi_hp0_arlen),
    .m_axi_mm2s_arsize      (axi_hp0_arsize),
    .m_axi_mm2s_arburst     (axi_hp0_arburst),
    .m_axi_mm2s_arprot      (axi_hp0_arprot),
    .m_axi_mm2s_arcache     (axi_hp0_arcache),
    .m_axi_mm2s_arvalid     (axi_hp0_arvalid),
    .m_axi_mm2s_arready     (axi_hp0_arready),
    .m_axi_mm2s_rdata       (axi_hp0_rdata),
    .m_axi_mm2s_rresp       (axi_hp0_rresp),
    .m_axi_mm2s_rlast       (axi_hp0_rlast),
    .m_axi_mm2s_rvalid      (axi_hp0_rvalid),
    .m_axi_mm2s_rready      (axi_hp0_rready),
    .mm2s_prmry_reset_out_n (),
    .m_axis_mm2s_tdata      (c2e.tdata),
    .m_axis_mm2s_tkeep      (c2e.tkeep),
    .m_axis_mm2s_tvalid     (c2e.tvalid),
    .m_axis_mm2s_tready     (c2e.tready),
    .m_axis_mm2s_tlast      (c2e.tlast),
    .m_axi_s2mm_awaddr      (axi_hp0_awaddr),
    .m_axi_s2mm_awlen       (axi_hp0_awlen),
    .m_axi_s2mm_awsize      (axi_hp0_awsize),
    .m_axi_s2mm_awburst     (axi_hp0_awburst),
    .m_axi_s2mm_awprot      (axi_hp0_awprot),
    .m_axi_s2mm_awcache     (axi_hp0_awcache),
    .m_axi_s2mm_awvalid     (axi_hp0_awvalid),
    .m_axi_s2mm_awready     (axi_hp0_awready),
    .m_axi_s2mm_wdata       (axi_hp0_wdata),
    .m_axi_s2mm_wstrb       (axi_hp0_wstrb),
    .m_axi_s2mm_wlast       (axi_hp0_wlast),
    .m_axi_s2mm_wvalid      (axi_hp0_wvalid),
    .m_axi_s2mm_wready      (axi_hp0_wready),
    .m_axi_s2mm_bresp       (axi_hp0_bresp),
    .m_axi_s2mm_bvalid      (axi_hp0_bvalid),
    .m_axi_s2mm_bready      (axi_hp0_bready),
    .s2mm_prmry_reset_out_n (),
    .s_axis_s2mm_tdata      (e2c.tdata),
    .s_axis_s2mm_tkeep      (e2c.tkeep),
    .s_axis_s2mm_tvalid     (e2c.tvalid),
    .s_axis_s2mm_tready     (e2c.tready),
    .s_axis_s2mm_tlast      (e2c.tlast),
    .mm2s_introut           (eth0_tx_irq),
    .s2mm_introut           (eth0_rx_irq),
    .axi_dma_tstvec         ()
  );

  //------------------------------------------------------------------
  // Internal Ethernet Interface
  //------------------------------------------------------------------

    AxiStreamIf #(.DATA_WIDTH(CHDR_W),.TKEEP(0),.TUSER(0))
      v2e_dma_cw (clk200, clk200_rst);
    AxiStreamIf #(.DATA_WIDTH(CHDR_W),.TKEEP(0),.TUSER(0))
      v2e_dma_cw0 (clk200, clk200_rst);
    AxiStreamIf #(.DATA_WIDTH(64),.TKEEP(0),.TUSER(0))
      v2e_dma    (clk200, clk200_rst);

    AxiStreamIf #(.DATA_WIDTH(64),.TKEEP(0),.TUSER(0))
      e2v_dma    (clk200, clk200_rst);
    AxiStreamIf #(.DATA_WIDTH(CHDR_W),.TKEEP(0),.TUSER(0))
      e2v_dma_cw0 (clk200, clk200_rst);
    AxiStreamIf #(.DATA_WIDTH(CHDR_W),.TKEEP(0),.TUSER(0))
      e2v_dma_cw (clk200, clk200_rst);

  // CHDR DMA bus (clk200 domain)
  // Internal Ethernet xport adapter to PS (clk200 domain)
  if (CPU_W != CHDR_W) begin
    // v2e_dma_cw(core:dmao)->(FIFO)->v2e_dma_cw0->(CONV_WIDTH)->v2e_dma(internal_ep:in)
    // help prevent upstream back pressure as we adjust size
    axi4s_fifo #(.SIZE(10))
      v2e_dma_fifo (.clear(1'b0),.space(),.occupied(),.i(v2e_dma_cw),.o(v2e_dma_cw0));
    // Convert incoming CHDR_W
    axi4s_width_conv v2e_dma_width_conv (.i(v2e_dma_cw0), .o(v2e_dma));
    // (internal_ep:out)e2v_dma ->(CONV_WIDTH)-> e2v_dma_cw0 ->(PACKET_GATE)-> e2v_dma_cw(core:dmai)
    axi4s_width_conv e2v_dma_width_conv (.i(e2v_dma), .o(e2v_dma_cw0));
    // Adding so packet will be contiguous going out
    // The MAC needs bandwdith feeding it to be greater than the line rate
    axi4s_packet_gate #(.SIZE(17-$clog2(CHDR_W)), .USE_AS_BUFF(0))
        e2v_dma_gate (.clear(1'b0),.error(1'b0),.i(e2v_dma_cw0),.o(e2v_dma_cw));
  end else begin
    always_comb begin
      `AXI4S_ASSIGN(v2e_dma,v2e_dma_cw)
      `AXI4S_ASSIGN(e2v_dma_cw,e2v_dma)
    end
  end



  //vhook_warn TODO: Connect unused misc signals from eth_internal
  //vhook_e eth_internal  eth_internal_i
  //vhook_# -- Generics ----------------------------------------------
  //vhook_g DWIDTH          REG_DWIDTH
  //vhook_g AWIDTH          REG_AWIDTH
  //vhook_g PORTNUM         8'd0
  //vhook_g RFNOC_PROTOVER  RFNOC_PROTOVER
  //vhook_# -- Clocking and resets -----------------------------------
  //vhook_a bus_clk        clk200
  //vhook_a bus_rst        clk200_rst
  //vhook_a s_axi_aclk     clk40
  //vhook_a s_axi_aresetn  clk40_rstn
  //vhook_# -- AXI4-Lite control bus ---------------------------------
  //vhook_a {^s_axi_(.*)}  {axi_eth_internal_$1}
  //vhook_# -- Host-Ethernet DMA interface ---------------------------
  //vhook_a {^e2h_(.*)}    {e2h_dma_$1}
  //vhook_a {^h2e_(.*)}    {h2e_dma_$1}
  //vhook_# -- CHDR router interface ---------------------------------
  //vhook_a {^e2v_(.*)     {e2v_dma.$1}
  //vhook_a {^v2e_(.*)     {v2e_dma.$1}
  //vhook_# -- Misc --------------------------------------------------
  //vhook_a port_info      {}
  //vhook_a link_up        {}
  //vhook_a activity       {}
  eth_internal
    # (
      .DWIDTH          (REG_DWIDTH),       //integer:=32
      .AWIDTH          (REG_AWIDTH),       //integer:=14
      .PORTNUM         (8'd0),             //wire[7:0]:=0
      .RFNOC_PROTOVER  (RFNOC_PROTOVER))   //wire[15:0]:={8'b01,8'b0}
    eth_internal_i (
      .bus_rst        (clk200_rst),                 //in  wire
      .bus_clk        (clk200),                     //in  wire
      .s_axi_aclk     (clk40),                      //in  wire
      .s_axi_aresetn  (clk40_rstn),                 //in  wire
      .s_axi_awaddr   (axi_eth_internal_awaddr),    //in  wire[(AWIDTH-1):0]
      .s_axi_awvalid  (axi_eth_internal_awvalid),   //in  wire
      .s_axi_awready  (axi_eth_internal_awready),   //out wire
      .s_axi_wdata    (axi_eth_internal_wdata),     //in  wire[(DWIDTH-1):0]
      .s_axi_wstrb    (axi_eth_internal_wstrb),     //in  wire[((DWIDTH/8)-1):0]
      .s_axi_wvalid   (axi_eth_internal_wvalid),    //in  wire
      .s_axi_wready   (axi_eth_internal_wready),    //out wire
      .s_axi_bresp    (axi_eth_internal_bresp),     //out wire[1:0]
      .s_axi_bvalid   (axi_eth_internal_bvalid),    //out wire
      .s_axi_bready   (axi_eth_internal_bready),    //in  wire
      .s_axi_araddr   (axi_eth_internal_araddr),    //in  wire[(AWIDTH-1):0]
      .s_axi_arvalid  (axi_eth_internal_arvalid),   //in  wire
      .s_axi_arready  (axi_eth_internal_arready),   //out wire
      .s_axi_rdata    (axi_eth_internal_rdata),     //out wire[(DWIDTH-1):0]
      .s_axi_rresp    (axi_eth_internal_rresp),     //out wire[1:0]
      .s_axi_rvalid   (axi_eth_internal_rvalid),    //out wire
      .s_axi_rready   (axi_eth_internal_rready),    //in  wire
      .e2h_tdata      (e2h_dma_tdata),              //out wire[63:0]
      .e2h_tkeep      (e2h_dma_tkeep),              //out wire[7:0]
      .e2h_tlast      (e2h_dma_tlast),              //out wire
      .e2h_tvalid     (e2h_dma_tvalid),             //out wire
      .e2h_tready     (e2h_dma_tready),             //in  wire
      .h2e_tdata      (h2e_dma_tdata),              //in  wire[63:0]
      .h2e_tkeep      (h2e_dma_tkeep),              //in  wire[7:0]
      .h2e_tlast      (h2e_dma_tlast),              //in  wire
      .h2e_tvalid     (h2e_dma_tvalid),             //in  wire
      .h2e_tready     (h2e_dma_tready),             //out wire
      .e2v_tdata      (e2v_dma.tdata),              //out wire[63:0]
      .e2v_tlast      (e2v_dma.tlast),              //out wire
      .e2v_tvalid     (e2v_dma.tvalid),             //out wire
      .e2v_tready     (e2v_dma.tready),             //in  wire
      .v2e_tdata      (v2e_dma.tdata),              //in  wire[63:0]
      .v2e_tlast      (v2e_dma.tlast),              //in  wire
      .v2e_tvalid     (v2e_dma.tvalid),             //in  wire
      .v2e_tready     (v2e_dma.tready),             //out wire
      .port_info      (),                           //out wire[31:0]
      .device_id      (device_id),                  //in  wire[15:0]
      .link_up        (),                           //out wire
      .activity       ());                          //out wire


  //---------------------------------------------------------------------------
  // CPLD interface
  //---------------------------------------------------------------------------


  //vhook_warn connect time and ctrlport to main application
  //vhook_e cpld_interface
  //vhook_a s_axi_aclk clk40
  //vhook_a s_axi_aresetn clk40_rstn
  //vhook_a radio_clk data_clk
  //vhook_a ctrlport_rst prc_rst
  //vhook_a {s_axi_(.*addr)} m_axi_mpm_ep_$1[16:0]
  //vhook_a {s_axi_(.*)} m_axi_mpm_ep_$1
  //vhook_a {s_ctrlport.*} {}
  //vhook_a ss \{PL_CPLD_CS1_n, PL_CPLD_CS0_n\}
  //vhook_a sclk PL_CPLD_SCLK
  //vhook_a mosi PL_CPLD_MOSI
  //vhook_a miso PL_CPLD_MISO
  //vhook_a {qsfp(0|1)_.*} {}
  cpld_interface
    cpld_interfacex (
      .s_axi_aclk               (clk40),            //in  wire
      .s_axi_aresetn            (clk40_rstn),       //in  wire
      .pll_ref_clk              (pll_ref_clk),      //in  wire
      .radio_clk                (data_clk),         //in  wire
      .ctrlport_rst             (prc_rst),          //in  wire
      .radio_time               (radio_time),       //in  wire[63:0]
      .radio_time_stb           (radio_time_stb),   //in  wire
      .s_axi_awaddr             (m_axi_mpm_ep_awaddr[16:0]), //in  wire[16:0]
      .s_axi_awvalid            (m_axi_mpm_ep_awvalid), //in  wire
      .s_axi_awready            (m_axi_mpm_ep_awready), //out wire
      .s_axi_wdata              (m_axi_mpm_ep_wdata), //in  wire[31:0]
      .s_axi_wstrb              (m_axi_mpm_ep_wstrb), //in  wire[3:0]
      .s_axi_wvalid             (m_axi_mpm_ep_wvalid), //in  wire
      .s_axi_wready             (m_axi_mpm_ep_wready), //out wire
      .s_axi_bresp              (m_axi_mpm_ep_bresp), //out wire[1:0]
      .s_axi_bvalid             (m_axi_mpm_ep_bvalid), //out wire
      .s_axi_bready             (m_axi_mpm_ep_bready), //in  wire
      .s_axi_araddr             (m_axi_mpm_ep_araddr[16:0]), //in  wire[16:0]
      .s_axi_arvalid            (m_axi_mpm_ep_arvalid), //in  wire
      .s_axi_arready            (m_axi_mpm_ep_arready), //out wire
      .s_axi_rdata              (m_axi_mpm_ep_rdata), //out wire[31:0]
      .s_axi_rresp              (m_axi_mpm_ep_rresp), //out wire[1:0]
      .s_axi_rvalid             (m_axi_mpm_ep_rvalid), //out wire
      .s_axi_rready             (m_axi_mpm_ep_rready), //in  wire
      .s_ctrlport_req_wr        (),                 //in  wire
      .s_ctrlport_req_rd        (),                 //in  wire
      .s_ctrlport_req_addr      (),                 //in  wire[19:0]
      .s_ctrlport_req_data      (),                 //in  wire[31:0]
      .s_ctrlport_req_byte_en   (),                 //in  wire[3:0]
      .s_ctrlport_req_has_time  (),                 //in  wire
      .s_ctrlport_req_time      (),                 //in  wire[63:0]
      .s_ctrlport_resp_ack      (),                 //out wire
      .s_ctrlport_resp_status   (),                 //out wire[1:0]
      .s_ctrlport_resp_data     (),                 //out wire[31:0]
      .ss                       ({PL_CPLD_CS1_n, PL_CPLD_CS0_n}), //out wire[1:0]
      .sclk                     (PL_CPLD_SCLK),     //out wire
      .mosi                     (PL_CPLD_MOSI),     //out wire
      .miso                     (PL_CPLD_MISO),     //in  wire
      .qsfp0_led_active         (),                 //in  wire[3:0]
      .qsfp0_led_link           (),                 //in  wire[3:0]
      .qsfp1_led_active         (),                 //in  wire[3:0]
      .qsfp1_led_link           ());                //in  wire[3:0]

  //------------------------------------------------------------------
  // X400 Core
  //------------------------------------------------------------------

  logic [32*NUM_CHANNELS-1:0] rx_data;
  logic [   NUM_CHANNELS-1:0] rx_stb;
  logic [32*NUM_CHANNELS-1:0] tx_data;
  logic [   NUM_CHANNELS-1:0] tx_stb;
  logic [               11:0] gpio_out_a;
  logic [               11:0] gpio_out_b;
  logic [               11:0] gpio_en_a;
  logic [               11:0] gpio_en_b;

  // Map RFDC ports to x4xx_core ports
  assign radio_clk = data_clk;
  assign rx_data = { adc_data_out_tdata[3],  adc_data_out_tdata[2],
                     adc_data_out_tdata[1],  adc_data_out_tdata[0] };
  assign rx_stb  = adc_data_out_tvalid;

  // Tie off unused radio ports
  if (NUM_CHANNELS == 2) begin
    assign dac_data_in_tdata[3] = {16'h0000, 16'h7FFF};
    assign dac_data_in_tdata[2] = {16'h0000, 16'h7FFF};
    assign {dac_data_in_tdata[1], dac_data_in_tdata[0] } = tx_data;
  end else if (NUM_CHANNELS == 4) begin
    assign { dac_data_in_tdata[3], dac_data_in_tdata[2],
             dac_data_in_tdata[1], dac_data_in_tdata[0] } = tx_data;
  end

  assign tx_stb  = dac_data_in_tready;

  //DIO tristate buffers
  genvar i;
  generate for (i=0; i<12; i=i+1) begin: dio_tristate_gen
    assign DIOA_FPGA[i] = (gpio_en_a[i]) ? gpio_out_a[i] : 1'bz;
    assign DIOB_FPGA[i] = (gpio_en_b[i]) ? gpio_out_b[i] : 1'bz;
  end endgenerate

  x4xx_core #(
    .REG_DWIDTH     (REG_DWIDTH),
    .REG_AWIDTH     (REG_AWIDTH),
    .CHDR_CLK_RATE  (CHDR_CLK_RATE),
    .NUM_CHANNELS   (NUM_CHANNELS),
    .CHDR_W         (CHDR_W),
    .RFNOC_PROTOVER (RFNOC_PROTOVER)
  ) x4xx_corex (
    .radio_clk                       (radio_clk),
    .radio_rst                       (radio_rst),
    .rfnoc_chdr_clk                  (clk200),
    .rfnoc_chdr_rst                  (clk200_rst),
    .rfnoc_ctrl_clk                  (clk40),
    .rfnoc_ctrl_rst                  (clk40_rst),
    .s_axi_aclk                      (clk40),
    .s_axi_aresetn                   (clk40_rstn),
    .s_axi_awaddr                    (axi_core_awaddr[REG_AWIDTH-1:0]),
    .s_axi_awvalid                   (axi_core_awvalid),
    .s_axi_awready                   (axi_core_awready),
    .s_axi_wdata                     (axi_core_wdata),
    .s_axi_wstrb                     (axi_core_wstrb),
    .s_axi_wvalid                    (axi_core_wvalid),
    .s_axi_wready                    (axi_core_wready),
    .s_axi_bresp                     (axi_core_bresp),
    .s_axi_bvalid                    (axi_core_bvalid),
    .s_axi_bready                    (axi_core_bready),
    .s_axi_araddr                    (axi_core_araddr[REG_AWIDTH-1:0]),
    .s_axi_arvalid                   (axi_core_arvalid),
    .s_axi_arready                   (axi_core_arready),
    .s_axi_rdata                     (axi_core_rdata),
    .s_axi_rresp                     (axi_core_rresp),
    .s_axi_rvalid                    (axi_core_rvalid),
    .s_axi_rready                    (axi_core_rready),
    .pps_radioclk                    (pps_radioclk),
    .refclk_locked                   (1'b1),             //vhook_warn TODO: No refclk_locked signal
    .pps_select                      (pps_select),
    .ref_select                      (),
    .trig_io_select                  (trig_io_select_clk40),
    .pll_sync_trigger                (pll_sync_trigger),
    .pll_sync_delay                  (pll_sync_delay),
    .pll_sync_done                   (pll_sync_done),
    .pps_brc_delay                   (pps_brc_delay),
    .pps_prc_delay                   (pps_prc_delay),
    .prc_rc_divider                  (prc_rc_divider),
    .pps_rc_enabled                  (pps_rc_enabled),
    .rx_data                         (rx_data),
    .rx_stb                          (rx_stb),
    .rx_running                      (rx_running),
    .tx_data                         (tx_data),
    .tx_stb                          (tx_stb),
    .tx_running                      (tx_running),
    .dmao_tdata                      (v2e_dma_cw.tdata),
    .dmao_tlast                      (v2e_dma_cw.tlast),
    .dmao_tvalid                     (v2e_dma_cw.tvalid),
    .dmao_tready                     (v2e_dma_cw.tready),
    .dmai_tdata                      (e2v_dma_cw.tdata),
    .dmai_tlast                      (e2v_dma_cw.tlast),
    .dmai_tvalid                     (e2v_dma_cw.tvalid),
    .dmai_tready                     (e2v_dma_cw.tready),
    .v2e_tdata                       (v2e.tdata),
    .v2e_tvalid                      (v2e.tvalid),
    .v2e_tlast                       (v2e.tlast),
    .v2e_tready                      (v2e.tready),
    .e2v_tdata                       (e2v.tdata),
    .e2v_tlast                       (e2v.tlast),
    .e2v_tvalid                      (e2v.tvalid),
    .e2v_tready                      (e2v.tready),
    .gpio_in_a                       (DIOA_FPGA),
    .gpio_in_b                       (DIOB_FPGA),
    .gpio_out_a                      (gpio_out_a),
    .gpio_out_b                      (gpio_out_b),
    .gpio_en_a                       (gpio_en_a),
    .gpio_en_b                       (gpio_en_b),
    .sfp_ports_info                  (sfp_port_info),
    .gps_status                      (32'b0),            //vhook_warn TODO: Remove GPS? Not connected to PL on x400
    .gps_ctrl                        (),
    .dboard_status                   (32'hDEADBEEF),     //vhook_warn TODO: How to connect dboard_status?
    .xadc_readback                   (),                 //vhook_warn TODO: How to connect xadc_readback
    .dboard_ctrl                     (),                 //vhook_warn TODO: How to connect dboard_ctrl?
    .radio_time                      (radio_time),
    .radio_time_stb                  (radio_time_stb),
    .device_id                       (device_id),
    .m_ctrlport_radio0_req_wr        (db_ctrlport_req_wr[0]),
    .m_ctrlport_radio0_req_rd        (db_ctrlport_req_rd[0]),
    .m_ctrlport_radio0_req_addr      (db_ctrlport_req_addr[0]),
    .m_ctrlport_radio0_req_data      (db_ctrlport_req_data[0]),
    .m_ctrlport_radio0_req_byte_en   (db_ctrlport_req_byte_en[0]),
    .m_ctrlport_radio0_req_has_time  (db_ctrlport_req_has_time[0]),
    .m_ctrlport_radio0_req_time      (db_ctrlport_req_time[0]),
    .m_ctrlport_radio0_resp_ack      (db_ctrlport_resp_ack[0]),
    .m_ctrlport_radio0_resp_status   (db_ctrlport_resp_status[0]),
    .m_ctrlport_radio0_resp_data     (db_ctrlport_resp_data[0]),
    .m_ctrlport_radio1_req_wr        (db_ctrlport_req_wr[1]),
    .m_ctrlport_radio1_req_rd        (db_ctrlport_req_rd[1]),
    .m_ctrlport_radio1_req_addr      (db_ctrlport_req_addr[1]),
    .m_ctrlport_radio1_req_data      (db_ctrlport_req_data[1]),
    .m_ctrlport_radio1_req_byte_en   (db_ctrlport_req_byte_en[1]),
    .m_ctrlport_radio1_req_has_time  (db_ctrlport_req_has_time[1]),
    .m_ctrlport_radio1_req_time      (db_ctrlport_req_time[1]),
    .m_ctrlport_radio1_resp_ack      (db_ctrlport_resp_ack[1]),
    .m_ctrlport_radio1_resp_status   (db_ctrlport_resp_status[1]),
    .m_ctrlport_radio1_resp_data     (db_ctrlport_resp_data[1])
  );

  // ----------------------------------------------------------------
  // TODO: Temporary test port toggling logic for bringup.
  //       Remove for final implementation.

  reg [7:0] counter_clk40;

  always @(posedge clk40) begin
    if (clk40_rstn == 1'b0) begin
      // reset
      counter_clk40 <= 8'b0;
    end
    else begin
      counter_clk40 <= counter_clk40 + 1'b1;
    end
  end

  // counter_clk40 is an 8-bit counter running at 40 MHz.
  // Since we use the MSB to toggle the test port, we should expect
  // to see a square waveform at 156.25 kHz = 40 MHz / (2^8).
  assign FPGA_TEST = counter_clk40[7];

  // ----------------------------------------------------------------

endmodule


//XmlParse xml_on
//<top name="X4XX_FPGA">
//  <info>
//    This documentation provides a description of the different register spaces available
//    for the USRP X4xx Open-Source FPGA target implementation, accessible through the
//    embedded ARM A53 processor in the RFSoC chip, and other UHD hosts.
//  </info>
//</top>
//XmlParse xml_off

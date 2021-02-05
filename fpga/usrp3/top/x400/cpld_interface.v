//
// Copyright 2020 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: cpld_interface.v
// Description:
// This module comprises the logic on the FPGA to connect with the
// motherboard CPLD.
//
// As a first step each request source is tranferred to PRC domain.
// Timestamps are removed in the timer modules. All requests are
// bundled in one combiner and then split / decoded across all targets.
// By inserting of ctrlport termination modules a ctrlport answer
// will be available for all addresses to avoid blocking the main
// ctrlport combiner.
//
//XmlParse xml_on
//<regmap name="PL_CPLD_REGMAP" readablestrobes="false" generatevhdl="true" ettusguidelines="true">
//  <info>
//    This register map is available from the PS via AXI and MPM endpoint.
//    Its size is 128K (17 bits). Only the 17 LSBs are used as address in this documentation.
//  </info>
//  <group name="PL_CPLD_WINDOWS">
//    <window name="BASE" offset="0x0" size="0x40" targetregmap="CPLD_INTERFACE_REGMAP"/>
//    <window name="MB_CPLD" offset="0x8000" size="0x8000" targetregmap="MB_CPLD_PL_REGMAP">
//      <info>
//        All registers of the MB CPLD (PL part).
//      </info>
//    </window>
//    <window name="DB0_CPLD" offset="0x10000" size="0x8000">
//      <info>
//        All registers of the first DB CPLD. Register map will be added later on.
//      </info>
//    </window>
//    <window name="DB1_CPLD" offset="0x18000" size="0x8000">
//      <info>
//        All registers of the second DB CPLD. Register map will be added later on.
//      </info>
//    </window>
//  </group>
//</regmap>
//XmlParse xml_off

module cpld_interface (
  //Clocks
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  input  wire        pll_ref_clk,
  input  wire        radio_clk,

  // Reset (domain: pll_ref_clk)
  input  wire        ctrlport_rst,

  // Timestamp (domain: radio_clk)
  input  wire [63:0] radio_time,
  input  wire        radio_time_stb,
  input  wire [ 3:0] time_ignore_bits,

  // AXI4-Lite: Write address port (domain: s_axi_aclk)
  input  wire [16:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  // AXI4-Lite: Write data port (domain: s_axi_aclk)
  input  wire [31:0] s_axi_wdata,
  input  wire [ 3:0] s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  // AXI4-Lite: Write response port (domain: s_axi_aclk)
  output wire[ 1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  // AXI4-Lite: Read address port (domain: s_axi_aclk)
  input  wire [16:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  // AXI4-Lite: Read data port (domain: s_axi_aclk)
  output wire [31:0] s_axi_rdata,
  output wire [ 1:0] s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready,

  // Control port from / to application (domain: radio_clk)
  input  wire        s_ctrlport_req_wr,
  input  wire        s_ctrlport_req_rd,
  input  wire [19:0] s_ctrlport_req_addr,
  input  wire [31:0] s_ctrlport_req_data,
  input  wire [ 3:0] s_ctrlport_req_byte_en,
  input  wire        s_ctrlport_req_has_time,
  input  wire [63:0] s_ctrlport_req_time,
  output wire        s_ctrlport_resp_ack,
  output wire [ 1:0] s_ctrlport_resp_status,
  output wire [31:0] s_ctrlport_resp_data,

  // SPI Bus to connect to MB CPLD
  output wire [ 1:0] ss,
  output wire        sclk,
  output wire        mosi,
  input  wire        miso,

  // QSFP port LED (domain: any)
  input  wire [ 3:0] qsfp0_led_active,
  input  wire [ 3:0] qsfp0_led_link,
  input  wire [ 3:0] qsfp1_led_active,
  input  wire [ 3:0] qsfp1_led_link,

  // iPass present signals
  input  wire [ 1:0] ipass_present_n,

  // Versioning (Constant)
  output wire [95:0] version_info
);

  `include "../../lib/rfnoc/core/ctrlport.vh"
  `include "regmap/pl_cpld_regmap_utils.vh"
  `include "cpld/regmap/mb_cpld_pl_regmap_utils.vh"
  `include "cpld/regmap/pl_cpld_base_regmap_utils.vh"

  //----------------------------------------------------------
  // Internal clocks and resets
  //----------------------------------------------------------
  wire s_axi_areset;
  wire ctrlport_clk;
  assign s_axi_areset = ~s_axi_aresetn;
  assign ctrlport_clk = pll_ref_clk;

  //----------------------------------------------------------
  // Timestamp synchronization
  //----------------------------------------------------------
  reg  [ 3:0] radio_time_stb_shift_reg;
  wire        radio_time_stb_prc;
  reg  [63:0] radio_time_prc;

  // radio_clk and pll_ref_clk are synchronous clocks with an integer
  // multiplier <= 4.
  // A simple register can be used to capture the latest timestamp
  // the strobe pulse is preserved for up to 4 clock cycles and used
  // in pll_ref_clk domain to driver timers.
  always @(posedge radio_clk) begin
    radio_time_stb_shift_reg <= {radio_time_stb_shift_reg[2:0], radio_time_stb};
    if (radio_time_stb) begin
      radio_time_prc <= radio_time;
    end
  end
  assign radio_time_stb_prc = | radio_time_stb_shift_reg;

  //----------------------------------------------------------
  // MPM Endpoint connection
  //----------------------------------------------------------
  // Translate AXI lite to control port.
  // Timeout based on the 40 MHz AXI clock is about 0.839 seconds.
  wire [19:0] mpm_endpoint_ctrlport_axi_clk_req_addr;
  wire [ 3:0] mpm_endpoint_ctrlport_axi_clk_req_byte_en;
  wire [31:0] mpm_endpoint_ctrlport_axi_clk_req_data;
  wire        mpm_endpoint_ctrlport_axi_clk_req_has_time;
  wire [ 9:0] mpm_endpoint_ctrlport_axi_clk_req_portid;
  wire        mpm_endpoint_ctrlport_axi_clk_req_rd;
  wire [15:0] mpm_endpoint_ctrlport_axi_clk_req_rem_epid;
  wire [ 9:0] mpm_endpoint_ctrlport_axi_clk_req_rem_portid;
  wire [63:0] mpm_endpoint_ctrlport_axi_clk_req_time;
  wire        mpm_endpoint_ctrlport_axi_clk_req_wr;
  wire        mpm_endpoint_ctrlport_axi_clk_resp_ack;
  wire [31:0] mpm_endpoint_ctrlport_axi_clk_resp_data;
  wire [ 1:0] mpm_endpoint_ctrlport_axi_clk_resp_status;
  //vhook_e axil_ctrlport_master mpm_endpoint
  //vhook_a TIMEOUT 25
  //vhook_a AXI_AWIDTH 17
  //vhook_a CTRLPORT_AWIDTH 17
  //vhook_a {m_ctrlport_(.*)} mpm_endpoint_ctrlport_axi_clk_$1
  axil_ctrlport_master
    # (
      .TIMEOUT          (25),   //integer:=10
      .AXI_AWIDTH       (17),   //integer:=17
      .CTRLPORT_AWIDTH  (17))   //integer:=17
    mpm_endpoint (
      .s_axi_aclk                 (s_axi_aclk),                                     //in  wire
      .s_axi_aresetn              (s_axi_aresetn),                                  //in  wire
      .s_axi_awaddr               (s_axi_awaddr),                                   //in  wire[(AXI_AWIDTH-1):0]
      .s_axi_awvalid              (s_axi_awvalid),                                  //in  wire
      .s_axi_awready              (s_axi_awready),                                  //out wire
      .s_axi_wdata                (s_axi_wdata),                                    //in  wire[31:0]
      .s_axi_wstrb                (s_axi_wstrb),                                    //in  wire[3:0]
      .s_axi_wvalid               (s_axi_wvalid),                                   //in  wire
      .s_axi_wready               (s_axi_wready),                                   //out wire
      .s_axi_bresp                (s_axi_bresp),                                    //out wire[1:0]
      .s_axi_bvalid               (s_axi_bvalid),                                   //out wire
      .s_axi_bready               (s_axi_bready),                                   //in  wire
      .s_axi_araddr               (s_axi_araddr),                                   //in  wire[(AXI_AWIDTH-1):0]
      .s_axi_arvalid              (s_axi_arvalid),                                  //in  wire
      .s_axi_arready              (s_axi_arready),                                  //out wire
      .s_axi_rdata                (s_axi_rdata),                                    //out wire[31:0]
      .s_axi_rresp                (s_axi_rresp),                                    //out wire[1:0]
      .s_axi_rvalid               (s_axi_rvalid),                                   //out wire
      .s_axi_rready               (s_axi_rready),                                   //in  wire
      .m_ctrlport_req_wr          (mpm_endpoint_ctrlport_axi_clk_req_wr),           //out wire
      .m_ctrlport_req_rd          (mpm_endpoint_ctrlport_axi_clk_req_rd),           //out wire
      .m_ctrlport_req_addr        (mpm_endpoint_ctrlport_axi_clk_req_addr),         //out wire[19:0]
      .m_ctrlport_req_portid      (mpm_endpoint_ctrlport_axi_clk_req_portid),       //out wire[9:0]
      .m_ctrlport_req_rem_epid    (mpm_endpoint_ctrlport_axi_clk_req_rem_epid),     //out wire[15:0]
      .m_ctrlport_req_rem_portid  (mpm_endpoint_ctrlport_axi_clk_req_rem_portid),   //out wire[9:0]
      .m_ctrlport_req_data        (mpm_endpoint_ctrlport_axi_clk_req_data),         //out wire[31:0]
      .m_ctrlport_req_byte_en     (mpm_endpoint_ctrlport_axi_clk_req_byte_en),      //out wire[3:0]
      .m_ctrlport_req_has_time    (mpm_endpoint_ctrlport_axi_clk_req_has_time),     //out wire
      .m_ctrlport_req_time        (mpm_endpoint_ctrlport_axi_clk_req_time),         //out wire[63:0]
      .m_ctrlport_resp_ack        (mpm_endpoint_ctrlport_axi_clk_resp_ack),         //in  wire
      .m_ctrlport_resp_status     (mpm_endpoint_ctrlport_axi_clk_resp_status),      //in  wire[1:0]
      .m_ctrlport_resp_data       (mpm_endpoint_ctrlport_axi_clk_resp_data));       //in  wire[31:0]

  // Transfer AXI clock based MPM entpoint control port request to pll_ref_clk domain.
  wire [19:0] mpm_endpoint_ctrlport_pll_clk_req_addr;
  wire [ 3:0] mpm_endpoint_ctrlport_pll_clk_req_byte_en;
  wire [31:0] mpm_endpoint_ctrlport_pll_clk_req_data;
  wire        mpm_endpoint_ctrlport_pll_clk_req_has_time;
  wire        mpm_endpoint_ctrlport_pll_clk_req_rd;
  wire [63:0] mpm_endpoint_ctrlport_pll_clk_req_time;
  wire        mpm_endpoint_ctrlport_pll_clk_req_wr;
  wire        mpm_endpoint_ctrlport_pll_clk_resp_ack;
  wire [31:0] mpm_endpoint_ctrlport_pll_clk_resp_data;
  wire [ 1:0] mpm_endpoint_ctrlport_pll_clk_resp_status;
  //vhook_e ctrlport_clk_cross mpm_clock_cross
  //vhook_a rst s_axi_areset
  //vhook_a s_ctrlport_clk s_axi_aclk
  //vhook_a {s_ctrlport_(.*)} mpm_endpoint_ctrlport_axi_clk_$1
  //vhook_a {m_ctrlport_(.*)id} {}
  //vhook_a {m_ctrlport_(.*)} mpm_endpoint_ctrlport_pll_clk_$1
  //vhook_a m_ctrlport_clk ctrlport_clk
  ctrlport_clk_cross
    mpm_clock_cross (
      .rst                        (s_axi_areset),                                   //in  wire
      .s_ctrlport_clk             (s_axi_aclk),                                     //in  wire
      .s_ctrlport_req_wr          (mpm_endpoint_ctrlport_axi_clk_req_wr),           //in  wire
      .s_ctrlport_req_rd          (mpm_endpoint_ctrlport_axi_clk_req_rd),           //in  wire
      .s_ctrlport_req_addr        (mpm_endpoint_ctrlport_axi_clk_req_addr),         //in  wire[19:0]
      .s_ctrlport_req_portid      (mpm_endpoint_ctrlport_axi_clk_req_portid),       //in  wire[9:0]
      .s_ctrlport_req_rem_epid    (mpm_endpoint_ctrlport_axi_clk_req_rem_epid),     //in  wire[15:0]
      .s_ctrlport_req_rem_portid  (mpm_endpoint_ctrlport_axi_clk_req_rem_portid),   //in  wire[9:0]
      .s_ctrlport_req_data        (mpm_endpoint_ctrlport_axi_clk_req_data),         //in  wire[31:0]
      .s_ctrlport_req_byte_en     (mpm_endpoint_ctrlport_axi_clk_req_byte_en),      //in  wire[3:0]
      .s_ctrlport_req_has_time    (mpm_endpoint_ctrlport_axi_clk_req_has_time),     //in  wire
      .s_ctrlport_req_time        (mpm_endpoint_ctrlport_axi_clk_req_time),         //in  wire[63:0]
      .s_ctrlport_resp_ack        (mpm_endpoint_ctrlport_axi_clk_resp_ack),         //out wire
      .s_ctrlport_resp_status     (mpm_endpoint_ctrlport_axi_clk_resp_status),      //out wire[1:0]
      .s_ctrlport_resp_data       (mpm_endpoint_ctrlport_axi_clk_resp_data),        //out wire[31:0]
      .m_ctrlport_clk             (ctrlport_clk),                                   //in  wire
      .m_ctrlport_req_wr          (mpm_endpoint_ctrlport_pll_clk_req_wr),           //out wire
      .m_ctrlport_req_rd          (mpm_endpoint_ctrlport_pll_clk_req_rd),           //out wire
      .m_ctrlport_req_addr        (mpm_endpoint_ctrlport_pll_clk_req_addr),         //out wire[19:0]
      .m_ctrlport_req_portid      (),                                               //out wire[9:0]
      .m_ctrlport_req_rem_epid    (),                                               //out wire[15:0]
      .m_ctrlport_req_rem_portid  (),                                               //out wire[9:0]
      .m_ctrlport_req_data        (mpm_endpoint_ctrlport_pll_clk_req_data),         //out wire[31:0]
      .m_ctrlport_req_byte_en     (mpm_endpoint_ctrlport_pll_clk_req_byte_en),      //out wire[3:0]
      .m_ctrlport_req_has_time    (mpm_endpoint_ctrlport_pll_clk_req_has_time),     //out wire
      .m_ctrlport_req_time        (mpm_endpoint_ctrlport_pll_clk_req_time),         //out wire[63:0]
      .m_ctrlport_resp_ack        (mpm_endpoint_ctrlport_pll_clk_resp_ack),         //in  wire
      .m_ctrlport_resp_status     (mpm_endpoint_ctrlport_pll_clk_resp_status),      //in  wire[1:0]
      .m_ctrlport_resp_data       (mpm_endpoint_ctrlport_pll_clk_resp_data));       //in  wire[31:0]

  // Apply time of controlport request to MPM endpoint request.
  wire [19:0] mpm_endpoint_ctrlport_req_addr;
  wire [ 3:0] mpm_endpoint_ctrlport_req_byte_en;
  wire [31:0] mpm_endpoint_ctrlport_req_data;
  wire        mpm_endpoint_ctrlport_req_rd;
  wire        mpm_endpoint_ctrlport_req_wr;
  wire        mpm_endpoint_ctrlport_resp_ack;
  wire [31:0] mpm_endpoint_ctrlport_resp_data;
  wire [ 1:0] mpm_endpoint_ctrlport_resp_status;
  //vhook_e ctrlport_timer mpm_endpoint_ctrlport_timer
  //vhook_a EXEC_LATE_CMDS 1
  //vhook_a clk ctrlport_clk
  //vhook_a rst ctrlport_rst
  //vhook_a {s_ctrlport_(.*)} mpm_endpoint_ctrlport_pll_clk_$1
  //vhook_a {m_ctrlport_(.*)} mpm_endpoint_ctrlport_$1
  //vhook_a time_now radio_time_prc
  //vhook_a time_now_stb radio_time_stb_prc
  ctrlport_timer
    # (.EXEC_LATE_CMDS(1))   //wire[0:0]:=1
    mpm_endpoint_ctrlport_timer (
      .clk                      (ctrlport_clk),                                 //in  wire
      .rst                      (ctrlport_rst),                                 //in  wire
      .time_now                 (radio_time_prc),                               //in  wire[63:0]
      .time_now_stb             (radio_time_stb_prc),                           //in  wire
      .time_ignore_bits         (time_ignore_bits),                             //in  wire[3:0]
      .s_ctrlport_req_wr        (mpm_endpoint_ctrlport_pll_clk_req_wr),         //in  wire
      .s_ctrlport_req_rd        (mpm_endpoint_ctrlport_pll_clk_req_rd),         //in  wire
      .s_ctrlport_req_addr      (mpm_endpoint_ctrlport_pll_clk_req_addr),       //in  wire[19:0]
      .s_ctrlport_req_data      (mpm_endpoint_ctrlport_pll_clk_req_data),       //in  wire[31:0]
      .s_ctrlport_req_byte_en   (mpm_endpoint_ctrlport_pll_clk_req_byte_en),    //in  wire[3:0]
      .s_ctrlport_req_has_time  (mpm_endpoint_ctrlport_pll_clk_req_has_time),   //in  wire
      .s_ctrlport_req_time      (mpm_endpoint_ctrlport_pll_clk_req_time),       //in  wire[63:0]
      .s_ctrlport_resp_ack      (mpm_endpoint_ctrlport_pll_clk_resp_ack),       //out wire
      .s_ctrlport_resp_status   (mpm_endpoint_ctrlport_pll_clk_resp_status),    //out wire[1:0]
      .s_ctrlport_resp_data     (mpm_endpoint_ctrlport_pll_clk_resp_data),      //out wire[31:0]
      .m_ctrlport_req_wr        (mpm_endpoint_ctrlport_req_wr),                 //out wire
      .m_ctrlport_req_rd        (mpm_endpoint_ctrlport_req_rd),                 //out wire
      .m_ctrlport_req_addr      (mpm_endpoint_ctrlport_req_addr),               //out wire[19:0]
      .m_ctrlport_req_data      (mpm_endpoint_ctrlport_req_data),               //out wire[31:0]
      .m_ctrlport_req_byte_en   (mpm_endpoint_ctrlport_req_byte_en),            //out wire[3:0]
      .m_ctrlport_resp_ack      (mpm_endpoint_ctrlport_resp_ack),               //in  wire
      .m_ctrlport_resp_status   (mpm_endpoint_ctrlport_resp_status),            //in  wire[1:0]
      .m_ctrlport_resp_data     (mpm_endpoint_ctrlport_resp_data));             //in  wire[31:0]

  //----------------------------------------------------------
  // User Application Request
  //----------------------------------------------------------
  // Transfer request to pll_ref_clk domain.
  wire [19:0] app_ctrlport_pll_clk_req_addr;
  wire [ 3:0] app_ctrlport_pll_clk_req_byte_en;
  wire [31:0] app_ctrlport_pll_clk_req_data;
  wire        app_ctrlport_pll_clk_req_has_time;
  wire        app_ctrlport_pll_clk_req_rd;
  wire [63:0] app_ctrlport_pll_clk_req_time;
  wire        app_ctrlport_pll_clk_req_wr;
  wire        app_ctrlport_pll_clk_resp_ack;
  wire [31:0] app_ctrlport_pll_clk_resp_data;
  wire [ 1:0] app_ctrlport_pll_clk_resp_status;
  //vhook_e ctrlport_clk_cross app_clock_cross
  //vhook_a rst ctrlport_rst
  //vhook_a s_ctrlport_clk radio_clk
  //vhook_a {._ctrlport_(.*)id} {}
  //vhook_a {m_ctrlport_(.*)} app_ctrlport_pll_clk_$1
  //vhook_a m_ctrlport_clk ctrlport_clk
  ctrlport_clk_cross
    app_clock_cross (
      .rst                        (ctrlport_rst),                      //in  wire
      .s_ctrlport_clk             (radio_clk),                         //in  wire
      .s_ctrlport_req_wr          (s_ctrlport_req_wr),                 //in  wire
      .s_ctrlport_req_rd          (s_ctrlport_req_rd),                 //in  wire
      .s_ctrlport_req_addr        (s_ctrlport_req_addr),               //in  wire[19:0]
      .s_ctrlport_req_portid      (),                                  //in  wire[9:0]
      .s_ctrlport_req_rem_epid    (),                                  //in  wire[15:0]
      .s_ctrlport_req_rem_portid  (),                                  //in  wire[9:0]
      .s_ctrlport_req_data        (s_ctrlport_req_data),               //in  wire[31:0]
      .s_ctrlport_req_byte_en     (s_ctrlport_req_byte_en),            //in  wire[3:0]
      .s_ctrlport_req_has_time    (s_ctrlport_req_has_time),           //in  wire
      .s_ctrlport_req_time        (s_ctrlport_req_time),               //in  wire[63:0]
      .s_ctrlport_resp_ack        (s_ctrlport_resp_ack),               //out wire
      .s_ctrlport_resp_status     (s_ctrlport_resp_status),            //out wire[1:0]
      .s_ctrlport_resp_data       (s_ctrlport_resp_data),              //out wire[31:0]
      .m_ctrlport_clk             (ctrlport_clk),                      //in  wire
      .m_ctrlport_req_wr          (app_ctrlport_pll_clk_req_wr),       //out wire
      .m_ctrlport_req_rd          (app_ctrlport_pll_clk_req_rd),       //out wire
      .m_ctrlport_req_addr        (app_ctrlport_pll_clk_req_addr),     //out wire[19:0]
      .m_ctrlport_req_portid      (),                                  //out wire[9:0]
      .m_ctrlport_req_rem_epid    (),                                  //out wire[15:0]
      .m_ctrlport_req_rem_portid  (),                                  //out wire[9:0]
      .m_ctrlport_req_data        (app_ctrlport_pll_clk_req_data),     //out wire[31:0]
      .m_ctrlport_req_byte_en     (app_ctrlport_pll_clk_req_byte_en),  //out wire[3:0]
      .m_ctrlport_req_has_time    (app_ctrlport_pll_clk_req_has_time), //out wire
      .m_ctrlport_req_time        (app_ctrlport_pll_clk_req_time),     //out wire[63:0]
      .m_ctrlport_resp_ack        (app_ctrlport_pll_clk_resp_ack),     //in  wire
      .m_ctrlport_resp_status     (app_ctrlport_pll_clk_resp_status),  //in  wire[1:0]
      .m_ctrlport_resp_data       (app_ctrlport_pll_clk_resp_data));   //in  wire[31:0]

  // Apply timing to application based controlport request.
  wire [19:0] app_ctrlport_req_addr;
  wire [ 3:0] app_ctrlport_req_byte_en;
  wire [31:0] app_ctrlport_req_data;
  wire        app_ctrlport_req_rd;
  wire        app_ctrlport_req_wr;
  wire        app_ctrlport_resp_ack;
  wire [31:0] app_ctrlport_resp_data;
  wire [ 1:0] app_ctrlport_resp_status;
  //vhook_e ctrlport_timer app_ctrlport_timer
  //vhook_a EXEC_LATE_CMDS 1
  //vhook_a clk ctrlport_clk
  //vhook_a rst ctrlport_rst
  //vhook_a {s_ctrlport_(.*)} app_ctrlport_pll_clk_$1
  //vhook_a {m_ctrlport_(.*)} app_ctrlport_$1
  //vhook_a time_now radio_time_prc
  //vhook_a time_now_stb radio_time_stb_prc
  ctrlport_timer
    # (.EXEC_LATE_CMDS(1))   //wire[0:0]:=1
    app_ctrlport_timer (
      .clk                      (ctrlport_clk),                        //in  wire
      .rst                      (ctrlport_rst),                        //in  wire
      .time_now                 (radio_time_prc),                      //in  wire[63:0]
      .time_now_stb             (radio_time_stb_prc),                  //in  wire
      .time_ignore_bits         (time_ignore_bits),                    //in  wire[3:0]
      .s_ctrlport_req_wr        (app_ctrlport_pll_clk_req_wr),         //in  wire
      .s_ctrlport_req_rd        (app_ctrlport_pll_clk_req_rd),         //in  wire
      .s_ctrlport_req_addr      (app_ctrlport_pll_clk_req_addr),       //in  wire[19:0]
      .s_ctrlport_req_data      (app_ctrlport_pll_clk_req_data),       //in  wire[31:0]
      .s_ctrlport_req_byte_en   (app_ctrlport_pll_clk_req_byte_en),    //in  wire[3:0]
      .s_ctrlport_req_has_time  (app_ctrlport_pll_clk_req_has_time),   //in  wire
      .s_ctrlport_req_time      (app_ctrlport_pll_clk_req_time),       //in  wire[63:0]
      .s_ctrlport_resp_ack      (app_ctrlport_pll_clk_resp_ack),       //out wire
      .s_ctrlport_resp_status   (app_ctrlport_pll_clk_resp_status),    //out wire[1:0]
      .s_ctrlport_resp_data     (app_ctrlport_pll_clk_resp_data),      //out wire[31:0]
      .m_ctrlport_req_wr        (app_ctrlport_req_wr),                 //out wire
      .m_ctrlport_req_rd        (app_ctrlport_req_rd),                 //out wire
      .m_ctrlport_req_addr      (app_ctrlport_req_addr),               //out wire[19:0]
      .m_ctrlport_req_data      (app_ctrlport_req_data),               //out wire[31:0]
      .m_ctrlport_req_byte_en   (app_ctrlport_req_byte_en),            //out wire[3:0]
      .m_ctrlport_resp_ack      (app_ctrlport_resp_ack),               //in  wire
      .m_ctrlport_resp_status   (app_ctrlport_resp_status),            //in  wire[1:0]
      .m_ctrlport_resp_data     (app_ctrlport_resp_data));             //in  wire[31:0]

  //----------------------------------------------------------
  // QSFP LED Controller
  //----------------------------------------------------------
  wire [19:0] led_ctrlport_req_addr;
  wire [ 3:0] led_ctrlport_req_byte_en;
  wire [31:0] led_ctrlport_req_data;
  wire        led_ctrlport_req_rd;
  wire        led_ctrlport_req_wr;
  wire        led_ctrlport_resp_ack;
  wire [31:0] led_ctrlport_resp_data;
  wire [ 1:0] led_ctrlport_resp_status;
  //vhook_e qsfp_led_controller
  //vhook_a LED_REGISTER_ADDRESS MB_CPLD + PL_REGISTERS + LED_REGISTER
  //vhook_a {m_ctrlport_(.*)} led_ctrlport_$1
  qsfp_led_controller
    # (.LED_REGISTER_ADDRESS(MB_CPLD + PL_REGISTERS + LED_REGISTER))   //integer:=0
    qsfp_led_controllerx (
      .ctrlport_clk            (ctrlport_clk),               //in  wire
      .ctrlport_rst            (ctrlport_rst),               //in  wire
      .m_ctrlport_req_wr       (led_ctrlport_req_wr),        //out wire
      .m_ctrlport_req_rd       (led_ctrlport_req_rd),        //out wire
      .m_ctrlport_req_addr     (led_ctrlport_req_addr),      //out wire[19:0]
      .m_ctrlport_req_data     (led_ctrlport_req_data),      //out wire[31:0]
      .m_ctrlport_req_byte_en  (led_ctrlport_req_byte_en),   //out wire[3:0]
      .m_ctrlport_resp_ack     (led_ctrlport_resp_ack),      //in  wire
      .m_ctrlport_resp_status  (led_ctrlport_resp_status),   //in  wire[1:0]
      .m_ctrlport_resp_data    (led_ctrlport_resp_data),     //in  wire[31:0]
      .qsfp0_led_active        (qsfp0_led_active),           //in  wire[3:0]
      .qsfp0_led_link          (qsfp0_led_link),             //in  wire[3:0]
      .qsfp1_led_active        (qsfp1_led_active),           //in  wire[3:0]
      .qsfp1_led_link          (qsfp1_led_link));            //in  wire[3:0]

  //----------------------------------------------------------
  // iPass present controller
  //----------------------------------------------------------
  wire [19:0] ipass_ctrlport_req_addr;
  wire [ 3:0] ipass_ctrlport_req_byte_en;
  wire [31:0] ipass_ctrlport_req_data;
  wire        ipass_ctrlport_req_rd;
  wire        ipass_ctrlport_req_wr;
  wire        ipass_ctrlport_resp_ack;
  wire [31:0] ipass_ctrlport_resp_data;
  wire [ 1:0] ipass_ctrlport_resp_status;

  wire ipass_enable;
  //vhook ipass_present_controller
  //vhook_a {m_(.*)} ipass_$1
  //vhook_a enable ipass_enable
  ipass_present_controller
    ipass_present_controllerx (
      .ctrlport_clk            (ctrlport_clk),                 //in  wire
      .ctrlport_rst            (ctrlport_rst),                 //in  wire
      .m_ctrlport_req_wr       (ipass_ctrlport_req_wr),        //out wire
      .m_ctrlport_req_rd       (ipass_ctrlport_req_rd),        //out wire
      .m_ctrlport_req_addr     (ipass_ctrlport_req_addr),      //out wire[19:0]
      .m_ctrlport_req_data     (ipass_ctrlport_req_data),      //out wire[31:0]
      .m_ctrlport_req_byte_en  (ipass_ctrlport_req_byte_en),   //out wire[3:0]
      .m_ctrlport_resp_ack     (ipass_ctrlport_resp_ack),      //in  wire
      .m_ctrlport_resp_status  (ipass_ctrlport_resp_status),   //in  wire[1:0]
      .m_ctrlport_resp_data    (ipass_ctrlport_resp_data),     //in  wire[31:0]
      .enable                  (ipass_enable),                 //in  wire
      .ipass_present_n         (ipass_present_n));             //in  wire[1:0]

  //----------------------------------------------------------
  // Combine all incomming combiner requests and provide to targets
  //----------------------------------------------------------
  wire [19:0] m_ctrlport_req_addr;
  wire [31:0] m_ctrlport_req_data;
  wire        m_ctrlport_req_rd;
  wire        m_ctrlport_req_wr;
  wire        m_ctrlport_resp_ack;
  wire [31:0] m_ctrlport_resp_data;
  wire [ 1:0] m_ctrlport_resp_status;
  //vhook_e ctrlport_combiner
  //vhook_a NUM_MASTERS 4
  //vhook_a PRIORITY 1
  //vhook_a {s_ctrlport_(.*)id} {}
  //vhook_a {s_ctrlport_(.*)time} {}
  //vhook_a {s_ctrlport_(.*)} \{ipass_ctrlport_$1, led_ctrlport_$1, mpm_endpoint_ctrlport_$1, app_ctrlport_$1\}
  //vhook_a {m_ctrlport_(.*)id} {}
  //vhook_a {m_ctrlport_(.*)time} {}
  //vhook_a {m_ctrlport_(.*)byte_en} {}
  ctrlport_combiner
    # (
      .NUM_MASTERS  (4),   //integer:=2
      .PRIORITY     (1))   //integer:=0
    ctrlport_combinerx (
      .ctrlport_clk               (ctrlport_clk),                                                                                                       //in  wire
      .ctrlport_rst               (ctrlport_rst),                                                                                                       //in  wire
      .s_ctrlport_req_wr          ({ipass_ctrlport_req_wr, led_ctrlport_req_wr, mpm_endpoint_ctrlport_req_wr, app_ctrlport_req_wr}),                    //in  wire[(NUM_MASTERS-1):0]
      .s_ctrlport_req_rd          ({ipass_ctrlport_req_rd, led_ctrlport_req_rd, mpm_endpoint_ctrlport_req_rd, app_ctrlport_req_rd}),                    //in  wire[(NUM_MASTERS-1):0]
      .s_ctrlport_req_addr        ({ipass_ctrlport_req_addr, led_ctrlport_req_addr, mpm_endpoint_ctrlport_req_addr, app_ctrlport_req_addr}),            //in  wire[((20*NUM_MASTERS)-1):0]
      .s_ctrlport_req_portid      (),                                                                                                                   //in  wire[((10*NUM_MASTERS)-1):0]
      .s_ctrlport_req_rem_epid    (),                                                                                                                   //in  wire[((16*NUM_MASTERS)-1):0]
      .s_ctrlport_req_rem_portid  (),                                                                                                                   //in  wire[((10*NUM_MASTERS)-1):0]
      .s_ctrlport_req_data        ({ipass_ctrlport_req_data, led_ctrlport_req_data, mpm_endpoint_ctrlport_req_data, app_ctrlport_req_data}),            //in  wire[((32*NUM_MASTERS)-1):0]
      .s_ctrlport_req_byte_en     ({ipass_ctrlport_req_byte_en, led_ctrlport_req_byte_en, mpm_endpoint_ctrlport_req_byte_en, app_ctrlport_req_byte_en}), //in  wire[((4*NUM_MASTERS)-1):0]
      .s_ctrlport_req_has_time    (),                                                                                                                   //in  wire[(NUM_MASTERS-1):0]
      .s_ctrlport_req_time        (),                                                                                                                   //in  wire[((64*NUM_MASTERS)-1):0]
      .s_ctrlport_resp_ack        ({ipass_ctrlport_resp_ack, led_ctrlport_resp_ack, mpm_endpoint_ctrlport_resp_ack, app_ctrlport_resp_ack}),            //out wire[(NUM_MASTERS-1):0]
      .s_ctrlport_resp_status     ({ipass_ctrlport_resp_status, led_ctrlport_resp_status, mpm_endpoint_ctrlport_resp_status, app_ctrlport_resp_status}), //out wire[((2*NUM_MASTERS)-1):0]
      .s_ctrlport_resp_data       ({ipass_ctrlport_resp_data, led_ctrlport_resp_data, mpm_endpoint_ctrlport_resp_data, app_ctrlport_resp_data}),        //out wire[((32*NUM_MASTERS)-1):0]
      .m_ctrlport_req_wr          (m_ctrlport_req_wr),                                                                                                  //out wire
      .m_ctrlport_req_rd          (m_ctrlport_req_rd),                                                                                                  //out wire
      .m_ctrlport_req_addr        (m_ctrlport_req_addr),                                                                                                //out wire[19:0]
      .m_ctrlport_req_portid      (),                                                                                                                   //out wire[9:0]
      .m_ctrlport_req_rem_epid    (),                                                                                                                   //out wire[15:0]
      .m_ctrlport_req_rem_portid  (),                                                                                                                   //out wire[9:0]
      .m_ctrlport_req_data        (m_ctrlport_req_data),                                                                                                //out wire[31:0]
      .m_ctrlport_req_byte_en     (),                                                                                                                   //out wire[3:0]
      .m_ctrlport_req_has_time    (),                                                                                                                   //out wire
      .m_ctrlport_req_time        (),                                                                                                                   //out wire[63:0]
      .m_ctrlport_resp_ack        (m_ctrlport_resp_ack),                                                                                                //in  wire
      .m_ctrlport_resp_status     (m_ctrlport_resp_status),                                                                                             //in  wire[1:0]
      .m_ctrlport_resp_data       (m_ctrlport_resp_data));                                                                                              //in  wire[31:0]
                                                                                            //in  wire[31:0]

  // Split for CPLD facing requests and others.
  wire [19:0] base_reg_ctrlport_req_addr;
  wire [31:0] base_reg_ctrlport_req_data;
  wire        base_reg_ctrlport_req_rd;
  wire        base_reg_ctrlport_req_wr;
  wire        base_reg_ctrlport_resp_ack;
  wire [31:0] base_reg_ctrlport_resp_data;
  wire [ 1:0] base_reg_ctrlport_resp_status;

  wire [19:0] spi_master_ctrlport_req_addr;
  wire [31:0] spi_master_ctrlport_req_data;
  wire        spi_master_ctrlport_req_rd;
  wire        spi_master_ctrlport_req_wr;
  wire        spi_master_ctrlport_resp_ack;
  wire [31:0] spi_master_ctrlport_resp_data;
  wire [ 1:0] spi_master_ctrlport_resp_status;

  wire [19:0] unused_fpga_intermediate_ctrlport_req_addr;
  wire [31:0] unused_fpga_intermediate_ctrlport_req_data;
  wire        unused_fpga_intermediate_ctrlport_req_rd;
  wire        unused_fpga_intermediate_ctrlport_req_wr;
  wire        unused_fpga_intermediate_ctrlport_resp_ack;
  wire [31:0] unused_fpga_intermediate_ctrlport_resp_data;
  wire [ 1:0] unused_fpga_intermediate_ctrlport_resp_status;

  wire [19:0] unused_fpga_msbs_ctrlport_req_addr;
  wire [31:0] unused_fpga_msbs_ctrlport_req_data;
  wire        unused_fpga_msbs_ctrlport_req_rd;
  wire        unused_fpga_msbs_ctrlport_req_wr;
  wire        unused_fpga_msbs_ctrlport_resp_ack;
  wire [31:0] unused_fpga_msbs_ctrlport_resp_data;
  wire [ 1:0] unused_fpga_msbs_ctrlport_resp_status;
  //vhook_e ctrlport_splitter
  //vhook_a NUM_SLAVES 4
  //vhook_a {._ctrlport_(.*)time} {}
  //vhook_a {._ctrlport_(.*)byte_en} {}
  //vhook_a {s_ctrlport_(.*)} m_ctrlport_$1
  //vhook_a {m_ctrlport_(.*)} \{unused_fpga_msbs_ctrlport_$1, unused_fpga_intermediate_ctrlport_$1, base_reg_ctrlport_$1, spi_master_ctrlport_$1\}
  ctrlport_splitter
    # (.NUM_SLAVES(4))   //integer:=2
    ctrlport_splitterx (
      .ctrlport_clk             (ctrlport_clk),                                                                                                                                            //in  wire
      .ctrlport_rst             (ctrlport_rst),                                                                                                                                            //in  wire
      .s_ctrlport_req_wr        (m_ctrlport_req_wr),                                                                                                                                       //in  wire
      .s_ctrlport_req_rd        (m_ctrlport_req_rd),                                                                                                                                       //in  wire
      .s_ctrlport_req_addr      (m_ctrlport_req_addr),                                                                                                                                     //in  wire[19:0]
      .s_ctrlport_req_data      (m_ctrlport_req_data),                                                                                                                                     //in  wire[31:0]
      .s_ctrlport_req_byte_en   (),                                                                                                                                                        //in  wire[3:0]
      .s_ctrlport_req_has_time  (),                                                                                                                                                        //in  wire
      .s_ctrlport_req_time      (),                                                                                                                                                        //in  wire[63:0]
      .s_ctrlport_resp_ack      (m_ctrlport_resp_ack),                                                                                                                                     //out wire
      .s_ctrlport_resp_status   (m_ctrlport_resp_status),                                                                                                                                  //out wire[1:0]
      .s_ctrlport_resp_data     (m_ctrlport_resp_data),                                                                                                                                    //out wire[31:0]
      .m_ctrlport_req_wr        ({unused_fpga_msbs_ctrlport_req_wr, unused_fpga_intermediate_ctrlport_req_wr, base_reg_ctrlport_req_wr, spi_master_ctrlport_req_wr}),                      //out wire[(NUM_SLAVES-1):0]
      .m_ctrlport_req_rd        ({unused_fpga_msbs_ctrlport_req_rd, unused_fpga_intermediate_ctrlport_req_rd, base_reg_ctrlport_req_rd, spi_master_ctrlport_req_rd}),                      //out wire[(NUM_SLAVES-1):0]
      .m_ctrlport_req_addr      ({unused_fpga_msbs_ctrlport_req_addr, unused_fpga_intermediate_ctrlport_req_addr, base_reg_ctrlport_req_addr, spi_master_ctrlport_req_addr}),              //out wire[((20*NUM_SLAVES)-1):0]
      .m_ctrlport_req_data      ({unused_fpga_msbs_ctrlport_req_data, unused_fpga_intermediate_ctrlport_req_data, base_reg_ctrlport_req_data, spi_master_ctrlport_req_data}),              //out wire[((32*NUM_SLAVES)-1):0]
      .m_ctrlport_req_byte_en   (),                                                                                                                                                        //out wire[((4*NUM_SLAVES)-1):0]
      .m_ctrlport_req_has_time  (),                                                                                                                                                        //out wire[(NUM_SLAVES-1):0]
      .m_ctrlport_req_time      (),                                                                                                                                                        //out wire[((64*NUM_SLAVES)-1):0]
      .m_ctrlport_resp_ack      ({unused_fpga_msbs_ctrlport_resp_ack, unused_fpga_intermediate_ctrlport_resp_ack, base_reg_ctrlport_resp_ack, spi_master_ctrlport_resp_ack}),              //in  wire[(NUM_SLAVES-1):0]
      .m_ctrlport_resp_status   ({unused_fpga_msbs_ctrlport_resp_status, unused_fpga_intermediate_ctrlport_resp_status, base_reg_ctrlport_resp_status, spi_master_ctrlport_resp_status}),  //in  wire[((2*NUM_SLAVES)-1):0]
      .m_ctrlport_resp_data     ({unused_fpga_msbs_ctrlport_resp_data, unused_fpga_intermediate_ctrlport_resp_data, base_reg_ctrlport_resp_data, spi_master_ctrlport_resp_data}));         //in  wire[((32*NUM_SLAVES)-1):0]

  //----------------------------------------------------------
  // Targets for Requests
  //----------------------------------------------------------
  wire [15:0] db_clock_divider;
  wire [15:0] mb_clock_divider;

  //vhook_e cpld_interface_regs
  //vhook_a BASE_ADDRESS BASE
  //vhook_a NUM_ADDRESSES BASE_SIZE
  //vhook_a {s_ctrlport_(.*)} base_reg_ctrlport_$1
  cpld_interface_regs
    # (
      .BASE_ADDRESS   (BASE),        //integer:=0
      .NUM_ADDRESSES  (BASE_SIZE))   //integer:=128
    cpld_interface_regsx (
      .ctrlport_clk            (ctrlport_clk),                    //in  wire
      .ctrlport_rst            (ctrlport_rst),                    //in  wire
      .s_ctrlport_req_wr       (base_reg_ctrlport_req_wr),        //in  wire
      .s_ctrlport_req_rd       (base_reg_ctrlport_req_rd),        //in  wire
      .s_ctrlport_req_addr     (base_reg_ctrlport_req_addr),      //in  wire[19:0]
      .s_ctrlport_req_data     (base_reg_ctrlport_req_data),      //in  wire[31:0]
      .s_ctrlport_resp_ack     (base_reg_ctrlport_resp_ack),      //out wire
      .s_ctrlport_resp_status  (base_reg_ctrlport_resp_status),   //out wire[1:0]
      .s_ctrlport_resp_data    (base_reg_ctrlport_resp_data),     //out wire[31:0]
      .mb_clock_divider        (mb_clock_divider),                //out wire[15:0]
      .db_clock_divider        (db_clock_divider),                //out wire[15:0]
      .ipass_enable            (ipass_enable),                    //out wire
      .version_info            (version_info));                   //out wire[95:0]

  //vhook_e ctrlport_spi_master
  //vhook_a CPLD_ADDRESS_WIDTH 15
  //vhook_a MB_CPLD_BASE_ADDRESS MB_CPLD
  //vhook_a DB_0_CPLD_BASE_ADDRESS DB0_CPLD
  //vhook_a DB_1_CPLD_BASE_ADDRESS DB1_CPLD
  //vhook_a {s_ctrlport_(.*)} spi_master_ctrlport_$1
  ctrlport_spi_master
    # (
      .CPLD_ADDRESS_WIDTH      (15),         //integer:=15
      .MB_CPLD_BASE_ADDRESS    (MB_CPLD),    //integer:=2#1000000000000000#
      .DB_0_CPLD_BASE_ADDRESS  (DB0_CPLD),   //integer:=2#10000000000000000#
      .DB_1_CPLD_BASE_ADDRESS  (DB1_CPLD))   //integer:=2#11000000000000000#
    ctrlport_spi_masterx (
      .ctrlport_clk            (ctrlport_clk),                      //in  wire
      .ctrlport_rst            (ctrlport_rst),                      //in  wire
      .s_ctrlport_req_wr       (spi_master_ctrlport_req_wr),        //in  wire
      .s_ctrlport_req_rd       (spi_master_ctrlport_req_rd),        //in  wire
      .s_ctrlport_req_addr     (spi_master_ctrlport_req_addr),      //in  wire[19:0]
      .s_ctrlport_req_data     (spi_master_ctrlport_req_data),      //in  wire[31:0]
      .s_ctrlport_resp_ack     (spi_master_ctrlport_resp_ack),      //out wire
      .s_ctrlport_resp_status  (spi_master_ctrlport_resp_status),   //out wire[1:0]
      .s_ctrlport_resp_data    (spi_master_ctrlport_resp_data),     //out wire[31:0]
      .ss                      (ss),                                //out wire[1:0]
      .sclk                    (sclk),                              //out wire
      .mosi                    (mosi),                              //out wire
      .miso                    (miso),                              //in  wire
      .mb_clock_divider        (mb_clock_divider),                  //in  wire[15:0]
      .db_clock_divider        (db_clock_divider));                 //in  wire[15:0]

  //----------------------------------------------------------
  // Invalid target address spaces
  //----------------------------------------------------------
  //vhook_e ctrlport_terminator intermediate_term_inst
  //vhook_a START_ADDRESS BASE + BASE_SIZE
  //vhook_a LAST_ADDRESS MB_CPLD-1
  //vhook_a {^s_ctrlport_(.*)} unused_fpga_intermediate_ctrlport_$1
  ctrlport_terminator
    # (
      .START_ADDRESS  (BASE + BASE_SIZE),   //integer:=0
      .LAST_ADDRESS   (MB_CPLD-1))          //integer:=32
    intermediate_term_inst (
      .ctrlport_clk            (ctrlport_clk),                                    //in  wire
      .ctrlport_rst            (ctrlport_rst),                                    //in  wire
      .s_ctrlport_req_wr       (unused_fpga_intermediate_ctrlport_req_wr),        //in  wire
      .s_ctrlport_req_rd       (unused_fpga_intermediate_ctrlport_req_rd),        //in  wire
      .s_ctrlport_req_addr     (unused_fpga_intermediate_ctrlport_req_addr),      //in  wire[19:0]
      .s_ctrlport_req_data     (unused_fpga_intermediate_ctrlport_req_data),      //in  wire[31:0]
      .s_ctrlport_resp_ack     (unused_fpga_intermediate_ctrlport_resp_ack),      //out wire
      .s_ctrlport_resp_status  (unused_fpga_intermediate_ctrlport_resp_status),   //out wire[1:0]
      .s_ctrlport_resp_data    (unused_fpga_intermediate_ctrlport_resp_data));    //out wire[31:0]

  //vhook_e ctrlport_terminator msbs_term_inst
  //vhook_a START_ADDRESS DB1_CPLD + DB1_CPLD_SIZE
  //vhook_a LAST_ADDRESS 2**CTRLPORT_ADDR_W-1
  //vhook_a {^s_ctrlport_(.*)} unused_fpga_msbs_ctrlport_$1
  ctrlport_terminator
    # (
      .START_ADDRESS  (DB1_CPLD + DB1_CPLD_SIZE),   //integer:=0
      .LAST_ADDRESS   (2**CTRLPORT_ADDR_W-1))       //integer:=32
    msbs_term_inst (
      .ctrlport_clk            (ctrlport_clk),                            //in  wire
      .ctrlport_rst            (ctrlport_rst),                            //in  wire
      .s_ctrlport_req_wr       (unused_fpga_msbs_ctrlport_req_wr),        //in  wire
      .s_ctrlport_req_rd       (unused_fpga_msbs_ctrlport_req_rd),        //in  wire
      .s_ctrlport_req_addr     (unused_fpga_msbs_ctrlport_req_addr),      //in  wire[19:0]
      .s_ctrlport_req_data     (unused_fpga_msbs_ctrlport_req_data),      //in  wire[31:0]
      .s_ctrlport_resp_ack     (unused_fpga_msbs_ctrlport_resp_ack),      //out wire
      .s_ctrlport_resp_status  (unused_fpga_msbs_ctrlport_resp_status),   //out wire[1:0]
      .s_ctrlport_resp_data    (unused_fpga_msbs_ctrlport_resp_data));    //out wire[31:0]

endmodule

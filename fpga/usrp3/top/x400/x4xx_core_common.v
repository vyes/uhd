/////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: x4xx_core_common
//
// Description:
//
//   This module contains the common core infrastructure for RFNoC,
//   such as the motherboard register and timekeeper.
//
/////////////////////////////////////////////////////////////////////

//XmlParse xml_on
//<regmap name="CORE_REGS_REGMAP" readablestrobes="false" generatevhdl="true" ettusguidelines="true">
//  <info>
//    This is the map for the registers that the CORE_REGS window has access to
//    from the ARM_AXI_HPM0_FPD port.
//
//    The registers contained here conform the mboard-regs node that MPM uses
//    to manage general FPGA control/status calls, such as versioning,
//    timekeeper, GPIO, etc.
//  </info>
//  <group name="CORE_REGS">
//    <window name="GLOBAL_REGS"     offset="0x0"   size="0xC00"  targetregmap="GLOBAL_REGS_REGMAP">
//      <info>Window to access global registers in the FPGA.</info>
//    </window>
//    <window name="VERSIONING_REGS" offset="0xC00" size="0x400"  targetregmap="VERSIONING_REGS_REGMAP">
//      <info>Window to access versioning registers in the FPGA.</info>
//    </window>
//    <window name="TIMEKEEPER"      offset="0x1000" size="0x20">
//      <info>Window to access the timekeeper register map.</info>
//    </window>
//    <window name="DIO"             offset="0x2000" size="0x20"  targetregmap="DIO_REGMAP">
//      <info>Window to access the DIO register map.</info>
//    </window>
//  </group>
//</regmap>
//XmlParse xml_off

module x4xx_core_common #(
  parameter CHDR_CLK_RATE  = 200000000, // rfnoc_chdr_clk rate
  parameter CHDR_W         = 64,        // Sw uses this to determine CHDR_W prior to enumerating
  parameter RFNOC_PROTOVER = {8'd1, 8'd0},
  parameter PCIE_PRESENT   = 0          // Is PCI-Express present in this image?
) (
  // Clocks and resets
  input radio_clk,
  input radio_rst,

  input rfnoc_chdr_clk,
  input rfnoc_chdr_rst,

  input rfnoc_ctrl_clk,
  input rfnoc_ctrl_rst,

  // Ctrlport master interface from AXI
  input         ctrlport_rst,
  input         ctrlport_clk,
  input         s_ctrlport_req_wr,
  input         s_ctrlport_req_rd,
  input  [19:0] s_ctrlport_req_addr,
  input  [ 9:0] s_ctrlport_req_portid,
  input  [15:0] s_ctrlport_req_rem_epid,
  input  [ 9:0] s_ctrlport_req_rem_portid,
  input  [31:0] s_ctrlport_req_data,
  input  [ 3:0] s_ctrlport_req_byte_en,
  input         s_ctrlport_req_has_time,
  input  [63:0] s_ctrlport_req_time,
  output        s_ctrlport_resp_ack,
  output [ 1:0] s_ctrlport_resp_status,
  output [31:0] s_ctrlport_resp_data,

  // PPS and Clock Control (top-level inputs)
  input        pps_radioclk,
  input        refclk_locked,

  // PPS and Clock Control (Domain: rfnoc_ctrl_clk)
  output [ 1:0] pps_select,
  output        ref_select,
  output [ 1:0] trig_io_select,
  output        pll_sync_trigger,
  output [ 7:0] pll_sync_delay,
  input         pll_sync_done,
  output [ 7:0] pps_brc_delay,
  output [25:0] pps_prc_delay,
  output [ 1:0] prc_rc_divider,
  output        pps_rc_enabled,

  // Timekeeper (Domain: radio_clk)
  input  [ 7:0] radio_spc,
  output [63:0] radio_time,
  input         sample_rx_stb,

  // GPIO to DIO board (Domain: rfnoc_ctrl_clk)
  output wire [11:0] gpio_en_a,
  output wire [11:0] gpio_en_b,
  // GPIO to DIO board (async)
  input  wire [11:0] gpio_in_a,
  input  wire [11:0] gpio_in_b,
  output wire [11:0] gpio_out_a,
  output wire [11:0] gpio_out_b,

  // GPIO to application (Domain: rfnoc_ctrl_clk)
  output wire [11:0] gpio_in_fabric_a,
  output wire [11:0] gpio_in_fabric_b,
  input  wire [11:0] gpio_out_fabric_a,
  input  wire [11:0] gpio_out_fabric_b,

  // Misc (Domain: rfnoc_ctrl_clk)
  input  [31:0] qsfp_port_0_0_info,
  input  [31:0] qsfp_port_0_1_info,
  input  [31:0] qsfp_port_0_2_info,
  input  [31:0] qsfp_port_0_3_info,
  input  [31:0] qsfp_port_1_0_info,
  input  [31:0] qsfp_port_1_1_info,
  input  [31:0] qsfp_port_1_2_info,
  input  [31:0] qsfp_port_1_3_info,
  input  [31:0] gps_status,
  output [31:0] gps_ctrl,
  input  [31:0] dboard_status,
  output [31:0] dboard_ctrl,
  output [15:0] device_id,
  output        mfg_test_en_fabric_clk,
  output        mfg_test_en_gty_rcv_clk,
  input         fpga_aux_ref,

  // Versioning (Constant)
  // Each component consists of a 96-bit vector (refer to versioning_utils.vh)
  input wire [64*96-1:0] version_info

);

  `include "../../lib/rfnoc/core/ctrlport.vh"
  `include "regmap/core_regs_regmap_utils.vh"

  //---------------------------------------------------------------------------
  // AXI4-Lite to ctrlport
  //---------------------------------------------------------------------------

  // Ctrlport master interface (domain: rfnoc_ctrl_clk)
  wire                       m_req_wr;
  wire                       m_req_rd;
  wire [CTRLPORT_ADDR_W-1:0] m_req_addr;
  wire [CTRLPORT_DATA_W-1:0] m_req_data;
  wire                       m_resp_ack;
  wire [CTRLPORT_STS_W-1:0]  m_resp_status;
  wire [CTRLPORT_DATA_W-1:0] m_resp_data;

  // Split ctrlport for multiple endpoints (domain: rfnoc_ctrl_clk)
  wire                       timekeeper_req_wr, versioning_req_wr, global_regs_req_wr, dio_req_wr;
  wire                       timekeeper_req_rd, versioning_req_rd, global_regs_req_rd, dio_req_rd;
  wire [CTRLPORT_ADDR_W-1:0] timekeeper_req_addr, versioning_req_addr, global_regs_req_addr, dio_req_addr;
  wire [CTRLPORT_DATA_W-1:0] timekeeper_req_data, versioning_req_data, global_regs_req_data, dio_req_data;
  wire                       timekeeper_resp_ack, versioning_resp_ack, global_regs_resp_ack, dio_resp_ack;
  wire [CTRLPORT_STS_W-1:0]  timekeeper_resp_status, versioning_resp_status, global_regs_resp_status, dio_resp_status;
  wire [CTRLPORT_DATA_W-1:0] timekeeper_resp_data, versioning_resp_data, global_regs_resp_data, dio_resp_data;

  ctrlport_clk_cross ctrlport_clk_cross_i (
    .rst                        (ctrlport_rst),
    .s_ctrlport_clk             (ctrlport_clk),
    .s_ctrlport_req_wr          (s_ctrlport_req_wr),
    .s_ctrlport_req_rd          (s_ctrlport_req_rd),
    .s_ctrlport_req_addr        (s_ctrlport_req_addr),
    .s_ctrlport_req_portid      (s_ctrlport_req_portid),
    .s_ctrlport_req_rem_epid    (s_ctrlport_req_rem_epid),
    .s_ctrlport_req_rem_portid  (s_ctrlport_req_rem_portid),
    .s_ctrlport_req_data        (s_ctrlport_req_data),
    .s_ctrlport_req_byte_en     (s_ctrlport_req_byte_en),
    .s_ctrlport_req_has_time    (s_ctrlport_req_has_time),
    .s_ctrlport_req_time        (s_ctrlport_req_time),
    .s_ctrlport_resp_ack        (s_ctrlport_resp_ack),
    .s_ctrlport_resp_status     (s_ctrlport_resp_status),
    .s_ctrlport_resp_data       (s_ctrlport_resp_data),
    .m_ctrlport_clk             (rfnoc_ctrl_clk),
    .m_ctrlport_req_wr          (m_req_wr),
    .m_ctrlport_req_rd          (m_req_rd),
    .m_ctrlport_req_addr        (m_req_addr),
    .m_ctrlport_req_portid      (),
    .m_ctrlport_req_rem_epid    (),
    .m_ctrlport_req_rem_portid  (),
    .m_ctrlport_req_data        (m_req_data),
    .m_ctrlport_req_byte_en     (),
    .m_ctrlport_req_has_time    (),
    .m_ctrlport_req_time        (),
    .m_ctrlport_resp_ack        (m_resp_ack),
    .m_ctrlport_resp_status     (m_resp_status),
    .m_ctrlport_resp_data       (m_resp_data)
  );

  ctrlport_splitter #(
    .NUM_SLAVES(4)
  ) ctrlport_splitter_i (
    .ctrlport_clk             (rfnoc_ctrl_clk),
    .ctrlport_rst             (rfnoc_ctrl_rst),
    .s_ctrlport_req_wr        (m_req_wr),
    .s_ctrlport_req_rd        (m_req_rd),
    .s_ctrlport_req_addr      (m_req_addr),
    .s_ctrlport_req_data      (m_req_data),
    .s_ctrlport_req_byte_en   (4'hF),
    .s_ctrlport_req_has_time  (1'b0),
    .s_ctrlport_req_time      (64'h0),
    .s_ctrlport_resp_ack      (m_resp_ack),
    .s_ctrlport_resp_status   (m_resp_status),
    .s_ctrlport_resp_data     (m_resp_data),
    .m_ctrlport_req_wr        ({timekeeper_req_wr, versioning_req_wr, global_regs_req_wr, dio_req_wr}),
    .m_ctrlport_req_rd        ({timekeeper_req_rd, versioning_req_rd, global_regs_req_rd, dio_req_rd}),
    .m_ctrlport_req_addr      ({timekeeper_req_addr, versioning_req_addr, global_regs_req_addr, dio_req_addr}),
    .m_ctrlport_req_data      ({timekeeper_req_data, versioning_req_data, global_regs_req_data, dio_req_data}),
    .m_ctrlport_req_byte_en   (),
    .m_ctrlport_req_has_time  (),
    .m_ctrlport_req_time      (),
    .m_ctrlport_resp_ack      ({timekeeper_resp_ack, versioning_resp_ack, global_regs_resp_ack, dio_resp_ack}),
    .m_ctrlport_resp_status   ({timekeeper_resp_status, versioning_resp_status, global_regs_resp_status, dio_resp_status}),
    .m_ctrlport_resp_data     ({timekeeper_resp_data, versioning_resp_data, global_regs_resp_data, dio_resp_data})
  );

  //--------------------------------------------------------------------
  // Global Registers
  // -------------------------------------------------------------------

  localparam NUM_TIMEKEEPERS = 1;

  assign global_regs_resp_status = CTRL_STS_OKAY;

  x4xx_global_regs # (
    .REG_BASE        (GLOBAL_REGS),
    .CHDR_CLK_RATE   (CHDR_CLK_RATE),
    .CHDR_W          (CHDR_W),
    .RFNOC_PROTOVER  (RFNOC_PROTOVER),
    .NUM_TIMEKEEPERS (NUM_TIMEKEEPERS),
    .PCIE_PRESENT    (PCIE_PRESENT)
  ) x4xx_global_regs_i (
    .s_ctrlport_clk       (rfnoc_ctrl_clk),
    .s_ctrlport_rst       (rfnoc_ctrl_rst),
    .s_ctrlport_req_wr    (global_regs_req_wr),
    .s_ctrlport_req_rd    (global_regs_req_rd),
    .s_ctrlport_req_addr  (global_regs_req_addr),
    .s_ctrlport_req_data  (global_regs_req_data),
    .s_ctrlport_resp_ack  (global_regs_resp_ack),
    .s_ctrlport_resp_data (global_regs_resp_data),
    .rfnoc_chdr_clk       (rfnoc_chdr_clk),
    .rfnoc_chdr_rst       (rfnoc_chdr_rst),
    .refclk_locked        (refclk_locked),
    .pps_select           (pps_select),
    .ref_select           (ref_select),
    .trig_io_select       (trig_io_select),
    .pll_sync_trigger     (pll_sync_trigger),
    .pll_sync_delay       (pll_sync_delay),
    .pll_sync_done        (pll_sync_done),
    .pps_brc_delay        (pps_brc_delay),
    .pps_prc_delay        (pps_prc_delay),
    .prc_rc_divider       (prc_rc_divider),
    .pps_rc_enabled       (pps_rc_enabled),
    .qsfp_port_0_0_info        (qsfp_port_0_0_info),
    .qsfp_port_0_1_info        (qsfp_port_0_1_info),
    .qsfp_port_0_2_info        (qsfp_port_0_2_info),
    .qsfp_port_0_3_info        (qsfp_port_0_3_info),
    .qsfp_port_1_0_info        (qsfp_port_1_0_info),
    .qsfp_port_1_1_info        (qsfp_port_1_1_info),
    .qsfp_port_1_2_info        (qsfp_port_1_2_info),
    .qsfp_port_1_3_info        (qsfp_port_1_3_info),
    .gps_status           (gps_status),
    .gps_ctrl             (gps_ctrl),
    .dboard_status        (dboard_status),
    .dboard_ctrl          (dboard_ctrl),
    .mfg_test_en_fabric_clk  (mfg_test_en_fabric_clk),
    .mfg_test_en_gty_rcv_clk (mfg_test_en_gty_rcv_clk),
    .fpga_aux_ref            (fpga_aux_ref),
    .device_id            (device_id)
  );

  //--------------------------------------------------------------------
  // Versioning Registers
  // -------------------------------------------------------------------

  x4xx_versioning_regs # (
    .REG_BASE (VERSIONING_REGS)
  ) x4xx_versioning_regs_i (
    .s_ctrlport_clk         (rfnoc_ctrl_clk),
    .s_ctrlport_rst         (rfnoc_ctrl_rst),
    .s_ctrlport_req_wr      (versioning_req_wr),
    .s_ctrlport_req_rd      (versioning_req_rd),
    .s_ctrlport_req_addr    (versioning_req_addr),
    .s_ctrlport_req_data    (versioning_req_data),
    .s_ctrlport_resp_ack    (versioning_resp_ack),
    .s_ctrlport_resp_status (versioning_resp_status),
    .s_ctrlport_resp_data   (versioning_resp_data),
    .version_info           (version_info)
  );

  //---------------------------------------------------------------------------
  // Timekeeper
  //---------------------------------------------------------------------------

  assign timekeeper_resp_status = CTRL_STS_OKAY;

  timekeeper #(
    .BASE_ADDR      (TIMEKEEPER),
    .TIME_INCREMENT (0)
  ) timekeeper_i (
    .tb_clk                (radio_clk),
    .tb_rst                (radio_rst),
    .s_ctrlport_clk        (rfnoc_ctrl_clk),
    .s_ctrlport_req_wr     (timekeeper_req_wr),
    .s_ctrlport_req_rd     (timekeeper_req_rd),
    .s_ctrlport_req_addr   (timekeeper_req_addr),
    .s_ctrlport_req_data   (timekeeper_req_data),
    .s_ctrlport_resp_ack   (timekeeper_resp_ack),
    .s_ctrlport_resp_data  (timekeeper_resp_data),
    .time_increment        (radio_spc),
    .sample_rx_stb         (sample_rx_stb),
    .pps                   (pps_radioclk),
    .tb_timestamp          (radio_time),
    .tb_timestamp_last_pps (),
    .tb_period_ns_q32      ()
  );

  //---------------------------------------------------------------------------
  // DIO
  //---------------------------------------------------------------------------

  assign dio_resp_status = CTRL_STS_OKAY;

  x4xx_dio #(
    .REG_BASE (DIO)
  ) x4xx_dio_i (
    .ctrlport_clk          (rfnoc_ctrl_clk),
    .ctrlport_rst          (rfnoc_ctrl_rst),
    .s_ctrlport_req_wr     (dio_req_wr),
    .s_ctrlport_req_rd     (dio_req_rd),
    .s_ctrlport_req_addr   (dio_req_addr),
    .s_ctrlport_req_data   (dio_req_data),
    .s_ctrlport_resp_ack   (dio_resp_ack),
    .s_ctrlport_resp_data  (dio_resp_data),
    .gpio_in_a             (gpio_in_a),
    .gpio_in_b             (gpio_in_b),
    .gpio_out_a            (gpio_out_a),
    .gpio_out_b            (gpio_out_b),
    .gpio_en_a             (gpio_en_a),
    .gpio_en_b             (gpio_en_b),
    .gpio_in_fabric_a      (gpio_in_fabric_a),
    .gpio_in_fabric_b      (gpio_in_fabric_b),
    .gpio_out_fabric_a     (gpio_out_fabric_a),
    .gpio_out_fabric_b     (gpio_out_fabric_b)
  );

endmodule

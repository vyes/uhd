//
// Copyright 2021 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: rfnoc_image_core (for x410)
//
// Description:
//
//   The RFNoC Image Core contains the Verilog description of the RFNoC design
//   to be loaded onto the FPGA.
//
//   This file was automatically generated by the RFNoC image builder tool.
//   Re-running that tool will overwrite this file!
//
// File generated on: 2021-03-09T10:14:37.816815
// Source: x410_400_rfnoc_image_core.yml
// Source SHA256: 565eab4c9ee9606457fa38a6e701d4273ae11a872c0b50b6e9908f26d3891276
//

`default_nettype none

`include "x410_400_rfnoc_image_core.vh"


module rfnoc_image_core #(
  parameter        CHDR_W     = `CHDR_WIDTH,
  parameter        MTU        = 10,
  parameter [15:0] PROTOVER   = {8'd1, 8'd0},
  parameter        RADIO_NIPC = 1
) (
  // Clocks
  input  wire         chdr_aclk,
  input  wire         ctrl_aclk,
  input  wire         core_arst,
  input  wire         radio_clk,
  input  wire         radio_2x_clk,
  // Basic
  input  wire [  15:0] device_id,

  // IO ports /////////////////////////

  // ctrlport_radio0
  output wire [   0:0] m_ctrlport_radio0_req_wr,
  output wire [   0:0] m_ctrlport_radio0_req_rd,
  output wire [  19:0] m_ctrlport_radio0_req_addr,
  output wire [  31:0] m_ctrlport_radio0_req_data,
  output wire [   3:0] m_ctrlport_radio0_req_byte_en,
  output wire [   0:0] m_ctrlport_radio0_req_has_time,
  output wire [  63:0] m_ctrlport_radio0_req_time,
  input  wire [   0:0] m_ctrlport_radio0_resp_ack,
  input  wire [   1:0] m_ctrlport_radio0_resp_status,
  input  wire [  31:0] m_ctrlport_radio0_resp_data,
  // ctrlport_radio1
  output wire [   0:0] m_ctrlport_radio1_req_wr,
  output wire [   0:0] m_ctrlport_radio1_req_rd,
  output wire [  19:0] m_ctrlport_radio1_req_addr,
  output wire [  31:0] m_ctrlport_radio1_req_data,
  output wire [   3:0] m_ctrlport_radio1_req_byte_en,
  output wire [   0:0] m_ctrlport_radio1_req_has_time,
  output wire [  63:0] m_ctrlport_radio1_req_time,
  input  wire [   0:0] m_ctrlport_radio1_resp_ack,
  input  wire [   1:0] m_ctrlport_radio1_resp_status,
  input  wire [  31:0] m_ctrlport_radio1_resp_data,
  // time
  input  wire [  63:0] radio_time,
  // radio0
  input  wire [ 255:0] radio_rx_data_radio0,
  input  wire [   3:0] radio_rx_stb_radio0,
  output wire [   1:0] radio_rx_running_radio0,
  output wire [ 255:0] radio_tx_data_radio0,
  input  wire [   3:0] radio_tx_stb_radio0,
  output wire [   1:0] radio_tx_running_radio0,
  // radio1
  input  wire [ 255:0] radio_rx_data_radio1,
  input  wire [   3:0] radio_rx_stb_radio1,
  output wire [   1:0] radio_rx_running_radio1,
  output wire [ 255:0] radio_tx_data_radio1,
  input  wire [   3:0] radio_tx_stb_radio1,
  output wire [   1:0] radio_tx_running_radio1,

  // Transport Adapters ///////////////

  // Transport 0 (eth0)
  input  wire [CHDR_W-1:0] s_eth0_tdata,
  input  wire              s_eth0_tlast,
  input  wire              s_eth0_tvalid,
  output wire              s_eth0_tready,
  output wire [CHDR_W-1:0] m_eth0_tdata,
  output wire              m_eth0_tlast,
  output wire              m_eth0_tvalid,
  input  wire              m_eth0_tready,
  // Transport 1 (eth1)
  input  wire [CHDR_W-1:0] s_eth1_tdata,
  input  wire              s_eth1_tlast,
  input  wire              s_eth1_tvalid,
  output wire              s_eth1_tready,
  output wire [CHDR_W-1:0] m_eth1_tdata,
  output wire              m_eth1_tlast,
  output wire              m_eth1_tvalid,
  input  wire              m_eth1_tready,
  // Transport 2 (eth2)
  input  wire [CHDR_W-1:0] s_eth2_tdata,
  input  wire              s_eth2_tlast,
  input  wire              s_eth2_tvalid,
  output wire              s_eth2_tready,
  output wire [CHDR_W-1:0] m_eth2_tdata,
  output wire              m_eth2_tlast,
  output wire              m_eth2_tvalid,
  input  wire              m_eth2_tready,
  // Transport 3 (eth3)
  input  wire [CHDR_W-1:0] s_eth3_tdata,
  input  wire              s_eth3_tlast,
  input  wire              s_eth3_tvalid,
  output wire              s_eth3_tready,
  output wire [CHDR_W-1:0] m_eth3_tdata,
  output wire              m_eth3_tlast,
  output wire              m_eth3_tvalid,
  input  wire              m_eth3_tready,
  // Transport 4 (eth4)
  input  wire [CHDR_W-1:0] s_eth4_tdata,
  input  wire              s_eth4_tlast,
  input  wire              s_eth4_tvalid,
  output wire              s_eth4_tready,
  output wire [CHDR_W-1:0] m_eth4_tdata,
  output wire              m_eth4_tlast,
  output wire              m_eth4_tvalid,
  input  wire              m_eth4_tready,
  // Transport 5 (dma)
  input  wire [CHDR_W-1:0] s_dma_tdata,
  input  wire              s_dma_tlast,
  input  wire              s_dma_tvalid,
  output wire              s_dma_tready,
  output wire [CHDR_W-1:0] m_dma_tdata,
  output wire              m_dma_tlast,
  output wire              m_dma_tvalid,
  input  wire              m_dma_tready
);

  localparam EDGE_TBL_FILE = `"`RFNOC_EDGE_TBL_FILE`";

  wire rfnoc_chdr_clk, rfnoc_chdr_rst;
  wire rfnoc_ctrl_clk, rfnoc_ctrl_rst;

  // Check that CHDR_W parameter matches value used by RFNoC Image Builder
  if (CHDR_W != `CHDR_WIDTH) begin
    ERROR_CHDR_W_values_do_not_match();
  end


  //---------------------------------------------------------------------------
  // CHDR Crossbar
  //---------------------------------------------------------------------------

  wire [CHDR_W-1:0] xb_to_ep0_tdata ;
  wire              xb_to_ep0_tlast ;
  wire              xb_to_ep0_tvalid;
  wire              xb_to_ep0_tready;
  wire [CHDR_W-1:0] ep0_to_xb_tdata ;
  wire              ep0_to_xb_tlast ;
  wire              ep0_to_xb_tvalid;
  wire              ep0_to_xb_tready;
  wire [CHDR_W-1:0] xb_to_ep1_tdata ;
  wire              xb_to_ep1_tlast ;
  wire              xb_to_ep1_tvalid;
  wire              xb_to_ep1_tready;
  wire [CHDR_W-1:0] ep1_to_xb_tdata ;
  wire              ep1_to_xb_tlast ;
  wire              ep1_to_xb_tvalid;
  wire              ep1_to_xb_tready;
  wire [CHDR_W-1:0] xb_to_ep2_tdata ;
  wire              xb_to_ep2_tlast ;
  wire              xb_to_ep2_tvalid;
  wire              xb_to_ep2_tready;
  wire [CHDR_W-1:0] ep2_to_xb_tdata ;
  wire              ep2_to_xb_tlast ;
  wire              ep2_to_xb_tvalid;
  wire              ep2_to_xb_tready;
  wire [CHDR_W-1:0] xb_to_ep3_tdata ;
  wire              xb_to_ep3_tlast ;
  wire              xb_to_ep3_tvalid;
  wire              xb_to_ep3_tready;
  wire [CHDR_W-1:0] ep3_to_xb_tdata ;
  wire              ep3_to_xb_tlast ;
  wire              ep3_to_xb_tvalid;
  wire              ep3_to_xb_tready;

  chdr_crossbar_nxn #(
    .CHDR_W         (CHDR_W),
    .NPORTS         (10),
    .DEFAULT_PORT   (0),
    .MTU            (MTU),
    .ROUTE_TBL_SIZE (6),
    .MUX_ALLOC      ("ROUND-ROBIN"),
    .OPTIMIZE       ("AREA"),
    .NPORTS_MGMT    (6),
    .EXT_RTCFG_PORT (0),
    .PROTOVER       (PROTOVER)
  ) chdr_xb_i (
    .clk            (rfnoc_chdr_clk),
    .reset          (rfnoc_chdr_rst),
    .device_id      (device_id),
    .s_axis_tdata   ({ep3_to_xb_tdata , ep2_to_xb_tdata , ep1_to_xb_tdata , ep0_to_xb_tdata , s_dma_tdata , s_eth4_tdata , s_eth3_tdata , s_eth2_tdata , s_eth1_tdata , s_eth0_tdata }),
    .s_axis_tlast   ({ep3_to_xb_tlast , ep2_to_xb_tlast , ep1_to_xb_tlast , ep0_to_xb_tlast , s_dma_tlast , s_eth4_tlast , s_eth3_tlast , s_eth2_tlast , s_eth1_tlast , s_eth0_tlast }),
    .s_axis_tvalid  ({ep3_to_xb_tvalid, ep2_to_xb_tvalid, ep1_to_xb_tvalid, ep0_to_xb_tvalid, s_dma_tvalid, s_eth4_tvalid, s_eth3_tvalid, s_eth2_tvalid, s_eth1_tvalid, s_eth0_tvalid}),
    .s_axis_tready  ({ep3_to_xb_tready, ep2_to_xb_tready, ep1_to_xb_tready, ep0_to_xb_tready, s_dma_tready, s_eth4_tready, s_eth3_tready, s_eth2_tready, s_eth1_tready, s_eth0_tready}),
    .m_axis_tdata   ({xb_to_ep3_tdata , xb_to_ep2_tdata , xb_to_ep1_tdata , xb_to_ep0_tdata , m_dma_tdata , m_eth4_tdata , m_eth3_tdata , m_eth2_tdata , m_eth1_tdata , m_eth0_tdata }),
    .m_axis_tlast   ({xb_to_ep3_tlast , xb_to_ep2_tlast , xb_to_ep1_tlast , xb_to_ep0_tlast , m_dma_tlast , m_eth4_tlast , m_eth3_tlast , m_eth2_tlast , m_eth1_tlast , m_eth0_tlast }),
    .m_axis_tvalid  ({xb_to_ep3_tvalid, xb_to_ep2_tvalid, xb_to_ep1_tvalid, xb_to_ep0_tvalid, m_dma_tvalid, m_eth4_tvalid, m_eth3_tvalid, m_eth2_tvalid, m_eth1_tvalid, m_eth0_tvalid}),
    .m_axis_tready  ({xb_to_ep3_tready, xb_to_ep2_tready, xb_to_ep1_tready, xb_to_ep0_tready, m_dma_tready, m_eth4_tready, m_eth3_tready, m_eth2_tready, m_eth1_tready, m_eth0_tready}),
    .ext_rtcfg_stb  (1'h0),
    .ext_rtcfg_addr (16'h0),
    .ext_rtcfg_data (32'h0),
    .ext_rtcfg_ack  ()
  );


  //---------------------------------------------------------------------------
  // Stream Endpoints
  //---------------------------------------------------------------------------

  wire [CHDR_W-1:0] m_ep0_out0_tdata;
  wire              m_ep0_out0_tlast;
  wire              m_ep0_out0_tvalid;
  wire              m_ep0_out0_tready;
  wire [CHDR_W-1:0] s_ep0_in0_tdata;
  wire              s_ep0_in0_tlast;
  wire              s_ep0_in0_tvalid;
  wire              s_ep0_in0_tready;
  wire [      31:0] m_ep0_ctrl_tdata,  s_ep0_ctrl_tdata;
  wire              m_ep0_ctrl_tlast,  s_ep0_ctrl_tlast;
  wire              m_ep0_ctrl_tvalid, s_ep0_ctrl_tvalid;
  wire              m_ep0_ctrl_tready, s_ep0_ctrl_tready;

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (1),
    .AXIS_DATA_EN       (1),
    .NUM_DATA_I         (1),
    .NUM_DATA_O         (1),
    .INST_NUM           (0),
    .CTRL_XBAR_PORT     (1),
    .INGRESS_BUFF_SIZE  (13),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1)
  ) ep0_i (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst),
    .device_id          (device_id),
    .s_axis_chdr_tdata  (xb_to_ep0_tdata),
    .s_axis_chdr_tlast  (xb_to_ep0_tlast),
    .s_axis_chdr_tvalid (xb_to_ep0_tvalid),
    .s_axis_chdr_tready (xb_to_ep0_tready),
    .m_axis_chdr_tdata  (ep0_to_xb_tdata),
    .m_axis_chdr_tlast  (ep0_to_xb_tlast),
    .m_axis_chdr_tvalid (ep0_to_xb_tvalid),
    .m_axis_chdr_tready (ep0_to_xb_tready),
    .s_axis_data_tdata  ({s_ep0_in0_tdata}),
    .s_axis_data_tlast  ({s_ep0_in0_tlast}),
    .s_axis_data_tvalid ({s_ep0_in0_tvalid}),
    .s_axis_data_tready ({s_ep0_in0_tready}),
    .m_axis_data_tdata  ({m_ep0_out0_tdata}),
    .m_axis_data_tlast  ({m_ep0_out0_tlast}),
    .m_axis_data_tvalid ({m_ep0_out0_tvalid}),
    .m_axis_data_tready ({m_ep0_out0_tready}),
    .s_axis_ctrl_tdata  (s_ep0_ctrl_tdata),
    .s_axis_ctrl_tlast  (s_ep0_ctrl_tlast),
    .s_axis_ctrl_tvalid (s_ep0_ctrl_tvalid),
    .s_axis_ctrl_tready (s_ep0_ctrl_tready),
    .m_axis_ctrl_tdata  (m_ep0_ctrl_tdata),
    .m_axis_ctrl_tlast  (m_ep0_ctrl_tlast),
    .m_axis_ctrl_tvalid (m_ep0_ctrl_tvalid),
    .m_axis_ctrl_tready (m_ep0_ctrl_tready),
    .strm_seq_err_stb   (),
    .strm_data_err_stb  (),
    .strm_route_err_stb (),
    .signal_data_err    (1'b0)
  );

  wire [CHDR_W-1:0] m_ep1_out0_tdata;
  wire              m_ep1_out0_tlast;
  wire              m_ep1_out0_tvalid;
  wire              m_ep1_out0_tready;
  wire [CHDR_W-1:0] s_ep1_in0_tdata;
  wire              s_ep1_in0_tlast;
  wire              s_ep1_in0_tvalid;
  wire              s_ep1_in0_tready;
  wire [      31:0] m_ep1_ctrl_tdata,  s_ep1_ctrl_tdata;
  wire              m_ep1_ctrl_tlast,  s_ep1_ctrl_tlast;
  wire              m_ep1_ctrl_tvalid, s_ep1_ctrl_tvalid;
  wire              m_ep1_ctrl_tready, s_ep1_ctrl_tready;

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (0),
    .AXIS_DATA_EN       (1),
    .NUM_DATA_I         (1),
    .NUM_DATA_O         (1),
    .INST_NUM           (1),
    .CTRL_XBAR_PORT     (2),
    .INGRESS_BUFF_SIZE  (13),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1)
  ) ep1_i (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst),
    .device_id          (device_id),
    .s_axis_chdr_tdata  (xb_to_ep1_tdata),
    .s_axis_chdr_tlast  (xb_to_ep1_tlast),
    .s_axis_chdr_tvalid (xb_to_ep1_tvalid),
    .s_axis_chdr_tready (xb_to_ep1_tready),
    .m_axis_chdr_tdata  (ep1_to_xb_tdata),
    .m_axis_chdr_tlast  (ep1_to_xb_tlast),
    .m_axis_chdr_tvalid (ep1_to_xb_tvalid),
    .m_axis_chdr_tready (ep1_to_xb_tready),
    .s_axis_data_tdata  ({s_ep1_in0_tdata}),
    .s_axis_data_tlast  ({s_ep1_in0_tlast}),
    .s_axis_data_tvalid ({s_ep1_in0_tvalid}),
    .s_axis_data_tready ({s_ep1_in0_tready}),
    .m_axis_data_tdata  ({m_ep1_out0_tdata}),
    .m_axis_data_tlast  ({m_ep1_out0_tlast}),
    .m_axis_data_tvalid ({m_ep1_out0_tvalid}),
    .m_axis_data_tready ({m_ep1_out0_tready}),
    .s_axis_ctrl_tdata  (s_ep1_ctrl_tdata),
    .s_axis_ctrl_tlast  (s_ep1_ctrl_tlast),
    .s_axis_ctrl_tvalid (s_ep1_ctrl_tvalid),
    .s_axis_ctrl_tready (s_ep1_ctrl_tready),
    .m_axis_ctrl_tdata  (m_ep1_ctrl_tdata),
    .m_axis_ctrl_tlast  (m_ep1_ctrl_tlast),
    .m_axis_ctrl_tvalid (m_ep1_ctrl_tvalid),
    .m_axis_ctrl_tready (m_ep1_ctrl_tready),
    .strm_seq_err_stb   (),
    .strm_data_err_stb  (),
    .strm_route_err_stb (),
    .signal_data_err    (1'b0)
  );

  wire [CHDR_W-1:0] m_ep2_out0_tdata;
  wire              m_ep2_out0_tlast;
  wire              m_ep2_out0_tvalid;
  wire              m_ep2_out0_tready;
  wire [CHDR_W-1:0] s_ep2_in0_tdata;
  wire              s_ep2_in0_tlast;
  wire              s_ep2_in0_tvalid;
  wire              s_ep2_in0_tready;
  wire [      31:0] m_ep2_ctrl_tdata,  s_ep2_ctrl_tdata;
  wire              m_ep2_ctrl_tlast,  s_ep2_ctrl_tlast;
  wire              m_ep2_ctrl_tvalid, s_ep2_ctrl_tvalid;
  wire              m_ep2_ctrl_tready, s_ep2_ctrl_tready;

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (0),
    .AXIS_DATA_EN       (1),
    .NUM_DATA_I         (1),
    .NUM_DATA_O         (1),
    .INST_NUM           (2),
    .CTRL_XBAR_PORT     (3),
    .INGRESS_BUFF_SIZE  (13),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1)
  ) ep2_i (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst),
    .device_id          (device_id),
    .s_axis_chdr_tdata  (xb_to_ep2_tdata),
    .s_axis_chdr_tlast  (xb_to_ep2_tlast),
    .s_axis_chdr_tvalid (xb_to_ep2_tvalid),
    .s_axis_chdr_tready (xb_to_ep2_tready),
    .m_axis_chdr_tdata  (ep2_to_xb_tdata),
    .m_axis_chdr_tlast  (ep2_to_xb_tlast),
    .m_axis_chdr_tvalid (ep2_to_xb_tvalid),
    .m_axis_chdr_tready (ep2_to_xb_tready),
    .s_axis_data_tdata  ({s_ep2_in0_tdata}),
    .s_axis_data_tlast  ({s_ep2_in0_tlast}),
    .s_axis_data_tvalid ({s_ep2_in0_tvalid}),
    .s_axis_data_tready ({s_ep2_in0_tready}),
    .m_axis_data_tdata  ({m_ep2_out0_tdata}),
    .m_axis_data_tlast  ({m_ep2_out0_tlast}),
    .m_axis_data_tvalid ({m_ep2_out0_tvalid}),
    .m_axis_data_tready ({m_ep2_out0_tready}),
    .s_axis_ctrl_tdata  (s_ep2_ctrl_tdata),
    .s_axis_ctrl_tlast  (s_ep2_ctrl_tlast),
    .s_axis_ctrl_tvalid (s_ep2_ctrl_tvalid),
    .s_axis_ctrl_tready (s_ep2_ctrl_tready),
    .m_axis_ctrl_tdata  (m_ep2_ctrl_tdata),
    .m_axis_ctrl_tlast  (m_ep2_ctrl_tlast),
    .m_axis_ctrl_tvalid (m_ep2_ctrl_tvalid),
    .m_axis_ctrl_tready (m_ep2_ctrl_tready),
    .strm_seq_err_stb   (),
    .strm_data_err_stb  (),
    .strm_route_err_stb (),
    .signal_data_err    (1'b0)
  );

  wire [CHDR_W-1:0] m_ep3_out0_tdata;
  wire              m_ep3_out0_tlast;
  wire              m_ep3_out0_tvalid;
  wire              m_ep3_out0_tready;
  wire [CHDR_W-1:0] s_ep3_in0_tdata;
  wire              s_ep3_in0_tlast;
  wire              s_ep3_in0_tvalid;
  wire              s_ep3_in0_tready;
  wire [      31:0] m_ep3_ctrl_tdata,  s_ep3_ctrl_tdata;
  wire              m_ep3_ctrl_tlast,  s_ep3_ctrl_tlast;
  wire              m_ep3_ctrl_tvalid, s_ep3_ctrl_tvalid;
  wire              m_ep3_ctrl_tready, s_ep3_ctrl_tready;

  chdr_stream_endpoint #(
    .PROTOVER           (PROTOVER),
    .CHDR_W             (CHDR_W),
    .AXIS_CTRL_EN       (0),
    .AXIS_DATA_EN       (1),
    .NUM_DATA_I         (1),
    .NUM_DATA_O         (1),
    .INST_NUM           (3),
    .CTRL_XBAR_PORT     (4),
    .INGRESS_BUFF_SIZE  (13),
    .MTU                (MTU),
    .REPORT_STRM_ERRS   (1)
  ) ep3_i (
    .rfnoc_chdr_clk     (rfnoc_chdr_clk),
    .rfnoc_chdr_rst     (rfnoc_chdr_rst),
    .rfnoc_ctrl_clk     (rfnoc_ctrl_clk),
    .rfnoc_ctrl_rst     (rfnoc_ctrl_rst),
    .device_id          (device_id),
    .s_axis_chdr_tdata  (xb_to_ep3_tdata),
    .s_axis_chdr_tlast  (xb_to_ep3_tlast),
    .s_axis_chdr_tvalid (xb_to_ep3_tvalid),
    .s_axis_chdr_tready (xb_to_ep3_tready),
    .m_axis_chdr_tdata  (ep3_to_xb_tdata),
    .m_axis_chdr_tlast  (ep3_to_xb_tlast),
    .m_axis_chdr_tvalid (ep3_to_xb_tvalid),
    .m_axis_chdr_tready (ep3_to_xb_tready),
    .s_axis_data_tdata  ({s_ep3_in0_tdata}),
    .s_axis_data_tlast  ({s_ep3_in0_tlast}),
    .s_axis_data_tvalid ({s_ep3_in0_tvalid}),
    .s_axis_data_tready ({s_ep3_in0_tready}),
    .m_axis_data_tdata  ({m_ep3_out0_tdata}),
    .m_axis_data_tlast  ({m_ep3_out0_tlast}),
    .m_axis_data_tvalid ({m_ep3_out0_tvalid}),
    .m_axis_data_tready ({m_ep3_out0_tready}),
    .s_axis_ctrl_tdata  (s_ep3_ctrl_tdata),
    .s_axis_ctrl_tlast  (s_ep3_ctrl_tlast),
    .s_axis_ctrl_tvalid (s_ep3_ctrl_tvalid),
    .s_axis_ctrl_tready (s_ep3_ctrl_tready),
    .m_axis_ctrl_tdata  (m_ep3_ctrl_tdata),
    .m_axis_ctrl_tlast  (m_ep3_ctrl_tlast),
    .m_axis_ctrl_tvalid (m_ep3_ctrl_tvalid),
    .m_axis_ctrl_tready (m_ep3_ctrl_tready),
    .strm_seq_err_stb   (),
    .strm_data_err_stb  (),
    .strm_route_err_stb (),
    .signal_data_err    (1'b0)
  );


  //---------------------------------------------------------------------------
  // Control Crossbar
  //---------------------------------------------------------------------------

  wire [31:0] m_core_ctrl_tdata,  s_core_ctrl_tdata;
  wire        m_core_ctrl_tlast,  s_core_ctrl_tlast;
  wire        m_core_ctrl_tvalid, s_core_ctrl_tvalid;
  wire        m_core_ctrl_tready, s_core_ctrl_tready;
  wire [31:0] m_radio0_ctrl_tdata,  s_radio0_ctrl_tdata;
  wire        m_radio0_ctrl_tlast,  s_radio0_ctrl_tlast;
  wire        m_radio0_ctrl_tvalid, s_radio0_ctrl_tvalid;
  wire        m_radio0_ctrl_tready, s_radio0_ctrl_tready;
  wire [31:0] m_radio1_ctrl_tdata,  s_radio1_ctrl_tdata;
  wire        m_radio1_ctrl_tlast,  s_radio1_ctrl_tlast;
  wire        m_radio1_ctrl_tvalid, s_radio1_ctrl_tvalid;
  wire        m_radio1_ctrl_tready, s_radio1_ctrl_tready;

  axis_ctrl_crossbar_nxn #(
    .WIDTH            (32),
    .NPORTS           (4),
    .TOPOLOGY         ("TORUS"),
    .INGRESS_BUFF_SIZE(5),
    .ROUTER_BUFF_SIZE (5),
    .ROUTING_ALLOC    ("WORMHOLE"),
    .SWITCH_ALLOC     ("PRIO")
  ) ctrl_xb_i (
    .clk              (rfnoc_ctrl_clk),
    .reset            (rfnoc_ctrl_rst),
    .s_axis_tdata     ({m_radio1_ctrl_tdata , m_radio0_ctrl_tdata , m_ep0_ctrl_tdata , m_core_ctrl_tdata }),
    .s_axis_tvalid    ({m_radio1_ctrl_tvalid, m_radio0_ctrl_tvalid, m_ep0_ctrl_tvalid, m_core_ctrl_tvalid}),
    .s_axis_tlast     ({m_radio1_ctrl_tlast , m_radio0_ctrl_tlast , m_ep0_ctrl_tlast , m_core_ctrl_tlast }),
    .s_axis_tready    ({m_radio1_ctrl_tready, m_radio0_ctrl_tready, m_ep0_ctrl_tready, m_core_ctrl_tready}),
    .m_axis_tdata     ({s_radio1_ctrl_tdata , s_radio0_ctrl_tdata , s_ep0_ctrl_tdata , s_core_ctrl_tdata }),
    .m_axis_tvalid    ({s_radio1_ctrl_tvalid, s_radio0_ctrl_tvalid, s_ep0_ctrl_tvalid, s_core_ctrl_tvalid}),
    .m_axis_tlast     ({s_radio1_ctrl_tlast , s_radio0_ctrl_tlast , s_ep0_ctrl_tlast , s_core_ctrl_tlast }),
    .m_axis_tready    ({s_radio1_ctrl_tready, s_radio0_ctrl_tready, s_ep0_ctrl_tready, s_core_ctrl_tready}),
    .deadlock_detected()
  );


  //---------------------------------------------------------------------------
  // RFNoC Core Kernel
  //---------------------------------------------------------------------------

  wire [(512*2)-1:0] rfnoc_core_config, rfnoc_core_status;

  rfnoc_core_kernel #(
    .PROTOVER            (PROTOVER),
    .DEVICE_TYPE         (16'hA400),
    .DEVICE_FAMILY       ("ULTRASCALE"),
    .SAFE_START_CLKS     (0),
    .NUM_BLOCKS          (2),
    .NUM_STREAM_ENDPOINTS(4),
    .NUM_ENDPOINTS_CTRL  (1),
    .NUM_TRANSPORTS      (6),
    .NUM_EDGES           (8),
    .CHDR_XBAR_PRESENT   (1),
    .EDGE_TBL_FILE       (EDGE_TBL_FILE)
  ) core_kernel_i (
    .chdr_aclk          (chdr_aclk),
    .chdr_aclk_locked   (1'b1),
    .ctrl_aclk          (ctrl_aclk),
    .ctrl_aclk_locked   (1'b1),
    .core_arst          (core_arst),
    .core_chdr_clk      (rfnoc_chdr_clk),
    .core_chdr_rst      (rfnoc_chdr_rst),
    .core_ctrl_clk      (rfnoc_ctrl_clk),
    .core_ctrl_rst      (rfnoc_ctrl_rst),
    .s_axis_ctrl_tdata  (s_core_ctrl_tdata),
    .s_axis_ctrl_tlast  (s_core_ctrl_tlast),
    .s_axis_ctrl_tvalid (s_core_ctrl_tvalid),
    .s_axis_ctrl_tready (s_core_ctrl_tready),
    .m_axis_ctrl_tdata  (m_core_ctrl_tdata),
    .m_axis_ctrl_tlast  (m_core_ctrl_tlast),
    .m_axis_ctrl_tvalid (m_core_ctrl_tvalid),
    .m_axis_ctrl_tready (m_core_ctrl_tready),
    .device_id          (device_id),
    .rfnoc_core_config  (rfnoc_core_config),
    .rfnoc_core_status  (rfnoc_core_status)
  );


  //---------------------------------------------------------------------------
  // Blocks
  //---------------------------------------------------------------------------

  //-----------------------------------
  // radio0
  //-----------------------------------

  wire              radio0_radio_clk;
  wire [CHDR_W-1:0] s_radio0_in_1_tdata , s_radio0_in_0_tdata ;
  wire              s_radio0_in_1_tlast , s_radio0_in_0_tlast ;
  wire              s_radio0_in_1_tvalid, s_radio0_in_0_tvalid;
  wire              s_radio0_in_1_tready, s_radio0_in_0_tready;
  wire [CHDR_W-1:0] m_radio0_out_1_tdata , m_radio0_out_0_tdata ;
  wire              m_radio0_out_1_tlast , m_radio0_out_0_tlast ;
  wire              m_radio0_out_1_tvalid, m_radio0_out_0_tvalid;
  wire              m_radio0_out_1_tready, m_radio0_out_0_tready;

  // ctrlport
  wire [   0:0] radio0_m_ctrlport_req_wr;
  wire [   0:0] radio0_m_ctrlport_req_rd;
  wire [  19:0] radio0_m_ctrlport_req_addr;
  wire [  31:0] radio0_m_ctrlport_req_data;
  wire [   3:0] radio0_m_ctrlport_req_byte_en;
  wire [   0:0] radio0_m_ctrlport_req_has_time;
  wire [  63:0] radio0_m_ctrlport_req_time;
  wire [   0:0] radio0_m_ctrlport_resp_ack;
  wire [   1:0] radio0_m_ctrlport_resp_status;
  wire [  31:0] radio0_m_ctrlport_resp_data;
  // time
  wire [  63:0] radio0_radio_time;
  // radio
  wire [ 255:0] radio0_radio_rx_data;
  wire [   3:0] radio0_radio_rx_stb;
  wire [   1:0] radio0_radio_rx_running;
  wire [ 255:0] radio0_radio_tx_data;
  wire [   3:0] radio0_radio_tx_stb;
  wire [   1:0] radio0_radio_tx_running;

  rfnoc_block_radio #(
    .THIS_PORTID         (2),
    .CHDR_W              (CHDR_W),
    .NUM_PORTS           (2),
    .NIPC                (RADIO_NIPC),
    .ITEM_W              (32),
    .MTU                 (MTU)
  ) b_radio0_0 (
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .radio_clk           (radio0_radio_clk),
    .rfnoc_core_config   (rfnoc_core_config[512*1-1:512*0]),
    .rfnoc_core_status   (rfnoc_core_status[512*1-1:512*0]),
    .m_ctrlport_req_wr   (radio0_m_ctrlport_req_wr),
    .m_ctrlport_req_rd   (radio0_m_ctrlport_req_rd),
    .m_ctrlport_req_addr (radio0_m_ctrlport_req_addr),
    .m_ctrlport_req_data (radio0_m_ctrlport_req_data),
    .m_ctrlport_req_byte_en(radio0_m_ctrlport_req_byte_en),
    .m_ctrlport_req_has_time(radio0_m_ctrlport_req_has_time),
    .m_ctrlport_req_time (radio0_m_ctrlport_req_time),
    .m_ctrlport_resp_ack (radio0_m_ctrlport_resp_ack),
    .m_ctrlport_resp_status(radio0_m_ctrlport_resp_status),
    .m_ctrlport_resp_data(radio0_m_ctrlport_resp_data),
    .radio_time          (radio0_radio_time),
    .radio_rx_data       (radio0_radio_rx_data),
    .radio_rx_stb        (radio0_radio_rx_stb),
    .radio_rx_running    (radio0_radio_rx_running),
    .radio_tx_data       (radio0_radio_tx_data),
    .radio_tx_stb        (radio0_radio_tx_stb),
    .radio_tx_running    (radio0_radio_tx_running),
    .s_rfnoc_chdr_tdata  ({s_radio0_in_1_tdata , s_radio0_in_0_tdata }),
    .s_rfnoc_chdr_tlast  ({s_radio0_in_1_tlast , s_radio0_in_0_tlast }),
    .s_rfnoc_chdr_tvalid ({s_radio0_in_1_tvalid, s_radio0_in_0_tvalid}),
    .s_rfnoc_chdr_tready ({s_radio0_in_1_tready, s_radio0_in_0_tready}),
    .m_rfnoc_chdr_tdata  ({m_radio0_out_1_tdata , m_radio0_out_0_tdata }),
    .m_rfnoc_chdr_tlast  ({m_radio0_out_1_tlast , m_radio0_out_0_tlast }),
    .m_rfnoc_chdr_tvalid ({m_radio0_out_1_tvalid, m_radio0_out_0_tvalid}),
    .m_rfnoc_chdr_tready ({m_radio0_out_1_tready, m_radio0_out_0_tready}),
    .s_rfnoc_ctrl_tdata  (s_radio0_ctrl_tdata),
    .s_rfnoc_ctrl_tlast  (s_radio0_ctrl_tlast),
    .s_rfnoc_ctrl_tvalid (s_radio0_ctrl_tvalid),
    .s_rfnoc_ctrl_tready (s_radio0_ctrl_tready),
    .m_rfnoc_ctrl_tdata  (m_radio0_ctrl_tdata),
    .m_rfnoc_ctrl_tlast  (m_radio0_ctrl_tlast),
    .m_rfnoc_ctrl_tvalid (m_radio0_ctrl_tvalid),
    .m_rfnoc_ctrl_tready (m_radio0_ctrl_tready)
  );

  //-----------------------------------
  // radio1
  //-----------------------------------

  wire              radio1_radio_clk;
  wire [CHDR_W-1:0] s_radio1_in_1_tdata , s_radio1_in_0_tdata ;
  wire              s_radio1_in_1_tlast , s_radio1_in_0_tlast ;
  wire              s_radio1_in_1_tvalid, s_radio1_in_0_tvalid;
  wire              s_radio1_in_1_tready, s_radio1_in_0_tready;
  wire [CHDR_W-1:0] m_radio1_out_1_tdata , m_radio1_out_0_tdata ;
  wire              m_radio1_out_1_tlast , m_radio1_out_0_tlast ;
  wire              m_radio1_out_1_tvalid, m_radio1_out_0_tvalid;
  wire              m_radio1_out_1_tready, m_radio1_out_0_tready;

  // ctrlport
  wire [   0:0] radio1_m_ctrlport_req_wr;
  wire [   0:0] radio1_m_ctrlport_req_rd;
  wire [  19:0] radio1_m_ctrlport_req_addr;
  wire [  31:0] radio1_m_ctrlport_req_data;
  wire [   3:0] radio1_m_ctrlport_req_byte_en;
  wire [   0:0] radio1_m_ctrlport_req_has_time;
  wire [  63:0] radio1_m_ctrlport_req_time;
  wire [   0:0] radio1_m_ctrlport_resp_ack;
  wire [   1:0] radio1_m_ctrlport_resp_status;
  wire [  31:0] radio1_m_ctrlport_resp_data;
  // time
  wire [  63:0] radio1_radio_time;
  // radio
  wire [ 255:0] radio1_radio_rx_data;
  wire [   3:0] radio1_radio_rx_stb;
  wire [   1:0] radio1_radio_rx_running;
  wire [ 255:0] radio1_radio_tx_data;
  wire [   3:0] radio1_radio_tx_stb;
  wire [   1:0] radio1_radio_tx_running;

  rfnoc_block_radio #(
    .THIS_PORTID         (3),
    .CHDR_W              (CHDR_W),
    .NUM_PORTS           (2),
    .NIPC                (RADIO_NIPC),
    .ITEM_W              (32),
    .MTU                 (MTU)
  ) b_radio1_1 (
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .radio_clk           (radio1_radio_clk),
    .rfnoc_core_config   (rfnoc_core_config[512*2-1:512*1]),
    .rfnoc_core_status   (rfnoc_core_status[512*2-1:512*1]),
    .m_ctrlport_req_wr   (radio1_m_ctrlport_req_wr),
    .m_ctrlport_req_rd   (radio1_m_ctrlport_req_rd),
    .m_ctrlport_req_addr (radio1_m_ctrlport_req_addr),
    .m_ctrlport_req_data (radio1_m_ctrlport_req_data),
    .m_ctrlport_req_byte_en(radio1_m_ctrlport_req_byte_en),
    .m_ctrlport_req_has_time(radio1_m_ctrlport_req_has_time),
    .m_ctrlport_req_time (radio1_m_ctrlport_req_time),
    .m_ctrlport_resp_ack (radio1_m_ctrlport_resp_ack),
    .m_ctrlport_resp_status(radio1_m_ctrlport_resp_status),
    .m_ctrlport_resp_data(radio1_m_ctrlport_resp_data),
    .radio_time          (radio1_radio_time),
    .radio_rx_data       (radio1_radio_rx_data),
    .radio_rx_stb        (radio1_radio_rx_stb),
    .radio_rx_running    (radio1_radio_rx_running),
    .radio_tx_data       (radio1_radio_tx_data),
    .radio_tx_stb        (radio1_radio_tx_stb),
    .radio_tx_running    (radio1_radio_tx_running),
    .s_rfnoc_chdr_tdata  ({s_radio1_in_1_tdata , s_radio1_in_0_tdata }),
    .s_rfnoc_chdr_tlast  ({s_radio1_in_1_tlast , s_radio1_in_0_tlast }),
    .s_rfnoc_chdr_tvalid ({s_radio1_in_1_tvalid, s_radio1_in_0_tvalid}),
    .s_rfnoc_chdr_tready ({s_radio1_in_1_tready, s_radio1_in_0_tready}),
    .m_rfnoc_chdr_tdata  ({m_radio1_out_1_tdata , m_radio1_out_0_tdata }),
    .m_rfnoc_chdr_tlast  ({m_radio1_out_1_tlast , m_radio1_out_0_tlast }),
    .m_rfnoc_chdr_tvalid ({m_radio1_out_1_tvalid, m_radio1_out_0_tvalid}),
    .m_rfnoc_chdr_tready ({m_radio1_out_1_tready, m_radio1_out_0_tready}),
    .s_rfnoc_ctrl_tdata  (s_radio1_ctrl_tdata),
    .s_rfnoc_ctrl_tlast  (s_radio1_ctrl_tlast),
    .s_rfnoc_ctrl_tvalid (s_radio1_ctrl_tvalid),
    .s_rfnoc_ctrl_tready (s_radio1_ctrl_tready),
    .m_rfnoc_ctrl_tdata  (m_radio1_ctrl_tdata),
    .m_rfnoc_ctrl_tlast  (m_radio1_ctrl_tlast),
    .m_rfnoc_ctrl_tvalid (m_radio1_ctrl_tvalid),
    .m_rfnoc_ctrl_tready (m_radio1_ctrl_tready)
  );

  //---------------------------------------------------------------------------
  // Static Router
  //---------------------------------------------------------------------------

  assign s_radio0_in_0_tdata = m_ep0_out0_tdata;
  assign s_radio0_in_0_tlast = m_ep0_out0_tlast;
  assign s_radio0_in_0_tvalid = m_ep0_out0_tvalid;
  assign m_ep0_out0_tready = s_radio0_in_0_tready;

  assign s_ep0_in0_tdata = m_radio0_out_0_tdata;
  assign s_ep0_in0_tlast = m_radio0_out_0_tlast;
  assign s_ep0_in0_tvalid = m_radio0_out_0_tvalid;
  assign m_radio0_out_0_tready = s_ep0_in0_tready;

  assign s_radio0_in_1_tdata = m_ep1_out0_tdata;
  assign s_radio0_in_1_tlast = m_ep1_out0_tlast;
  assign s_radio0_in_1_tvalid = m_ep1_out0_tvalid;
  assign m_ep1_out0_tready = s_radio0_in_1_tready;

  assign s_ep1_in0_tdata = m_radio0_out_1_tdata;
  assign s_ep1_in0_tlast = m_radio0_out_1_tlast;
  assign s_ep1_in0_tvalid = m_radio0_out_1_tvalid;
  assign m_radio0_out_1_tready = s_ep1_in0_tready;

  assign s_radio1_in_0_tdata = m_ep2_out0_tdata;
  assign s_radio1_in_0_tlast = m_ep2_out0_tlast;
  assign s_radio1_in_0_tvalid = m_ep2_out0_tvalid;
  assign m_ep2_out0_tready = s_radio1_in_0_tready;

  assign s_ep2_in0_tdata = m_radio1_out_0_tdata;
  assign s_ep2_in0_tlast = m_radio1_out_0_tlast;
  assign s_ep2_in0_tvalid = m_radio1_out_0_tvalid;
  assign m_radio1_out_0_tready = s_ep2_in0_tready;

  assign s_radio1_in_1_tdata = m_ep3_out0_tdata;
  assign s_radio1_in_1_tlast = m_ep3_out0_tlast;
  assign s_radio1_in_1_tvalid = m_ep3_out0_tvalid;
  assign m_ep3_out0_tready = s_radio1_in_1_tready;

  assign s_ep3_in0_tdata = m_radio1_out_1_tdata;
  assign s_ep3_in0_tlast = m_radio1_out_1_tlast;
  assign s_ep3_in0_tvalid = m_radio1_out_1_tvalid;
  assign m_radio1_out_1_tready = s_ep3_in0_tready;


  //---------------------------------------------------------------------------
  // Unused Ports
  //---------------------------------------------------------------------------



  //---------------------------------------------------------------------------
  // Clock Domains
  //---------------------------------------------------------------------------

  assign radio0_radio_clk = radio_clk;
  assign radio1_radio_clk = radio_clk;


  //---------------------------------------------------------------------------
  // IO Port Connection
  //---------------------------------------------------------------------------

  // Master/Slave Connections:
  assign m_ctrlport_radio0_req_wr = radio0_m_ctrlport_req_wr;
  assign m_ctrlport_radio0_req_rd = radio0_m_ctrlport_req_rd;
  assign m_ctrlport_radio0_req_addr = radio0_m_ctrlport_req_addr;
  assign m_ctrlport_radio0_req_data = radio0_m_ctrlport_req_data;
  assign m_ctrlport_radio0_req_byte_en = radio0_m_ctrlport_req_byte_en;
  assign m_ctrlport_radio0_req_has_time = radio0_m_ctrlport_req_has_time;
  assign m_ctrlport_radio0_req_time = radio0_m_ctrlport_req_time;
  assign radio0_m_ctrlport_resp_ack = m_ctrlport_radio0_resp_ack;
  assign radio0_m_ctrlport_resp_status = m_ctrlport_radio0_resp_status;
  assign radio0_m_ctrlport_resp_data = m_ctrlport_radio0_resp_data;

  assign m_ctrlport_radio1_req_wr = radio1_m_ctrlport_req_wr;
  assign m_ctrlport_radio1_req_rd = radio1_m_ctrlport_req_rd;
  assign m_ctrlport_radio1_req_addr = radio1_m_ctrlport_req_addr;
  assign m_ctrlport_radio1_req_data = radio1_m_ctrlport_req_data;
  assign m_ctrlport_radio1_req_byte_en = radio1_m_ctrlport_req_byte_en;
  assign m_ctrlport_radio1_req_has_time = radio1_m_ctrlport_req_has_time;
  assign m_ctrlport_radio1_req_time = radio1_m_ctrlport_req_time;
  assign radio1_m_ctrlport_resp_ack = m_ctrlport_radio1_resp_ack;
  assign radio1_m_ctrlport_resp_status = m_ctrlport_radio1_resp_status;
  assign radio1_m_ctrlport_resp_data = m_ctrlport_radio1_resp_data;

  assign radio0_radio_rx_data = radio_rx_data_radio0;
  assign radio0_radio_rx_stb = radio_rx_stb_radio0;
  assign radio_rx_running_radio0 = radio0_radio_rx_running;
  assign radio_tx_data_radio0 = radio0_radio_tx_data;
  assign radio0_radio_tx_stb = radio_tx_stb_radio0;
  assign radio_tx_running_radio0 = radio0_radio_tx_running;

  assign radio1_radio_rx_data = radio_rx_data_radio1;
  assign radio1_radio_rx_stb = radio_rx_stb_radio1;
  assign radio_rx_running_radio1 = radio1_radio_rx_running;
  assign radio_tx_data_radio1 = radio1_radio_tx_data;
  assign radio1_radio_tx_stb = radio_tx_stb_radio1;
  assign radio_tx_running_radio1 = radio1_radio_tx_running;

  // Broadcaster/Listener Connections:
  assign radio0_radio_time = radio_time;

  assign radio1_radio_time = radio_time;

endmodule


`default_nettype wire

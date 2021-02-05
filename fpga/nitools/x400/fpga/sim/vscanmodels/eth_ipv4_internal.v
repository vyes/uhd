///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: eth_ipv4_internal
//
// Description:
//
//   Port model for VSMake to use eth_ipv4_internal
//
///////////////////////////////////////////////////////////////////////////////

module eth_ipv4_internal #(
  parameter        CHDR_W         = 64,
  parameter        BYTE_MTU       = 10,
  parameter        DWIDTH         = 32,
  parameter        AWIDTH         = 14,
  parameter [ 7:0] PORTNUM        = 0,
  parameter [15:0] RFNOC_PROTOVER = {8'd1, 8'd0}
) (
  input wire bus_clk,
  input wire bus_rst,

  // AXI-Lite
  input  wire              s_axi_aclk,
  input  wire              s_axi_aresetn,
  input  wire [AWIDTH-1:0] s_axi_awaddr,
  input  wire              s_axi_awvalid,
  output wire              s_axi_awready,

  input  wire [  DWIDTH-1:0] s_axi_wdata,
  input  wire [DWIDTH/8-1:0] s_axi_wstrb,
  input  wire                s_axi_wvalid,
  output wire                s_axi_wready,

  output wire [1:0] s_axi_bresp,
  output wire       s_axi_bvalid,
  input  wire       s_axi_bready,

  input  wire [AWIDTH-1:0] s_axi_araddr,
  input  wire              s_axi_arvalid,
  output wire              s_axi_arready,

  output wire [DWIDTH-1:0] s_axi_rdata,
  output wire [       1:0] s_axi_rresp,
  output wire              s_axi_rvalid,
  input  wire              s_axi_rready,

  // Host DMA Interface
  output wire [  63:0] e2h_tdata,
  output wire [   7:0] e2h_tkeep,
  output wire          e2h_tlast,
  output wire          e2h_tvalid,
  input  wire          e2h_tready,

  input  wire [  63:0] h2e_tdata,
  input  wire [   7:0] h2e_tkeep,
  input  wire          h2e_tlast,
  input  wire          h2e_tvalid,
  output wire          h2e_tready,

  // RFNoC Interface
  output reg  [CHDR_W-1:0] e2v_tdata,
  output reg               e2v_tlast,
  output reg               e2v_tvalid,
  input  wire              e2v_tready,

  input  wire [CHDR_W-1:0] v2e_tdata,
  input  wire              v2e_tlast,
  input  wire              v2e_tvalid,
  output reg               v2e_tready,

  // Misc
  input  wire [15:0] device_id
);

 //vhook_nowarn *

endmodule

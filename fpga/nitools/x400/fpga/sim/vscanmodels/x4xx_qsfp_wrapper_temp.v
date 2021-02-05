///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: x4xx_qsfp_wrapper_temp
//
// Description:
//
//   temporary tranlation layer while waiting for VSMAKE to support SV
//
///////////////////////////////////////////////////////////////////////////////

`include "./x4xx_mgt_types.vh"

module x4xx_qsfp_wrapper_temp #(
  parameter        PROTOCOL0     = `MGT_Disabled,
  parameter        PROTOCOL1     = `MGT_Disabled,
  parameter        PROTOCOL2     = `MGT_Disabled,
  parameter        PROTOCOL3     = `MGT_Disabled,

  parameter        CPU_W        = 64,
  parameter        CHDR_W       = 64,
  parameter        BYTE_MTU     = $clog2(8*1024),
  parameter [7:0]  PORTNUM      = 8'd0
)(
  // Resets
  input  areset,
  input  bus_rst,
  input  clk40_rst,

  // Clocks
  input  refclk_p,
  input  refclk_n,
  input  clk100,
  input  clk40,
  input  bus_clk,

  // AXI-Lite
  input   [39:0] s_axi_awaddr,
  input          s_axi_awvalid,
  output         s_axi_awready,
  input   [31:0] s_axi_wdata,
  input   [3:0]  s_axi_wstrb,
  input          s_axi_wvalid,
  output         s_axi_wready,
  output  [1:0]  s_axi_bresp,
  output         s_axi_bvalid,
  input          s_axi_bready,
  input   [39:0] s_axi_araddr,
  input          s_axi_arvalid,
  output         s_axi_arready,
  output  [31:0] s_axi_rdata,
  output  [1:0]  s_axi_rresp,
  output         s_axi_rvalid,
  input          s_axi_rready,

  // MGT high-speed IO
  output  [3:0] tx_p,
  output  [3:0] tx_n,
  input   [3:0] rx_p,
  input   [3:0] rx_n,

  // CHDR router interface
  output   [4*CHDR_W-1:0]  e2v_tdata,
  output   [3:0]           e2v_tlast,
  output   [3:0]           e2v_tvalid,
  input    [3:0]           e2v_tready,

  input    [4*CHDR_W-1:0]  v2e_tdata,
  input    [3:0]           v2e_tlast,
  input    [3:0]           v2e_tvalid,
  output   [3:0]           v2e_tready,

  // ETH DMA AXI To CPU
  output  [48:0]  axi_hp_araddr,
  output  [1:0]   axi_hp_arburst,
  output  [3:0]   axi_hp_arcache,
  output  [7:0]   axi_hp_arlen,
  output  [0:0]   axi_hp_arlock,
  output  [2:0]   axi_hp_arprot,
  output  [3:0]   axi_hp_arqos,
  input           axi_hp_arready,
  output  [2:0]   axi_hp_arsize,
  output          axi_hp_arvalid,
  output  [48:0]  axi_hp_awaddr,
  output  [1:0]   axi_hp_awburst,
  output  [3:0]   axi_hp_awcache,
  output  [7:0]   axi_hp_awlen,
  output  [0:0]   axi_hp_awlock,
  output  [2:0]   axi_hp_awprot,
  output  [3:0]   axi_hp_awqos,
  input           axi_hp_awready,
  output  [2:0]   axi_hp_awsize,
  output          axi_hp_awvalid,
  output          axi_hp_bready,
  input   [1:0]   axi_hp_bresp,
  input           axi_hp_bvalid,
  input   [127:0] axi_hp_rdata,
  input           axi_hp_rlast,
  output          axi_hp_rready,
  input   [1:0]   axi_hp_rresp,
  input           axi_hp_rvalid,
  output  [127:0] axi_hp_wdata,
  output          axi_hp_wlast,
  input           axi_hp_wready,
  output  [15:0]  axi_hp_wstrb,
  output          axi_hp_wvalid,

  // ETH DMA IRQs
  output  [3:0] eth_rx_irq,
  output  [3:0] eth_tx_irq,

  // MISC
  output         rxrecclkout,
  input   [15:0] device_id,

  output  [31:0] port_info_0,
  output  [31:0] port_info_1,
  output  [31:0] port_info_2,
  output  [31:0] port_info_3,

  output  [3:0] link_up,
  output  [3:0] activity
 );

 //vhook_nowarn *

endmodule

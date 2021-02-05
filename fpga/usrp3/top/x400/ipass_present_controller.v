//
// Copyright 2020 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: ipass_present_controller
//
// Description:
//   Translate the IPass present signals on FPGA to control port requests in
//   order to transfer them to the MB CPLD, which needs it for PCIe reset
//   generation.

module ipass_present_controller (
  // common Controlport signals
  input wire ctrlport_clk,
  input wire ctrlport_rst,

  // Controlport request
  output  reg        m_ctrlport_req_wr,
  output wire        m_ctrlport_req_rd,
  output wire [19:0] m_ctrlport_req_addr,
  output wire [31:0] m_ctrlport_req_data,
  output wire [ 3:0] m_ctrlport_req_byte_en,

  // Controlport response
  input  wire        m_ctrlport_resp_ack,
  input  wire [ 1:0] m_ctrlport_resp_status,
  input  wire [31:0] m_ctrlport_resp_data,

  // configuration
  input  wire        enable,

  // asynchronous ipass present signals
  input  wire [ 1:0] ipass_present_n
);

`include "regmap/pl_cpld_regmap_utils.vh"
`include "cpld/regmap/mb_cpld_pl_regmap_utils.vh"
`include "cpld/regmap/pl_cpld_base_regmap_utils.vh"
`include "../../lib/rfnoc/core/ctrlport.vh"

//vhook_nowarn m_ctrlport_resp_data

//----------------------------------------------------------
// Transfer iPass signals to local clock domain
//----------------------------------------------------------
wire [1:0] ipass_present;
wire [1:0] ipass_present_lcl;

assign ipass_present = ~ipass_present_n;

//vhook_e synchronizer
//vhook_a WIDTH 2
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk ctrlport_clk
//vhook_a rst ctrlport_rst
//vhook_a in ipass_present
//vhook_a out ipass_present_lcl
synchronizer
  # (
    .WIDTH             (2),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (0),   //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  synchronizerx (
    .clk  (ctrlport_clk),        //in  wire
    .rst  (ctrlport_rst),        //in  wire
    .in   (ipass_present),       //in  wire[(WIDTH-1):0]
    .out  (ipass_present_lcl));  //out wire[(WIDTH-1):0]

//----------------------------------------------------------
// Logic to wait for response after trigging request
//----------------------------------------------------------
reg transfer_in_progress  = 1'b0;
reg error_occurred        = 1'b0;
reg enable_delayed        = 1'b0;
reg [1:0] ipass_present_cached = 2'b0;

// rising_edge detection on enable signal
wire activated;
assign activated = enable & ~enable_delayed;

always @(posedge ctrlport_clk) begin
  if (ctrlport_rst) begin
    m_ctrlport_req_wr         <= 1'b0;
    transfer_in_progress      <= 1'b0;
    enable_delayed            <= 1'b0;
    error_occurred            <= 1'b0;
    ipass_present_cached <= 2'b0;
  end else begin
    // default assignment
    m_ctrlport_req_wr <= 1'b0;
    enable_delayed    <= enable;

    // issue new request on change if no request is pending
    if (((ipass_present_lcl != ipass_present_cached) || error_occurred || activated)
      && ~transfer_in_progress && enable) begin
      transfer_in_progress      <= 1'b1;
      m_ctrlport_req_wr         <= 1'b1;
      ipass_present_cached <= ipass_present_lcl;
    end

    // reset pending request
    if (m_ctrlport_resp_ack) begin
      transfer_in_progress <= 1'b0;
      error_occurred       <= m_ctrlport_resp_status != CTRL_STS_OKAY;
    end
  end
end

//----------------------------------------------------------
// Static controlport assignments
//----------------------------------------------------------
assign m_ctrlport_req_rd      = 1'b0;
assign m_ctrlport_req_byte_en = 4'b1111;
assign m_ctrlport_req_addr    = MB_CPLD + PL_REGISTERS + CABLE_PRESENT_REG;
assign m_ctrlport_req_data    = 32'b0 |
                                (ipass_present_cached[0] << IPASS0_CABLE_PRESENT) |
                                (ipass_present_cached[1] << IPASS1_CABLE_PRESENT);

endmodule
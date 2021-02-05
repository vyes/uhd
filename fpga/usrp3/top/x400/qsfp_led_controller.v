//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: qsfp_led_controller
// Description:
// Translate the CLIP active and link LED signals on FPGA to control port
// requests in order to transfer them to the CPLD, which drives the LEDs

module qsfp_led_controller #(
  parameter LED_REGISTER_ADDRESS = 0 // address of LED register within CPLD
)(
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

  // QSFP port LED signals
  input  wire [ 3:0] qsfp0_led_active,
  input  wire [ 3:0] qsfp0_led_link,
  input  wire [ 3:0] qsfp1_led_active,
  input  wire [ 3:0] qsfp1_led_link
);

//vhook_nowarn m_ctrlport_resp_status
//vhook_nowarn m_ctrlport_resp_data

//----------------------------------------------------------
// Transfer LED signals to local clock domain
//----------------------------------------------------------
wire [15:0] led_combined;
//vhook_e synchronizer
//vhook_a WIDTH 16
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk ctrlport_clk
//vhook_a rst ctrlport_rst
//vhook_a in \{qsfp1_led_active, qsfp1_led_link, qsfp0_led_active, qsfp0_led_link\}
//vhook_a out led_combined
synchronizer
  # (
    .WIDTH             (16),  //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (0),   //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  synchronizerx (
    .clk  (ctrlport_clk),                                                          //in  wire
    .rst  (ctrlport_rst),                                                          //in  wire
    .in   ({qsfp1_led_active, qsfp1_led_link, qsfp0_led_active, qsfp0_led_link}),  //in  wire[(WIDTH-1):0]
    .out  (led_combined));                                                         //out wire[(WIDTH-1):0]

//----------------------------------------------------------
// Logic to wait for response after trigging request
//----------------------------------------------------------
reg transfer_in_progress;
reg [15:0] led_combined_delayed;

always @(posedge ctrlport_clk) begin
  if (ctrlport_rst) begin
    m_ctrlport_req_wr <= 1'b0;
    transfer_in_progress <= 1'b0;
    led_combined_delayed <= 16'b0;
  end else begin
    // default assignment
    m_ctrlport_req_wr <= 1'b0;

    // issue new request on change if no request is pending
    if (led_combined != led_combined_delayed && ~transfer_in_progress) begin
      transfer_in_progress <= 1'b1;
      m_ctrlport_req_wr <= 1'b1;
      led_combined_delayed <= led_combined;
    end

    // reset pending request
    if (m_ctrlport_resp_ack) begin
      transfer_in_progress <= 1'b0;
    end
  end
end

//----------------------------------------------------------
// Static controlport assignments
//----------------------------------------------------------
assign m_ctrlport_req_rd = 0;
assign m_ctrlport_req_byte_en = 4'b0011;
assign m_ctrlport_req_addr = LED_REGISTER_ADDRESS;
assign m_ctrlport_req_data = {16'b0, led_combined_delayed};

endmodule
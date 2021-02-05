//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: spi_slave_to_ctrlport_master
// Description:
// SPI slave to ContolPort master conversion in order to tunnel control port
// request through an SPI bus.
//
// The request format on SPI is defined as:
// Write request:
// 1'b1 = write, 15 bit address, 32 bit data (MOSI), 8 bit processing gap,
// 5 bit padding, 1 bit ack, 2 bit status
// Read request:
// 1'b0 = read, 15 bit address, 8 bit processing gap, 32 bit data (MISO),
// 5 bit padding, 1 bit ack, 2 bit status

module spi_slave_to_ctrlport_master#(
  parameter CLK_FREQUENCY = 50000000,
  parameter SPI_FREQUENCY = 10000000
)(
  //---------------------------------------------------------------
  // ControlPort master
  //---------------------------------------------------------------
  input wire ctrlport_clk,
  input wire ctrlport_rst,

  output wire        m_ctrlport_req_wr,
  output wire        m_ctrlport_req_rd,
  output wire [19:0] m_ctrlport_req_addr,
  output wire [31:0] m_ctrlport_req_data,

  input  wire        m_ctrlport_resp_ack,
  input  wire [ 1:0] m_ctrlport_resp_status,
  input  wire [31:0] m_ctrlport_resp_data,

  //---------------------------------------------------------------
  // SPI slave
  //---------------------------------------------------------------
  input  wire sclk,
  input  wire cs_n,
  input  wire mosi,
  output wire miso
 );

`include "../../../lib/rfnoc/core/ctrlport.vh"

//---------------------------------------------------------------
// SPI slave
//---------------------------------------------------------------
wire [7:0] data_in;
wire [7:0] data_out;
wire       data_in_valid;
wire       data_out_valid;
wire       data_in_required;
wire       spi_slave_active;

//vhook spi_slave spi_slave_async
//vhook_a clk ctrlport_clk
//vhook_a rst ctrlport_rst
//vhook_a active spi_slave_active
spi_slave
  # (
    .CLK_FREQUENCY  (CLK_FREQUENCY),   //integer:=50000000
    .SPI_FREQUENCY  (SPI_FREQUENCY))   //integer:=10000000
  spi_slave_async (
    .sclk              (sclk),               //in  wire
    .cs_n              (cs_n),               //in  wire
    .mosi              (mosi),               //in  wire
    .miso              (miso),               //out wire
    .clk               (ctrlport_clk),       //in  wire
    .rst               (ctrlport_rst),       //in  wire
    .data_in_required  (data_in_required),   //out wire
    .data_in_valid     (data_in_valid),      //in  wire
    .data_in           (data_in),            //in  wire[7:0]
    .data_out_valid    (data_out_valid),     //out wire
    .data_out          (data_out),           //out wire[7:0]
    .active            (spi_slave_active));  //out wire

//---------------------------------------------------------------
// Reset generation from SPI slave
//---------------------------------------------------------------
reg spi_slave_active_delayed = 1'b0;
always @(posedge ctrlport_clk) begin
  if (ctrlport_rst) begin
    spi_slave_active_delayed <= 1'b0;
  end
  else begin
    spi_slave_active_delayed <= spi_slave_active;
  end
end

// trigger reset on falling edge of active signal (rising edge of cs_n)
wire spi_slave_reset;
assign spi_slave_reset = spi_slave_active_delayed & (~spi_slave_active);

//---------------------------------------------------------------
// Transfer constants
//---------------------------------------------------------------
localparam NUM_BYTES_TRANSACTION = 8;
localparam NUM_BYTES_WRITE_REQUEST_PAYLOAD = 6;
localparam NUM_BYTES_READ_REQUEST_PAYLOAD = 2;
localparam MAX_BYTES_RESPONSE_PAYLOAD = 5;

//---------------------------------------------------------------
// Data receiver
//---------------------------------------------------------------
reg [3:0] num_bytes_received;
reg       request_received;
reg       write_request;
reg       provide_response;
reg [NUM_BYTES_WRITE_REQUEST_PAYLOAD*8-1:0] request_reg = {NUM_BYTES_WRITE_REQUEST_PAYLOAD*8 {1'b0}};

always @(posedge ctrlport_clk) begin
  if (ctrlport_rst || spi_slave_reset) begin
    num_bytes_received <= 4'b0;
    request_received <= 1'b0;
    write_request <= 1'b0;
    provide_response <= 1'b0;
  end
  else begin
    // counter number of received bytes
    if (data_out_valid) begin
      // increment counter
      num_bytes_received <= num_bytes_received + 1'b1;

      if (num_bytes_received == NUM_BYTES_TRANSACTION-1) begin
        num_bytes_received <= 4'b0;
      end
    end

    // check for read / write on first received byte's MSB
    if (data_out_valid && (num_bytes_received == 0)) begin
      write_request <= data_out[7];
    end

    // detect complete request
    request_received <= 1'b0;
    if (data_out_valid) begin
      if (write_request && (num_bytes_received == NUM_BYTES_WRITE_REQUEST_PAYLOAD-1)) begin
        request_received <= 1'b1;
        provide_response <= 1'b1;
      end else if (~write_request && (num_bytes_received == NUM_BYTES_READ_REQUEST_PAYLOAD-1)) begin
        request_received <= 1'b1;
        provide_response <= 1'b1;
      end
    end

    // detect end of response on last received byte
    if (num_bytes_received == NUM_BYTES_TRANSACTION-1) begin
      provide_response <= 1'b0;
    end

    // capture data into shift register
    if (data_out_valid) begin
      request_reg <= {request_reg[NUM_BYTES_WRITE_REQUEST_PAYLOAD*8-8-1:0], data_out};
    end
  end
end

// drive controlport
localparam SPI_TRANSFER_ADDRESS_WIDTH = 15;
assign m_ctrlport_req_wr   = request_received && write_request;
assign m_ctrlport_req_rd   = request_received && ~write_request;
assign m_ctrlport_req_data = request_reg[CTRLPORT_DATA_W-1:0];
assign m_ctrlport_req_addr = (write_request) ?
                             {5'b0, request_reg[CTRLPORT_DATA_W+:SPI_TRANSFER_ADDRESS_WIDTH]} :
                             {5'b0, request_reg[0+:SPI_TRANSFER_ADDRESS_WIDTH]};


//---------------------------------------------------------------
// Response handling
//---------------------------------------------------------------
reg  [MAX_BYTES_RESPONSE_PAYLOAD*8-1:0] response_reg;
reg  ready_for_response; // active during processing gap
wire write_response_byte;

always @(posedge ctrlport_clk) begin
  if (ctrlport_rst || spi_slave_reset) begin
    response_reg <= {8*MAX_BYTES_RESPONSE_PAYLOAD {1'b0}};
    ready_for_response <= 1'b0;
  end
  else begin
    // reset response on new request
    if (request_received) begin
      ready_for_response <= 1'b1;
      if (write_request) begin
        // just last byte -> padding, ack flag, CMDERR, padding (data length)
        response_reg <= {5'b0, 1'b1, CTRL_STS_CMDERR, {CTRLPORT_DATA_W{1'b0}}};
      end else begin
        // last 5 bytes -> data = 0, Padding, ack flag, CMDERR
        response_reg <= {{CTRLPORT_DATA_W{1'b0}}, 5'b0, 1'b1, CTRL_STS_CMDERR};
      end

    // capture response within processing gap, leave default response from above otherwise
    end else if (m_ctrlport_resp_ack && ready_for_response) begin
      if (write_request) begin
        response_reg <= {5'b0, m_ctrlport_resp_ack, m_ctrlport_resp_status, {CTRLPORT_DATA_W{1'b0}}};
      end else begin
        response_reg <= {m_ctrlport_resp_data, 5'b0, m_ctrlport_resp_ack, m_ctrlport_resp_status};
      end
    end

    // shift data after writing to slave
    if (write_response_byte) begin
      response_reg <= {response_reg[0+:(MAX_BYTES_RESPONSE_PAYLOAD-1)*8], 8'b0};
      ready_for_response <= 1'b0;
    end
  end
end

// response is written after request part has been transferred
assign write_response_byte = data_in_required && provide_response;

// assign SPI slave inputs
assign data_in = response_reg[(MAX_BYTES_RESPONSE_PAYLOAD-1)*8+:8];
assign data_in_valid = write_response_byte;

endmodule
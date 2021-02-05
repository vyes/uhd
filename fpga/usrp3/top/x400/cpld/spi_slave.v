//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: spi_slave
// Description:
// SPI slave for configuration CPOL = CPHA = 0.
// Transfers 8 bit = 1 byte MSB first. Parallel data has to be
// provided and consumed immediatelly when flags are asserted.
//
// Limitation: clk frequency <= 2*sclk frequency
//
// Data request from sclk domain is triggered towards the clk
// domain ahead of time. This is due to the clock domain
// crossing using the synchronizer and processing pipeline stages.
// The worst case propagation delay of the used synchronizer is
// 4 'clk' clock cycles:
// 1 clock cycle of signal propagation to synchronizer
//    (data_request_sclk assertion)
// 1 clock cycle to capture data with instability in first stage
// 1 clock cycle to stabilize first stage
// 1 clock cycle to capture data in second stage
//    (data_request_clk available in 'clk' domain)
// Once synchronized in 'clk' domain:
// There is one additional clock cycle to derive data_out_valid
// and data_in_required
// To ensure that transmit data is registered a 'clk' cycle ahead
// of the actual transmission we need 2 more 'clk' clock cycles.
// This ensures that transmit_word has changed and is stable for
// at least on 'clk' cycle before 'sclk' asserts again.
// Any additional time required externally to respond to the
// control port requests should be considered in this crossing as well
// This is a total of 7 clock cycles(+ctrlport response margin) @ clk domain.
// The minimum required time in sclk domain to issue the request
// is calculated based on the clock frequencies.

module spi_slave #(
  parameter CLK_FREQUENCY = 50000000,
  parameter SPI_FREQUENCY = 10000000
)(
  //---------------------------------------------------------------
  // SPI Interface
  //---------------------------------------------------------------
  input  wire sclk,
  input  wire cs_n,
  input  wire mosi,
  output wire miso,

  //---------------------------------------------------------------
  // Parallel Interface
  //---------------------------------------------------------------
  input  wire clk,
  input  wire rst,

  output reg  data_in_required,
  input  wire data_in_valid,
  input  wire [7:0] data_in,

  output reg  data_out_valid,
  output reg  [7:0] data_out,

  output wire active
);

//vhook_sigstart
  wire [0:0] data_request_clk;
  wire [0:0] reception_complete_clk;
//vhook_sigend

//---------------------------------------------------------------
// SPI Receiver @ sclk
//---------------------------------------------------------------
reg [7:0] receiver_reg;
reg [2:0] current_bit_index;
reg       reception_complete_sclk = 1'b0;
reg [7:0] received_word;

always @(posedge sclk or posedge cs_n) begin
  // reset logic on positive cs_n edge = slave idle
  if (cs_n) begin
    receiver_reg <= 8'b0;
  end
  // rising edge of sclk
  else begin
    // capture bits into shift register MSBs first
    receiver_reg <= {receiver_reg[6:0], mosi};
  end
end

// reset with cs_n might occur too early during clk sync
// reset half way through the reception
always @(posedge sclk) begin
  // complete word was received
  if (current_bit_index == 7) begin
    //vhook_nowarn id=Misc11 msg={reception_complete_sclk}
    reception_complete_sclk <= 1'b1;
    received_word <= {receiver_reg[6:0], mosi};

  // reset after half transaction
  end else if (current_bit_index == 3) begin
    reception_complete_sclk <= 1'b0;
  end
end

//---------------------------------------------------------------
// Handover of data sclk -> clk
//---------------------------------------------------------------
//vhook_e synchronizer data_sync_inst
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a rst 1'b0
//vhook_a in reception_complete_sclk
//vhook_a out reception_complete_clk
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  data_sync_inst (
    .clk  (clk),                      //in  wire
    .rst  (1'b0),                     //in  wire
    .in   (reception_complete_sclk),  //in  wire[(WIDTH-1):0]
    .out  (reception_complete_clk));  //out wire[(WIDTH-1):0]

//---------------------------------------------------------------
// Parallel interface data output @ clk
//---------------------------------------------------------------
reg reception_complete_clk_delayed = 1'b0;

// Propagate toggling signal without reset to ensure stability on reset
always @(posedge clk) begin
  // capture last state of reception
  reception_complete_clk_delayed <= reception_complete_clk;
end

// Derive data and control signal
always @(posedge clk) begin
  if (rst) begin
    data_out_valid <= 1'b0;
    data_out <= 8'b0;
  end
  else begin
    // default assignment
    data_out_valid <= 1'b0;

    // provide data to output on rising_edge
    if (reception_complete_clk & ~reception_complete_clk_delayed) begin
      // data can simply be captured as the reception complete signal
      // indicates stable values in received_word
      data_out <= received_word;
      data_out_valid <= 1'b1;
    end
  end
end

//---------------------------------------------------------------
// SPI Transmitter @ sclk
//---------------------------------------------------------------
// data request calculation
// SCLK_CYCLES_DURING_DATA_REQ = 8 clk period / sclk period
// clock periods are expressed by reciprocal of frequencies
// Term "+CLK_FREQUENCY-1" is used to round up the result in integer logic
localparam SCLK_CYCLES_DURING_DATA_REQ  = (8*SPI_FREQUENCY + CLK_FREQUENCY-1)/CLK_FREQUENCY;
// subtract from 8 bits per transfer to get target index
localparam DATA_REQ_BIT_INDEX = 8 - SCLK_CYCLES_DURING_DATA_REQ;

reg [7:0] transmit_bits;
reg [7:0] transmit_word;
reg       data_request_sclk = 1'b0;

always @(negedge sclk or posedge cs_n) begin
  // reset logic on positive cs_n edge = slave idle
  if (cs_n) begin
    current_bit_index <= 3'b0;
    data_request_sclk <= 1'b0;
    transmit_bits <= 8'b0;
  end
  // falling edge of sclk
  else begin
    // fill or move shift register for byte transmissions
    if (current_bit_index == 7) begin
      transmit_bits <= transmit_word;
    end else begin
      transmit_bits <= {transmit_bits[6:0], 1'b0};
    end

    // update bit index
    current_bit_index <= current_bit_index + 1'b1;

    // trigger request for new word at start of calculated index
    if (current_bit_index == DATA_REQ_BIT_INDEX-1) begin
      data_request_sclk <= 1'b1;
    // reset after half the reception in case cs_n is not changed
    // in between two transactions
    end else if (current_bit_index == (DATA_REQ_BIT_INDEX+4-1)%8) begin
      data_request_sclk <= 1'b0;
    end
  end
end

// drive miso output with data when cs_n low
assign miso = cs_n ? 1'bz : transmit_bits[7];

//---------------------------------------------------------------
// Handover of data request sclk -> clk
//---------------------------------------------------------------
//vhook_e synchronizer request_sync_inst
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a in data_request_sclk
//vhook_a out data_request_clk
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  request_sync_inst (
    .clk  (clk),                //in  wire
    .rst  (rst),                //in  wire
    .in   (data_request_sclk),  //in  wire[(WIDTH-1):0]
    .out  (data_request_clk));  //out wire[(WIDTH-1):0]

//---------------------------------------------------------------
// Parallel interface data input control
//---------------------------------------------------------------
reg data_request_clk_delayed;

always @(posedge clk) begin
  if (rst) begin
    data_request_clk_delayed <= 1'b0;
    data_in_required <= 1'b0;
    transmit_word <= 8'b0;
  end
  else begin
    // default assignment
    data_in_required <= 1'b0;

    // capture last state of data request
    data_request_clk_delayed <= data_request_clk;

    // request data from input
    if (~data_request_clk_delayed & data_request_clk) begin
      data_in_required <= 1'b1;
    end

    // capture new data if valid data available, 0 otherwise
    if (data_in_required) begin
      if (data_in_valid) begin
        transmit_word <= data_in;
      end else begin
        transmit_word <= 8'b0;
      end
    end
  end
end

//---------------------------------------------------------------
// chip select signal as active signal in parallel clock domain
//---------------------------------------------------------------
wire cs_n_clk;
assign active = ~cs_n_clk;
//vhook_e synchronizer active_sync_inst
//vhook_a WIDTH 1
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b1
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a in cs_n
//vhook_a out cs_n_clk
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b1), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  active_sync_inst (
    .clk  (clk),        //in  wire
    .rst  (rst),        //in  wire
    .in   (cs_n),       //in  wire[(WIDTH-1):0]
    .out  (cs_n_clk));  //out wire[(WIDTH-1):0]

endmodule

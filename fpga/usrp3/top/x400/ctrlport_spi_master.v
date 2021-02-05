//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: ctrlport_spi_master
//
// Description:
// This block transfers a control port request via SPI.
//
// The request format on SPI is defined as:
// Write request:
// 1'b1 = write, 15 bit address, 32 bit data (MOSI), 8 bit processing gap,
// 5 bit padding, 1 bit ack, 2 bit status
// Read request:
// 1'b0 = read, 15 bit address, 8 bit processing gap, 32 bit data (MISO),
// 5 bit padding, 1 bit ack, 2 bit status
//
// Parameters:
//
//   CPLD_ADDRESS_WIDTH : Number of address bits to allocate to one CPLD register map
//   MB_CPLD_BASE_ADDRESS : Base address to access the motherboard CPLD
//   DB_0_CPLD_BASE_ADDRESS : Base address to access the first daughterboard CPLD
//   DB_1_CPLD_BASE_ADDRESS : Base address to access the second daughterboard CPLD
//

module ctrlport_spi_master #(
  parameter CPLD_ADDRESS_WIDTH = 15,
  parameter MB_CPLD_BASE_ADDRESS = 20'h8000,
  parameter DB_0_CPLD_BASE_ADDRESS = 20'h10000,
  parameter DB_1_CPLD_BASE_ADDRESS = 20'h18000
)(
  input wire ctrlport_clk,
  input wire ctrlport_rst,

  // Request
  input  wire        s_ctrlport_req_wr,
  input  wire        s_ctrlport_req_rd,
  input  wire [19:0] s_ctrlport_req_addr,
  input  wire [31:0] s_ctrlport_req_data,

  // Response
  output reg         s_ctrlport_resp_ack = 1'b0,
  output reg  [ 1:0] s_ctrlport_resp_status = 2'b0,
  output reg  [31:0] s_ctrlport_resp_data = 32'b0,

  // SPI
  output wire [ 1:0] ss,
  output wire        sclk,
  output wire        mosi,
  input  wire        miso,

  // configuration from register interface
  input  wire [15:0] mb_clock_divider,
  input  wire [15:0] db_clock_divider
);

  `include "../../lib/rfnoc/core/ctrlport.vh"

  // Registers / wires for spi core communication
  reg  [31:0] set_data = 0;
  reg  [ 7:0] set_addr = 0;
  reg         set_stb  = 1'b0;

  wire [63:0] readback;
  wire        readback_stb;

  //----------------------------------------------------------
  // Address calculation
  //----------------------------------------------------------
  // define configuration for the address calculation
  localparam [19:0] BASE_ADDRESS_MASK = {20{1'b1}} << CPLD_ADDRESS_WIDTH;

  // wires for saving access
  wire mb_cpld_access = (s_ctrlport_req_addr & BASE_ADDRESS_MASK) == MB_CPLD_BASE_ADDRESS;
  wire db_0_cpld_access = (s_ctrlport_req_addr & BASE_ADDRESS_MASK) == DB_0_CPLD_BASE_ADDRESS;
  wire db_1_cpld_access = (s_ctrlport_req_addr & BASE_ADDRESS_MASK) == DB_1_CPLD_BASE_ADDRESS;

  //----------------------------------------------------------
  // FSM to handle transfers
  //----------------------------------------------------------
  localparam IDLE            = 3'd0;
  localparam SET_DIVIDER     = 3'd1;
  localparam WRITE_SPI_MSB   = 3'd2;
  localparam WRITE_SPI_LSB   = 3'd3;
  localparam CONFIG_TRANSFER = 3'd4;
  localparam WAIT_SPI        = 3'd5;

  localparam DIVIDER_ADDRESS    = 8'd0;
  localparam CTRL_ADDRESS       = 8'd1;
  localparam DATA_UPPER_ADDRESS = 8'd2;
  localparam DATA_LOWER_ADDRESS = 8'd3;

  // combined static configuration consisting of
  // 0x4000 = in data bit latched on rising edge of sclk
  // - out data launched on falling edge
  // - num bits = 64
  localparam CTRL_VALUE = 32'h40000000;

  //vhook_nowarn id=Misc11 msg={reset value 'CONFIG_TRANSFER' of 'state'} 
  reg [ 2:0] state = IDLE;
  reg [31:0] data_cache;
  reg [19:0] address_cache;
  reg        wr_cache;
  reg [15:0] divider;
  reg [ 1:0] cs;

  always @ (posedge ctrlport_clk) begin
    // moving reset to the end of the block to reduce fanout of ctrlport_rst

    // default assignments
    s_ctrlport_resp_ack <= 1'b0;
    set_stb <= 1'b0;

    case (state)
      IDLE: begin
        //requests appear
        if (s_ctrlport_req_wr | s_ctrlport_req_rd) begin
          // any CPLD targeted
          if (mb_cpld_access | db_0_cpld_access | db_1_cpld_access) begin
            state <= CONFIG_TRANSFER;
          end
        end

        // select chip select and divider value
        if (mb_cpld_access) begin
          divider <= mb_clock_divider;
          cs      <= 2'b00;
        end else begin
          divider <= db_clock_divider;
          if (db_0_cpld_access) begin
            cs <= 2'b10;
          end else begin
            cs <= 2'b01;
          end
        end

        // save data and address for further steps
        data_cache    <= s_ctrlport_req_data;
        address_cache <= s_ctrlport_req_addr;
        wr_cache      <= s_ctrlport_req_wr;
      end

      // set slave select
      CONFIG_TRANSFER: begin
        state    <= SET_DIVIDER;

        set_stb  <= 1'b1;
        set_addr <= CTRL_ADDRESS;
        // Slave select located in LSBs. Inverted against the desired value in
        // cs register as 1 represents slave enabled in combination with
        // generic IDLE value.
        set_data <= CTRL_VALUE | {30'b0, ~cs};
      end

      // write divider to SPI core
      SET_DIVIDER: begin
        state    <= WRITE_SPI_LSB;

        set_stb  <= 1'b1;
        set_addr <= DIVIDER_ADDRESS;
        set_data <= {16'b0, divider};
      end

      //write lower bits to SPI core (aligned to MSB)
      WRITE_SPI_LSB: begin
        state    <= WRITE_SPI_MSB;

        set_stb  <= 1'b1;
        set_addr <= DATA_LOWER_ADDRESS;
        set_data <= {data_cache[15:0], 16'bx};
      end

      //write upper bits, which triggers transaction to start
      WRITE_SPI_MSB: begin
        state    <= WAIT_SPI;

        set_stb  <= 1'b1;
        set_addr <= DATA_UPPER_ADDRESS;
        set_data <= {wr_cache, address_cache[14:0], data_cache[31:16]};
      end

      // wait for transaction to complete and translate to ctrlport response
      WAIT_SPI: begin
        s_ctrlport_resp_status <= readback[2] ? readback[1:0] : CTRL_STS_CMDERR;
        s_ctrlport_resp_data   <= wr_cache ? {CTRLPORT_DATA_W {1'b0}} : readback[39:8];
        s_ctrlport_resp_ack    <= readback_stb;

        if (readback_stb) begin
          state <= IDLE;
        end
      end

      default: begin
        state <= IDLE;
      end
    endcase

    // reset control registers only
    if (ctrlport_rst) begin
      state <= IDLE;
      s_ctrlport_resp_ack <= 1'b0;
      set_stb <= 1'b0;
    end
  end

  //----------------------------------------------------------
  // SPI master
  //----------------------------------------------------------
  //vhook simple_spi_core_64bit spi_inst
  //vhook_a BASE     0
  //vhook_a WIDTH    2
  //vhook_a CLK_IDLE 0
  //vhook_a SEN_IDLE 2'b11
  //vhook_a MAX_BITS 64
  //vhook_a clock    ctrlport_clk
  //vhook_a reset    ctrlport_rst
  //vhook_a sen      ss
  //vhook_a debug    {}
  //vhook_a ready    {}
  simple_spi_core_64bit
    # (
      .BASE      (0),       //integer:=0
      .WIDTH     (2),       //integer:=8
      .CLK_IDLE  (0),       //integer:=0
      .SEN_IDLE  (2'b11),   //integer:=2#111111111111111111111111#
      .MAX_BITS  (64))      //integer:=32
    spi_inst (
      .clock         (ctrlport_clk),   //in  wire
      .reset         (ctrlport_rst),   //in  wire
      .set_stb       (set_stb),        //in  wire
      .set_addr      (set_addr),       //in  wire[7:0]
      .set_data      (set_data),       //in  wire[31:0]
      .readback      (readback),       //out wire[(MAX_BITS-1):0]
      .readback_stb  (readback_stb),   //out wire
      .ready         (),               //out wire
      .sen           (ss),             //out wire[(WIDTH-1):0]
      .sclk          (sclk),           //out wire
      .mosi          (mosi),           //out wire
      .miso          (miso),           //in  wire
      .debug         ());              //out wire[23:0]

endmodule

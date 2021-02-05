//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: ctrlport_to_spi
// Description:
// his module wraps a SPI master and provides a ControlPort interface.
//
//XmlParse xml_on
//<regmap name="SPI_REGMAP" readablestrobes="false" markdown="true" generatevhdl="true" ettusguidelines="true">
//
//  <group name="SPI_REGS">
//    <info>
//      This register map is present for each SPI master.
//
//      For information about the register content and the way to interact with the core see the
//      <a href="https://opencores.org/websvn/filedetails?repname=spi&path=%2Fspi%2Ftrunk%2Fdoc%2Fspi.pdf" target="_blank">documentation</a>
//      of the SPI master from opencores used internally.
//
//      The core is configured to operate with 16 slave signal signals, up to 128 bits per transmission and 8 bit clock divider.
//      Only 64 bits of data are available via this register inteface.
//
//      For the different SPI modes use the following table to derive the bits in @.CONTROL register. Only option 0 (CPOL=0, CPHA=0) has been tested.
//
//| CPOL | CPHA | TX_NEG | RX_NEG |
//| ------- | -------- | -------- | ------- |
//| 0  | 0  | 1  | 0  |
//| 0  | 1  | 0  | 1  |
//| 1  | 0  | 0  | 1  |
//| 1  | 1  | 1  | 0  |
//    </info>
//
//    <register name="RX_DATA_LOW" offset="0x00" writable="false" size="32">
//      <info>Lower 32 bits of the received word. (RxWord[31:0])</info>
//    </register>
//
//    <register name="RX_DATA_HIGH" offset="0x04" writable="false" size="32">
//      <info>Higher 32 bits of the received word. (RxWord[63:32])</info>
//    </register>
//
//    <register name="TX_DATA_LOW" offset="0x08" readable="false" size="32">
//      <info>Lower 32 bits of the received word. (TxWord[31:0])</info>
//    </register>
//
//    <register name="TX_DATA_HIGH" offset="0x0C" readable="false" size="32">
//      <info>Higher 32 bits of the received word. (TxWord[63:32])</info>
//    </register>
//
//    <register name="CONTROL" offset="0x10" size="32">
//      <info>Conrol register</info>
//    </register>

//    <register name="CLOCK_DIVIDER" offset="0x14" size="8">
//      <bitfield name="Divider" range="7..0">
//        <info>
//          Clock Divider.
//        </info>
//      </bitfield>
//    </register>
//    <register name="SLAVE_SELECT" offset="0x18" size="16">
//      <bitfield name="SS" range="15..0">
//        <info>
//          Slave select.
//        </info>
//      </bitfield>
//    </register>
//
//  </group>
//</regmap>
//XmlParse xml_off

module ctrlport_to_spi #(
  parameter BASE_ADDRESS = 0
)(
  //---------------------------------------------------------------
  // ControlPort slave
  //---------------------------------------------------------------
  input  wire        ctrlport_clk,
  input  wire        ctrlport_rst,
  input  wire        s_ctrlport_req_wr,
  input  wire        s_ctrlport_req_rd,
  input  wire [19:0] s_ctrlport_req_addr,
  input  wire [31:0] s_ctrlport_req_data,

  output reg         s_ctrlport_resp_ack,
  output reg  [ 1:0] s_ctrlport_resp_status = 0,
  output reg  [31:0] s_ctrlport_resp_data = 0,

  //---------------------------------------------------------------
  // SPI signals
  //---------------------------------------------------------------
  output wire        sclk,
  output wire        mosi,
  output wire [15:0] ss,
  input  wire        miso
);

`include "../../../lib/rfnoc/core/ctrlport.vh"
`include "./regmap/spi_regmap_utils.vh"

//---------------------------------------------------------------
// Translating ctrlport <-> wishbone
//---------------------------------------------------------------
reg        wb_cyc_i; // active bus cycle
reg        wb_we_i = 1'b0;  // write access
reg [ 4:0] wb_adr_i= 5'b0;
reg [31:0] wb_dat_i= 32'b0;
//vhook_sigstart
  wire wb_ack_o;
  wire [31:0] wb_dat_o;
  wire wb_err_o;
//vhook_sigend

// check for adress to be in range [base_addr..base_addr+32)
localparam NUM_ADDRESSES = 32;
wire address_in_range = (s_ctrlport_req_addr >= BASE_ADDRESS) && (s_ctrlport_req_addr < BASE_ADDRESS + NUM_ADDRESSES);

// following chapter 3.2.3 (classic standard SINGLE WRITE cycle) of https://cdn.opencores.org/downloads/wbspec_b4.pdf
always @(posedge ctrlport_clk) begin
  // reset internal registers and reponses
  if (ctrlport_rst) begin
    wb_cyc_i <= 1'b0;
    s_ctrlport_resp_ack <= 1'b0;

  end else begin
    // request independent default assignments
    s_ctrlport_resp_ack <= 1'b0;

    // wait for ack on active bus transactions
    if (wb_cyc_i) begin
      if (wb_ack_o) begin
        // end bus cycle and generate response
        wb_cyc_i <= 1'b0;
        s_ctrlport_resp_ack <= 1'b1;
        s_ctrlport_resp_data <= wb_dat_o;

        if (wb_err_o) begin
          s_ctrlport_resp_status <= CTRL_STS_CMDERR;
        end else begin
          s_ctrlport_resp_status <= CTRL_STS_OKAY;
        end
      end

    // write requests
    end else if (s_ctrlport_req_wr) begin
      // assume there is a valid address
      wb_cyc_i <= 1'b1;
      wb_we_i <= 1'b1;
      wb_dat_i <= s_ctrlport_req_data;

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + TX_DATA_LOW: begin
          wb_adr_i <= 5'h00;
        end

        BASE_ADDRESS + TX_DATA_HIGH: begin
          wb_adr_i <= 5'h04;
        end

        BASE_ADDRESS + CONTROL: begin
          wb_adr_i <= 5'h10;
        end

        BASE_ADDRESS + CLOCK_DIVIDER: begin
          wb_adr_i <= 5'h14;
        end

        BASE_ADDRESS + SLAVE_SELECT: begin
          wb_adr_i <= 5'h18;
        end

        // error on undefined address
        default: begin
          wb_cyc_i <= 1'b0;

          if (address_in_range) begin
            s_ctrlport_resp_status <= CTRL_STS_CMDERR;

          // no response if out of range
          end else begin
            s_ctrlport_resp_ack <= 1'b0;
          end
        end
      endcase

    // read requests
    end else if (s_ctrlport_req_rd) begin
      // assume there is a valid address
      wb_cyc_i <= 1'b1;
      wb_we_i <= 1'b0;

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + RX_DATA_LOW: begin
          wb_adr_i <= 5'h00;
        end

        BASE_ADDRESS + RX_DATA_HIGH: begin
          wb_adr_i <= 5'h04;
        end

        BASE_ADDRESS + CONTROL: begin
          wb_adr_i <= 5'h10;
        end

        BASE_ADDRESS + CLOCK_DIVIDER: begin
          wb_adr_i <= 5'h14;
        end

        BASE_ADDRESS + SLAVE_SELECT: begin
          wb_adr_i <= 5'h18;
        end

        // error on undefined address
        default: begin
          wb_cyc_i <= 1'b0;

          if (address_in_range) begin
            s_ctrlport_resp_status <= CTRL_STS_CMDERR;

          // no response if out of range
          end else begin
            s_ctrlport_resp_ack <= 1'b0;
          end
        end
      endcase

    // no request
    end else begin
      s_ctrlport_resp_ack <= 1'b0;
    end
  end
end

//---------------------------------------------------------------
// SPI master
//---------------------------------------------------------------
//vhook spi_top spi_master
//vhook_a {^(.*)_pad_.} $1
//vhook_a wb_clk_i ctrlport_clk
//vhook_a wb_rst_i ctrlport_rst
//vhook_a wb_int_o {}
//vhook_a wb_stb_i wb_cyc_i
//vhook_a wb_sel_i 4'hF
spi_top
  spi_master (
    .wb_clk_i    (ctrlport_clk), //in  wire
    .wb_rst_i    (ctrlport_rst), //in  wire
    .wb_adr_i    (wb_adr_i),     //in  wire[4:0]
    .wb_dat_i    (wb_dat_i),     //in  wire[(32-1):0]
    .wb_dat_o    (wb_dat_o),     //out reg[(32-1):0]
    .wb_sel_i    (4'hF),         //in  wire[3:0]
    .wb_we_i     (wb_we_i),      //in  wire
    .wb_stb_i    (wb_cyc_i),     //in  wire
    .wb_cyc_i    (wb_cyc_i),     //in  wire
    .wb_ack_o    (wb_ack_o),     //out reg
    .wb_err_o    (wb_err_o),     //out wire
    .wb_int_o    (),             //out reg
    .ss_pad_o    (ss),           //out wire[(16-1):0]
    .sclk_pad_o  (sclk),         //out wire
    .mosi_pad_o  (mosi),         //out wire
    .miso_pad_i  (miso));        //in  wire

endmodule
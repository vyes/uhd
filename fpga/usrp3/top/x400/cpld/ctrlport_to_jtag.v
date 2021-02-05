//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: ctrlport_to_jtag
// Description:
// This module wraps a JTAG master and provides a ControlPort slave interface.
//
//XmlParse xml_on
//<regmap name="JTAG_REGMAP" readablestrobes="false" markdown="true" generatevhdl="true" ettusguidelines="true">
//
//  <group name="JTAG_REGS">
//    <info>
//      This register map is present for each JTAG module.
//
//      Basic operation would be:
//
//      - poll @.ready until asserted
//      - write / read data
//      - write @.CONTROL register along with @.reset deasserted to start a transaction
//
//      For resetting the BITQ FSM, simply assert @.reset.
//
//      This operation seems a little strange, but it is what the axi_bitq driver
//      expects. This behavior has been implemented in previous products.
//
//    </info>
//
//    <register name="TX_DATA" readable="false" offset="0x00" size="32">
//      <info>Data to be transmitted (TDI)</info>
//    </register>
//
//    <register name="STB_DATA" readable="false" offset="0x04" size="32">
//      <info>Data to be transmitted (TMS)</info>
//    </register>
//
//    <register name="CONTROL" offset="0x08"  size="32">
//      <info>JTAG module status and control</info>
//      <bitfield name="prescalar" range="7..0" initialvalue="true">
//        <info>Clock divider. Resulting JTAG frequency will be f_ctrlport / (2*(prescalar + 1)). See window description for details on the initial/minimum value.</info>
//      </bitfield>
//      <bitfield name="length" range="12..8">
//        <info>(Number of bits - 1) to be transferred</info>
//      </bitfield>
//      <bitfield name="reset" readable="false" range="31">
//        <info>When asserted ('1') a soft-reset for the bitq FSM is triggered,
//              preventing any transactions to take place.
//
//              Deassert this bit, along with values for @.prescalar and @.length
//              to trigger a new transaction (start strobe).</info>
//      </bitfield>
//      <bitfield name="ready" writable="false" range="31">
//        <info>Bitq FSM is ready for input (no data transmission in progress).</info>
//      </bitfield>
//    </register>
//
//    <register name="RX_DATA" offset="0x0C" writable="false" size="32">
//      <info>Received data (TDO)</info>
//    </register>
//
//  </group>
//</regmap>
//XmlParse xml_off

module ctrlport_to_jtag #(
  parameter BASE_ADDRESS = 0,
  parameter DEFAULT_PRESCALAR = 0 // default clock divider
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
  // JTAG signals
  //---------------------------------------------------------------
  output wire tck,
  output wire tdi,
  input  wire tdo,
  output wire tms
);

`include "../../../lib/rfnoc/core/ctrlport.vh"
`include "./regmap/jtag_regmap_utils.vh"

//---------------------------------------------------------------
// local registers
//---------------------------------------------------------------
reg [TX_DATA_SIZE-1:0]   tx_data_reg;
reg [STB_DATA_SIZE-1:0]  stb_data_reg;
reg [PRESCALAR_SIZE-1:0] prescalar_reg = DEFAULT_PRESCALAR;
reg [LENGTH_SIZE-1:0]    length_reg;
reg start_reg;
reg soft_rst_stb_reg;

//---------------------------------------------------------------
// readback signals from JTAG master
//---------------------------------------------------------------
wire [31:0] rd_data;
wire ready;

//---------------------------------------------------------------
// Handling of ctrlport
//---------------------------------------------------------------
localparam NUM_ADDRESSES = 32;
wire address_in_range = (s_ctrlport_req_addr >= BASE_ADDRESS) && (s_ctrlport_req_addr < BASE_ADDRESS + NUM_ADDRESSES);
wire soft_rst_requested = (s_ctrlport_req_addr == BASE_ADDRESS + CONTROL) && (s_ctrlport_req_data[RESET] == 1'b1);

always @(posedge ctrlport_clk) begin
  // reset internal registers and reponses
  if (ctrlport_rst) begin
    tx_data_reg         <= {TX_DATA_SIZE {1'b0}};
    stb_data_reg        <= {STB_DATA_SIZE {1'b0}};
    prescalar_reg       <= DEFAULT_PRESCALAR;
    length_reg          <= {LENGTH_SIZE {1'b0}};
    start_reg           <= 1'b0;
    soft_rst_stb_reg    <= 1'b0;
    s_ctrlport_resp_ack <= 1'b0;

  end else begin
    // request independent default assignments
    start_reg <= 1'b0;
    soft_rst_stb_reg <= 1'b0; // self-clearing strobe

    // write requests
    if (s_ctrlport_req_wr) begin
      // always issue an ack and no data
      s_ctrlport_resp_ack <= 1'b1;
      s_ctrlport_resp_data <= {CTRLPORT_DATA_W{1'bx}};
      s_ctrlport_resp_status <= CTRL_STS_OKAY;

      // process write requests only in case ready is asserted
      // because JTAG module requires these values to be stable
      // when it is not ready.
      // The one exception is when a soft-reset is requested to
      // reset the bitq_fsm, in that case that is a valid write.
      if (soft_rst_requested) begin
        soft_rst_stb_reg <= 1'b1;

      end else if (ready) begin
        case (s_ctrlport_req_addr)
          BASE_ADDRESS + TX_DATA: begin
            tx_data_reg <= s_ctrlport_req_data;
          end

          BASE_ADDRESS + STB_DATA: begin
            stb_data_reg <= s_ctrlport_req_data;
          end

          BASE_ADDRESS + CONTROL: begin
            length_reg <= s_ctrlport_req_data[LENGTH_MSB:LENGTH];
            prescalar_reg <= s_ctrlport_req_data[PRESCALAR_MSB:PRESCALAR];
            // When the RESET bit is high, a soft-reset (i.e. no start strobe)
            // must take place, which is handled by the default assignemnt.
            // Otherwise, if the RESET bit is low, a start strobe  should be
            // issued, triggering a transaction.
            start_reg <= (s_ctrlport_req_data[RESET] == 1'b0);
          end

          // error on undefined address
          default: begin
            if (address_in_range) begin
              s_ctrlport_resp_status <= CTRL_STS_CMDERR;

            // no response if out of range
            end else begin
              s_ctrlport_resp_ack <= 1'b0;
            end
          end
        endcase

      // error in case ready is not asserted
      end else begin
        s_ctrlport_resp_status <= CTRL_STS_CMDERR;
      end

    // read requests
    end else if (s_ctrlport_req_rd) begin
      // default assumption: valid request
      s_ctrlport_resp_ack <= 1'b1;
      s_ctrlport_resp_status <= CTRL_STS_OKAY;

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + RX_DATA: begin
          s_ctrlport_resp_data <= rd_data;
        end

        BASE_ADDRESS + CONTROL: begin
          s_ctrlport_resp_data <= {CTRLPORT_DATA_W {1'b0}};
          s_ctrlport_resp_data[LENGTH_MSB:LENGTH] <= length_reg;
          s_ctrlport_resp_data[PRESCALAR_MSB:PRESCALAR] <= prescalar_reg;
          s_ctrlport_resp_data[READY] <= ready;
        end

        // error on undefined address
        default: begin
          s_ctrlport_resp_data <= {CTRLPORT_DATA_W {1'bx}};
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
// JTAG master
//---------------------------------------------------------------

// bitq_fsm reset is asserted by either the ctrlport_rst or the
// soft-reset strobe triggered through software.
wire bitq_resetn = ~(ctrlport_rst | soft_rst_stb_reg);

bitq_fsm #(
  .IDLE_VALUE (1'b0)
) jtag_master (
  .clk        (ctrlport_clk),    //in  std_logic
  .rstn       (bitq_resetn),     //in  std_logic
  .prescalar  (prescalar_reg),   //in  std_logic_vector(7:0)
  .bit_clk    (tck),             //inout std_logic
  .bit_in     (tdo),             //in  std_logic
  .bit_out    (tdi),             //inout std_logic
  .bit_stb    (tms),             //inout std_logic
  .start      (start_reg),       //in  std_logic
  .ready      (ready),           //out std_logic
  .len        (length_reg),      //in  std_logic_vector(4:0)
  .wr_data    (tx_data_reg),     //in  std_logic_vector(31:0)
  .stb_data   (stb_data_reg),    //in  std_logic_vector(31:0)
  .rd_data    (rd_data)          //out std_logic_vector(31:0)
);

endmodule

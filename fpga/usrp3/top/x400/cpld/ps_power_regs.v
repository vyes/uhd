//
// Copyright 2020 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: ps_power_regs
// Description:
// Registers to control power supplies on the motherboard.
//
//XmlParse xml_on
//<regmap name="PS_POWER_REGMAP" readablestrobes="false" generatevhdl="true" ettusguidelines="true">
//  <group name="PS_POWER_REGS">
//    <info>
//      Registers to control power supplies on the motherboard.
//    </info>
//
//    <register name="IPASS_POWER_REG" offset="0x00" size="32">
//      <info>Controls the power supplies for the iPass connectors.</info>
//      <bitfield name="IPASS_DISABLE_POWER_BIT" range="0">
//        <info>Set to 1 to disable power for both iPass connectors.</info>
//      </bitfield>
//      <bitfield name="IPASS_CLEAR_POWER_FAULT0" range="30" readable="false">
//        <info>Clear @.IPASS_POWER_FAULT0.</info>
//      </bitfield>
//      <bitfield name="IPASS_CLEAR_POWER_FAULT1" range="31" readable="false">
//        <info>Clear @.IPASS_POWER_FAULT1.</info>
//      </bitfield>
//      <bitfield name="IPASS_POWER_FAULT0" range="30" writable="false">
//        <info>
//          Asserted signal indicates a power fault in power switch for iPass
//          connector 0. Sticky bit. Asserted on occurrence. Reset using
//          @.IPASS_CLEAR_POWER_FAULT0.
//        </info>
//      </bitfield>
//      <bitfield name="IPASS_POWER_FAULT1" range="31" writable="false">
//        <info>
//          Asserted signal indicates a power fault in power switch for iPass
//          connector 1. Sticky bit. Asserted on occurrence. Reset using
//          @.IPASS_CLEAR_POWER_FAULT1.
//        </info>
//      </bitfield>
//    </register>
//
//    <register name="OSC_POWER_REG" offset="0x04" size="32">
//      <info>Controls the power supplies for the oscillators.</info>
//      <bitfield name="OSC_100" range="0">
//        <info>Enables 5V power switch for the 100 MHz oscillator.</info>
//      </bitfield>
//      <bitfield name="OSC_122_88" range="1">
//        <info>Enables 5V power switch for the 122.88 MHz oscillator.</info>
//      </bitfield>
//    </register>
//  </group>
//</regmap>
//XmlParse xml_off

module ps_power_regs #(
  parameter BASE_ADDRESS  = 0,
  parameter NUM_ADDRESSES = 32
)(
  input wire ctrlport_clk,
  input wire ctrlport_rst,

  // Request
  input  wire        s_ctrlport_req_wr,
  input  wire        s_ctrlport_req_rd,
  input  wire [19:0] s_ctrlport_req_addr,
  input  wire [31:0] s_ctrlport_req_data,
  // Response
  output reg         s_ctrlport_resp_ack,
  output reg  [ 1:0] s_ctrlport_resp_status,
  output reg  [31:0] s_ctrlport_resp_data,

  // iPass
  output reg         ipass_power_disable = 1'b0,
  input  wire [ 1:0] ipass_power_fault_n,

  // Oscillators
  output reg         osc_100_en,
  output reg         osc_122_88_en
);

`include "regmap/ps_power_regmap_utils.vh"
`include "../../../lib/rfnoc/core/ctrlport.vh"

//----------------------------------------------------------
// Address calculation
//----------------------------------------------------------
wire address_in_range = (s_ctrlport_req_addr >= BASE_ADDRESS) && (s_ctrlport_req_addr < BASE_ADDRESS + NUM_ADDRESSES);

//----------------------------------------------------------
// Internal registers
//----------------------------------------------------------
reg [1:0] ipass_power_sticky = 2'b00;
reg [1:0] ipass_clear_sticky = 2'b00;

//----------------------------------------------------------
// Handling of controlport requests
//----------------------------------------------------------
always @(posedge ctrlport_clk) begin
  // reset internal registers and reponses
  if (ctrlport_rst) begin
    ipass_power_disable <= 1'b0;
    //vhook_nowarn id=Misc12 msg={s_ctrlport_resp_data}
    //vhook_nowarn id=Misc12 msg={s_ctrlport_resp_status}
    s_ctrlport_resp_ack <= 1'b0;

    osc_100_en    <= 1'b0;
    osc_122_88_en <= 1'b0;

  end else begin
    // default assignments
    ipass_clear_sticky <= 2'b00;

    // write requests
    if (s_ctrlport_req_wr) begin
      // always issue an ack and no data
      s_ctrlport_resp_ack    <= 1'b1;
      s_ctrlport_resp_status <= CTRL_STS_OKAY;
      s_ctrlport_resp_data   <= {CTRLPORT_ADDR_W {1'bx}};

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + IPASS_POWER_REG: begin
          ipass_power_disable   <= s_ctrlport_req_data[IPASS_DISABLE_POWER_BIT];
          ipass_clear_sticky[0] <= s_ctrlport_req_data[IPASS_CLEAR_POWER_FAULT0];
          ipass_clear_sticky[1] <= s_ctrlport_req_data[IPASS_CLEAR_POWER_FAULT1];
        end

        BASE_ADDRESS + OSC_POWER_REG: begin
          osc_100_en    <= s_ctrlport_req_data[OSC_100];
          osc_122_88_en <= s_ctrlport_req_data[OSC_122_88];
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

    // read request
    end else if (s_ctrlport_req_rd) begin
      // default assumption: valid request
      s_ctrlport_resp_ack    <= 1'b1;
      s_ctrlport_resp_status <= CTRL_STS_OKAY;
      s_ctrlport_resp_data   <= {CTRLPORT_DATA_W {1'b0}};

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + IPASS_POWER_REG: begin
          s_ctrlport_resp_data[IPASS_DISABLE_POWER_BIT] <= ipass_power_disable;
          s_ctrlport_resp_data[IPASS_POWER_FAULT0]      <= ipass_power_sticky[0];
          s_ctrlport_resp_data[IPASS_POWER_FAULT1]      <= ipass_power_sticky[1];
        end

        BASE_ADDRESS + OSC_POWER_REG: begin
          s_ctrlport_resp_data[OSC_100]    <= osc_100_en;
          s_ctrlport_resp_data[OSC_122_88] <= osc_122_88_en;
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

//----------------------------------------------------------
// Sticky logic of power registers
//----------------------------------------------------------
//sync async inputs
wire [1:0] ipass_power_fault_lcl_n;
//vhook synchronizer power_fault_sync
//vhook_a WIDTH 2
//vhook_a STAGES 2
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk ctrlport_clk
//vhook_a rst ctrlport_rst
//vhook_a in ipass_power_fault_n
//vhook_a out ipass_power_fault_lcl_n
synchronizer
  # (
    .WIDTH             (2),   //integer:=1
    .STAGES            (2),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (1))   //integer:=1
  power_fault_sync (
    .clk  (ctrlport_clk),              //in  wire
    .rst  (ctrlport_rst),              //in  wire
    .in   (ipass_power_fault_n),       //in  wire[(WIDTH-1):0]
    .out  (ipass_power_fault_lcl_n));  //out wire[(WIDTH-1):0]

always @(posedge ctrlport_clk) begin
  if (ctrlport_rst) begin
    ipass_power_sticky <= 2'b00;
  end else begin
    // keep value if not cleared or set in case of fault
    ipass_power_sticky <= (ipass_power_sticky & ~ipass_clear_sticky) | ~ipass_power_fault_lcl_n;
  end
end

endmodule

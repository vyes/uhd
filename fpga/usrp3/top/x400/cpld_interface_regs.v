//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: cpld_interface_regs
// Description:
// Basic Registers to inform software about version and capabilities
//
//XmlParse xml_on
//<regmap name="VERSIONING_REGS_REGMAP">
//  <group name="VERSIONING_CONSTANTS">
//    <enumeratedtype name="CPLD_IFC_VERSION" showhex="true">
//      <info>
//        CPLD interface module.{BR/}
//        For guidance on when to update these revision numbers,
//        please refer to the register map documentation accordingly:
//        <li> Current version: @.VERSIONING_REGS_REGMAP..CURRENT_VERSION
//        <li> Oldest compatible version: @.VERSIONING_REGS_REGMAP..OLDEST_COMPATIBLE_VERSION
//        <li> Version last modified: @.VERSIONING_REGS_REGMAP..VERSION_LAST_MODIFIED
//      </info>
//      <value name="CPLD_IFC_CURRENT_VERSION_MAJOR"           integer="2"/>
//      <value name="CPLD_IFC_CURRENT_VERSION_MINOR"           integer="0"/>
//      <value name="CPLD_IFC_CURRENT_VERSION_BUILD"           integer="0"/>
//      <value name="CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR" integer="2"/>
//      <value name="CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MINOR" integer="0"/>
//      <value name="CPLD_IFC_OLDEST_COMPATIBLE_VERSION_BUILD" integer="0"/>
//      <value name="CPLD_IFC_VERSION_LAST_MODIFIED_TIME"      integer="0x21011809"/>
//    </enumeratedtype>
//  </group>
//</regmap>
//
//<regmap name="CPLD_INTERFACE_REGMAP" readablestrobes="false" generatevhdl="true" ettusguidelines="true">
//  <group name="CPLD_INTERFACE_REGS">
//    <info>
//      Basic registers containing version and capabilites information.
//    </info>
//
//    <register name="SIGNATURE_REGISTER" offset="0x00" writable="false" size="32">
//      <info>Contains the product's signature.</info>
//      <bitfield name="PRODUCT_SIGNATURE" range="31..0">
//        <info>fixed value 0xCB1D1FAC</info>
//      </bitfield>
//    </register>
//
//    <register name="SCRATCH_REGISTER" offset="0x0C" size="32">
//      <info>Read/write register for general software use.</info>
//    </register>
//  </group>
//
//  <group name="IPASS_REGS">
//    <register name="IPASS_CONTROL" offset="0x10" size="32">
//      <bitfield name="IPASS_ENABLE_TRANSFER" range="0">
//        <info>
//          If 1 enables the forwarding of iPass cable present signal to MB CPLD
//          using ctrlport requests. On change from 0 to 1 the current status is
//          transferred to the MB CPLD via SPI ctrlport request initially.
//        </info>
//      </bitfield>
//    </register>
//  </group>
//
//  <group name="CPLD_SPI_CONTROL_REGS">
//    <info>
//      Registers to control the SPI clock frequency of the CPLD interfaces.
//      The resulting clock frequency is calculated by <math><mrow><mfrac><mrow><msub><mi>f</mi><mrow><mi>PRC</mi></mrow></msub></mrow><mrow><mn>2</mn><mrow><mo form="prefix">(</mo><mo>divider</mi><mo>+</mo><mn>1</mn><mo form="postfix">)</mo></mrow></mrow></mfrac></mrow></math>.
//      <br>
//      Note that the Pll Reference Clock (PRC) is depending on the RF clocks.
//    </info>
//
//    <register name="MOTHERBOARD_CPLD_DIVIDER" offset="0x20" size="32">
//      <info>
//        Clock divider used for SPI transactions targeting the MB CPLD.<br/>
//        Minimum required value is 2.
//      </info>
//      <bitfield name="MB_DIVIDER" range="15..0" initialvalue="2">
//        <info>Divider value</info>
//      </bitfield>
//    </register>
//
//    <register name="DAUGHTERBOARD_CPLD_DIVIDER" offset="0x24" size="32">
//      <info>
//        Clock divider used for SPI transactions targeting any of the DB CPLDs.<br/>
//        Minimum required value is 5.
//      </info>
//      <bitfield name="DB_DIVIDER" range="15..0" initialvalue="5">
//        <info>Divider value</info>
//      </bitfield>
//    </register>
//  </group>
//</regmap>
//XmlParse xml_off

module cpld_interface_regs #(
  parameter BASE_ADDRESS = 0,
  parameter NUM_ADDRESSES = 128
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

  // configuration to the SPI master
  output wire [15:0] mb_clock_divider,
  output wire [15:0] db_clock_divider,

  output reg         ipass_enable = 1'b0,

  // Versioning (Constant)
  output wire [95:0] version_info
);

`include "regmap/cpld_interface_regmap_utils.vh"
`include "regmap/versioning_regs_regmap_utils.vh"
`include "regmap/versioning_utils.vh"
`include "../../lib/rfnoc/core/ctrlport.vh"

//----------------------------------------------------------
// Address calculation
//----------------------------------------------------------
wire address_in_range = (s_ctrlport_req_addr >= BASE_ADDRESS) && (s_ctrlport_req_addr < BASE_ADDRESS + NUM_ADDRESSES);

//----------------------------------------------------------
// Static variables
//----------------------------------------------------------
localparam SIGNATURE_VALUE = 32'hCB1D1FAC;

//----------------------------------------------------------
// Internal registers
//----------------------------------------------------------
reg [SCRATCH_REGISTER_SIZE-1:0] scratch_reg;
reg [MB_DIVIDER_SIZE-1:0]       mb_divider_reg = 2;
reg [DB_DIVIDER_SIZE-1:0]       db_divider_reg = 5;

//----------------------------------------------------------
// Assigne configuration signals
//----------------------------------------------------------
assign mb_clock_divider = mb_divider_reg;
assign db_clock_divider = db_divider_reg;

//----------------------------------------------------------
// Handling of ControlPort requests
//----------------------------------------------------------
always @(posedge ctrlport_clk) begin
  // reset internal registers and responses
  if (ctrlport_rst) begin
    scratch_reg <= 0;
    s_ctrlport_resp_ack <= 1'b0;
    s_ctrlport_resp_data <= {32{1'bx}};
    s_ctrlport_resp_status <= {2{1'bx}};

  // write requests
end else begin
  if (s_ctrlport_req_wr) begin
    // always issue an ack and no data
    s_ctrlport_resp_ack <= 1'b1;
    s_ctrlport_resp_data <= {32{1'bx}};
    s_ctrlport_resp_status <= CTRL_STS_OKAY;

    case (s_ctrlport_req_addr)
      BASE_ADDRESS + SCRATCH_REGISTER: begin
        scratch_reg <= s_ctrlport_req_data;
      end

      BASE_ADDRESS + IPASS_CONTROL: begin
        ipass_enable <= s_ctrlport_req_data[IPASS_ENABLE_TRANSFER];
      end

      BASE_ADDRESS + MOTHERBOARD_CPLD_DIVIDER: begin
        mb_divider_reg <= s_ctrlport_req_data[MB_DIVIDER_MSB:MB_DIVIDER];
      end

      BASE_ADDRESS + DAUGHTERBOARD_CPLD_DIVIDER: begin
        db_divider_reg <= s_ctrlport_req_data[DB_DIVIDER_MSB:DB_DIVIDER];
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
      s_ctrlport_resp_ack <= 1'b1;
      s_ctrlport_resp_status <= CTRL_STS_OKAY;

      case (s_ctrlport_req_addr)
        BASE_ADDRESS + SIGNATURE_REGISTER: begin
          s_ctrlport_resp_data <= SIGNATURE_VALUE;
        end

        BASE_ADDRESS + SCRATCH_REGISTER: begin
          s_ctrlport_resp_data <= scratch_reg;
        end

        BASE_ADDRESS + IPASS_CONTROL: begin
          s_ctrlport_resp_data <= 32'h0;
          s_ctrlport_resp_data[IPASS_ENABLE_TRANSFER] <= ipass_enable;
        end

        BASE_ADDRESS + MOTHERBOARD_CPLD_DIVIDER: begin
          s_ctrlport_resp_data <= {{(CTRLPORT_DATA_W - MB_DIVIDER_SIZE){1'b0}}, mb_divider_reg};
        end

        BASE_ADDRESS + DAUGHTERBOARD_CPLD_DIVIDER: begin
          s_ctrlport_resp_data <= {{(CTRLPORT_DATA_W - DB_DIVIDER_SIZE){1'b0}}, db_divider_reg};
        end

        // error on undefined address
        default: begin
          s_ctrlport_resp_data <= {32{1'bx}};
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
// Versioning
//----------------------------------------------------------

// Version metadata, constants come from auto-generated versioning_regs_regmap_utils.vh
assign version_info = build_component_versions(
  CPLD_IFC_VERSION_LAST_MODIFIED_TIME,
  build_version(
    CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR,
    CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MINOR,
    CPLD_IFC_OLDEST_COMPATIBLE_VERSION_BUILD),
  build_version(
    CPLD_IFC_CURRENT_VERSION_MAJOR,
    CPLD_IFC_CURRENT_VERSION_MINOR,
    CPLD_IFC_CURRENT_VERSION_BUILD));

endmodule

/////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: x4xx_dio
//
// Description:
//
//   This module contains the motherboard registers for the DIO
//   auxiliary board and the logic to drive these GPIO signals.
//
/////////////////////////////////////////////////////////////////////

//XmlParse xml_on
//<regmap name="DIO_REGMAP" readablestrobes="false" ettusguidelines="true">
//  <group name="DIO_REGS">
//    <info>
//      Registers to control the GPIO buffer direction on the FPGA connected to the DIO board.
//      Further registers enable the PS to control and read the GPIO lines as master.
//      Make sure the GPIO lines between FPGA and GPIO board are not driven by two drivers.
//      Set the DIO registers in @.PS_CPLD_BASE_REGMAP appropriately.
//    </info>
//
//    <register name="DIO_MASTER_REGISTER" offset="0x00" size="32">
//      <info>
//        Sets whether the DIO signal line is driven by this register interface or the user application.{br/}
//        0 = user application is master, 1 = PS is master
//      </info>
//      <bitfield name="DIO_MASTER_A" range="0..11" initialvalue="0"/>
//      <bitfield name="DIO_MASTER_B" range="16..27" initialvalue="0"/>
//    </register>
//    <register name="DIO_DIRECTION_REGISTER" offset="0x04" size="32">
//      <info>
//        Set the direction of FPGA buffer connected to DIO ports on the DIO board.{br/}
//        Each bit represents one signal line. 0 = line is an input to the FPGA, 1 = line is an output driven by the FPGA.
//      </info>
//      <bitfield name="DIO_DIRECTION_A" range="0..11" initialvalue="0"/>
//      <bitfield name="DIO_DIRECTION_B" range="16..27" initialvalue="0"/>
//    </register>
//    <register name="DIO_INPUT_REGISTER" offset="0x08" size="32" writable="false">
//      <info>
//        Status of each bit at the FPGA input.
//      </info>
//      <bitfield name="DIO_INPUT_A" range="0..11"/>
//      <bitfield name="DIO_INPUT_B" range="16..27"/>
//    </register>
//    <register name="DIO_OUTPUT_REGISTER" offset="0x0C" size="32">
//      <info>
//        Controls the values on each DIO signal line in case the line master is set to PS in @.DIO_MASTER_REGISTER.
//      </info>
//      <bitfield name="DIO_OUTPUT_A" range="0..11" initialvalue="0"/>
//      <bitfield name="DIO_OUTPUT_B" range="16..27" initialvalue="0"/>
//    </register>
//  </group>
//</regmap>
//XmlParse xml_off

module x4xx_dio #(
  parameter REG_BASE = 0 // Registers' base
) (

  // Slave ctrlport interface
  input             ctrlport_clk,
  input             ctrlport_rst,
  input             s_ctrlport_req_wr,
  input             s_ctrlport_req_rd,
  input      [19:0] s_ctrlport_req_addr,
  input      [31:0] s_ctrlport_req_data,
  output reg        s_ctrlport_resp_ack = 1'b0,
  output reg [31:0] s_ctrlport_resp_data = {32 {1'b0}},

  // GPIO to DIO board (ctrlport_clk)
  output wire [11:0] gpio_en_a,
  output wire [11:0] gpio_en_b,
  // GPIO to DIO board (async)
  input  wire [11:0] gpio_in_a,
  input  wire [11:0] gpio_in_b,
  output wire [11:0] gpio_out_a,
  output wire [11:0] gpio_out_b,

  // GPIO to application (async)
  output wire [11:0] gpio_in_fabric_a,
  output wire [11:0] gpio_in_fabric_b,
  input  wire [11:0] gpio_out_fabric_a,
  input  wire [11:0] gpio_out_fabric_b
);

`include "../../lib/rfnoc/core/ctrlport.vh"
`include "regmap/dio_regmap_utils.vh"

//--------------------------------------------------------------------
// Constants
// -------------------------------------------------------------------
localparam DIO_WIDTH = 12;

//--------------------------------------------------------------------
// DIO Registers
// -------------------------------------------------------------------
reg  [DIO_WIDTH-1:0] dio_direction_a = 0;
reg  [DIO_WIDTH-1:0] dio_direction_b = 0;
reg  [DIO_WIDTH-1:0] dio_master_a    = 0;
reg  [DIO_WIDTH-1:0] dio_master_b    = 0;
reg  [DIO_WIDTH-1:0] dio_output_a    = 0;
reg  [DIO_WIDTH-1:0] dio_output_b    = 0;
wire [DIO_WIDTH-1:0] dio_input_a;
wire [DIO_WIDTH-1:0] dio_input_b;

//--------------------------------------------------------------------
// Control interface handling
// -------------------------------------------------------------------
always @ (posedge ctrlport_clk) begin
  if (ctrlport_rst) begin
    s_ctrlport_resp_ack <= 1'b0;

    dio_direction_a <= 0;
    dio_direction_b <= 0;
    dio_master_a    <= 0;
    dio_master_b    <= 0;
    dio_output_a    <= 0;
    dio_output_b    <= 0;

  end else begin
    // Write registers
    if (s_ctrlport_req_wr) begin
      // Acknowledge by default
      s_ctrlport_resp_ack  <= 1'b1;
      s_ctrlport_resp_data <= {CTRLPORT_DATA_W {1'b0}};

      case (s_ctrlport_req_addr)
        REG_BASE + DIO_MASTER_REGISTER: begin
          dio_master_a <= s_ctrlport_req_data[DIO_MASTER_A_MSB:DIO_MASTER_A];
          dio_master_b <= s_ctrlport_req_data[DIO_MASTER_B_MSB:DIO_MASTER_B];
        end

        REG_BASE + DIO_DIRECTION_REGISTER: begin
          dio_direction_a <= s_ctrlport_req_data[DIO_DIRECTION_A_MSB:DIO_DIRECTION_A];
          dio_direction_b <= s_ctrlport_req_data[DIO_DIRECTION_B_MSB:DIO_DIRECTION_B];
        end

        REG_BASE + DIO_OUTPUT_REGISTER: begin
          dio_output_a <= s_ctrlport_req_data[DIO_OUTPUT_A_MSB:DIO_OUTPUT_A];
          dio_output_b <= s_ctrlport_req_data[DIO_OUTPUT_B_MSB:DIO_OUTPUT_B];
        end

        // Do not acknowledge if address is not defined
        default: begin
          s_ctrlport_resp_ack <= 1'b0;
        end
      endcase

    // Read registers
    end else if (s_ctrlport_req_rd) begin
      // Acknowledge by default
      s_ctrlport_resp_ack  <= 1'b1;
      s_ctrlport_resp_data <= {CTRLPORT_DATA_W {1'b0}};

      case (s_ctrlport_req_addr)
        REG_BASE + DIO_MASTER_REGISTER: begin
          s_ctrlport_resp_data[DIO_MASTER_A_MSB:DIO_MASTER_A] <= dio_master_a;
          s_ctrlport_resp_data[DIO_MASTER_B_MSB:DIO_MASTER_B] <= dio_master_b;
        end

        REG_BASE + DIO_DIRECTION_REGISTER: begin
          s_ctrlport_resp_data[DIO_DIRECTION_A_MSB:DIO_DIRECTION_A] <= dio_direction_a;
          s_ctrlport_resp_data[DIO_DIRECTION_B_MSB:DIO_DIRECTION_B] <= dio_direction_b;
        end

        REG_BASE + DIO_OUTPUT_REGISTER: begin
          s_ctrlport_resp_data[DIO_OUTPUT_A_MSB:DIO_OUTPUT_A] <= dio_output_a;
          s_ctrlport_resp_data[DIO_OUTPUT_B_MSB:DIO_OUTPUT_B] <= dio_output_b;
        end

        REG_BASE + DIO_INPUT_REGISTER: begin
          s_ctrlport_resp_data[DIO_INPUT_A_MSB:DIO_INPUT_A] <= dio_input_a;
          s_ctrlport_resp_data[DIO_INPUT_B_MSB:DIO_INPUT_B] <= dio_input_b;
        end

        // Do not acknowledge if address is not defined
        default: begin
          s_ctrlport_resp_ack <= 1'b0;
        end
      endcase

    end else begin
      s_ctrlport_resp_ack <= 1'b0;
    end
  end
end

//----------------------------------------------------------
// DIO handling
//----------------------------------------------------------
// Synchronizer for asynchronous inputs.
// Downstream user logic has to ensure bus coherency if required.
//vhook synchronizer dio_sync_inst
//vhook_a WIDTH DIO_WIDTH*2
//vhook_a STAGES 2
//vhook_a INITIAL_VAL \{DIO_WIDTH*2 \{1'b0\}\}
//vhook_a FALSE_PATH_TO_IN 1
//vhook_a clk ctrlport_clk
//vhook_a rst ctrlport_rst
//vhook_a in \{gpio_in_a, gpio_in_b\}
//vhook_a out \{dio_input_a, dio_input_b\}
synchronizer
  # (
    .WIDTH             (DIO_WIDTH*2),       //integer:=1
    .STAGES            (2),                 //integer:=2
    .INITIAL_VAL       ({DIO_WIDTH*2 {1'b0}}), //integer:=0
    .FALSE_PATH_TO_IN  (1))                 //integer:=1
  dio_sync_inst (
    .clk  (ctrlport_clk),                 //in  wire
    .rst  (ctrlport_rst),                 //in  wire
    .in   ({gpio_in_a, gpio_in_b}),       //in  wire[(WIDTH-1):0]
    .out  ({dio_input_a, dio_input_b}));  //out wire[(WIDTH-1):0]

// forward raw input to user application
assign gpio_in_fabric_a = gpio_in_a;
assign gpio_in_fabric_b = gpio_in_b;

// direction control
assign gpio_en_a = dio_direction_a;
assign gpio_en_b = dio_direction_b;

// output assignment depending on master
generate
  genvar i;
  for (i = 0; i < DIO_WIDTH; i = i + 1) begin: dio_output_gen
    //vhook glitch_free_mux dio_a_mux
    //vhook_a select       dio_master_a[i]
    //vhook_a signal0      gpio_out_fabric_a[i]
    //vhook_a signal1      dio_output_a[i]
    //vhook_a muxed_signal gpio_out_a[i]
    glitch_free_mux
      dio_a_mux (
        .select        (dio_master_a[i]),   //in  wire
        .signal0       (gpio_out_fabric_a[i]), //in  wire
        .signal1       (dio_output_a[i]),   //in  wire
        .muxed_signal  (gpio_out_a[i]));    //out wire

    //vhook glitch_free_mux dio_b_mux
    //vhook_a select       dio_master_b[i]
    //vhook_a signal0      gpio_out_fabric_b[i]
    //vhook_a signal1      dio_output_b[i]
    //vhook_a muxed_signal gpio_out_b[i]
    glitch_free_mux
      dio_b_mux (
        .select        (dio_master_b[i]),   //in  wire
        .signal0       (gpio_out_fabric_b[i]), //in  wire
        .signal1       (dio_output_b[i]),   //in  wire
        .muxed_signal  (gpio_out_b[i]));    //out wire
  end
endgenerate

endmodule

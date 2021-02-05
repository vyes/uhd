//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: reset_generator
// Description:
// Generate a 1-bit synchronous signal (initialize) to safely initialize
// the rPwrOnRstCounter incremental counter to 0's.
// A delayed version of the initializing signal is also generated
// (counter_enable) to start counting.
//
//                 1_  2_  3_  4_  5_  6_  7_  8_  9_
//           clk  _| |_| |_| |_| |_| |_| |_| |_| |_|
//                              _____________________
//     initialize _____________|
//                                          _________
// counter_enable _________________________|
//

module reset_generator(
  input  wire clk,
  output reg  power_on_reset = 1'b1
);

//vhook_sigstart
  wire [0:0] counter_enable;
  wire [0:0] initialize;
//vhook_sigend

//vhook_e synchronizer init_sync_inst
//vhook_a WIDTH 1
//vhook_a STAGES 3
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 0
//vhook_a rst 1'b0
//vhook_a in 1'b1
//vhook_a out initialize
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (3),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (0))   //integer:=1
  init_sync_inst (
    .clk  (clk),          //in  wire
    .rst  (1'b0),         //in  wire
    .in   (1'b1),         //in  wire[(WIDTH-1):0]
    .out  (initialize));  //out wire[(WIDTH-1):0]

//vhook_e synchronizer counter_en_sync_inst
//vhook_a WIDTH 1
//vhook_a STAGES 3
//vhook_a INITIAL_VAL 1'b0
//vhook_a FALSE_PATH_TO_IN 0
//vhook_a rst 1'b0
//vhook_a in initialize
//vhook_a out counter_enable
synchronizer
  # (
    .WIDTH             (1),   //integer:=1
    .STAGES            (3),   //integer:=2
    .INITIAL_VAL       (1'b0), //integer:=0
    .FALSE_PATH_TO_IN  (0))   //integer:=1
  counter_en_sync_inst (
    .clk  (clk),              //in  wire
    .rst  (1'b0),             //in  wire
    .in   (initialize),       //in  wire[(WIDTH-1):0]
    .out  (counter_enable));  //out wire[(WIDTH-1):0]


// Internal synchronous reset generator.
localparam CYCLES_IN_RESET = 20;
reg [7:0] power_on_reset_counter = 8'b0;

// This block generates a synchronous reset in the ReliableClk domain
// that can be used by downstream logic.
// power_on_reset_counter is first initialized to 0's upon assertion of
// initialize. Some cycles later (3), upon assertion if counter_enable,
// power_on_reset_counter starts to increment.
// power_on_reset will remain asserted until power_on_reset_counter reaches
// cycles_in_reset, resulting in the deassertion of power_on_reset.
always @(posedge clk) begin : power_on_reset_gen
  if (counter_enable) begin
    if (power_on_reset_counter == CYCLES_IN_RESET-1) begin
      //vhook_nowarn id=Misc11 msg={power_on_reset}
      power_on_reset <= 1'b0;
    end else begin
      power_on_reset_counter <= power_on_reset_counter + 1'b1;
      power_on_reset <= 1'b1;
    end
  end
  else if (initialize) begin
    power_on_reset_counter <= 0;
    power_on_reset <= 1'b1;
  end
end

endmodule
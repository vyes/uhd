/////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Ettus Research, A National Instruments Brand
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: sync_wrapper.v
//
// Purpose:
//
// As the original synchronizer component has port signal names that
// are incompatible with VHDL(in, out), this modules provides an
// an interface to instantiate the synchronizer block in VHDL.
//
//////////////////////////////////////////////////////////////////////

module sync_wrapper #(
   parameter WIDTH            = 1,
   parameter STAGES           = 2,
   parameter INITIAL_VAL      = 0,
   parameter FALSE_PATH_TO_IN = 1
)(
   input              clk,
   input              rst,
   input  [WIDTH-1:0] signal_in,
   output [WIDTH-1:0] signal_out
);

//vhook_e synchronizer
//vhook_a in    signal_in
//vhook_a out   signal_out
synchronizer
  # (
    .WIDTH             (WIDTH),              //integer:=1
    .STAGES            (STAGES),             //integer:=2
    .INITIAL_VAL       (INITIAL_VAL),        //integer:=0
    .FALSE_PATH_TO_IN  (FALSE_PATH_TO_IN))   //integer:=1
  synchronizerx (
    .clk  (clk),          //in  wire
    .rst  (rst),          //in  wire
    .in   (signal_in),    //in  wire[(WIDTH-1):0]
    .out  (signal_out));  //out wire[(WIDTH-1):0]

endmodule   //sync_wrapper

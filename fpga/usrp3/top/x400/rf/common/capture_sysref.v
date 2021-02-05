/////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Ettus Research, A National Instruments Brand
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: capture_sysref.v
//
// Purpose:
//
// Capture SYSREF and transfer it to the higher clock domain. Module incurs
// 2 pll_ref_clk cycles + 1 rfdc_clk cycle of delay.
//
//////////////////////////////////////////////////////////////////////

module capture_sysref (
  input  wire pll_ref_clk,
  input  wire rfdc_clk,
  // Single-ended SYSREF (previously buffered)
  input  wire sysref_in,
  input  wire enable_rclk, // enables SYSREF output in the rfdc_clk domain
  output wire sysref_out_pclk, // Debug output on the pll_ref_clk
  output wire sysref_out_rclk  // Output for the rfdc
  );

  reg sysref_pclk_ms = 1'b0, sysref_pclk = 1'b0, sysref_rclk = 1'b0;

  // Capture SYSREF synchronously with the pll_ref_clk, but double-sync it just in
  // case static timing isn't met so as not to destroy downstream logic.
  always @ (posedge pll_ref_clk) begin
    sysref_pclk_ms <= sysref_in;
    sysref_pclk    <= sysref_pclk_ms;
  end

  assign sysref_out_pclk = sysref_pclk;

  // Transfer to faster clock which is edge-aligned with the pll_ref_clk.
  always @ (posedge rfdc_clk) begin
    if (enable_rclk) begin
      sysref_rclk <= sysref_pclk;
    end else begin
      sysref_rclk <= 1'b0;
    end
  end

  assign sysref_out_rclk = sysref_rclk;

endmodule

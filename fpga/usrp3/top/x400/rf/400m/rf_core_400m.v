/////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Ettus Research, A National Instruments Brand
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: rf_core_400m.v
//
// Purpose:
//
// Top-level wrapper for the ADC/DAC processing logic. One
// of these wrappers exists for every supported Data Rate.
// An instance of this core should exist per dboard.
//
// Data/RF Specs:
//   DBs:   1
//   RX/DB: 2
//   TX/DB: 2
//   Data Rate: 122.88 or 125 MSps @ 4 SPC
//
// Input Clocks, all aligned to one another and coming from same MMCM
//   rfdc_clk:    184.32 or 187.5 MHz (3x pll_ref_clk)
//   rfdc_clk_2x: 368.64 or 375 MHz (6x pll_ref_clk)
//   data_clk:    122.88 or 125 MHz (2x pll_ref_clk)
//   data_clk_2x: 245.76 or 250 MHz (4x pll_ref_clk)
//
//////////////////////////////////////////////////////////////////////

//XmlParse xml_on
//<regmap name="VERSIONING_REGS_REGMAP">
//  <group name="VERSIONING_CONSTANTS">
//    <enumeratedtype name="RF_CORE_400M_VERSION" showhex="true">
//      <info>
//        400 MHz RF core.{BR/}
//        For guidance on when to update these revision numbers,
//        please refer to the register map documentation accordingly:
//        <li> Current version: @.VERSIONING_REGS_REGMAP..CURRENT_VERSION
//        <li> Oldest compatible version: @.VERSIONING_REGS_REGMAP..OLDEST_COMPATIBLE_VERSION
//        <li> Version last modified: @.VERSIONING_REGS_REGMAP..VERSION_LAST_MODIFIED
//      </info>
//      <value name="RF_CORE_400M_CURRENT_VERSION_MAJOR"           integer="1"/>
//      <value name="RF_CORE_400M_CURRENT_VERSION_MINOR"           integer="0"/>
//      <value name="RF_CORE_400M_CURRENT_VERSION_BUILD"           integer="0"/>
//      <value name="RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MAJOR" integer="1"/>
//      <value name="RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MINOR" integer="0"/>
//      <value name="RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_BUILD" integer="0"/>
//      <value name="RF_CORE_400M_VERSION_LAST_MODIFIED_TIME"      integer="0x20102617"/>
//    </enumeratedtype>
//  </group>
//</regmap>
//XmlParse xml_off

module rf_core_400m (

  // Clocking ///////////////////////////////////////////////////////////////////////////
  // Main Clock Inputs
  input  wire rfdc_clk,
  input  wire rfdc_clk_2x,
  input  wire data_clk,
  input  wire data_clk_2x,

  // AXI4-Lite Config Clock
  // This clock is used to synchronize status bits for the RFDC
  // registers in the AXI-S clock domain.
  input  wire s_axi_config_clk,


  // RFDC Data Interfaces ///////////////////////////////////////////////////////////////
  // all ports here are in the rfdc_clk domain
  // ADC
  input  wire [127:0] adc_data_in_i_tdata_0,
  output wire        adc_data_in_i_tready_0,
  input  wire        adc_data_in_i_tvalid_0,
  input  wire [127:0] adc_data_in_q_tdata_0,
  output wire        adc_data_in_q_tready_0,
  input  wire        adc_data_in_q_tvalid_0,
  input  wire [127:0] adc_data_in_i_tdata_1,
  output wire        adc_data_in_i_tready_1,
  input  wire        adc_data_in_i_tvalid_1,
  input  wire [127:0] adc_data_in_q_tdata_1,
  output wire        adc_data_in_q_tready_1,
  input  wire        adc_data_in_q_tvalid_1,

  // DAC
  output wire [255:0] dac_data_out_tdata_0,
  input  wire        dac_data_out_tready_0,
  output wire        dac_data_out_tvalid_0,
  output wire [255:0] dac_data_out_tdata_1,
  input  wire        dac_data_out_tready_1,
  output wire        dac_data_out_tvalid_1,


  // User Data Interfaces ///////////////////////////////////////////////////////////////
  // all ports here are in the data_clk domain
  // ADC
  output wire [127:0] adc_data_out_tdata_0,  // Packed [Q3,I3, ... , Q0,I0] with Q in MSBs
  output wire        adc_data_out_tvalid_0,
  output wire [127:0] adc_data_out_tdata_1,  // Packed [Q3,I3, ... , Q0,I0] with Q in MSBs
  output wire        adc_data_out_tvalid_1,

  // DAC
  input  wire [127:0] dac_data_in_tdata_0,  // Packed [Q3,I3, ... , Q0,I0] with Q in MSBs
  output wire        dac_data_in_tready_0,
  input  wire        dac_data_in_tvalid_0,
  input  wire [127:0] dac_data_in_tdata_1,  // Packed [Q3,I3, ... , Q0,I0] with Q in MSBs
  output wire        dac_data_in_tready_1,
  input  wire        dac_data_in_tvalid_1,

  // Misc. //////////////////////////////////////////////////////////////////////////////

  // Invert I/Q control signals from RFDC to DSP chain.
  input  wire [3:0] invert_adc_iq_rclk2,
  input  wire [3:0] invert_dac_iq_rclk2,

  // Control/status vectors from/to RFDC.
  // Notice these are all in the s_axi_config_clk domain.
  output wire [15:0] dsp_info_sclk,
  output wire [15:0] axi_status_sclk,

  input wire adc_data_out_resetn_dclk,
  input wire adc_enable_data_rclk,
  input wire adc_rfdc_axi_resetn_rclk,
  input wire dac_data_in_resetn_dclk,
  input wire dac_data_in_resetn_dclk2x,
  input wire dac_data_in_resetn_rclk,
  input wire fir_resetn_rclk2x,

  // Versioning (Constant)
  output wire [95:0] version_info

);

  `include "../../regmap/rfdc_regs_regmap_utils.vh"
  `include "../../regmap/versioning_regs_regmap_utils.vh"
  `include "../../regmap/versioning_utils.vh"

  // Fixed for this implementation
  localparam NUM_ADC_CHANNELS = 2;
  localparam NUM_DAC_CHANNELS = 2;

  // ADC data interface from RFDC.
  wire [127:0] adc_data_in_i_tdata       [0:7]; // 8 SPC (I)
  wire [127:0] adc_data_in_q_tdata       [0:7]; // 8 SPC (Q)
  wire [7:0]  adc_data_in_i_tready;
  wire [7:0]  adc_data_in_q_tready;
  wire [7:0]  adc_data_in_i_tvalid;
  wire [7:0]  adc_data_in_q_tvalid;
  // DAC data interface to RFDC.
  wire [255:0] dac_data_out_tdata        [0:7]; // 8 SPC (I + Q)
  wire [7:0]  dac_data_out_tready;
  wire [7:0]  dac_data_out_tvalid;

  // ADC data interface to user.
  wire [127:0] adc_data_out_tdata        [0:7]; // 4 SPC (I + Q)
  wire [7:0]  adc_data_out_tready;
  wire [7:0]  adc_data_out_tvalid;
  // DAC data interface from user.
  wire [127:0] dac_data_in_tdata_preswap [0:7]; // 4 SPC (I + Q)
  wire [127:0] dac_data_in_tdata         [0:7]; // 4 SPC (I + Q)
  wire [7:0]  dac_data_in_tready;
  wire [7:0]  dac_data_in_tvalid;

  wire [7:0] invert_dac_iq_dclk;
  wire [15:0] axi_status;

  //vhook_sigstart
  //vhook_sigend


  // Resets and DEBUG : -----------------------------------------------------------------
  // ------------------------------------------------------------------------------------

  // Group all these status bits together. They don't toggle frequently so
  // data coherency is not an issue here.
  // Using constants for DB0 since the bits are the 16 LSBs in a 32-bit vector.
  // DB1 simply uses the 16 MSBs when wiring the status vector.
  assign axi_status[USER_ADC_TREADY_MSB  :USER_ADC_TREADY  ] = adc_data_out_tready[1:0];
  assign axi_status[USER_ADC_TVALID_MSB  :USER_ADC_TVALID  ] = adc_data_out_tvalid[1:0];
  assign axi_status[RFDC_ADC_I_TVALID_MSB:RFDC_ADC_I_TVALID] = adc_data_in_i_tvalid[1:0];
  assign axi_status[RFDC_ADC_Q_TVALID_MSB:RFDC_ADC_Q_TVALID] = adc_data_in_q_tvalid[1:0];
  assign axi_status[RFDC_ADC_I_TREADY_MSB:RFDC_ADC_I_TREADY] = adc_data_in_i_tready[1:0];
  assign axi_status[RFDC_ADC_Q_TREADY_MSB:RFDC_ADC_Q_TREADY] = adc_data_in_q_tready[1:0];
  assign axi_status[RFDC_DAC_TVALID_MSB  :RFDC_DAC_TVALID  ] = dac_data_out_tvalid[1:0];
  assign axi_status[RFDC_DAC_TREADY_MSB  :RFDC_DAC_TREADY  ] = dac_data_out_tready[1:0];

  //vhook synchronizer axis_status_sync
  //vhook_g WIDTH 16
  //vhook_g STAGES 2
  //vhook_g INITIAL_VAL 0
  //vhook_g FALSE_PATH_TO_IN 1
  //vhook_a clk s_axi_config_clk
  //vhook_a rst 1'b0
  //vhook_a in  axi_status
  //vhook_a out axi_status_sclk
  synchronizer
    # (
      .WIDTH             (16),  //integer:=1
      .STAGES            (2),   //integer:=2
      .INITIAL_VAL       (0),   //integer:=0
      .FALSE_PATH_TO_IN  (1))   //integer:=1
    axis_status_sync (
      .clk  (s_axi_config_clk),   //in  wire
      .rst  (1'b0),               //in  wire
      .in   (axi_status),         //in  wire[(WIDTH-1):0]
      .out  (axi_status_sclk));   //out wire[(WIDTH-1):0]

  // Drive the DSP info vector with information on this specific DSP chain.
  assign dsp_info_sclk[FABRIC_DSP_BW_MSB    :FABRIC_DSP_BW]     = FABRIC_DSP_BW_400M;
  assign dsp_info_sclk[FABRIC_DSP_RX_CNT_MSB:FABRIC_DSP_RX_CNT] = NUM_ADC_CHANNELS;
  assign dsp_info_sclk[FABRIC_DSP_TX_CNT_MSB:FABRIC_DSP_TX_CNT] = NUM_DAC_CHANNELS;

  // ADC Post-Processing : --------------------------------------------------------------
  // ------------------------------------------------------------------------------------

  // Data comes from the RFDC... as 8 SPC, separate streams for each channel and I/Q.
  assign adc_data_in_i_tdata[0]  = adc_data_in_i_tdata_0;
  assign adc_data_in_q_tdata[0]  = adc_data_in_q_tdata_0;
  assign adc_data_in_i_tdata[1]  = adc_data_in_i_tdata_1;
  assign adc_data_in_q_tdata[1]  = adc_data_in_q_tdata_1;

  assign adc_data_in_i_tready_0  = adc_data_in_i_tready[0];
  assign adc_data_in_i_tvalid[0] = adc_data_in_i_tvalid_0;
  assign adc_data_in_q_tready_0  = adc_data_in_q_tready[0];
  assign adc_data_in_q_tvalid[0] = adc_data_in_q_tvalid_0;
  assign adc_data_in_i_tready_1  = adc_data_in_i_tready[1];
  assign adc_data_in_i_tvalid[1] = adc_data_in_i_tvalid_1;
  assign adc_data_in_q_tready_1  = adc_data_in_q_tready[1];
  assign adc_data_in_q_tvalid[1] = adc_data_in_q_tvalid_1;

  // ADC Data from the RFDC arrives here as 8 SPC with separate I and Q streams.
  // It leaves the adc_100m_bd as 4 SPC with I and Q packed into a single 128 bit word.
  genvar adc_num;
  generate
  for (adc_num=0; adc_num < (NUM_ADC_CHANNELS); adc_num = adc_num + 1)
    begin : adc_gen
      //vhook   adc_400m_bd adc_400m_bd_gen
      //vhook_a {adc_data_out_t(.*)} adc_data_out_t$1[adc_num]
      //vhook_a {^adc_(.)_data_in_(.*)} adc_data_in_$1_$2[adc_num]
      //vhook_a swap_iq_2x invert_adc_iq_rclk2[adc_num]
      //vhook_a enable_data_to_fir_rclk adc_enable_data_rclk
      //vhook_a rfdc_adc_axi_resetn_rclk adc_rfdc_axi_resetn_rclk
      adc_400m_bd
        adc_400m_bd_gen (
          .adc_data_out_resetn_dclk  (adc_data_out_resetn_dclk),    //in  STD_LOGIC
          .data_clk                  (data_clk),                    //in  STD_LOGIC
          .enable_data_to_fir_rclk   (adc_enable_data_rclk),        //in  STD_LOGIC
          .fir_resetn_rclk2x         (fir_resetn_rclk2x),           //in  STD_LOGIC
          .rfdc_adc_axi_resetn_rclk  (adc_rfdc_axi_resetn_rclk),    //in  STD_LOGIC
          .rfdc_clk                  (rfdc_clk),                    //in  STD_LOGIC
          .rfdc_clk_2x               (rfdc_clk_2x),                 //in  STD_LOGIC
          .swap_iq_2x                (invert_adc_iq_rclk2[adc_num]), //in  STD_LOGIC
          .adc_q_data_in_tvalid      (adc_data_in_q_tvalid[adc_num]), //in  STD_LOGIC
          .adc_q_data_in_tready      (adc_data_in_q_tready[adc_num]), //out STD_LOGIC
          .adc_q_data_in_tdata       (adc_data_in_q_tdata[adc_num]), //in  STD_LOGIC_VECTOR(127:0)
          .adc_i_data_in_tvalid      (adc_data_in_i_tvalid[adc_num]), //in  STD_LOGIC
          .adc_i_data_in_tready      (adc_data_in_i_tready[adc_num]), //out STD_LOGIC
          .adc_i_data_in_tdata       (adc_data_in_i_tdata[adc_num]), //in  STD_LOGIC_VECTOR(127:0)
          .adc_data_out_tvalid       (adc_data_out_tvalid[adc_num]), //out STD_LOGIC
          .adc_data_out_tdata        (adc_data_out_tdata[adc_num]));//out STD_LOGIC_VECTOR(127:0)
      //vhook_nowarn rf_core_400m.adc_data_out_t*
      //vhook_nowarn rf_core_400m.adc_tile_dout_*_t*
      //vhook_nowarn rf_core_400m.invert_adc_iq_rclk2
    end
  endgenerate

  // Data is released to the user... as 4 SPC, separate streams for each channel.
  assign adc_data_out_tdata_0 = adc_data_out_tdata[0];
  assign adc_data_out_tdata_1 = adc_data_out_tdata[1];

  // There is no tready going to the ADC (one has to be always ready for ADC data), but
  // it is still a component of the axi_status vector as a generic AXI stream status.
  // Report 1'b1 to the status vector consistent with being always ready
  assign adc_data_out_tready[0] = 1'b1;
  assign adc_data_out_tvalid_0  = adc_data_out_tvalid[0];
  assign adc_data_out_tready[1] = 1'b1;
  assign adc_data_out_tvalid_1  = adc_data_out_tvalid[1];


  // DAC Pre-Processing : ---------------------------------------------------------------
  // ------------------------------------------------------------------------------------

  // Data comes from the user... as 4 SPC, separate streams for each channel.
  assign dac_data_in_tdata_preswap[0] = dac_data_in_tdata_0;
  assign dac_data_in_tdata_preswap[1] = dac_data_in_tdata_1;

  assign dac_data_in_tready_0  = dac_data_in_tready[0];
  assign dac_data_in_tvalid[0] = dac_data_in_tvalid_0;
  assign dac_data_in_tready_1  = dac_data_in_tready[1];
  assign dac_data_in_tvalid[1] = dac_data_in_tvalid_1;

  // Optionally swap IQ data positions in the vector. First cross the swap vector over
  // to the data_clk domain.
  // vhook synchronizer invert_dac_iq_sync
  // vhook_g WIDTH 8
  // vhook_g STAGES 2
  // vhook_g INITIAL_VAL 0
  // vhook_g FALSE_PATH_TO_IN 1
  // vhook_a clk data_clk
  // vhook_a rst 1'b0
  // vhook_a in  invert_dac_iq_rclk2
  // vhook_a out invert_dac_iq_dclk
  synchronizer
    # (
      .WIDTH             (8),   //integer:=1
      .STAGES            (2),   //integer:=2
      .INITIAL_VAL       (0),   //integer:=0
      .FALSE_PATH_TO_IN  (1))   //integer:=1
    invert_dac_iq_sync (
      .clk  (data_clk),             //in  wire
      .rst  (1'b0),                 //in  wire
      .in   (invert_dac_iq_rclk2),  //in  wire[(WIDTH-1):0]
      .out  (invert_dac_iq_dclk));  //out wire[(WIDTH-1):0]

  genvar dac_num;
  generate
  for (dac_num=0; dac_num < (NUM_DAC_CHANNELS); dac_num = dac_num + 1)
    begin : dac_swap_gen
      //IO and Q0 swap
      assign dac_data_in_tdata[dac_num][15:00] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][31:16]) : (dac_data_in_tdata_preswap[dac_num][15:0]);
      assign dac_data_in_tdata[dac_num][31:16] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][15:00]) : (dac_data_in_tdata_preswap[dac_num][31:16]);

      //I1 and Q1 swap
      assign dac_data_in_tdata[dac_num][47:32] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][63:48]) : (dac_data_in_tdata_preswap[dac_num][47:32]);
      assign dac_data_in_tdata[dac_num][63:48] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][47:32]) : (dac_data_in_tdata_preswap[dac_num][63:48]);

      //I2 and Q2 swap
      assign dac_data_in_tdata[dac_num][79:64] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][95:80]) : (dac_data_in_tdata_preswap[dac_num][79:64]);
      assign dac_data_in_tdata[dac_num][95:80] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][79:64]) : (dac_data_in_tdata_preswap[dac_num][95:80]);

      //I3 and Q3 swap
      assign dac_data_in_tdata[dac_num][111:96] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][127:112]) : (dac_data_in_tdata_preswap[dac_num][111:96]);
      assign dac_data_in_tdata[dac_num][127:112] = invert_dac_iq_dclk[dac_num] ?
        (dac_data_in_tdata_preswap[dac_num][111:96]) : (dac_data_in_tdata_preswap[dac_num][127:112]);

    end
  endgenerate

  // These streams are then interpolated by dac_400m_bd, and form a single stream per
  // channel, 8 SPC, packed: msb [Sample7Q, Sample7I, ... , Sample0Q, Sample0I] lsb
  generate
  for (dac_num=0; dac_num < (NUM_DAC_CHANNELS); dac_num = dac_num + 1)
    begin : dac_gen
      //vhook   dac_400m_bd dac_400m_bd_gen
      //vhook_a {dac_data_in_t(.*)} dac_data_in_t$1[dac_num]
      //vhook_a {^dac_data_out_(.*)} dac_data_out_$1[dac_num]
      dac_400m_bd
        dac_400m_bd_gen (
          .dac_data_in_resetn_dclk    (dac_data_in_resetn_dclk),     //in  STD_LOGIC
          .dac_data_in_resetn_dclk2x  (dac_data_in_resetn_dclk2x),   //in  STD_LOGIC
          .dac_data_in_resetn_rclk    (dac_data_in_resetn_rclk),     //in  STD_LOGIC
          .dac_data_in_tdata          (dac_data_in_tdata[dac_num]),  //in  STD_LOGIC_VECTOR(127:0)
          .dac_data_in_tready         (dac_data_in_tready[dac_num]), //out STD_LOGIC
          .dac_data_in_tvalid         (dac_data_in_tvalid[dac_num]), //in  STD_LOGIC
          .dac_data_out_tdata         (dac_data_out_tdata[dac_num]), //out STD_LOGIC_VECTOR(255:0)
          .dac_data_out_tready        (dac_data_out_tready[dac_num]), //in  STD_LOGIC
          .dac_data_out_tvalid        (dac_data_out_tvalid[dac_num]), //out STD_LOGIC
          .data_clk                   (data_clk),                    //in  STD_LOGIC
          .data_clk_2x                (data_clk_2x),                 //in  STD_LOGIC
          .rfdc_clk                   (rfdc_clk));                   //in  STD_LOGIC
      //vhook_nowarn rf_core_400m.dac_tile_din_t*
    end
  endgenerate

  // Data is released to the RFDC... as 8 SPC, separate streams per channel (I/Q together)
  assign dac_data_out_tdata_0 = dac_data_out_tdata[0];
  assign dac_data_out_tdata_1 = dac_data_out_tdata[1];

  assign dac_data_out_tready[0] = dac_data_out_tready_0;
  assign dac_data_out_tvalid_0  = dac_data_out_tvalid[0];
  assign dac_data_out_tready[1] = dac_data_out_tready_1;
  assign dac_data_out_tvalid_1  = dac_data_out_tvalid[1];


  // Versioning : -----------------------------------------------------------------------
  // ------------------------------------------------------------------------------------

  // Version metadata, constants come from auto-generated versioning_regs_regmap_utils.vh
  assign version_info = build_component_versions(
    RF_CORE_400M_VERSION_LAST_MODIFIED_TIME,
    build_version(
      RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MAJOR,
      RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MINOR,
      RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_BUILD),
    build_version(
      RF_CORE_400M_CURRENT_VERSION_MAJOR,
      RF_CORE_400M_CURRENT_VERSION_MINOR,
      RF_CORE_400M_CURRENT_VERSION_BUILD));


endmodule

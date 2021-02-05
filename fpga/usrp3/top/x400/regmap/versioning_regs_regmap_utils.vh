//
// Copyright 2021 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: versioning_regs_regmap_utils.vh
// Description:
// The constants in this file are autogenerated by XmlParse.

//===============================================================================
// A numerically ordered list of registers and their HDL source files
//===============================================================================

  // CURRENT_VERSION           : 0x0 (x4xx_versioning_regs.v)
  // OLDEST_COMPATIBLE_VERSION : 0x4 (x4xx_versioning_regs.v)
  // VERSION_LAST_MODIFIED     : 0x8 (x4xx_versioning_regs.v)
  // RESERVED                  : 0xC (x4xx_versioning_regs.v)

//===============================================================================
// RegTypes
//===============================================================================

  // RESERVED_TYPE Type (from x4xx_versioning_regs.v)
  localparam RESERVED_TYPE_SIZE = 32;
  localparam RESERVED_TYPE_MASK = 32'h0;

  // TIMESTAMP_TYPE Type (from x4xx_versioning_regs.v)
  localparam TIMESTAMP_TYPE_SIZE = 32;
  localparam TIMESTAMP_TYPE_MASK = 32'hFFFFFFFF;
  localparam HH_SIZE = 8;  //TIMESTAMP_TYPE:HH
  localparam HH_MSB  = 7;  //TIMESTAMP_TYPE:HH
  localparam HH      = 0;  //TIMESTAMP_TYPE:HH
  localparam DD_SIZE =  8;  //TIMESTAMP_TYPE:DD
  localparam DD_MSB  = 15;  //TIMESTAMP_TYPE:DD
  localparam DD      =  8;  //TIMESTAMP_TYPE:DD
  localparam MM_SIZE =  8;  //TIMESTAMP_TYPE:MM
  localparam MM_MSB  = 23;  //TIMESTAMP_TYPE:MM
  localparam MM      = 16;  //TIMESTAMP_TYPE:MM
  localparam YY_SIZE =  8;  //TIMESTAMP_TYPE:YY
  localparam YY_MSB  = 31;  //TIMESTAMP_TYPE:YY
  localparam YY      = 24;  //TIMESTAMP_TYPE:YY

  // VERSION_TYPE Type (from x4xx_versioning_regs.v)
  localparam VERSION_TYPE_SIZE = 32;
  localparam VERSION_TYPE_MASK = 32'hFFFFFFFF;
  localparam BUILD_SIZE = 12;  //VERSION_TYPE:BUILD
  localparam BUILD_MSB  = 11;  //VERSION_TYPE:BUILD
  localparam BUILD      =  0;  //VERSION_TYPE:BUILD
  localparam MINOR_SIZE = 11;  //VERSION_TYPE:MINOR
  localparam MINOR_MSB  = 22;  //VERSION_TYPE:MINOR
  localparam MINOR      = 12;  //VERSION_TYPE:MINOR
  localparam MAJOR_SIZE =  9;  //VERSION_TYPE:MAJOR
  localparam MAJOR_MSB  = 31;  //VERSION_TYPE:MAJOR
  localparam MAJOR      = 23;  //VERSION_TYPE:MAJOR

//===============================================================================
// Register Group VERSIONING_CONSTANTS
//===============================================================================

  // Enumerated type CPLD_IFC_VERSION
  localparam CPLD_IFC_VERSION_SIZE = 7;
  localparam CPLD_IFC_CURRENT_VERSION_MINOR            = 'h0;  // CPLD_IFC_VERSION:CPLD_IFC_CURRENT_VERSION_MINOR
  localparam CPLD_IFC_CURRENT_VERSION_BUILD            = 'h0;  // CPLD_IFC_VERSION:CPLD_IFC_CURRENT_VERSION_BUILD
  localparam CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MINOR  = 'h0;  // CPLD_IFC_VERSION:CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MINOR
  localparam CPLD_IFC_OLDEST_COMPATIBLE_VERSION_BUILD  = 'h0;  // CPLD_IFC_VERSION:CPLD_IFC_OLDEST_COMPATIBLE_VERSION_BUILD
  localparam CPLD_IFC_CURRENT_VERSION_MAJOR            = 'h2;  // CPLD_IFC_VERSION:CPLD_IFC_CURRENT_VERSION_MAJOR
  localparam CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR  = 'h2;  // CPLD_IFC_VERSION:CPLD_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR
  localparam CPLD_IFC_VERSION_LAST_MODIFIED_TIME       = 'h21011809;  // CPLD_IFC_VERSION:CPLD_IFC_VERSION_LAST_MODIFIED_TIME

  // Enumerated type DB_GPIO_IFC_VERSION
  localparam DB_GPIO_IFC_VERSION_SIZE = 7;
  localparam DB_GPIO_IFC_CURRENT_VERSION_MINOR            = 'h0;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_CURRENT_VERSION_MINOR
  localparam DB_GPIO_IFC_CURRENT_VERSION_BUILD            = 'h0;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_CURRENT_VERSION_BUILD
  localparam DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_MINOR  = 'h0;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_MINOR
  localparam DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_BUILD  = 'h0;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_BUILD
  localparam DB_GPIO_IFC_CURRENT_VERSION_MAJOR            = 'h1;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_CURRENT_VERSION_MAJOR
  localparam DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR  = 'h1;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_OLDEST_COMPATIBLE_VERSION_MAJOR
  localparam DB_GPIO_IFC_VERSION_LAST_MODIFIED_TIME       = 'h20110616;  // DB_GPIO_IFC_VERSION:DB_GPIO_IFC_VERSION_LAST_MODIFIED_TIME

  // Enumerated type FPGA_VERSION
  localparam FPGA_VERSION_SIZE = 7;
  localparam FPGA_CURRENT_VERSION_BUILD            = 'h0;  // FPGA_VERSION:FPGA_CURRENT_VERSION_BUILD
  localparam FPGA_OLDEST_COMPATIBLE_VERSION_MINOR  = 'h0;  // FPGA_VERSION:FPGA_OLDEST_COMPATIBLE_VERSION_MINOR
  localparam FPGA_OLDEST_COMPATIBLE_VERSION_BUILD  = 'h0;  // FPGA_VERSION:FPGA_OLDEST_COMPATIBLE_VERSION_BUILD
  localparam FPGA_CURRENT_VERSION_MINOR            = 'h1;  // FPGA_VERSION:FPGA_CURRENT_VERSION_MINOR
  localparam FPGA_CURRENT_VERSION_MAJOR            = 'h7;  // FPGA_VERSION:FPGA_CURRENT_VERSION_MAJOR
  localparam FPGA_OLDEST_COMPATIBLE_VERSION_MAJOR  = 'h7;  // FPGA_VERSION:FPGA_OLDEST_COMPATIBLE_VERSION_MAJOR
  localparam FPGA_VERSION_LAST_MODIFIED_TIME       = 'h21020314;  // FPGA_VERSION:FPGA_VERSION_LAST_MODIFIED_TIME

  // Enumerated type RF_CORE_100M_VERSION
  localparam RF_CORE_100M_VERSION_SIZE = 7;
  localparam RF_CORE_100M_CURRENT_VERSION_MINOR            = 'h0;  // RF_CORE_100M_VERSION:RF_CORE_100M_CURRENT_VERSION_MINOR
  localparam RF_CORE_100M_CURRENT_VERSION_BUILD            = 'h0;  // RF_CORE_100M_VERSION:RF_CORE_100M_CURRENT_VERSION_BUILD
  localparam RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_MINOR  = 'h0;  // RF_CORE_100M_VERSION:RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_MINOR
  localparam RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_BUILD  = 'h0;  // RF_CORE_100M_VERSION:RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_BUILD
  localparam RF_CORE_100M_CURRENT_VERSION_MAJOR            = 'h1;  // RF_CORE_100M_VERSION:RF_CORE_100M_CURRENT_VERSION_MAJOR
  localparam RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_MAJOR  = 'h1;  // RF_CORE_100M_VERSION:RF_CORE_100M_OLDEST_COMPATIBLE_VERSION_MAJOR
  localparam RF_CORE_100M_VERSION_LAST_MODIFIED_TIME       = 'h20102617;  // RF_CORE_100M_VERSION:RF_CORE_100M_VERSION_LAST_MODIFIED_TIME

  // Enumerated type RF_CORE_400M_VERSION
  localparam RF_CORE_400M_VERSION_SIZE = 7;
  localparam RF_CORE_400M_CURRENT_VERSION_MINOR            = 'h0;  // RF_CORE_400M_VERSION:RF_CORE_400M_CURRENT_VERSION_MINOR
  localparam RF_CORE_400M_CURRENT_VERSION_BUILD            = 'h0;  // RF_CORE_400M_VERSION:RF_CORE_400M_CURRENT_VERSION_BUILD
  localparam RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MINOR  = 'h0;  // RF_CORE_400M_VERSION:RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MINOR
  localparam RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_BUILD  = 'h0;  // RF_CORE_400M_VERSION:RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_BUILD
  localparam RF_CORE_400M_CURRENT_VERSION_MAJOR            = 'h1;  // RF_CORE_400M_VERSION:RF_CORE_400M_CURRENT_VERSION_MAJOR
  localparam RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MAJOR  = 'h1;  // RF_CORE_400M_VERSION:RF_CORE_400M_OLDEST_COMPATIBLE_VERSION_MAJOR
  localparam RF_CORE_400M_VERSION_LAST_MODIFIED_TIME       = 'h20102617;  // RF_CORE_400M_VERSION:RF_CORE_400M_VERSION_LAST_MODIFIED_TIME

//===============================================================================
// Register Group VERSIONING_REGS
//===============================================================================

  // Enumerated type COMPONENTS_INDEXES
  localparam COMPONENTS_INDEXES_SIZE = 6;
  localparam FPGA_VERSION_INDEX  = 'h0;  // COMPONENTS_INDEXES:FPGA_VERSION_INDEX
  localparam CPLD_IFC_INDEX      = 'h1;  // COMPONENTS_INDEXES:CPLD_IFC_INDEX
  localparam DB0_RF_CORE_INDEX   = 'h2;  // COMPONENTS_INDEXES:DB0_RF_CORE_INDEX
  localparam DB1_RF_CORE_INDEX   = 'h3;  // COMPONENTS_INDEXES:DB1_RF_CORE_INDEX
  localparam DB0_GPIO_IFC_INDEX  = 'h4;  // COMPONENTS_INDEXES:DB0_GPIO_IFC_INDEX
  localparam DB1_GPIO_IFC_INDEX  = 'h5;  // COMPONENTS_INDEXES:DB1_GPIO_IFC_INDEX

  // CURRENT_VERSION Register (from x4xx_versioning_regs.v)
  localparam CURRENT_VERSION_COUNT = 64; // Number of elements in array

  // OLDEST_COMPATIBLE_VERSION Register (from x4xx_versioning_regs.v)
  localparam OLDEST_COMPATIBLE_VERSION_COUNT = 64; // Number of elements in array

  // VERSION_LAST_MODIFIED Register (from x4xx_versioning_regs.v)
  localparam VERSION_LAST_MODIFIED_COUNT = 64; // Number of elements in array

  // RESERVED Register (from x4xx_versioning_regs.v)
  localparam RESERVED_COUNT = 64; // Number of elements in array

  // Return the offset of an element of register array CURRENT_VERSION
  function integer CURRENT_VERSION (input integer i);
    CURRENT_VERSION = (i * 'h10) + 'h0;
  endfunction

  // Return the offset of an element of register array OLDEST_COMPATIBLE_VERSION
  function integer OLDEST_COMPATIBLE_VERSION (input integer i);
    OLDEST_COMPATIBLE_VERSION = (i * 'h10) + 'h4;
  endfunction

  // Return the offset of an element of register array VERSION_LAST_MODIFIED
  function integer VERSION_LAST_MODIFIED (input integer i);
    VERSION_LAST_MODIFIED = (i * 'h10) + 'h8;
  endfunction

  // Return the offset of an element of register array RESERVED
  function integer RESERVED (input integer i);
    RESERVED = (i * 'h10) + 'hC;
  endfunction

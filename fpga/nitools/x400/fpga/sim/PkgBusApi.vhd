------------------------------------------------------------------------------------------
--
-- File: PkgBusApi.vhd
-- Author: Rolando Ortega
-- Original Project: The Macallan Next FlexRIO
-- Date: 21 February 2018
--
------------------------------------------------------------------------------------------
-- (c) 2018 Copyright National Instruments Corporation
-- All Rights Reserved
-- National Instruments Internal Information
------------------------------------------------------------------------------------------
--
-- Purpose: Instantiation of PkgGenericBusApi to provide BFM support to test
-- these modules.
------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.PkgNiUtilities.all;

package PkgBusApi is new work.PkgGenericBusApi
  generic map (
    -- We are mostly testing Axi4Lite Ports. We'll make that the default. The secondary
    -- Bus will be SRegPort
    PkgBusModel0  => work.PkgBusModelMbAxi4Lite,
    PkgBusModel1  => work.PkgBusModelUnused,
    PkgBusModel2  => work.PkgBusModelUnused,
    PkgBusModel3  => work.PkgBusModelUnused,
    PkgBusModel4  => work.PkgBusModelUnused,
    PkgBusModel5  => work.PkgBusModelUnused,
    PkgBusModel6  => work.PkgBusModelUnused,
    PkgBusModel7  => work.PkgBusModelUnused,
    PkgBusModel8  => work.PkgBusModelUnused,
    PkgBusModel9  => work.PkgBusModelUnused,
    PkgBusModel10 => work.PkgBusModelUnused,
    PkgBusModel11 => work.PkgBusModelUnused
    );

---------------------------------------------------------------------
--
-- Copyright 2020 Ettus Research, A National Instruments Brand
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: PkgAxisMuxStimulus.vhd
--
-- Purpose:
--
-- This package has a Random_t variable used by AxisMuxStimulus.vhd
--
----------------------------------------------------------------------

library WORK;
  use WORK.PkgNiSim.all;

package PkgAxisMuxStimulus is
  shared variable Random : Random_t;
end package PkgAxisMuxStimulus;

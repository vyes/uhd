#
# Copyright 2020 Ettus Research, A National Instruments Brand
# SPDX-License-Identifier: LGPL-3.0
#
# Pin Definitions for the X4xx Product Family.
# QSFP28 Port 1 (Lane 3).
#

######################################################################
# Pin constraints for the MGTs (QSFP28 ports)
######################################################################

# Bank 128 (Quad X0Y1, Lanes X0Y4-X0Y7)
# Lane 3 (X0Y7)
set_property PACKAGE_PIN R38  [get_ports {QSFP1_3_RX_P}]
set_property PACKAGE_PIN R39  [get_ports {QSFP1_3_RX_N}]

set_property PACKAGE_PIN R33  [get_ports {QSFP1_3_TX_P}]
set_property PACKAGE_PIN R34  [get_ports {QSFP1_3_TX_N}]

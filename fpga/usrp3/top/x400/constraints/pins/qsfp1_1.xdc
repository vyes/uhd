#
# Copyright 2020 Ettus Research, A National Instruments Brand
# SPDX-License-Identifier: LGPL-3.0
#
# Pin Definitions for the X4xx Product Family.
# QSFP28 Port 1 (Lane 1).
#

######################################################################
# Pin constraints for the MGTs (QSFP28 ports)
######################################################################

# Bank 128 (Quad X0Y1, Lanes X0Y4-X0Y7)
# Lane 1 (X0Y5)
set_property PACKAGE_PIN W38  [get_ports {QSFP1_1_RX_P}]
set_property PACKAGE_PIN W39  [get_ports {QSFP1_1_RX_N}]

set_property PACKAGE_PIN V35  [get_ports {QSFP1_1_TX_P}]
set_property PACKAGE_PIN V36  [get_ports {QSFP1_1_TX_N}]

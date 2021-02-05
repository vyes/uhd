#
# Copyright 2020 Ettus Research, A National Instruments Brand
# SPDX-License-Identifier: LGPL-3.0
#
# Pin Definitions for the X4xx Product Family.
# QSFP28 Port 0 (Lane 1).
#

######################################################################
# Pin constraints for the MGTs (QSFP28 ports)
######################################################################

# Bank 131 (Quad X0Y4, Lanes X0Y16-X0Y19)
# Lane 1 (X0Y17)

set_property PACKAGE_PIN D36  [get_ports {QSFP0_1_RX_P}]
set_property PACKAGE_PIN D37  [get_ports {QSFP0_1_RX_N}]

set_property PACKAGE_PIN C33  [get_ports {QSFP0_1_TX_P}]
set_property PACKAGE_PIN C34  [get_ports {QSFP0_1_TX_N}]

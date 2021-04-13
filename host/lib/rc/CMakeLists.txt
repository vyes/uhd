#
# Copyright 2020 Ettus Research, a National Instruments Brand
#
# SPDX-License-Identifier: GPL-3.0-or-later
#

include(CMakeRC)
cmrc_add_resource_library(uhd-resources
    ALIAS uhd_rc
    NAMESPACE rc
# calibration data test file
    cal/test.cal
# mockup calibration data for testing
    cal/x4xx_pwr_mock_tx_0_tx+rx0.cal
    cal/x4xx_pwr_mock_tx_1_tx+rx0.cal
    cal/x4xx_pwr_mock_rx_0_rx1.cal
    cal/x4xx_pwr_mock_rx_1_rx1.cal
# ZBX revB TX calibration data
    cal/x4xx_pwr_4002_tx_0_tx+rx0.cal
    cal/x4xx_pwr_4002_tx_1_tx+rx0.cal
    cal/x4xx_pwr_4002_tx_2_tx+rx0.cal
    cal/x4xx_pwr_4002_tx_3_tx+rx0.cal
# ZBX revC TX calibration data
    cal/x4xx_pwr_4003_tx_0_tx+rx0.cal
    cal/x4xx_pwr_4003_tx_1_tx+rx0.cal
    cal/x4xx_pwr_4003_tx_2_tx+rx0.cal
    cal/x4xx_pwr_4003_tx_3_tx+rx0.cal
# ZBX revB RX calibration data
    cal/x4xx_pwr_4002_rx_0_tx+rx0.cal
    cal/x4xx_pwr_4002_rx_1_tx+rx0.cal
    cal/x4xx_pwr_4002_rx_2_tx+rx0.cal
    cal/x4xx_pwr_4002_rx_3_tx+rx0.cal
    cal/x4xx_pwr_4002_rx_0_rx1.cal
    cal/x4xx_pwr_4002_rx_1_rx1.cal
    cal/x4xx_pwr_4002_rx_2_rx1.cal
    cal/x4xx_pwr_4002_rx_3_rx1.cal
# ZBX revC RX calibration data
    cal/x4xx_pwr_4003_rx_0_tx+rx0.cal
    cal/x4xx_pwr_4003_rx_1_tx+rx0.cal
    cal/x4xx_pwr_4003_rx_2_tx+rx0.cal
    cal/x4xx_pwr_4003_rx_3_tx+rx0.cal
    cal/x4xx_pwr_4003_rx_0_rx1.cal
    cal/x4xx_pwr_4003_rx_1_rx1.cal
    cal/x4xx_pwr_4003_rx_2_rx1.cal
    cal/x4xx_pwr_4003_rx_3_rx1.cal
# ZBX DSA data
    cal/zbx_dsa_tx.cal
    cal/zbx_dsa_rx.cal
)
set_property(TARGET uhd-resources PROPERTY POSITION_INDEPENDENT_CODE ON)

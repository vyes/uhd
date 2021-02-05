#!/bin/bash

VIVADO_VER=2019.1
VIVADO_VER_FULL=2019.1.1_AR73068
DISPLAY_NAME="USRP-X4xx"
REPO_BASE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

declare -A PRODUCT_ID_MAP
PRODUCT_ID_MAP["X410"]="zynquplusRFSOC/xczu28dr/ffvg1517/-1/e"

source $REPO_BASE_PATH/tools/scripts/setupenv_base.sh

#!/bin/bash

export path=""
export path_boot=""
export path_modules=""
export artifacts="./rpi/artifacts/bcm2711-rpi-4b"
export defconfig="./rpi/configs/bcm2711_rpi_4b_defconfig"
export dtb_prefix="broadcom/bcm"
export kernel_src="../linux"

pwd

./kernel/build-aarch-common.sh "bcm2711-rpi-4b" "$CLEAN" no-install-modules

#!/bin/bash

export path=""
export path_boot=""
export path_modules=""
export artifacts="./rpi/artifacts/bcm2837-rpi-3bp"
export defconfig="./rpi/configs/bcm2837_rpi_3bp_defconfig"
export dtb_prefix="broadcom/bcm28"
export kernel_src="../linux"

pwd

./kernel/build-aarch-common.sh "bcm2837-rpi-3bp" "$CLEAN" no-install-modules

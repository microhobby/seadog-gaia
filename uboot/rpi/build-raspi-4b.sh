#!/bin/bash

export path=""
export path_boot=""
export path_modules=""
export artifacts="./rpi/artifacts/bcm2711-rpi-4b"
export defconfig="./rpi/configs/bcm2711_rpi_4b_defconfig"
export dtb_prefix="broadcom/bcm27"
export uboot_src="../u-boot"
export uboot_script="rpi4b"
export uboot_prefix="rpi"

./uboot/build-aarch-common.sh "bcm2711-rpi-4b" "$CLEAN"

#!/bin/bash

export path=""
export path_boot=""
export path_modules=""
export artifacts="./rpi/artifacts/bcm2837-rpi-3b"
export defconfig="./rpi/configs/bcm2837_rpi_3b_defconfig"
export dtb_prefix="broadcom/bcm28"
export uboot_src="../u-boot"
export uboot_script="rpi3b"
export uboot_prefix="rpi"

./uboot/build-aarch-common.sh "bcm2837-rpi-3b" "$CLEAN"

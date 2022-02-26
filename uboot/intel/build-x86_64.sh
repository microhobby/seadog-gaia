#!/bin/bash

export path=""
export path_boot=""
export path_modules=""
export artifacts="./intel/artifacts/x86_64"
export defconfig="./intel/configs/x86_64_defconfig"
export dtb_prefix=""
export uboot_src="../u-boot"
export uboot_script="intel"
export uboot_prefix="intel"

./uboot/build-x86_64-common.sh "x86_64_seadog" "$CLEAN"

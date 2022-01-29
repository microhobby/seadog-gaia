#!/bin/bash

function boardPipeline () {
    # Raspberry Pi 3B+
    writeln "Seadog for Raspberry Pi 3B+"

    # replace for the new version
    replaceVersions kernel/rpi/configs/bcm2837_rpi_3bp_defconfig
    replaceVersions uboot/rpi/configs/bcm2837_rpi_3bp_defconfig
    replaceVersions rootfs/common/os-release

    # configure branch tag
    setUBootBranch v2021.04
    setKernelBranch v5.12
    printConfigurationEnvironment

    # compile u-boot
    ./uboot/rpi/build-raspi-3bp.sh

    # compile mainline Kernel
    ./kernel/rpi/build-raspi-3bp.sh

    # compile initrd
    ./initrd/do-initrd-common.sh

    # do rootfs and pack img
    ./rootfs/rpi/do-rootfs-rpi-3bp.sh
}

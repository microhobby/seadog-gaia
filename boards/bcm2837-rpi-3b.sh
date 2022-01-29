#!/bin/bash

function boardPipeline () {
    # Raspberry Pi 3B
    writeln "Seadog for Raspberry Pi 3B"

    # replace for the new version
    replaceVersions kernel/rpi/configs/bcm2837_rpi_3b_defconfig
    # replaceVersions uboot/rpi/configs/bcm2837_rpi_3b_defconfig
    # #replaceVersions rootfs/common/os-release

    # # configure branch tag
    # setUBootBranch master
    # setKernelBranch master
    printConfigurationEnvironment

    # # compile u-boot
    ./uboot/rpi/build-raspi-3b.sh

    # # compile mainline Kernel
    ./kernel/rpi/build-raspi-3b.sh

    # do rootfs and pack img
    ./rootfs/rpi/do-rootfs-rpi-3b.sh
}

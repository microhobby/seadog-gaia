#!/bin/bash

function boardPipeline () {
    # Raspberry Pi 4B
    writeln "Seadog for Raspberry Pi 4B"

    # replace for the new version
    replaceVersions kernel/rpi/configs/bcm2711_rpi_4b_defconfig
    replaceVersions uboot/rpi/configs/bcm2711_rpi_4b_defconfig
    replaceVersions rootfs/common/os-release

    # configure branch tag
    setUBootBranch v2021.04
    setKernelBranch seadog-pi4b
    printConfigurationEnvironment

    # compile u-boot
    ./uboot/rpi/build-raspi-4b.sh

    # compile mainline Kernel
    ./kernel/rpi/build-raspi-4b.sh

    # compile initrd
    ./initrd/do-initrd-common.sh

    # do rootfs and pack img
    ./rootfs/rpi/do-rootfs-rpi-4b.sh
}

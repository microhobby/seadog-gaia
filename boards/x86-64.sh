#!/bin/bash

function boardPipeline () {
    writeln "Seadog for Intel x86_64"

    # replace for the new version
    replaceVersions kernel/intel/configs/x86_64_defconfig
    replaceVersions uboot/intel/configs/x86_64_defconfig
    replaceVersions rootfs/common/os-release

    # configure branch and set env
    setUBootBranch seadog
    printConfigurationEnvironment

    # compile u-boot
    ./uboot/intel/build-x86_64.sh

    # compile mainline Kernel
    ./kernel/intel/build-x86_64.sh

    # create img
    ./rootfs/intel/do-rootfs-x86_64.sh
}

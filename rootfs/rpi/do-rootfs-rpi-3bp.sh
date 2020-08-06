#!/bin/bash

# use the common functions
. ./rootfs/do-rootfs-common.sh --source-only

export hardware='bcm2837-rpi-3bp'
export family='rpi'
export arch='arm64'
export vendor='broadcom'
export dtb='bcm2837-rpi-3-b-plus.dtb'

prepare
# create the img file and mount
createImg $hardware
mountImg $hardware
# install boot files and kernel
doBootfs $family $hardware $arch $vendor $dtb
# install base distro
doRootfsArm64 $hardware
umountImg $hardware
finish $hardware

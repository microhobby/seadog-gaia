#!/bin/bash

# use the common functions
. ./rootfs/do-rootfs-common.sh --source-only

export artifacts="./rpi/artifacts/bcm2837-rpi-3b"
export kernel_src="../linux"
export hardware='bcm2837-rpi-3b'
export family='rpi'
export arch='arm64'
export alpine_arch='aarch64'
export vendor='broadcom'
export dtb='bcm2837-rpi-3-b.dtb'
export kernelImage='Image'

doRootFs

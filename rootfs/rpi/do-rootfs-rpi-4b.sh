#!/bin/bash

# use the common functions
. ./rootfs/do-rootfs-common.sh --source-only

export artifacts="./rpi/artifacts/bcm2711-rpi-4b"
export kernel_src="../linux"
export hardware='bcm2711-rpi-4b'
export family='rpi'
export arch='arm64'
export alpine_arch='aarch64'
export vendor='broadcom'
export dtb='bcm2711-rpi-4-b.dtb'
export kernelImage='Image'

doRootFs

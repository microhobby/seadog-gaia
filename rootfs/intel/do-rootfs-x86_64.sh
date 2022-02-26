#!/bin/bash

# use the common functions
. ./rootfs/do-rootfs-common.sh --source-only

export artifacts="./intel/artifacts/x86_64"
export kernel_src="../linux"
export hardware='x86_64'
export arch='x86'
export alpine_arch='x86_64'
export family='intel'
export vendor='genereric'
export dtb=''
export kernelImage='bzImage'
export grub='true'

doRootFs

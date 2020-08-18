#!/bin/bash

# TODO check for this configs on .config
# CONFIG_BLK_DEV_INITRD=y
# CONFIG_INITRAMFS_SOURCE=""
# CONFIG_RD_GZIP=y

# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

writeln "🔥🔥 CREATE initramfs"

# get binary to work
chmod +x ./initrd/common/initramfs/bin/busybox

# create .cpio
cd ./initrd/common
cd initramfs
find . | cpio -ov --format=newc | gzip -9 >../lasco
cd -

: '
find . | cpio -H newc -o > ../initramfs.cpio
cd ..
cat initramfs.cpio | gzip > initramfs.igz
'

writeln "🔥🔥🔥 CREATE u-boot IMG"

# for u-boot
mkimage \
	-A arm \
	-T ramdisk \
	-C none \
	-n "ramdisk" \
	-d lasco emerg.img

writeln '✅ initrd CREATED'

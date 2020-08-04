#!/bin/bash

# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

# compile boot script for u-boot
function compileBootScript () {
	mkimage -A arm -O linux -T script -C none \
		-n ./uboot/$1/scripts/$2.scr \
		-d ./uboot/$1/scripts/$2.scr \
		$artifacts/boot.scr.uimg
	pwd
	lastError=$(lastErrorCheck $lastError)
}

# check if we have jobs
if [[ ! -v JOBS ]]; then
	export jobs=12
fi

# append the gaia path
defconfig="../../seadog-gaia/uboot/$defconfig"
export artifacts="../seadog-gaia/uboot/$artifacts"

# create the artifacts folder
mkdir -p $artifacts
sudo chmod -R 777 $artifacts

# so lets build
writeln "🏗️  Building u-boot for $1"
# go to source folder
cd $uboot_src

if [ "$2" != "no-clean" ]; then
    writeln "🧹 CLEAN"
    make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts clean
    lastError=$(lastErrorCheck $lastError)
fi
pwd
writeln "🧰 CONFIG"
make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts $defconfig
lastError=$(lastErrorCheck $lastError)

writeln "🔥 COMPILE"
make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts -j $jobs
lastError=$(lastErrorCheck $lastError)
cd -

# build script
compileBootScript rpi rpi3bp

if [ "$lastError" -ne "0" ]; then
	writelnError "ERRORS DURING BUILD 😖❌"
	exit -1
else
	writeln "U-BOOT BUILD DONE 👌😎"
	exit 0
fi

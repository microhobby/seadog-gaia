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
	
	checkError
}

# terminate message
function checkError () {
	checkErrorAndKill 'ERRORS DURING U-BOOT BUILD 😖❌'
}

# check if we have jobs
if [[ ! -v JOBS ]]; then
	export jobs=12
else
	export jobs=${JOBS}
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

# checkout to the right repo
if [ "$UBOOT_BRANCH" != "" ]; then
	echo "U-Boot checkout to ${UBOOT_BRANCH}"
	git checkout ${UBOOT_BRANCH}
fi

if [ "$2" != "no-clean" ]; then
    writeln "🧹 CLEAN"
    make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts clean
    checkError
fi

pwd
writeln "🧰 CONFIG"
make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts $defconfig
checkError

writeln "🔥 COMPILE"
make CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts -j $jobs
checkError
cd -

# build script
compileBootScript $uboot_prefix $uboot_script

writeln "U-BOOT BUILD DONE 👌😎"
exit 0

#!/bin/bash

# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

# terminate message
function checkError () {
	checkErrorAndKill 'ERRORS DURING KERNEL BUILD 😖❌'
}

writeln "KERNEL BUILD FOR $1"
writeln "Author: Matheus Castello <matheus@castello.eng.br>"
echo "Version: 🌠"
echo "We need super cow powers! 🐄"
sudo echo "WE HAVE THE POWER!"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export O=$artifacts

if [[ ! -v JOBS ]]; then
	export jobs=12
else
	export jobs=${JOBS}
fi

# append the gaia path
defconfig="../../../../seadog-gaia/kernel/$defconfig"
artifacts="../seadog-gaia/kernel/$artifacts"

# create the artifacts folder
mkdir -p $artifacts
sudo chmod -R 777 $artifacts

# go to source folder
cd $kernel_src

# checkout to the right repo
if [ "$KERNEL_BRANCH" != "" ]; then
	echo "Linux Kernel checkout to ${KERNEL_BRANCH}"
	git checkout ${KERNEL_BRANCH}
fi

if [ "$2" == "clean" ] || [ "$2" == "kernel" ]; then
	writeln "CLEAN 🧹"
	# Goto kernel source and clean
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts distclean
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts clean
fi

writeln "CONFIG 🧰"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts $defconfig
checkError

writeln "COMPILE zImage 🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts Image -j $jobs
checkError

writeln "COMPILE modules 🔥🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts modules -j $jobs
checkError

if [ "$3" != "no-install-modules" ]; then
	writeln "INSTALL modules 🔥🔥🔥"
	sudo make O=$artifacts INSTALL_MOD_PATH=$path modules_install
	checkError
	sudo make O=$artifacts ARCH=arm64 INSTALL_HDR_PATH=$path/usr headers_install
	checkError
fi

writeln "COMPILE dtb 🔥🔥🔥🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts dtbs -j $jobs
checkError

echo "Recording analytics 💾"
cd -
countCompiles=$(wget "http://microhobby.com.br/safira2/kernelbuild.php?name=$1&error=$lastError"  -q -O -)
writeln "COMPILED KERNEL :: $countCompiles 📑"

writeln "COPY TO SDCARD 💾"
cd -
cd $artifacts

# umount and copy if we have paths
if [ "$path_boot" != "" ]; then
	sudo cp arch/arm64/boot/dts/*$dtb_prefix* $path_boot
	sudo cp arch/arm64/boot/Image $path_boot
	sudo umount $path_boot

	checkError
	echo "Boot files ✔️"
fi

if [ "$path" != "" ]; then
	sudo umount $path
fi

if [ "$path_ramdisk" != "" ]; then
	sudo umount $path_ramdisk
fi

writeln "KERNEL BUILD DONE 👌😎"
exit 0

#!/bin/bash

# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

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
fi

# append the gaia path
defconfig="../../../../seadog-gaia/kernel/$defconfig"
artifacts="../seadog-gaia/kernel/$artifacts"

# go to source folder
cd $kernel_src

if [ "$2" != "no-clean" ]; then
	writeln "CLEAN 🧹"
	# Goto kernel source and clean
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts distclean
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts clean
fi

writeln "CONFIG 🧰"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts $defconfig
lastError=$(lastErrorCheck $lastError)

writeln "COMPILE zImage 🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts Image -j $jobs
lastError=$(lastErrorCheck $lastError)

writeln "COMPILE modules 🔥🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts modules -j $jobs
lastError=$(lastErrorCheck $lastError)

if [ "$3" != "no-install-modules" ]; then
	writeln "INSTALL modules 🔥🔥🔥"
	sudo make O=$artifacts INSTALL_MOD_PATH=$path modules_install
	lastError=$(lastErrorCheck $lastError)
	sudo make O=$artifacts ARCH=arm64 INSTALL_HDR_PATH=$path/usr headers_install
	lastError=$(lastErrorCheck $lastError)
fi

writeln "COMPILE dtb 🔥🔥🔥🔥"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=$artifacts dtbs -j $jobs
lastError=$(lastErrorCheck $lastError)

echo "Recording analytics 💾"
cd -
countCompiles=$(wget "http://microhobby.com.br/safira2/kernelbuild.php?name=$1&error=$lastError"  -q -O -)
writeln "COMPILED KERNEL :: $countCompiles 📑"

if [ "$lastError" -ne "0" ]; then
	writelnError "ERRORS DURING BUILD 😖❌"
	exit -1
else
	writeln "COPY TO SDCARD 💾"
	cd -
	cd $artifacts

	# umount and copy if we have paths
	if [ "$path_boot" != "" ]; then
		sudo cp arch/arm64/boot/dts/*$dtb_prefix* $path_boot
		sudo cp arch/arm64/boot/Image $path_boot
		sudo umount $path_boot
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
fi

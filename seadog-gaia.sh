#!/bin/bash

# use message utils
. ./utils/fancyTerminalUtils.sh --source-only
. ./utils/welcome.sh --source-only

# you can use to set how many threads for the build
# export JOBS=12

export CLEAN="$2"
export arg=""

# welcome
seadogWelcome

# check the arguments
case "$1" in
	"bcm2837-rpi-3bp")
		# Raspberry Pi 3B+
        writeln "Raspberry Pi 3B+"

        # compile u-boot

        # compile mainline Kernel
        ./kernel/rpi/build-raspi-3bp.sh

        # do rootfs

        # pack img
		;;
	*)
		writelnError "What? 🤷"
		writelnError "🚫 ${BOLD}$1${RED} Not implemented ..."

        echo "Supported hardwares:"
        echo -e "Raspberry Pi 3B+ \t::\t bcm2837-rpi-3bp"

		exit 1
		;;
esac

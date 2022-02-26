
# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

export ROOTFS_IMG_TIME=$(date +%s)

# terminate message
function checkError () {
	checkErrorAndKill ' - ERRORS DURING ROOTFS BUILD 😖❌'
}

# create the template disk
function createImg () {
    writeln 'Creating IMG'

    export IMAGE_FILE="$PWD/dist/$1/$1-seadog-v${SEADOG_MAJOR_VERSION}.${SEADOG_MINOR_VERSION}.${SEADOG_BUILD_VERSION}.img"

    # create the file
    mkdir -p dist/$1

    dd if=/dev/zero of=$IMAGE_FILE \
        bs=1024 count=400000 status=progress

    # partitions
    sudo parted $IMAGE_FILE -s mktable msdos
    sudo parted $IMAGE_FILE -s mkpart primary fat32 1 50 \
        set 1 lba on align-check optimal 1 \
        mkpart primary ext4 51 350

    # format
    kpartxret="$(sudo kpartx -av $IMAGE_FILE)"
    read PART_LOOP <<<$(grep -o 'loop.' <<<"$kpartxret")

    sudo mkfs.vfat -F 32 /dev/mapper/${PART_LOOP}p1
    sudo mkfs.ext4 /dev/mapper/${PART_LOOP}p2
    sudo fatlabel /dev/mapper/${PART_LOOP}p1 'BOOT'
    sudo e2label /dev/mapper/${PART_LOOP}p2 'seadog'
    sync

    sudo kpartx -dv $IMAGE_FILE
    # sudo dmsetup remove /dev/mapper/${PART_LOOP}p1
    # sudo dmsetup remove /dev/mapper/${PART_LOOP}p2
    # sudo losetup -d /dev/${PART_LOOP}

    checkError
    writeln '✅ IMG Created'
}

function mountImg () {
    writeln 'Mountint IMG'

    # mount
    kpartxret="$(sudo kpartx -av $IMAGE_FILE)"
    read PART_LOOP <<<$(grep -o 'loop.' <<<"$kpartxret")
    export PART_LOOP

    sudo mount /dev/mapper/${PART_LOOP}p1 rootfs/mntfat
    sudo mount /dev/mapper/${PART_LOOP}p2 rootfs/mntext

    checkError
    writeln '✅ IMG mounted'
}

function umountImg () {
    writeln 'Umount IMG'

    # umount
    sudo umount rootfs/mntfat
    sudo umount rootfs/mntext
    sudo kpartx -dv $IMAGE_FILE
    # sudo dmsetup remove /dev/mapper/${PART_LOOP}p1
    # sudo dmsetup remove /dev/mapper/${PART_LOOP}p2
    # sudo losetup -d /dev/${PART_LOOP}

    checkError
    writeln '✅ IMG umounted'
}

function doRootfs () {
    writeln 'Installing rootfs files'

    # unpack
    sudo tar -xzf rootfs/alpine-minirootfs-3.15.0-$1.tar.gz \
        -C rootfs/mntext/

    checkError
    writeln '✅ rootfs files installed'
}

function doBootfs () {
    writeln 'Installing boot files'

    # copy specific resources
    sudo cp -r rootfs/$1/$2/boot/* rootfs/mntfat/
    
    # copy u-boot
    writeln 'Installing Bootloader'
    if [ "$grub" = "" ];
    then
        writelnWarn "This system uses U-boot as primary boot loader"
        sudo cp uboot/$1/artifacts/$2/u-boot.bin rootfs/mntfat/bootImg
    else
        writelnWarn "This system uses GRUB as primary boot loader"
        # sudo cp /home/castello/tmp/myos/OS/Kernel/Simple/src/kernel_1/MyOS.bin rootfs/mntfat/bootImg
        sudo cp uboot/$1/artifacts/$2/u-boot.bin rootfs/mntfat/bootImg
    fi
    
    sudo cp uboot/$1/artifacts/$2/boot.scr.uimg rootfs/mntfat/

    # copy kernel
    writeln 'Installing Kernel'
    echo "sudo cp kernel/$1/artifacts/$2/arch/$3/boot/$kernelImage rootfs/mntfat/"
    sudo cp kernel/$1/artifacts/$2/arch/$3/boot/$kernelImage rootfs/mntfat/

    # copy emerg initrd
    sudo cp initrd/common/emerg.img rootfs/mntfat/

    # copy device tree
    if [ "$dtb" = "" ];
    then
        writelnWarn 'System has no device trees'
    else
        writeln 'Installing Device Tree'
        sudo mkdir -p rootfs/mntfat/$vendor
        sudo cp \
            kernel/$1/artifacts/$2/arch/arm64/boot/dts/$4/$5 \
            rootfs/mntfat/$vendor/$dtb
    fi

    if [ "$grub" != "" ];
    then
        doGrubInstall
    fi
    
    checkError
    writeln '✅ Boot Files installed'
}

function prepare () {
    writeln 'Prepare mount point'

    # clear
    sudo rm -rf rootfs/mntfat
    sudo rm -rf rootfs/mntext

    # create
    mkdir rootfs/mntext
    mkdir rootfs/mntfat

    checkError
    writeln '✅ Mount points ok'
}

function checkWSL () {
    if [[ -z "$WSL_DISTRO_NAME" ]]; then
        writelnWarn 'we are not in WSL ...'
    else
        writeln '📦 WSL :: Copying dist to C:'

        mv $IMAGE_FILE /mnt/c/Users/Public/
    fi
}

function mountImgChroot () {
    writeln 'Mountint IMG'
    
    export IMAGE_FILE="$1"

    # mount
    kpartxret="$(sudo kpartx -av $IMAGE_FILE)"
    read PART_LOOP <<<$(grep -o 'loop.' <<<"$kpartxret")
    export PART_LOOP

    sudo mount /dev/mapper/${PART_LOOP}p1 rootfs/mntfat
    sudo mount /dev/mapper/${PART_LOOP}p2 rootfs/mntext

    checkError
    writeln '✅ IMG mounted'
}

function doModulesInstall () {
    writeln 'Installing Kernel Modules'

    path=$2
    export CDCD=1

    # go to Linux source folder
    artifacts="../seadog-gaia/kernel/$artifacts"
    cd $kernel_src

    # install modules .ko
    sudo make O=$artifacts INSTALL_MOD_PATH=$path modules_install
	checkError
    
    # TODO add switch for this feature
    # install the headers for compile reference (not needed for now)
    #sudo make O=$artifacts ARCH=arm64 INSTALL_HDR_PATH=$path/usr headers_install
    #checkError

    cd -
    unset CDCD

    writeln '✅ Kernel Modules'
}

function doChrootBase () {
    export chroot_dir=$1

    # mount the sysfs
    sudo mount /dev/ ${chroot_dir}/dev/ --bind
    sudo mount -o remount,ro,bind ${chroot_dir}/dev
    sudo mount -t proc none ${chroot_dir}/proc
    sudo mount -o bind /sys ${chroot_dir}/sys
    sudo mkdir -p ${chroot_dir}/root

    # set .bashrc for all users including root
    sudo cp rootfs/common/.bashrc ${chroot_dir}/etc/bash.bashrc

    # run bash.bashrc on profile 
    sudo cp rootfs/common/profile ${chroot_dir}/etc/profile

    # the welcome message Seadog char logo
    sudo cp rootfs/common/issue ${chroot_dir}/etc/issue

    # customize the distro name and version
    sudo cp rootfs/common/os-release ${chroot_dir}/etc/os-release

    # add the serial as login tty
    sudo cp rootfs/common/inittab ${chroot_dir}/etc/inittab

    # add 10s timeout for kernel panic reboot
    sudo cp rootfs/common/sysctl.conf ${chroot_dir}/etc/sysctl.conf
    
    # add the network eth0 with dhcp
    sudo cp rootfs/common/interfaces ${chroot_dir}/etc/network/interfaces

    # Nothing on login message
    sudo bash -c "echo '' > ${chroot_dir}/etc/motd"

    # Add the mapping for te uboot-tools
    sudo cp rootfs/common/fw_env.config ${chroot_dir}/etc/fw_env.config

    # Add the fstab for auto mount the /boot
    sudo cp rootfs/common/fstab ${chroot_dir}/etc/fstab

    # Add the seadog-expand service
    sudo cp rootfs/common/seadog-expand ${chroot_dir}/etc/init.d/seadog-expand

    # Add images for the seadog expand wait
    sudo cp rootfs/common/seadog-expand1.jpg \
        ${chroot_dir}/etc/seadog-expand1.jpg
    
    sudo cp rootfs/common/seadog-expand2.jpg \
        ${chroot_dir}/etc/seadog-expand2.jpg

    sudo cp rootfs/common/seadog-expand3.jpg \
        ${chroot_dir}/etc/seadog-expand3.jpg
    
    sudo cp rootfs/common/seadog-expand4.jpg \
        ${chroot_dir}/etc/seadog-expand4.jpg

    # the welcome message for the first boot
    sudo cp rootfs/common/welcome ${chroot_dir}/etc/welcome

    # splash screen images
    sudo cp rootfs/common/boot1.ppm ${chroot_dir}/etc/boot1.ppm
    sudo cp rootfs/common/boot2.ppm ${chroot_dir}/etc/boot2.ppm

    # splash screen scripts
    sudo cp rootfs/common/splash ${chroot_dir}/usr/bin/splash
    sudo cp rootfs/common/splash-boot ${chroot_dir}/etc/init.d/splash-boot

    # boot count emergency mode
    sudo cp rootfs/common/all-ok ${chroot_dir}/usr/bin/all-ok
    sudo cp rootfs/common/boot-ok ${chroot_dir}/etc/init.d/boot-ok

    # image to show during the kdump
    sudo cp rootfs/common/bsod.jpg ${chroot_dir}/etc/bsod.jpg

    # service to check seadog.kdump
    sudo cp rootfs/common/init-emerg ${chroot_dir}/sbin/init-emerg

    # kexec service with specific cmdline
    sudo cp rootfs/$family/$hardware/custom/kexec \
        ${chroot_dir}/etc/init.d/kexec

    # copy the prepare script to the rootfs
    sudo cp rootfs/common/prepare ${chroot_dir}/bin/
    # run the script that will install the base tools and init services
    sudo chroot ${chroot_dir}/ /bin/prepare

    # test
    #sudo chroot ${chroot_dir}/

    # Add the hardware name used on script as hostname
    sudo bash -c "echo $hardware > ${chroot_dir}/etc/hostname"

    # Update the neofetch for Seadog Linux
    sudo cp rootfs/common/neofetch ${chroot_dir}/usr/bin/neofetch

    # add the docker registry for podman
    sudo cp rootfs/common/registries.conf ${chroot_dir}/etc/containers/registries.conf

    # umount
    sudo umount ${chroot_dir}/dev/
    sudo umount ${chroot_dir}/proc/
    sudo umount ${chroot_dir}/sys/ 
}

function doGrubInstall () {
    writeln 'Installing GRUB'

    sudo grub-install \
            --target=i386-pc \
            --boot-directory=$PWD/rootfs/mntfat/ \
            /dev/${PART_LOOP}

    checkError
    writeln '✅ GRUB installed'
}

function doRootFs () {
    prepare
    # create the img file and mount
    createImg $hardware
    mountImg
    # install boot files and kernel
    doBootfs $family $hardware $arch $vendor $dtb $kernelImage
    # install base distro
    doRootfs $arch
    doModulesInstall $artifacts "$PWD/rootfs/mntext"
    doChrootBase "$PWD/rootfs/mntext" $hardware

    umountImg
    checkWSL
}

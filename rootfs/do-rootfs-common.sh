
# use message utils
. ./utils/fancyTerminalUtils.sh --source-only

# terminate message
function checkError () {
	checkErrorAndKill 'ERRORS DURING ROOTFS BUILD 😖❌'
}

# create the template disk
function createImg () {
    writeln "Create IMG"

    # create the file
    mkdir -p dist/$1
    rm dist/$1/$1-seadog.img
    dd if=/dev/zero of=dist/$1/$1-seadog.img \
        bs=1024 count=600240 status=progress

    # partitions
    sudo parted dist/$1/$1-seadog.img -s mktable msdos
    sudo parted dist/$1/$1-seadog.img -s mkpart primary fat32 1 100 \
        set 1 lba on align-check optimal 1 \
        mkpart primary ext4 101 500

    # format
    sudo kpartx -a dist/$1/$1-seadog.img
    sudo mkfs.vfat -F 32 /dev/mapper/loop0p1
    sudo mkfs.ext4 /dev/mapper/loop0p2
    sudo fatlabel /dev/mapper/loop0p1 'boot'
    sudo e2label /dev/mapper/loop0p2 'seadog'
    sudo kpartx -d dist/$1/$1-seadog.img

    checkError
}

function mountImg () {
    writeln "Mount IMG"
    
    # mount
    sudo kpartx -a dist/$1/$1-seadog.img
    sudo mount /dev/mapper/loop0p1 rootfs/mntfat
    sudo mount /dev/mapper/loop0p2 rootfs/mntext

    checkError
}

function umountImg () {
    writeln "Umount IMG"

    # umount
    sudo umount /dev/mapper/loop0p1 rootfs/mntfat
    sudo umount /dev/mapper/loop0p2 rootfs/mntext
    sudo kpartx -d dist/$1/$1-seadog.img

    checkError
}

function doRootfsArm64 () {
    writeln "Installing rootfs files"

    # unpack
    sudo tar -xzf rootfs/alpine-minirootfs-3.12.0-aarch64.tar.gz \
        -C rootfs/mntext/

    checkError
}

function doRootfsCommon () {
    writeln "nada"
}

function doBootfs () {
    writeln "Installing boot files"

    # copy specific resources
    sudo cp -r rootfs/$1/$2/boot/* rootfs/mntfat/
    
    # copy u-boot
    writeln "Installing Bootloader"
    sudo cp uboot/$1/artifacts/$2/u-boot.bin rootfs/mntfat/bootImg
    sudo cp uboot/$1/artifacts/$2/boot.scr.uimg rootfs/mntfat/

    # copy kernel
    writeln "Installing Kernel"
    sudo cp kernel/$1/artifacts/$2/arch/$3/boot/Image rootfs/mntfat/

    # copy device tree
    writeln "Installing Device Tree"
    sudo cp \
        kernel/$1/artifacts/$2/arch/arm64/boot/dts/$4/$5 \
        rootfs/mntfat/
    
    checkError
}

function prepare () {
    # clear
    sudo rm -rf rootfs/mntfat
    sudo rm -rf rootfs/mntext

    # create
    mkdir rootfs/mntext
    mkdir rootfs/mntfat

    checkError
}

function finish () {
    mv dist/$1/$1-seadog.img dist/$1/$1-seadog-$(date +%s).img

    checkError
}

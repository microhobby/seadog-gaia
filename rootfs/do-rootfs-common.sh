
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

    IMAGE_FILE="$PWD/dist/$1/$1-seadog-$ROOTFS_IMG_TIME.img"

    # create the file
    mkdir -p dist/$1

    dd if=/dev/zero of=$IMAGE_FILE \
        bs=1024 count=600240 status=progress

    # partitions
    sudo parted $IMAGE_FILE -s mktable msdos
    sudo parted $IMAGE_FILE -s mkpart primary fat32 1 100 \
        set 1 lba on align-check optimal 1 \
        mkpart primary ext4 101 500

    # format
    kpartxret="$(sudo kpartx -av $IMAGE_FILE)"
    read PART_LOOP <<<$(grep -o 'loop.' <<<"$kpartxret")

    sudo mkfs.vfat -F 32 /dev/mapper/${PART_LOOP}p1
    sudo mkfs.ext4 /dev/mapper/${PART_LOOP}p2
    sudo fatlabel /dev/mapper/${PART_LOOP}p1 'boot'
    sudo e2label /dev/mapper/${PART_LOOP}p2 'seadog'
    sudo kpartx -dv $IMAGE_FILE
    sudo dmsetup remove /dev/mapper/${PART_LOOP}p1
    sudo dmsetup remove /dev/mapper/${PART_LOOP}p2
    sudo losetup -d /dev/${PART_LOOP}

    checkError
    writeln '✅ IMG Created'
}

function mountImg () {
    writeln 'Mountint IMG'
    
    export IMAGE_FILE="$PWD/dist/$1/$1-seadog-$ROOTFS_IMG_TIME.img"

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
    sudo dmsetup remove /dev/mapper/${PART_LOOP}p1
    sudo dmsetup remove /dev/mapper/${PART_LOOP}p2
    sudo losetup -d /dev/${PART_LOOP}

    checkError
    writeln '✅ IMG umounted'
}

function doRootfsArm64 () {
    writeln 'Installing rootfs files'

    # unpack
    sudo tar -xzf rootfs/alpine-minirootfs-3.12.0-aarch64.tar.gz \
        -C rootfs/mntext/

    checkError
    writeln '✅ rootfs files installed'
}

function doBootfs () {
    writenln 'Installing boot files'

    # copy specific resources
    sudo cp -r rootfs/$1/$2/boot/* rootfs/mntfat/
    
    # copy u-boot
    writeln 'Installing Bootloader'
    sudo cp uboot/$1/artifacts/$2/u-boot.bin rootfs/mntfat/bootImg
    sudo cp uboot/$1/artifacts/$2/boot.scr.uimg rootfs/mntfat/

    # copy kernel
    writeln 'Installing Kernel'
    sudo cp kernel/$1/artifacts/$2/arch/$3/boot/Image rootfs/mntfat/

    # copy device tree
    writeln 'Installing Device Tree'
    sudo cp \
        kernel/$1/artifacts/$2/arch/arm64/boot/dts/$4/$5 \
        rootfs/mntfat/
    
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
    if [[ -z "${WSL_DISTRO_NAME}" ]]; then
        echo 'we are not in WSL ...'
    else
        writeln '📦 WSL :: Copying dist to C:'

        mv $IMAGE_FILE /mnt/c/Users/Public/
    fi
}

function doRootFs () {
    prepare
    # create the img file and mount
    createImg $hardware
    mountImg $hardware
    # install boot files and kernel
    doBootfs $family $hardware $arch $vendor $dtb
    # install base distro
    doRootfsArm64 $hardware
    umountImg $hardware
    checkWSL
}

#!/bin/sh
#making of image

BASEDIR=$1

if [ -z $BASEDIR ]
then
	echo "Usage: $0 base_dir_path"
	exit 1
fi

KRNLBIN=$(pwd)/out
BUILDDIR=${BASEDIR}/build
R=${BASEDIR}/build/chroot

# Build the image file
# Currently hardcoded to a 1.75GiB image
DATE="$(date +%Y-%m-%d)"
dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=1
dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=0 seek=1792
sfdisk -f "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" <<EOM
#unit: sectors

#1 : start=     2048, size=   131072, Id= c, bootable
#2 : start=   133120, size=  3536896, Id=83
#3 : start=        0, size=        0, Id= 0
#4 : start=        0, size=        0, Id= 0
EOM
VFAT_LOOP="$(losetup -o 1M --sizelimit 64M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
EXT4_LOOP="$(losetup -o 65M --sizelimit 1727M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
mkfs.vfat "$VFAT_LOOP"
mkfs.ext4 "$EXT4_LOOP"
MOUNTDIR="$BUILDDIR/mount"
mkdir -p "$MOUNTDIR"
mount "$EXT4_LOOP" "$MOUNTDIR"
mkdir -p "$MOUNTDIR/boot"
mount "$VFAT_LOOP" "$MOUNTDIR/boot/fw"
#== cp kernel files ======
rsync -a "out/lib" "$MOUNTDIR/"
rsync -a "out/uImage" "$MOUNTDIR/boot/fw/"
rsync -a "boards/orangepi/orangepi.cmd" "$MOUNTDIR/boot/fw/uEnv.txt"
rsync -a "boards/orangepi/script.bin" "$MOUNTDIR/boot/fw/"
rsync -a "boards/orangepi/sun8i-h3-orangepi-pc.dts" "$MOUNTDIR/boot/fw/"
#=========================
rsync -a "$R/" "$MOUNTDIR/"
umount "$MOUNTDIR/boot"
umount "$MOUNTDIR"
losetup -d "$EXT4_LOOP"
losetup -d "$VFAT_LOOP"
if which bmaptool; then
  bmaptool create -o "$BASEDIR/${DATE}-ubuntu-${RELEASE}.bmap" "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img"
fi

# Done!
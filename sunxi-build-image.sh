#!/bin/sh

########################################################################
# sunxi-build-image
# Copyright (C) 2015 Ryan Finnie <ryan@finnie.org>
# Copyright (C) 2015 Borislav Sapundziev <bsapundjiev@gmail.com>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
########################################################################

set -e
set -x

RELEASE=xenial
BASEDIR=$(pwd)/${RELEASE}
BUILDDIR=${BASEDIR}/build
# I use a local caching proxy to save time/bandwidth; in this mode, the
# local mirror is used to download almost everything, then the standard
# http://ports.ubuntu.com/ is replaced at the end for distribution.
#LOCAL_MIRROR=""

# Don't clobber an old build
if [ -e "$BUILDDIR" ]; then
  echo "$BUILDDIR exists, not proceeding"
  #exit 1
fi

# Set up environment
export TZ=UTC
R=${BUILDDIR}/chroot
mkdir -p $R

# Base debootstrap
apt-get -y install ubuntu-keyring
if [ -n "$LOCAL_MIRROR" ]; then
  debootstrap $RELEASE $R $LOCAL_MIRROR
else
  #debootstrap $RELEASE $R http://ports.ubuntu.com/
  qemu-debootstrap --arch armhf $RELEASE $R http://ports.ubuntu.com/
fi

# Mount required filesystems
mount -t proc none $R/proc
mount -t sysfs none $R/sys

# Set up initial sources.list
if [ -n "$LOCAL_MIRROR" ]; then
  cat <<EOM >$R/etc/apt/sources.list
deb ${LOCAL_MIRROR} ${RELEASE} main restricted universe multiverse
# deb-src ${LOCAL_MIRROR} ${RELEASE} main restricted universe multiverse

deb ${LOCAL_MIRROR} ${RELEASE}-updates main restricted universe multiverse
# deb-src ${LOCAL_MIRROR} ${RELEASE}-updates main restricted universe multiverse

deb ${LOCAL_MIRROR} ${RELEASE}-security main restricted universe multiverse
# deb-src ${LOCAL_MIRROR} ${RELEASE}-security main restricted universe multiverse

deb ${LOCAL_MIRROR} ${RELEASE}-backports main restricted universe multiverse
# deb-src ${LOCAL_MIRROR} ${RELEASE}-backports main restricted universe multiverse
EOM
else
  cat <<EOM >$R/etc/apt/sources.list
deb http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
EOM
fi

chroot $R apt-get -yf install

chroot $R apt-get update
chroot $R apt-get -y -u dist-upgrade

# Install the RPi PPA
cat <<"EOM" >$R/etc/apt/preferences.d/rpi2-ppa
Package: *
Pin: release o=LP-PPA-fo0bar-rpi2
Pin-Priority: 990

Package: *
Pin: release o=LP-PPA-fo0bar-rpi2-staging
Pin-Priority: 990
EOM
chroot $R apt-get -y install software-properties-common ubuntu-keyring
chroot $R apt-add-repository -y ppa:fo0bar/rpi2
chroot $R apt-get update

# Standard packages
#chroot $R apt-get -y install ubuntu-standard initramfs-tools raspberrypi-bootloader-nokernel rpi2-ubuntu-errata language-pack-en
chroot $R apt-get -y install ubuntu-standard initramfs-tools language-pack-en
#Desktop 
chroot $R apt-get -y install linux-firmware
chroot $R apt-get -y install lubuntu-desktop

# Install video drivers
chroot $R apt-get -y install xserver-xorg-video-fbturbo
cat <<EOM >$R/etc/X11/xorg.conf
Section "Device"
    Identifier "Sunxi FBDEV"
    Driver "fbturbo"
    Option "fbdev" "/dev/fb0"
    Option "SwapbuffersWait" "true"
EndSection
EOM

cat <<EOM >$R/etc/udev/rules.d/50-mali.rules
KERNEL=="mali", MODE="0660", GROUP="video"
KERNEL=="ump", MODE="0660", GROUP="video"
EOM

# Kernel installation
# Install flash-kernel last so it doesn't try (and fail) to detect the
# platform in the chroot.
#chroot $R apt-get -y --no-install-recommends install linux-image-rpi2
#chroot $R apt-get -y install flash-kernel
#VMLINUZ="$(ls -1 $R/boot/vmlinuz-* | sort | tail -n 1)"
#[ -z "$VMLINUZ" ] && exit 1
#cp $VMLINUZ $R/boot/firmware/kernel7.img
#INITRD="$(ls -1 $R/boot/initrd.img-* | sort | tail -n 1)"
#[ -z "$INITRD" ] && exit 1
#cp $INITRD $R/boot/firmware/initrd7.img

# Set up fstab
#cat <<EOM >$R/etc/fstab
#proc            /proc           proc    defaults          0       0
#/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
#/dev/mmcblk0p1  /boot/firmware  vfat    defaults          0       2
#EOM

# Set up fstab
cat <<EOM >$R/etc/fstab
proc           /proc        proc    defaults          0    	0
/dev/root      /            ext4   	defaults,noatime  0 	1
tmpfs    	   /tmp        	tmpfs   defaults  		  0 	0
tmpfs    	   /var/tmp    	tmpfs   defaults    	  0 	0
EOM

# Set up hosts
echo ubuntu >$R/etc/hostname
cat <<EOM >$R/etc/hosts
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       ubuntu
EOM

# Set up default user
chroot $R adduser --gecos "Ubuntu user" --add_extra_groups --disabled-password ubuntu
chroot $R usermod -a -G sudo,adm -p '$6$iTPEdlv4$HSmYhiw2FmvQfueq32X30NqsYKpGDoTAUV2mzmHEgP/1B7rV3vfsjZKnAWn6M2d.V2UsPuZ2nWHg1iqzIu/nF/' ubuntu

# Restore standard sources.list if a local mirror was used
if [ -n "$LOCAL_MIRROR" ]; then
  cat <<EOM >$R/etc/apt/sources.list
deb http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
EOM
chroot $R apt-get update
fi

# Clean cached downloads
chroot $R apt-get clean

# Set up interfaces
cat <<EOM >$R/etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp
iface wlan0 inet dhcp
EOM

# Load sound module on boot
cat <<EOM >$R/lib/modules-load.d/sunxi.conf
#For SATA Support
sw_ahci_platform

#Display and GPU
lcd
ump
disp
mali
mali_drm
8192cu
gpio-sunxi
sunxi_cedar_mod
#sun4i_ts
sunxi-codec
pwm-sunxi
#ledtrig-heartbeat
#leds-sunxi
sun4i-keyboard
EOM

# Blacklist platform modules not applicable to the sunxi
#cat <<EOM >$R/etc/modprobe.d/sunxi.conf
#EOM

# Unmount mounted filesystems
umount $R/proc
umount $R/sys

# Clean up files
rm -f $R/etc/apt/sources.list.save
rm -f $R/etc/resolvconf/resolv.conf.d/original
rm -rf $R/run
mkdir -p $R/run
rm -f $R/etc/*-
rm -f $R/root/.bash_history
rm -rf $R/tmp/*
rm -f $R/var/lib/urandom/random-seed
[ -L $R/var/lib/dbus/machine-id ] || rm -f $R/var/lib/dbus/machine-id
rm -f $R/etc/machine-id

# Build the image file
# Currently hardcoded to a 1.75GiB image
DATE="$(date +%Y-%m-%d)"
#dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=1
#dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=0 seek=1792
#sfdisk -f "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" <<EOM
#unit: sectors

#1 : start=     2048, size=   131072, Id= c, bootable
#2 : start=   133120, size=  3536896, Id=83
#3 : start=        0, size=        0, Id= 0
#4 : start=        0, size=        0, Id= 0
#EOM
#VFAT_LOOP="$(losetup -o 1M --sizelimit 64M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
#EXT4_LOOP="$(losetup -o 65M --sizelimit 1727M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
#mkfs.vfat "$VFAT_LOOP"
#mkfs.ext4 "$EXT4_LOOP"
#MOUNTDIR="$BUILDDIR/mount"
#mkdir -p "$MOUNTDIR"
#mount "$EXT4_LOOP" "$MOUNTDIR"
#mkdir -p "$MOUNTDIR/boot/firmware"
#mount "$VFAT_LOOP" "$MOUNTDIR/boot/firmware"
#rsync -a "$R/" "$MOUNTDIR/"
#umount "$MOUNTDIR/boot/firmware"
#umount "$MOUNTDIR"
#losetup -d "$EXT4_LOOP"
#losetup -d "$VFAT_LOOP"
#if which bmaptool; then
#  bmaptool create -o "$BASEDIR/${DATE}-ubuntu-${RELEASE}.bmap" "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img"
#fi

# Done!

#!/bin/sh

FIRMWAREDIR=$OUTPUTDIR/lib/firmware

echo "* Start build linux-$KERNEL"

cd linux-$KERNEL

if [ $? -ne 0 ]
  then
    echo "Error: Krenel tree is not found!"
    exit 2
fi

# Change to the first directory ls finds, e.g. 'linux-3.18.6'
#cd $(ls -d *)

echo "* Checking the kernel configuration existence.."

if [ -f .config ]
  then
    echo "* OK .config exists."
else
    echo "* Copy config $KERNEL_DEFCONFIG --> .config"
    cp $KERNEL_DEFCONFIG .config
fi

if [ "menuconfig" = "$1" ]; then
  echo "manual configuration..."
  make ARCH=arm CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX menuconfig
  exit 1
fi

if [ "clean" = "$1" ]; then
  echo "manual configuration..."
  make ARCH=arm CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX mrproper
  rm -rf $OUTPUTDIR
  exit 1
fi

#
# Update existing configuration for new kernel options
#

make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX oldconfig

# Changes the name of the system
#sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\"minimal\"/" .config

# Compile the kernel
# Good explanation of the different kernels
# http://unix.stackexchange.com/questions/5518/what-is-the-difference-between-the-following-kernel-makefile-terms-vmlinux-vmlinux
# make bzImage

if [ -n $LOADADDR ]; then
	make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX -j4 uImage LOADADDR=$LOADADDR dtbs
else
	make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX -j4 uImage
fi


if [ -f arch/arm/boot/uImage ]; then

	mkdir -p $OUTPUTDIR
	cp -p arch/arm/boot/uImage $OUTPUTDIR
#modules install
	make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX -j4 INSTALL_MOD_PATH=$OUTPUTDIR modules
	make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX -j4 INSTALL_MOD_PATH=$OUTPUTDIR modules_install
#firmware install
	mkdir -p $FIRMWAREDIR
	make ARCH=$PLATFORM CROSS_COMPILE=$CROSS_TOOLKIT_PREFIX -j4 INSTALL_FW_PATH=$FIRMWAREDIR firmware_install
#dtbs
	rsync -av arch/arm/boot/dts/*.dtb "$OUTPUTDIR/dts/"
else
	echo "Error building kernel!"
	exit 3
fi

echo "****************************"
echo "*  linux-$KERNEL Build OK    *"
echo "****************************"

cd ..

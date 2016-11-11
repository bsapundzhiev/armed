#!/bin/sh
###############################################
#setup env
###############################################
#build root
ROOT=`pwd`

export CONFIG=$ROOT/boards

#product dir
export OUTPUTDIR=$ROOT/out

#Linux platform
export PLATFORM=arm
export CROSS_TOOLKIT_PREFIX=arm-linux-gnueabihf-
CROSS_TOOLKIT=gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
CROSS_PATH=$ROOT/tools/$CROSS_TOOLKIT/bin/
export PATH=$CROSS_PATH:$PATH

case "$1" in
        init)
        echo "Setup tools"
	sh scripts/0_prepare_kernel.sh
	exit 1
            ;;
        a13)
        export KERNEL=sunxi
        GIT_REPO="https://github.com/linux-sunxi/linux-sunxi.git"
        export KERNEL_DEFCONFIG=$CONFIG/a13/a13_linux_defconfig
            ;;
        orangepi)
        export KERNEL=4.9-rc5
        export LOADADDR=0x48000000
        GIT_REPO="https://github.com/orangepi-xunlong/linux-sunxi.git"
        #export KERNEL_DEFCONFIG=$CONFIG/orangepi/sun8iw7p1smp_lobo_defconfig
        export KERNEL_DEFCONFIG=$CONFIG/orangepi/sun8iw7p1_mainline_defconfig
            ;;
        mkimage)
   	echo "Image setup"
	exit 1
            ;;
        *)

	echo "Usage: $0 {init|a13|orangepi|mkimage}"
	echo "run init first for setup build tools"
	exit 1
esac

if [ ! -d "linux-$KERNEL" ]; then
  	echo "Clone $GIT_REPO"
	git clone $GIT_REPO
fi

export VARIANT="$1"
echo "*** $VARIANT setup ***"

sh scripts/1_build_kernel.sh "$2"

##test
#sh ./test.sh

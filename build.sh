#!/bin/sh
###############################################
#setup env
#
#if [ $# -ne 2 ]; then
#   echo "Usage $0 kernel version"	
#   exit 2             		
#fi

#build root
ROOT=`pwd`

export KERNEL=sunxi
export CONFIG=$ROOT/conf
export KERNEL_DEFCONFIG=$CONFIG/a13_linux_defconfig
#product dir
export OUTPUTDIR=$ROOT/out

#Linux platform
export PLATFORM=arm 
export CROSS_TOOLKIT_PREFIX=arm-linux-gnueabihf-
CROSS_TOOLKIT=gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
CROSS_PATH=$ROOT/tools/$CROSS_TOOLKIT/bin/
export PATH=$CROSS_PATH:$PATH

sh scripts/0_prepare_kernel.sh
sh scripts/1_build_kernel.sh

##test
#sh ./test.sh
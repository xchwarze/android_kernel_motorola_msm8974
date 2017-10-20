#!/bin/bash
# NetHunter kernel for Motorola MSM8974 devices build script by DSR!
# This build script is for LineageOS only

# root directory of NetHunter Samsung MSM8974 git repo (default is this script's location)
RDIR=$(pwd)


# directory containing cross-compile arm toolchain
# https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9
TOOLCHAIN=`pwd`/../toolchain/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9

# amount of cpu threads to use in kernel make process
CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
THREADS=$((CPU_THREADS + 1))


export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN/bin/arm-linux-androideabi-


make clean
make mrproper
make lineageos_victara_defconfig
make -j"$THREADS" CONFIG_NO_ERROR_ON_MISMATCH=y

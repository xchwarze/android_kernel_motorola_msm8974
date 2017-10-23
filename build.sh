#!/bin/bash
# NetHunter kernel for Motorola MSM8974 devices build script by DSR!
# Based on jcadduono work - This build script is for LineageOS only!

export ARCH=arm
export SUBARCH=arm

CONTINUE=false

# root directory of NetHunter git repo (default is this script's location)
RDIR=$(pwd)

# version number
[ "$VER" ] ||
VER=$(cat "$RDIR/VERSION")

# ndk
# TOOLCHAIN=`pwd`/../ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64
# export CROSS_COMPILE=$TOOLCHAIN/bin/arm-linux-androideabi-

# linaro
# TOOLCHAIN=`pwd`/../toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf
# export CROSS_COMPILE=$TOOLCHAIN/bin/arm-linux-gnueabihf-

# Uber Linaro
# git clone https://bitbucket.org/UBERTC/arm-eabi-4.9.git
TOOLCHAIN=`pwd`/../toolchain/arm-eabi-4.9
export CROSS_COMPILE=$TOOLCHAIN/bin/arm-eabi-


# amount of cpu threads to use in kernel make process
CPU_THREADS=$(grep -c "processor" /proc/cpuinfo)
THREADS=$((CPU_THREADS + 1))


ABORT() {
	[ "$1" ] && echo "Error: $*"
	exit 1
}

[ -x "${CROSS_COMPILE}gcc" ] ||
ABORT "Unable to find gcc cross-compiler at location: ${CROSS_COMPILE}gcc"

while [ $# != 0 ]; do
	if [ "$1" = "--continue" ] || [ "$1" == "-c" ]; then
		CONTINUE=true
	elif [ ! "$MEXTRA" ]; then
		MEXTRA=$1
	else
		echo "Too many arguments!"
		echo "Usage: ./build.sh [--continue] [device] [variant] [target defconfig]"
		ABORT
	fi
	shift
done

[ "$MEXTRA" ] || MEXTRA=""

DEFCONFIG="kali-lite_victara_defconfig"
[ -f "$RDIR/arch/$ARCH/configs/${DEFCONFIG}" ] ||
ABORT "Device config $DEFCONFIG not found in $ARCH configs!"


CLEAN_BUILD() {
	echo "Cleaning build..."
	rm -rf build
}

SETUP_BUILD() {
	echo "Creating kernel config for $DEFCONFIG..."
	mkdir -p build

	make clean
	make mrproper

	make -C "$RDIR" O=build "$DEFCONFIG" \
		|| ABORT "Failed to set up build!"
}

BUILD_KERNEL() {
	echo "Starting build for $DEFCONFIG with $THREADS threads"

	# while ! make -C "$RDIR" O=build V=1 -j"$THREADS" CONFIG_NO_ERROR_ON_MISMATCH=y; do
	while ! make -C "$RDIR" O=build -j"$THREADS" CONFIG_NO_ERROR_ON_MISMATCH=y; do
		read -rp "Build failed. Retry? " do_retry
		case $do_retry in
			Y|y) continue ;;
			*) return 1 ;;
		esac
	done
}

INSTALL_MODULES() {
	grep -q 'CONFIG_MODULES=y' build/.config || return 0
	echo "Installing kernel modules to build/lib/modules..."
	while ! make -C "$RDIR" O=build \
			INSTALL_MOD_PATH="." \
			INSTALL_MOD_STRIP=1 \
			modules_install
	do
		read -rp "Build failed. Retry? " do_retry
		case $do_retry in
			Y|y) continue ;;
			*) return 1 ;;
		esac
	done
	rm build/lib/modules/*/build build/lib/modules/*/source
}

cd "$RDIR" || ABORT "Failed to enter $RDIR!"

if ! $CONTINUE; then
	CLEAN_BUILD
	SETUP_BUILD ||
	ABORT "Failed to set up build!"
fi

BUILD_KERNEL &&
INSTALL_MODULES &&
echo "Finished building $DEFCONFIG!"

#!/bin/bash

set -x

try () {
	"$@" || exit -1
}

# iOS SDK Environmnent
export SDKVER=`xcodebuild -showsdks | fgrep "iphoneos" | tail -n 1 | awk '{print $2}'`
export SDKROOT=$(xcodebuild -version -sdk iphoneos Path)
export SIMULATORSDKVER=`xcodebuild -showsdks | fgrep "iphonesimulator" | tail -n 1 | awk '{print $4}'`
export SIMULATORSDKROOT=$(xcodebuild -version -sdk iphonesimulator Path)

if [ ! -d $SDKROOT ]; then
	echo "Unable to found the Xcode iPhoneOS.platform"
	echo
	echo "The path is automatically set from 'xcode-select -print-path'"
	echo " + /Platforms/iPhoneOS.platform/Developer"
	echo
	echo "Ensure 'xcode-select -print-path' is set."
	exit 1
fi

# version of packages
export PYTHON_VERSION=2.7.1
export SDLTTF_VERSION=2.0.10
export FT_VERSION=2.4.8
export XML2_VERSION=2.7.8
export XSLT_VERSION=1.1.26
export LXML_VERSION=2.3.1

# where the build will be located
export KIVYIOSROOT="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
export BUILDROOT="$KIVYIOSROOT/build"
export TMPROOT="$KIVYIOSROOT/tmp"
export CACHEROOT="$KIVYIOSROOT/.cache"

# pkg-config for SDL and futures
try mkdir -p $BUILDROOT/pkgconfig
export PKG_CONFIG_PATH="$BUILDROOT/pkgconfig:$PKG_CONFIG_PATH"

# some tools
export CCACHE=$(which ccache)

# flags for arm compilation
export ARM_CC="$CCACHE $(xcrun -find -sdk iphoneos arm-apple-darwin10-llvm-gcc-4.2)"
export ARM_AR=$(xcrun -find -sdk iphoneos ar)
export ARM_LD=$(xcrun -find -sdk iphoneos ld)
export ARM_CFLAGS="-march=armv7 -mcpu=arm176jzf -mcpu=cortex-a8"
export ARM_CFLAGS="$ARM_CFLAGS -pipe -no-cpp-precomp"
export ARM_CFLAGS="$ARM_CFLAGS -isysroot $SDKROOT"
export ARM_CFLAGS="$ARM_CFLAGS -miphoneos-version-min=$SDKVER"
export ARM_LDFLAGS="-isysroot $SDKROOT"
export ARM_LDFLAGS="$ARM_LDFLAGS -miphoneos-version-min=$SDKVER"

# xcode
#export I386_CC=$(xcrun -find -sdk "$SDK" llvm-gcc)
export I386_CC="$CCACHE $(xcrun -find -sdk iphonesimulator llvm-gcc)"
export I386_LD=$(xcrun -find -sdk iphonesimulator ld)
export I386_CFLAGS="-m32 -isysroot $SIMULATORSDKROOT -miphoneos-version-min=$SIMULATORSDKVER"
export I386_LDFLAGS="-m32 -isysroot $SIMULATORSDKROOT -static-libgcc -miphoneos-version-min=$SIMULATORSDKVER"


# uncomment this line if you want debugging stuff
export ARM_CFLAGS="$ARM_CFLAGS -O3"
#export ARM_CFLAGS="$ARM_CFLAGS -O0 -g"

# create build directory if not found
try mkdir -p $BUILDROOT
try mkdir -p $BUILDROOT/include
try mkdir -p $BUILDROOT/lib
try mkdir -p $CACHEROOT
try mkdir -p $TMPROOT

# one method to deduplicate some symbol in libraries
function deduplicate() {
	fn=$(basename $1)
	echo "== Trying to remove duplicate symbol in $1"
	try mkdir ddp
	try cd ddp
	try ar x $1
	try ar rc $fn *.o
	try ranlib $fn
	try mv -f $fn $1
	try cd ..
	try rm -rf ddp
}

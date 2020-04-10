#!/bin/bash

### conf ##
ANDROID="$2"
if [ "$ANDROID" == "" ]; then
	ANDROID="/Developer/android-chain/bin"
fi


set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ORIG="$( pwd )"



### params ###
if [ "$1" == "android64" ] || [ "$1" == "android" ]; then
	cpp="$ANDROID/aarch64-linux-android21-clang++"
	ar="$ANDROID/aarch64-linux-android-ar"
	plat="android64"
	plat_exe_flags="-static -lc++_static"
elif [ "$1" == "android32"  ]; then
	cpp="$ANDROID/armv7a-linux-androideabi21-clang++"
	ar="$ANDROID/arm-linux-androideabi-ar"
	plat="android32"
	plat_exe_flags="-static -lc++_static"
elif [ "$1" == "android_x64"  ]; then
	cpp="$ANDROID/x86_64-linux-android21-clang++"
	ar="$ANDROID/x86_64-linux-android-ar"
	plat="android_x64"
	plat_exe_flags="-static -lc++_static"
elif [ "$1" == "android_i686"  ]; then
	cpp="$ANDROID/i686-linux-android21-clang++"
	ar="$ANDROID/i686-linux-android-ar"
	plat="android_i686"
	plat_exe_flags="-static -lc++_static"
else
	cpp="g++"
	ar="ar"
	INSTALL="/usr/local/bin/temporal"
	plat="`uname`"
	if [ "$plat" == "Darwin"  ]; then
		plat="MacOSX"
	elif [ "$plat" == ""  ]; then
		plat="Native"
	fi
fi

BUILD="build/${plat}"
RESULT="result/${plat}"



### START ### 

echo "Building '${plat}'"
echo "Creating folders"
mkdir -p build
mkdir -p result
mkdir -p "$RESULT"
mkdir -p "$BUILD"
cd "$DIR/${BUILD}"
echo "Compiling in: $( pwd )"
$cpp  -fPIC  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
$cpp  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/temporal.cpp"
$cpp  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ../..
echo "Linking in: $( pwd )"
$cpp  -fPIC  -pthread ${plat_exe_flags} ${BUILD}/gen.o ${BUILD}/temporal.o -o ${RESULT}/temporal
$ar   rcs      ${RESULT}/TemporalLib.a ${BUILD}/gen.o ${BUILD}/lib.o
cp Src/TemporalLib.h ${RESULT}/TemporalLib.h # lets be nice... friendly 
echo ""
echo "Created Product at: $( pwd )/${RESULT}"
echo ""
### FINISH ### 



cd "$ORIG"

if [ "$1" != "noinstall" ] && [ "$INSTALL" != "" ]; then
	echo "Installing temporal at: ${INSTALL}" 
	sudo cp "${RESULT}/temporal" "$INSTALL"
fi

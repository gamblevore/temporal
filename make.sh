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
	cpp="$ANDROID/aarch64-linux-android29-clang++"
	ar="$ANDROID/aarch64-linux-android-ar"
	plat="android64"
elif [ "$1" == "android32"  ]; then
	cpp="$ANDROID/armv7a-linux-androideabi29-clang++"
	#ar="$ANDROID/arm-linux-androideabi-ar"
	ar="$ANDROID/llvm-ar"
	plat="android32"
else
	cpp="g++"
	ar="ar"
	plat="Native" #whatever platform you happen to be using.
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
$cpp  -fPIC  -pthread ${BUILD}/gen.o ${BUILD}/temporal.o -o ${RESULT}/temporal
$ar   rcs      ${RESULT}/TemporalLib.a ${BUILD}/gen.o ${BUILD}/lib.o
cp Src/TemporalLib.h ${RESULT}/TemporalLib.h # lets be nice... friendly 
echo ""
echo "Created Product at: $( pwd )/${RESULT}"
echo ""
### FINISH ### 



cd "$ORIG"

if [ "$1" != "noinstall" ] && [ plat == "" ]; then
	sudo cp "$DIR/result/temporal" "/usr/local/bin/temporal"
fi

#!/bin/bash

### conf ##
ANDROID="/Developer/android-chain/bin"


set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ORIG="$( pwd )"



### params ###
if [ "$1" == "android64" ] || [ "$1" == "android" ]; then
	echo "build android 64"
	cpp="$ANDROID/aarch64-linux-android29-clang++"
	ar="$ANDROID/aarch64-linux-androideabi-ar"
	plat="android64_"
elif [ "$1" == "android32"  ]; then
	echo "build android 32"
	cpp="$ANDROID/armv7a-linux-androideabi29-clang++"
	#ar="$ANDROID/arm-linux-androideabi-ar"
	ar="$ANDROID/llvm-ar"
	plat="android32_"
else
	echo "building generic"
	cpp="g++"
	ar="ar"
	plat=""
fi




### START ### 
mkdir -p "$DIR/${plat}build"
mkdir -p "$DIR/${plat}result"
cd "$DIR/${plat}build"
$cpp  -fPIC  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
$cpp  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/temporal.cpp"
$cpp  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ..
$cpp  -fPIC  -pthread ${plat}build/gen.o ${plat}build/temporal.o -o ${plat}result/temporal
$ar   rcs      ${plat}result/TemporalLib.a ${plat}build/gen.o ${plat}build/lib.o
### FINISH ### 



cd "$ORIG"

if [ "$1" != "noinstall" ] && [ plat == "" ]; then
	sudo cp "$DIR/result/temporal" "/usr/local/bin/temporal"
fi

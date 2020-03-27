#!/bin/bash

### conf ##
ANDROID="/Developer/android-chain/bin"


set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ORIG="$( pwd )"



### params ###
if [ "$1" == "android" ]; then
	cpp="$ANDROID/arm-linux-androideabi-g++"
	ar="$ANDROID/arm-linux-androideabi-ar"
	plat="android_"
else
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

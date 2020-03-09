#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ORIG="$( pwd )"

# You can run these commands without the script...
mkdir -p "$DIR/build"
mkdir -p "$DIR/result"
cd "$DIR/build"
g++  -fPIC  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
g++  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/temporal.cpp"
g++  -fPIC  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ..
g++  -fPIC  -pthread build/gen.o build/temporal.o -o result/temporal
ar   rcs      result/TemporalLib.a build/gen.o build/lib.o
cd "$ORIG"

if [ "$1" != "noinstall" ]; then
	sudo cp "$DIR/result/temporal" "/usr/local/bin/temporal"
fi


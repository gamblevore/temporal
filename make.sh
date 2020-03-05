#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# You can run these commands without the script...
mkdir -p build
mkdir -p result
cd build
g++  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/temporal.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ..
g++  -pthread build/gen.o build/temporal.o -o result/temporal
ar   rcs      result/TemporalLib.a build/gen.o build/lib.o


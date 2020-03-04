#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# You can run these commands without the script...
mkdir -p build
mkdir -p temporal
cd build
g++  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/vis.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/dump.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ..
g++  -pthread build/gen.o build/vis.o -o temporal/tvis
g++  -pthread build/gen.o build/dump.o -o temporal/tdump
ar   rcs      temporal/TemporalLib.a build/gen.o build/lib.o



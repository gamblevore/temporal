#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# You can run these commands without the script...
mkdir -p build
mkdir -p temporal
cd build
g++  -std=c++0x  -O0  -c  "$DIR/Src/gen.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/demo.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/dump.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/lib.cpp"
cd ..
g++  -pthread build/gen.o build/demo.o -o temporal/temporal_demo
g++  -pthread build/gen.o build/dump.o -o temporal/temporal_dump
ar   rcs      temporal/temporal_lib.a build/gen.o build/lib.o



#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# You can run these commands without the script...
mkdir -p build
cd build
g++  -std=c++0x  -O0  -c  "$DIR/Src/tmp_gen.cpp"
g++  -std=c++0x  -Os  -c  "$DIR/Src/temporal.cpp"
cd ..
g++  -pthread build/*.o -o temporal

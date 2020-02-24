#!/bin/bash
set -e #exit on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR

# You can run these commands without the script...
mkdir -p build
cd build
g++  -std=c++0x  -O0  -c  ../Src/tmp_gen.cpp
g++  -std=c++0x  -Os  -c  ../Src/temporal.cpp
g++ -pthread *.o -o temporal

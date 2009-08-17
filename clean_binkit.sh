#!/bin/bash

set -e

cd milkymist-core
./clean_all.sh
cd ..
cd ml401-flasher
cd board
make clean
cd ..
cd host
make clean
cd ../..
rm -rf binkit
rm -f binkit-ml401.tar.bz2

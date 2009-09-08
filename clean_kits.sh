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
rm -f milkymist_binkit_ml401.tar.bz2
rm -f milkymist_binkit_sp3aevl.tar.bz2
rm -f milkymist_binkit_one.tar.bz2

rm -rf dockit
rm -f milkymist_dockit.tar.bz2

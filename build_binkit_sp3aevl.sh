#!/bin/bash

set -e

# Set the board variable
# for the build scripts in milkymist-core
export BOARD=avnet-sp3aevl

unset LANG
unset LOCALE

# Build all we need
cd milkymist-core
./build_bitstream.sh
./build_bios.sh
cd ..

echo "======================================="
echo "Packing binaries"
echo "======================================="
echo ""

# Pack everything
echo -n "Preparing files..."
rm -rf binkit
mkdir binkit

cp milkymist-core/boards/avnet-sp3aevl/synthesis/build/system.bit binkit/
cp milkymist-core/synthesis.log binkit/

mkdir binkit/flash
cp milkymist-core/software/bios/bios.bin binkit/flash/

cp milkymist-core/tools/flterm binkit/

cat << EOF > binkit/README
This is a binary distribution of Milkymist(tm), an open hardware
FPGA-based videosynth platform.

Built for the Avnet Spartan-3A evaluation kit.

You can find source and more information at :
  http://www.milkymist.org
Milkymist is copyrighted software.
EOF

date > binkit/TIMESTAMP
echo "OK"

# Make a tarball
echo -n "Generating tarball..."
rm -f milkymist_binkit_sp3aevl.tar.bz2
tar cjf milkymist_binkit_sp3aevl.tar.bz2 binkit
echo "OK"

echo ""
echo "All done !"

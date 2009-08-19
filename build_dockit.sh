#!/bin/bash

set -e

cd milkymist-core
./build_doc.sh
cd ..

rm -rf dockit
mkdir dockit
find milkymist-core -name *.pdf -exec cp {} dockit \;
rm -f milkymist_dockit.tar.bz2
tar cjf milkymist_dockit.tar.bz2 dockit

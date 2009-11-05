#!/bin/bash

BASEDIR=`pwd`

source $BASEDIR/coredoc.inc

cd $BASEDIR/tools && make clean

cd $BASEDIR/software/libbase && make clean
cd $BASEDIR/software/libmath && make clean
cd $BASEDIR/software/libhal && make clean
cd $BASEDIR/software/bios && make clean
cd $BASEDIR/software/demo && make clean

cd $BASEDIR/boards/xilinx-ml401/synthesis && make -f common.mak clean
cd $BASEDIR/boards/avnet-sp3aevl/synthesis && make -f common.mak clean
cd $BASEDIR/boards/milkymist-one/synthesis && make -f common.mak clean

cd $BASEDIR/doc && make clean
for i in $COREDOC; do
	cd $BASEDIR/cores/$i/doc && make clean
done 

cd $BASEDIR/cores/pfpu
./cleanroms.sh

cd $BASEDIR

rm -f tools.log software.log synthesis.log doc.log load.log biosflash.log bitflash.log

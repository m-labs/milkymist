#!/bin/bash

BASEDIR=`pwd`

source $BASEDIR/coredoc.inc

cd $BASEDIR/tools && make clean

cd $BASEDIR/software/libhpdmc && make clean
cd $BASEDIR/software/libbase && make clean
cd $BASEDIR/software/libmath && make clean
cd $BASEDIR/software/libhal && make clean
cd $BASEDIR/software/libfpvm && make clean
cd $BASEDIR/software/libfpvm/x86-linux && make clean
cd $BASEDIR/software/libfpvm/lm32-linux && make clean
cd $BASEDIR/software/libfpvm/lm32-rtems && make clean
cd $BASEDIR/software/libnet && make clean
cd $BASEDIR/software/bios && make clean
cd $BASEDIR/software/demo && make clean

cd $BASEDIR/softusb-input && make clean

cd $BASEDIR/boards/milkymist-one/synthesis && make -f common.mak clean
cd $BASEDIR/boards/milkymist-one/flash && make clean

cd $BASEDIR/doc && make clean
for i in $COREDOC; do
	cd $BASEDIR/cores/$i/doc && make clean
done 

cd $BASEDIR/cores/pfpu
./cleanroms.sh

cd $BASEDIR

rm -f tools.log software.log synthesis.log doc.log load.log

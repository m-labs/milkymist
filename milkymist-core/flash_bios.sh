#!/bin/bash

source setup.inc

BASEDIR=`pwd`
LOGFILE=$BASEDIR/biosflash.log
BIOSDIR=$BASEDIR/software/bios

echo "================================================================================"
echo "Flashing Milkymist BIOS"
if [ -z $NOSPLASH ] ; then
	BIOSFILE=$BIOSDIR/bios_splash.bin
else
	BIOSFILE=$BIOSDIR/bios.bin
	echo "Splash screen flashing disabled"
fi
echo ""
echo "Board:    $BOARD"
echo "Log file: $LOGFILE"
echo "================================================================================"
echo ""

if [ $BOARD == "xilinx-ml401" ] ; then
	FLASHERDIR=$BASEDIR/../ml401-flasher
else
	echo "Unsupported board, aborting."
	exit
fi

echo "Flashing BIOS into NOR flash..."

echo -n "  Building and loading flasher bitstream..."
cd $FLASHERDIR/board
make load > $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

echo -n "  Building host-side flasher tool..."
cd $FLASHERDIR/host
make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

echo -n "  Writing flash..."
./flasher $BIOSFILE >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

cd $BASEDIR

echo "Flashing complete!"

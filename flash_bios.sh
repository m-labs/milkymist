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

echo "Flashing BIOS into NOR flash..."

echo >> $LOGFILE
date >> $LOGFILE

if [ $BOARD == "xilinx-ml401" ] ; then
	echo -n "  Loading flasher bitstream..."
	load-ml401-flasher > $LOGFILE 2>&1
	if [ "$?" != 0 ] ; then
		echo "FAILED"
		exit 1
	else
		echo "OK"
	fi

	echo -n "  Writing flash..."
	ml401-flasher $BIOSFILE >> $LOGFILE 2>&1
	if [ "$?" != 0 ] ; then
		echo "FAILED"
		exit 1
	else
		echo "OK"
	fi
else
	echo "Unsupported board, aborting."
	exit
fi

echo "Flashing complete!"

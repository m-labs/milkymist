#!/bin/bash

source setup.inc

BASEDIR=`pwd`
LOGFILE=$BASEDIR/bitflash.log

echo "================================================================================"
echo "Flashing Milkymist bitstream file"
echo ""
echo "Board:    $BOARD"
echo "Log file: $LOGFILE"
echo "================================================================================"
echo ""

echo -n "Flashing FPGA bitstream..."
echo >> $LOGFILE
date >> $LOGFILE
cd $BASEDIR/boards/$BOARD/synthesis && make -f Makefile.$SYNTOOL flash > $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

cd $BASEDIR

echo "Flashing complete!"

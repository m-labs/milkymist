#!/bin/bash

source setup.inc

BASEDIR=`pwd`
LOGFILE=$BASEDIR/load.log

echo "================================================================================"
echo "Loading Milkymist bitstream file"
echo ""
echo "Board:    $BOARD"
echo "Log file: $LOGFILE"
echo "================================================================================"
echo ""

echo -n "Loading FPGA bitstream..."
cd $BASEDIR/boards/$BOARD/synthesis && make -f Makefile.$SYNTOOL load > $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

cd $BASEDIR

echo "Load complete!"

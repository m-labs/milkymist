#!/bin/bash

if [ -z "$PORT" ]
then
	PORT=/dev/ttyUSB0
fi

if [ -z "$LOADADDR" ]
then
	LOADADDR=0x40000000
fi

if [ -z "$IMAGE" ]
then
	IMAGE=software/demo/boot.bin
fi

BASEDIR=`pwd`
LOGFILE=$BASEDIR/tools.log

echo "================================================================================"
echo "Starting Milkymist debug terminal"
echo ""
echo "Log file (host): $LOGFILE"
echo "Serial port:     $PORT"
echo "Image:           $IMAGE"
echo "Load address:    $LOADADDR"
echo "================================================================================"
echo ""

echo -n "Building host utilities..."
cd $BASEDIR/tools
make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

echo "Executing flterm..."

exec $BASEDIR/tools/flterm --port $PORT --kernel $BASEDIR/$IMAGE --kernel-adr $LOADADDR

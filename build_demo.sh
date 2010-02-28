#!/bin/bash

BASEDIR=`pwd`
LOGFILEHOST=$BASEDIR/tools.log
LOGFILE=$BASEDIR/software.log

echo "================================================================================"
echo "Building Milkymist demo firmware"
echo ""
echo "Log file (host):   $LOGFILEHOST"
echo "Log file (target): $LOGFILE"
echo "================================================================================"
echo ""

BASEDIR=`pwd`

echo -n "Building host utilities..."
cd $BASEDIR/tools
echo >> $LOGFILEHOST
date >> $LOGFILEHOST
make >> $LOGFILEHOST 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

echo "Building embedded software:"
echo -n "  Base library..."
echo >> $LOGFILE
date >> $LOGFILE
cd $BASEDIR/software/libbase && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
echo -n "  Math library..."
cd $BASEDIR/software/libmath && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
echo -n "  HAL..."
cd $BASEDIR/software/libhal && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
echo -n "  Networking library..."
cd $BASEDIR/software/libnet && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
echo -n "  Demonstration firmware..."
cd $BASEDIR/software/demo && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

cd $BASEDIR

echo "Build complete!"

#!/bin/bash

BASEDIR=`pwd`
LOGFILEHOST=$BASEDIR/tools.log
LOGFILE=$BASEDIR/software.log

echo "================================================================================"
echo "Building Milkymist BIOS image"
echo ""
echo "Log file (host):   $LOGFILEHOST"
echo "Log file (target): $LOGFILE"
echo "================================================================================"
echo ""

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

echo "Building embedded software :"
echo -n "  HPDMC runtime..."
echo >> $LOGFILE
date >> $LOGFILE
cd $BASEDIR/software/libhpdmc && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
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
echo -n "  Networking library..."
cd $BASEDIR/software/libnet && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi
echo -n "  BIOS..."
cd $BASEDIR/software/bios && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
	exit 1
else
        echo "OK"
fi

cd $BASEDIR

echo "Build complete!"

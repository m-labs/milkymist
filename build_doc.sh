#!/bin/bash

source coredoc.inc
BASEDIR=`pwd`
LOGFILE=$BASEDIR/doc.log

echo "================================================================================"
echo "Building Milkymist documentation"
echo ""
echo "Log file: $LOGFILE"
echo "================================================================================"
echo ""

echo -n "Building system documentation..."
echo >> $LOGFILE
date >> $LOGFILE
cd $BASEDIR/doc && make >> $LOGFILE 2>&1
if [ "$?" != 0 ] ; then
        echo "FAILED"
else
        echo "OK"
fi

echo "Building IP core documentation..."
for i in $COREDOC; do
	echo -n "  $i..."
	cd $BASEDIR/cores/$i/doc && make >> $LOGFILE 2>&1
	if [ "$?" != 0 ] ; then
        	echo "FAILED"
	else
        	echo "OK"
	fi
done

cd $BASEDIR

echo "Build complete!"

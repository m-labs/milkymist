#!/bin/sh
for i in *.po; do
	l=`echo $i|sed s/\\.po//`
	echo "Compiling messages for locale $l"
	msgfmt -c -v -o ../locale/$l/LC_MESSAGES/sample.mo $i
done


#/bin/sh
l=$1
if [ "$l" == "" ]; then
	echo "Please specify the locale"
	exit 1
fi

echo "Initializing translation file for locale $l"
msginit -l $l -o $l.po -i sample.pot

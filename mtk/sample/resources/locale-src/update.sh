#/bin/sh
l=$1
if [ "$l" == "" ]; then
	echo "Please specify the locale"
	exit 1
fi

echo "Updating translation file for locale $l"

msgmerge -s -U $l.po sample.pot

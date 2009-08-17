#!/bin/sh
exec xgettext -d sample --keyword=_ -s -o sample.pot ../../*.cpp

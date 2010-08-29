#!/bin/sh
set -e
mkdir -p impact_sucks
cd impact_sucks
cat ../template.cmd | sed s/__FILE__/..\\/$1/g > flash.cmd
impact -batch flash.cmd
cat flash.cmd
cd ..
rm -rf impact_sucks

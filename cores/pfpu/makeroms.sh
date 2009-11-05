#!/bin/bash

set -e

gcc -o sinrom -O2 scripts/sinrom.c -lm
./sinrom > roms/sin.rom

#!/bin/bash

make -C libbase depend
make -C libmath depend
make -C libhal depend
make -C libfpvm depend
make -C libnet depend
make -C bios depend

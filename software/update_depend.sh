#!/bin/bash

make -C libbase depend
make -C libmath depend
make -C libhal depend
make -C bios depend
make -C demo depend

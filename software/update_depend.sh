#!/bin/bash

make -C libbase depend
make -C libhal depend
make -C libnet depend
make -C bios depend

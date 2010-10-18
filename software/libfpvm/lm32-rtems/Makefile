CC=lm32-rtems4.11-gcc
CFLAGS=-O9 -mmultiply-enabled -mdivide-enabled -mbarrel-shift-enabled -msign-extend-enabled -DPRINTF_FLOAT -I$(MMDIR)/software/include
AR=lm32-rtems4.11-ar
RANLIB=lm32-rtems4.11-ranlib

include ../subdir.mak

install: all
	test -n "$(RTEMS_MAKEFILE_PATH)"
	cp libfpvm.a $(RTEMS_MAKEFILE_PATH)/lib
	mkdir -p $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm
	cp ../../include/fpvm/* $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm

.PHONY: install

MMDIR=../..
INCLUDES_NOLIBC=-DPRINTF_FLOAT 
include $(MMDIR)/software/include.mak

OBJECTS=fpvm.o gfpus.o lnfpus.o pfpu.o

.PHONY: all clean install

all: libfpvm.a

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

install: all
	test -n "$(RTEMS_MAKEFILE_PATH)"
	cp libfpvm.a $(RTEMS_MAKEFILE_PATH)/lib
	mkdir -p $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm
	cp ../include/fpvm/* $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm

clean:
	rm -f $(OBJECTS) libfpvm.a
	rm -f .*~ *~ Makefile.bak

MMDIR=../..
INCLUDES_NOLIBC=-DPRINTF_FLOAT 
include $(MMDIR)/software/include.mak

OBJECTS=fpvm.o gfpus.o lnfpus.o pfpu.o

.PHONY: all clean depend install

all: libfpvm.a

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

install: all
	test -n "$(RTEMS_MAKEFILE_PATH)"
	cp libfpvm.a $(RTEMS_MAKEFILE_PATH)/lib
	mkdir -p $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm
	cp ../include/fpvm/* $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) libfpvm.a
	rm -f .*~ *~ Makefile.bak

# DO NOT DELETE

fpvm.o: ../../software/include/base/version.h
fpvm.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
fpvm.o: ../../software/include/fpvm/ast.h
gfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
gfpus.o: ../../software/include/fpvm/ast.h ../../software/include/fpvm/pfpu.h
gfpus.o: ../../software/include/fpvm/schedulers.h
gfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
lnfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
lnfpus.o: ../../software/include/fpvm/ast.h
lnfpus.o: ../../software/include/fpvm/pfpu.h
lnfpus.o: ../../software/include/fpvm/schedulers.h
lnfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/fpvm/fpvm.h ../../software/include/fpvm/is.h
pfpu.o: ../../software/include/fpvm/ast.h ../../software/include/fpvm/pfpu.h

MMDIR=../..
INCLUDES_NOLIBC=-DPRINTF_FLOAT 
include $(MMDIR)/software/include.mak

OBJECTS=fpvm.o parser_helper.o scanner.o parser.o gfpus.o lnfpus.o pfpu.o \
	unique.o fpvm-export.o

.PHONY: all clean depend install

all: libfpvm.a

%.c: %.re
	re2c -o $@ $<

scanner.c: parser.h

parser.h: parser.c

%.c: %.y
	lemon $<

%.h %.inc: %.ids
	./idgen $<

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

install: all
	test -n "$(RTEMS_MAKEFILE_PATH)"
	cp libfpvm.a $(RTEMS_MAKEFILE_PATH)/lib
	mkdir -p $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm
	cp ../include/fpvm/* $(RTEMS_MAKEFILE_PATH)/lib/include/fpvm

depend: parser.c scanner.c
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) scanner.c parser.c parser.h parser.out libfpvm.a
	rm -f .*~ *~ Makefile.bak
	rm -f fnp.h fnp.inc

# DO NOT DELETE

fpvm-export.o: ../../software/include/fpvm/fpvm.h
fpvm-export.o: ../../software/include/fpvm/is.h
fpvm-export.o: ../../software/include/fpvm/ast.h unique.h parser_helper.h
fpvm.o: ../../software/include/base/version.h
fpvm.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
fpvm.o: ../../software/include/fpvm/ast.h
gfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
gfpus.o: ../../software/include/fpvm/pfpu.h
gfpus.o: ../../software/include/fpvm/schedulers.h
gfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
lnfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
lnfpus.o: ../../software/include/fpvm/pfpu.h
lnfpus.o: ../../software/include/fpvm/schedulers.h
lnfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
parser.o: ../../software/include/fpvm/ast.h parser_itf.h parser.h
parser_helper.o: ../../software/include/fpvm/ast.h scanner.h parser.h
parser_helper.o: parser_itf.h parser_helper.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/fpvm/fpvm.h ../../software/include/fpvm/is.h
pfpu.o: ../../software/include/fpvm/pfpu.h
scanner.o: unique.h scanner.h parser.h
test.o: fnp.h unique.h
unique.o: unique.h fnp.inc

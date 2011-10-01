MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=fpvm.o parser_helper.o scanner.o parser.o gfpus.o lnfpus.o pfpu.o

all: libfpvm.a

%.c: %.re
	re2c -o $@ $<

scanner.c: parser.h

parser.h: parser.c

%.c: %.y
	lemon $<

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

.PHONY: clean depend

depend: parser.c scanner.c
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) scanner.c parser.c parser.h parser.out libfpvm.a .*~ *~ Makefile.bak

# DO NOT DELETE

fpvm.o: ../../software/include/base/string.h
fpvm.o: ../../software/include/base/stdlib.h
fpvm.o: ../../software/include/base/stdio.h
fpvm.o: ../../software/include/base/version.h
fpvm.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
fpvm.o: ast.h parser_helper.h
gfpus.o: ../../software/include/base/stdio.h
gfpus.o: ../../software/include/base/stdlib.h
gfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
gfpus.o: ../../software/include/fpvm/pfpu.h
gfpus.o: ../../software/include/fpvm/schedulers.h
gfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
lnfpus.o: ../../software/include/base/stdlib.h
lnfpus.o: ../../software/include/base/stdio.h
lnfpus.o: ../../software/include/base/string.h
lnfpus.o: ../../software/include/base/assert.h
lnfpus.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/fpvm.h
lnfpus.o: ../../software/include/fpvm/pfpu.h
lnfpus.o: ../../software/include/fpvm/schedulers.h
lnfpus.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
parser.o: ../../software/include/base/stdio.h
parser.o: ../../software/include/base/stdlib.h
parser.o: ../../software/include/base/assert.h
parser.o: ../../software/include/base/string.h
parser.o: ../../software/include/base/malloc.h
parser.o: ../../software/include/base/math.h ast.h
parser_helper.o: ../../software/include/base/stdio.h
parser_helper.o: ../../software/include/base/stdlib.h
parser_helper.o: ../../software/include/base/malloc.h scanner.h parser.h
parser_helper.o: ast.h parser_helper.h
pfpu.o: ../../software/include/base/stdio.h
pfpu.o: ../../software/include/base/stdlib.h ../../software/include/hw/pfpu.h
pfpu.o: ../../software/include/hw/common.h ../../software/include/fpvm/fpvm.h
pfpu.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/pfpu.h
scanner.o: ../../software/include/base/stdio.h
scanner.o: ../../software/include/base/stdlib.h
scanner.o: ../../software/include/base/string.h
scanner.o: ../../software/include/base/malloc.h scanner.h parser.h

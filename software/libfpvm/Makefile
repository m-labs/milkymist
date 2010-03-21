MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=fpvm.o parser_helper.o scanner.o parser.o

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
	rm -f $(OBJECTS) scanner.c parser.c parser.h parser.out libfpvm.a  boot.bin .*~ *~ Makefile.bak

# DO NOT DELETE

fpvm.o: ../../software/include/base/string.h
fpvm.o: ../../software/include/base/stdlib.h ../../software/include/fpvm/is.h
fpvm.o: ../../software/include/fpvm/fpvm.h ast.h parser_helper.h
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
scanner.o: ../../software/include/base/stdio.h
scanner.o: ../../software/include/base/stdlib.h
scanner.o: ../../software/include/base/string.h
scanner.o: ../../software/include/base/malloc.h scanner.h parser.h

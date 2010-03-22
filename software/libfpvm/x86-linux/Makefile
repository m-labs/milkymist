CC=gcc
CFLAGS=-O2 -DPRINTF_FLOAT -I$(MMDIR)/software/include
AR=ar
RANLIB=ranlib

OBJECTS=fpvm.o parser_helper.o scanner.o parser.o

all: libfpvm.a

%.c: %.re
	re2c -o $@ $<

../scanner.c: ../parser.h

../parser.h: ../parser.c

../parser_helper.c: ../parser.h

%.c: %.y
	lemon $<

%.o: ../%.c
	$(CC) $(CFLAGS) -c -o $@ $<

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

test: test.c libfpvm.a
	$(CC) $(CFLAGS) -o test test.c libfpvm.a

.PHONY: clean

clean:
	rm -f $(OBJECTS) ../scanner.c ../parser.c ../parser.h ../parser.out libfpvm.a test .*~ *~ Makefile.bak

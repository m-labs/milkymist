CC=gcc
CFLAGS=-O2 -DPRINTF_FLOAT -I$(MMDIR)/software/include
AR=ar
RANLIB=ranlib

include ../subdir.mak

test: test.c libfpvm.a
	$(CC) $(CFLAGS) -o test test.c libfpvm.a

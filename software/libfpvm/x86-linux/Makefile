MMDIR?=../../../

CC_normal	= clang
AR_normal	= ar
RANLIB_normal	= ranlib

CC_quiet	= @echo " CC " $@ && $(CC_normal)
AR_quiet	= @echo " AR " $@ && $(AR_normal)
RANLIB_quiet 	= @echo " RANLIB " $@ && $(RANLIB_normal)

ifeq ($(V),1)
    CC = $(CC_normal)
    AR = $(AR_normal)
    RANLIB = $(RANLIB_normal)
else
    CC = $(CC_quiet)
    AR = $(AR_quiet)
    RANLIB = $(RANLIB_quiet)
endif

CFLAGS=-O2 -DPRINTF_FLOAT -I$(MMDIR)/software/include

include ../subdir.mak

test: test.c libfpvm.a
	$(CC) $(CFLAGS) -o test test.c libfpvm.a

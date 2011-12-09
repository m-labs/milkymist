OBJECTS=fpvm.o gfpus.o lnfpus.o pfpu.o

all: libfpvm.a

%.o: ../%.c
	$(CC) $(CFLAGS) -I. -c -o $@ $<

libfpvm.a: $(OBJECTS)
	$(AR) clr libfpvm.a $(OBJECTS)
	$(RANLIB) libfpvm.a

.PHONY: clean

clean:
	rm -f $(OBJECTS) libfpvm.a test .*~ *~ Makefile.bak

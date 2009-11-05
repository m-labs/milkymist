MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS_ALL=divsi3.o libc.o crc16.o crc32.o console.o cfcard.o cffat.o system.o board.o
OBJECTS=$(OBJECTS_ALL) irq.o softfloat.o softfloat-glue.o vsnprintf.o atof.o malloc.o uart-async.o
OBJECTS_LIGHT=$(OBJECTS_ALL) vsnprintf-nofloat.o uart.o

all: libbase-light.a libbase.a

libbase-light.a: $(OBJECTS_LIGHT)
	$(AR) clr libbase-light.a $(OBJECTS_LIGHT)
	$(RANLIB) libbase-light.a

libbase.a: $(OBJECTS)
	$(AR) clr libbase.a $(OBJECTS)
	$(RANLIB) libbase.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libbase.a libbase-light.a .*~ *~ Makefile.bak

# DO NOT DELETE

atof.o: ../../software/include/stdlib.h ../../software/include/ctype.h
board.o: ../../software/include/hw/sysctl.h
board.o: ../../software/include/hw/common.h ../../software/include/stdlib.h
board.o: ../../software/include/board.h
cfcard.o: ../../software/include/hw/systemace.h
cfcard.o: ../../software/include/hw/common.h ../../software/include/cfcard.h
cfcard.o: ../../software/include/console.h
cffat.o: ../../software/include/stdlib.h ../../software/include/stdio.h
cffat.o: ../../software/include/string.h ../../software/include/ctype.h
cffat.o: ../../software/include/endian.h ../../software/include/cfcard.h
cffat.o: ../../software/include/console.h ../../software/include/cffat.h
console.o: ../../software/include/uart.h ../../software/include/console.h
console.o: ../../software/include/stdio.h ../../software/include/stdlib.h
console.o: ../../software/include/stdarg.h
crc16.o: ../../software/include/crc.h
crc32.o: ../../software/include/crc.h
libc.o: ../../software/include/ctype.h ../../software/include/stdio.h
libc.o: ../../software/include/stdlib.h ../../software/include/stdarg.h
libc.o: ../../software/include/string.h ../../software/include/limits.h
malloc.o: ../../software/include/stdio.h ../../software/include/stdlib.h
malloc.o: ../../software/include/string.h ../../software/include/console.h
malloc.o: ../../software/include/malloc.h
softfloat-glue.o: softfloat.h
softfloat.o: milieu.h softfloat.h softfloat-macros.h softfloat-specialize.h
system.o: ../../software/include/hw/fmlbrg.h ../../software/include/system.h
uart-async.o: ../../software/include/uart.h ../../software/include/irq.h
uart-async.o: ../../software/include/hw/uart.h
uart-async.o: ../../software/include/hw/common.h
uart-async.o: ../../software/include/hw/interrupts.h
uart.o: ../../software/include/hw/uart.h ../../software/include/hw/common.h
uart.o: ../../software/include/uart.h
vsnprintf-nofloat.o: ../../software/include/stdlib.h
vsnprintf-nofloat.o: ../../software/include/stdio.h
vsnprintf-nofloat.o: ../../software/include/stdarg.h
vsnprintf-nofloat.o: ../../software/include/string.h
vsnprintf-nofloat.o: ../../software/include/ctype.h
vsnprintf.o: ../../software/include/stdlib.h ../../software/include/stdio.h
vsnprintf.o: ../../software/include/stdarg.h ../../software/include/string.h
vsnprintf.o: ../../software/include/ctype.h

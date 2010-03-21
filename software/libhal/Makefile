MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=brd.o hdlcd.o mem.o pfpu.o slowout.o snd.o time.o tmu.o vga.o

all: libhal.a

libhal.a: $(OBJECTS)
	$(AR) clr libhal.a $(OBJECTS)
	$(RANLIB) libhal.a

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libhal.a .*~ *~ Makefile.bak

# DO NOT DELETE

brd.o: ../../software/include/base/stdlib.h
brd.o: ../../software/include/base/stdio.h
brd.o: ../../software/include/base/board.h ../../software/include/hal/brd.h
hdlcd.o: ../../software/include/base/stdlib.h
hdlcd.o: ../../software/include/base/stdio.h
hdlcd.o: ../../software/include/base/stdarg.h
hdlcd.o: ../../software/include/base/board.h
hdlcd.o: ../../software/include/hw/sysctl.h
hdlcd.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
hdlcd.o: ../../software/include/hal/brd.h
hdlcd.o: ../../software/include/hal/slowout.h
hdlcd.o: ../../software/include/hal/hdlcd.h
mem.o: ../../software/include/base/stdio.h
mem.o: ../../software/include/base/stdlib.h
mem.o: ../../software/include/base/malloc.h ../../software/include/hw/sram.h
mem.o: ../../software/include/hal/mem.h
pfpu.o: ../../software/include/base/stdio.h
pfpu.o: ../../software/include/base/stdlib.h
pfpu.o: ../../software/include/base/irq.h
pfpu.o: ../../software/include/hw/interrupts.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/hal/pfpu.h
slowout.o: ../../software/include/base/stdio.h
slowout.o: ../../software/include/base/stdlib.h
slowout.o: ../../software/include/base/irq.h
slowout.o: ../../software/include/hw/interrupts.h
slowout.o: ../../software/include/hw/sysctl.h
slowout.o: ../../software/include/hw/common.h
slowout.o: ../../software/include/hal/slowout.h
snd.o: ../../software/include/base/stdio.h
snd.o: ../../software/include/base/stdlib.h ../../software/include/base/irq.h
snd.o: ../../software/include/hw/ac97.h ../../software/include/hw/common.h
snd.o: ../../software/include/hw/interrupts.h
snd.o: ../../software/include/hal/snd.h
time.o: ../../software/include/base/stdio.h
time.o: ../../software/include/base/stdlib.h
time.o: ../../software/include/base/irq.h ../../software/include/base/board.h
time.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
time.o: ../../software/include/hw/interrupts.h
time.o: ../../software/include/hal/brd.h ../../software/include/hal/time.h
tmu.o: ../../software/include/base/stdio.h
tmu.o: ../../software/include/base/stdlib.h ../../software/include/base/irq.h
tmu.o: ../../software/include/base/board.h
tmu.o: ../../software/include/hw/interrupts.h ../../software/include/hw/tmu.h
tmu.o: ../../software/include/hw/common.h ../../software/include/hal/brd.h
tmu.o: ../../software/include/hal/tmu.h
vga.o: ../../software/include/base/stdio.h
vga.o: ../../software/include/base/stdlib.h ../../software/include/hw/vga.h
vga.o: ../../software/include/hw/common.h ../../software/include/hal/vga.h

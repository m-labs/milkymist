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

brd.o: ../../software/include/stdlib.h ../../software/include/stdio.h
brd.o: ../../software/include/board.h ../../software/include/hal/brd.h
hdlcd.o: ../../software/include/stdlib.h ../../software/include/stdio.h
hdlcd.o: ../../software/include/stdarg.h ../../software/include/board.h
hdlcd.o: ../../software/include/hw/sysctl.h
hdlcd.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
hdlcd.o: ../../software/include/hal/brd.h
hdlcd.o: ../../software/include/hal/slowout.h
hdlcd.o: ../../software/include/hal/hdlcd.h
mem.o: ../../software/include/stdio.h ../../software/include/stdlib.h
mem.o: ../../software/include/malloc.h ../../software/include/hw/sram.h
mem.o: ../../software/include/hal/mem.h
pfpu.o: ../../software/include/stdio.h ../../software/include/stdlib.h
pfpu.o: ../../software/include/irq.h ../../software/include/hw/interrupts.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/hal/pfpu.h
slowout.o: ../../software/include/stdio.h ../../software/include/stdlib.h
slowout.o: ../../software/include/irq.h
slowout.o: ../../software/include/hw/interrupts.h
slowout.o: ../../software/include/hw/sysctl.h
slowout.o: ../../software/include/hw/common.h
slowout.o: ../../software/include/hal/slowout.h
snd.o: ../../software/include/stdio.h ../../software/include/stdlib.h
snd.o: ../../software/include/irq.h ../../software/include/hw/ac97.h
snd.o: ../../software/include/hw/common.h
snd.o: ../../software/include/hw/interrupts.h
snd.o: ../../software/include/hal/snd.h
time.o: ../../software/include/stdio.h ../../software/include/stdlib.h
time.o: ../../software/include/irq.h ../../software/include/board.h
time.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
time.o: ../../software/include/hw/interrupts.h
time.o: ../../software/include/hal/brd.h ../../software/include/hal/time.h
tmu.o: ../../software/include/stdio.h ../../software/include/stdlib.h
tmu.o: ../../software/include/irq.h ../../software/include/board.h
tmu.o: ../../software/include/hw/interrupts.h ../../software/include/hw/tmu.h
tmu.o: ../../software/include/hw/common.h ../../software/include/hal/brd.h
tmu.o: ../../software/include/hal/tmu.h
vga.o: ../../software/include/stdio.h ../../software/include/stdlib.h
vga.o: ../../software/include/hw/vga.h ../../software/include/hw/common.h
vga.o: ../../software/include/hal/vga.h

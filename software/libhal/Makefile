MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=brd.o dmx.o mem.o pfpu.o snd.o time.o tmu.o usb.o vga.o vin.o

all: libhal.a

libhal.a: $(OBJECTS)
	$(AR) clr libhal.a $(OBJECTS)
	$(RANLIB) libhal.a

$(MMDIR)/softusb-ohci/softusb-ohci.bin:
	$(MAKE) -C $(MMDIR)/softusb-ohci

softusb-ohci.h: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MAKE) -C $(MMDIR)/softusb-ohci
	cat $(MMDIR)/softusb-ohci/softusb-ohci.bin | xxd -i - softusb-ohci.h

.PHONY: clean depend

depend: softusb-ohci.h
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o libhal.a .*~ *~ Makefile.bak softusb-ohci.h

# DO NOT DELETE

brd.o: ../../software/include/base/stdlib.h
brd.o: ../../software/include/base/stdio.h
brd.o: ../../software/include/base/board.h ../../software/include/hal/brd.h
mem.o: ../../software/include/base/stdio.h
mem.o: ../../software/include/base/stdlib.h
mem.o: ../../software/include/base/malloc.h ../../software/include/hal/mem.h
pfpu.o: ../../software/include/base/stdio.h
pfpu.o: ../../software/include/base/stdlib.h
pfpu.o: ../../software/include/base/irq.h
pfpu.o: ../../software/include/hw/interrupts.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: ../../software/include/hal/pfpu.h
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
usb.o: ../../software/include/hw/softusb.h ../../software/include/hw/common.h
usb.o: ../../software/include/hw/sysctl.h
usb.o: ../../software/include/hw/capabilities.h
usb.o: ../../software/include/base/stdio.h
usb.o: ../../software/include/base/stdlib.h softusb-ohci.h
vga.o: ../../software/include/base/stdio.h
vga.o: ../../software/include/base/stdlib.h ../../software/include/hw/vga.h
vga.o: ../../software/include/hw/common.h ../../software/include/hal/vga.h
vin.o: ../../software/include/base/stdio.h
vin.o: ../../software/include/base/stdlib.h ../../software/include/hal/vin.h
vin.o: ../../software/include/hw/bt656cap.h
vin.o: ../../software/include/hw/common.h

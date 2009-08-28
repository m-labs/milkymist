MMDIR?=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o main.o boot.o splash.o
SEGMENTS=-j .text -j .data -j .rodata

all: bios_splash.bin

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	$(MMDIR)/tools/crc32 $@ write

bios.elf: linker.ld $(OBJECTS) $(MMDIR)/software/baselib/baselib-light.a
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) $(MMDIR)/software/baselib/baselib-light.a

splash.raw: splash.png
	$(MMDIR)/tools/makeraw splash.png

bios_padded.bin: bios.bin
	dd if=bios.bin of=bios_padded.bin bs=65536 conv=sync

bios_splash.bin: bios_padded.bin splash.raw
	cat bios_padded.bin splash.raw > bios_splash.bin

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o bios.elf bios.bin bios_padded.bin splash.raw bios_splash.bin .*~ *~ Makefile.bak

# DO NOT DELETE

boot.o: ../../software/include/libc.h ../../software/include/console.h
boot.o: ../../software/include/uart.h ../../software/include/system.h
boot.o: ../../software/include/cffat.h ../../software/include/crc.h
boot.o: ../../std/sfl.h ../../software/include/hw/hpdmc.h
boot.o: ../../software/include/hw/common.h boot.h
main.o: ../../software/include/libc.h ../../software/include/console.h
main.o: ../../software/include/uart.h ../../software/include/cffat.h
main.o: ../../software/include/crc.h ../../software/include/system.h
main.o: ../../software/include/board.h ../../software/include/version.h
main.o: ../../software/include/hw/hpdmc.h ../../software/include/hw/common.h
main.o: ../../software/include/hw/vga.h ../../software/include/hw/fmlbrg.h
main.o: ../../software/include/hw/sysctl.h ../../software/include/hw/gpio.h
main.o: ../../software/include/hw/uart.h boot.h splash.h
splash.o: ../../software/include/libc.h ../../software/include/console.h
splash.o: ../../software/include/system.h ../../software/include/hw/vga.h
splash.o: ../../software/include/hw/common.h splash.h

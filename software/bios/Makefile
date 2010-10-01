MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o main.o boot.o splash.o
SEGMENTS=-j .text -j .data -j .rodata

all: bios.bin bios-rescue.bin

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/crc32 $@ write

bios.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) -L$(MMDIR)/software/libhpdmc -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libhal -L$(MMDIR)/software/libnet --start-group -lhpdmc -lbase-light -lhal -lnet --end-group
	chmod -x $@

bios-rescue.elf: linker-rescue.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker-rescue.ld -N -o $@ $(OBJECTS) -L$(MMDIR)/software/libhpdmc -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libhal -L$(MMDIR)/software/libnet --start-group -lhpdmc -lbase-light -lhal -lnet --end-group
	chmod -x $@

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o bios.elf bios.bin bios-rescue.elf bios-rescue.bin .*~ *~ Makefile.bak

# DO NOT DELETE

boot.o: ../../software/include/base/stdio.h
boot.o: ../../software/include/base/stdlib.h
boot.o: ../../software/include/base/console.h
boot.o: ../../software/include/base/uart.h
boot.o: ../../software/include/base/system.h
boot.o: ../../software/include/base/board.h ../../software/include/base/crc.h
boot.o: ../../tools/sfl.h ../../software/include/base/blockdev.h
boot.o: ../../software/include/base/fatfs.h
boot.o: ../../software/include/base/string.h
boot.o: ../../software/include/net/microudp.h
boot.o: ../../software/include/net/tftp.h ../../software/include/hw/hpdmc.h
boot.o: ../../software/include/hw/common.h ../../software/include/hw/flash.h
boot.o: boot.h
main.o: ../../software/include/base/stdio.h
main.o: ../../software/include/base/stdlib.h
main.o: ../../software/include/base/console.h
main.o: ../../software/include/base/string.h
main.o: ../../software/include/base/uart.h
main.o: ../../software/include/base/blockdev.h
main.o: ../../software/include/base/fatfs.h ../../software/include/base/crc.h
main.o: ../../software/include/base/system.h
main.o: ../../software/include/base/board.h
main.o: ../../software/include/base/version.h
main.o: ../../software/include/net/mdio.h ../../software/include/hw/vga.h
main.o: ../../software/include/hw/common.h ../../software/include/hw/fmlbrg.h
main.o: ../../software/include/hw/sysctl.h
main.o: ../../software/include/hw/capabilities.h
main.o: ../../software/include/hw/gpio.h ../../software/include/hw/uart.h
main.o: ../../software/include/hw/hpdmc.h ../../software/include/hw/flash.h
main.o: boot.h splash.h
splash.o: ../../software/include/base/stdio.h
splash.o: ../../software/include/base/stdlib.h
splash.o: ../../software/include/hw/vga.h ../../software/include/hw/common.h
splash.o: ../../software/include/hw/flash.h splash.h

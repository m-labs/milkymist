MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=monitor.o
SEGMENTS=-j .text -j .data -j .rodata

all: monitor.bin monitor.rom

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@

monitor.rom: monitor.bin
	$(MAKE) -C $(MMDIR)/tools
	$(MMDIR)/tools/bin2hex $< $@ 512

monitor.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS)
	chmod -x $@

.PHONY: clean depend

depend:
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f *.o monitor.elf monitor.bin monitor.rom .*~ *~ Makefile.bak


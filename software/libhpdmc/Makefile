MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=libhpdmc.o
SEGMENTS=-j .text -j .data -j .rodata

all: libhpdmc.a test.bin

libhpdmc.o: libhpdmc.S libhpdmc.h

libhpdmc.a: libhpdmc.o
	$(AR) clr libhpdmc.a libhpdmc.o
	$(RANLIB) libhpdmc.a

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@

test.elf: linker.ld libhpdmc.a test.o
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ -L. test.o --start-group -lhpdmc --end-group
	chmod -x $@

sim: test.elf
	qemu-system-lm32 -M milkymist -nographic -kernel test.elf

.PHONY: clean depend sim

clean:
	rm -f libhpdmc.a libhpdmc.o test.o test.elf test.bin

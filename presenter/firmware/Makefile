include $(MMDIR)/software/include.mak

OBJECTS=crt0.o main.o vga.o
SEGMENTS=-j .text -j .data -j .rodata

all: boot.bin

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	$(MMDIR)/tools/crc32 $@

boot.elf: linker.ld $(OBJECTS) $(MMDIR)/software/baselib/baselib-light.a
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) $(MMDIR)/software/baselib/baselib-light.a

.PHONY: clean

clean:
	rm -f $(OBJECTS) boot.elf boot.bin .*~ *~

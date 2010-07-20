SOURCES=crt0.S main.c debug.c crc.c

all: softusb-ohci.bin

%.bin: %.elf
	avr-objcopy -O binary $< $@

softusb-ohci.elf: $(SOURCES)
	avr-gcc -o softusb-ohci.elf -mmcu=avr2 -Os $(SOURCES) $(CFLAGS) -nostdlib -Wl,-T -Wl,navre.ld

.PHONY: clean

clean:
	rm -f softusb-ohci.bin softusb-ohci.elf

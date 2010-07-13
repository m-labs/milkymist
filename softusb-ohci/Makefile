SOURCES=crt0.S main.c debug.c

all: softusb-ohci.bin

softusb-ohci.bin: softusb-ohci.elf
	zpu-elf-objcopy -O binary softusb-ohci.elf softusb-ohci.bin

softusb-ohci.elf: $(SOURCES)
	zpu-elf-gcc -o softusb-ohci.elf -nostdlib -nodefaultlibs -Os -Wall $(SOURCES)

.PHONY: clean

clean:
	rm -f softusb-ohci.bin softusb-ohci.elf

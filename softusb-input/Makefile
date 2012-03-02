SOURCES=crt0.S main.c debug.c crc.c libc.c
INCLUDES=comloc.h crc.h debug.h host.h io.h libc.h progmem.h sie.h timer.h

.PHONY:	all install upload clean

all:	softusb-input.h

softusb-input.elf: $(SOURCES) $(INCLUDES)
	avr-gcc -o $@ -mmcu=avr2 -mno-interrupts -Wall -Os \
	    $(SOURCES) $(CFLAGS) -nostdlib -Wl,-T -Wl,navre.ld

%.bin: %.elf
	avr-objcopy -O binary $< $@

softusb-input.h: softusb-input.bin
	cat $< | xxd -i - $@

install: softusb-input.h
	test -n "$(RTEMS_MAKEFILE_PATH)"
	mkdir -p $(RTEMS_MAKEFILE_PATH)/lib/include
	cp $< $(RTEMS_MAKEFILE_PATH)/lib/include

upload:	softusb-input.bin
	@[ "$(MM_HOST)" ] && [ "$(MM_USER)" ] && [ "$(MM_PW)" ] || \
	    { echo "please define MM_HOST, MM_USER, and MM_PW"; exit 1; }
	ftp-upload --host $(MM_HOST) --user $(MM_USER) --password $(MM_PW) $<

clean:
	rm -f softusb-input.elf softusb-input.bin softusb-input.h

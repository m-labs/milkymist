MMDIR?=../../..
SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

firmware.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware0.rom 1024 16

sim: firmware.rom
	cver $(SOURCES)

fib.elf: fib.S
	avr-gcc -o fib.elf -mmcu=avr2 -Os fib.S -nostdlib

fib.bin: fib.elf
	avr-objcopy -O binary fib.elf fib.bin

fib.rom: fib.bin
	$(MMDIR)/tools/bin2hex fib.bin fib.rom 1024 16

sim-navre: fib.rom
	cver ../rtl/softusb_navre.v tb_navre.v

clean:
	rm -f verilog.log firmware.rom fib.elf fib.bin fib.rom

.PHONY: clean sim sim-navre

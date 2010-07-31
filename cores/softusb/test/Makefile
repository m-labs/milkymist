MMDIR?=../../..
SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

firmware.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware.rom 2048 16

sim: firmware.rom
	cver $(SOURCES)

isim: runsim firmware.rom
	./runsim

runsim: $(SOURCES)
	iverilog -o runsim $(SOURCES)

fib.elf: fib.S
	avr-gcc -o fib.elf -mmcu=avr2 -Os fib.S -nostdlib

fibc.elf: fibc.c fibc_crt.S
	avr-gcc -o fibc.elf -mmcu=avr2 -Os fibc_crt.S fibc.c -nostdlib

%.bin: %.elf
	avr-objcopy -O binary $< $@

%.rom: %.bin
	$(MMDIR)/tools/bin2hex $< $@ 1024 16

sim-navre: fib.rom fibc.rom
	cver ../rtl/softusb_navre.v tb_navre.v

isim-sie: runsim-sie
	./runsim-sie

runsim-sie: ../rtl/softusb_tx.v ../rtl/softusb_rx.v tb_sie.v
	iverilog -o runsim-sie ../rtl/softusb_tx.v ../rtl/softusb_rx.v tb_sie.v

clean:
	rm -f verilog.log firmware.rom fib.elf fib.bin fib.rom fibc.elf fibc.bin fibc.rom runsim softusb.vcd softusb_tx.vcd runsim-sie

.PHONY: clean sim sim-navre

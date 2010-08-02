MMDIR?=../../..
SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

sim: trx.rom
	cver $(SOURCES)

isim: runsim trx.rom
	./runsim

runsim: $(SOURCES)
	iverilog -o runsim $(SOURCES)

trx.elf: trx.S
	avr-gcc -o trx.elf -mmcu=avr2 -Os trx.S -nostdlib

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
	rm -f verilog.log trx.elf trx.bin trx.rom fib.elf fib.bin fib.rom fibc.elf fibc.bin fibc.rom runsim softusb.vcd softusb_sie.vcd runsim-sie

.PHONY: clean sim sim-navre

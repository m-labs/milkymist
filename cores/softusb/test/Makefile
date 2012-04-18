MMDIR?=../../..
SOURCES=$(wildcard ../rtl/*.v)

all: sim

sim: trx.rom
	cver tb_softusb.v $(SOURCES)

isim: runsim trx.rom
	./runsim

runsim: tb_softusb.v $(SOURCES)
	iverilog -o runsim tb_softusb.v $(SOURCES)

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

isim-%: runsim-%
	./$<

runsim-%: tb_%.v $(SOURCES)
	iverilog -o $@ $(SOURCES) $<

clean:
	rm -f verilog.log trx.elf trx.bin trx.rom fib.elf fib.bin fib.rom fibc.elf fibc.bin fibc.rom runsim runsim-* *.vcd

.PHONY: clean sim sim-navre

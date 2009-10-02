SOURCES=tb_norflash8.v $(wildcard ../rtl/*.v)

all: tb_norflash8

isim: tb_norflash8
	./tb_norflash8

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_norflash8 verilog.log norflash8.vcd

tb_norflash8: $(SOURCES)
	iverilog -o tb_norflash8 $(SOURCES)

.PHONY: clean sim cversim

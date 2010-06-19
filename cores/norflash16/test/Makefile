SOURCES=tb_norflash16.v $(wildcard ../rtl/*.v)

all: tb_norflash16

isim: tb_norflash16
	./tb_norflash16

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_norflash16 verilog.log norflash16.vcd

tb_norflash16: $(SOURCES)
	iverilog -o tb_norflash16 $(SOURCES)

.PHONY: clean sim cversim

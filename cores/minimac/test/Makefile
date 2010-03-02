SOURCES=tb_minimac.v $(wildcard ../rtl/*.v)

all: cversim

isim: tb_minimac
	./tb_minimac

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_minimac verilog.log minimac.vcd

tb_minimac: $(SOURCES)
	iverilog -o tb_minimac $(SOURCES)

.PHONY: clean sim cversim

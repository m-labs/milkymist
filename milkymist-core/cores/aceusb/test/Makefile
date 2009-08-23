SOURCES=tb_aceusb.v $(wildcard ../rtl/*.v)

all: tb_aceusb

isim: tb_aceusb
	./tb_aceusb

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_aceusb verilog.log aceusb.vcd

tb_aceusb: $(SOURCES)
	iverilog -o tb_aceusb $(SOURCES)

.PHONY: clean sim cversim

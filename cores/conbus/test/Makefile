SOURCES=tb_conbus.v master.v slave.v $(wildcard ../rtl/*.v)

all: tb_conbus

sim: tb_conbus
	./tb_conbus

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_conbus verilog.log

tb_conbus: $(SOURCES)
	iverilog -o tb_conbus $(SOURCES)

.PHONY: clean sim cversim

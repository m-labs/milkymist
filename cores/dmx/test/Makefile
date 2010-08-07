SOURCES=tb_dmx.v $(wildcard ../rtl/*.v)

all: sim

sim:
	cver $(SOURCES)

clean:
	rm -f verilog.log dmx.vcd

.PHONY: clean sim

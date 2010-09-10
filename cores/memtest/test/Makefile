SOURCES=$(wildcard ../rtl/*) tb_memtest.v

all: sim

sim:
	cver $(SOURCES)

clean:
	rm -f verilog.log memtest.vcd

.PHONY: clean sim

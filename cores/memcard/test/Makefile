SOURCES=tb_memcard.v $(wildcard ../rtl/*.v)

all: sim

sim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f verilog.log memcard.vcd

.PHONY: sim

SOURCES=tb_ac97.v $(wildcard ../rtl/*.v)

all: sim

sim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f verilog.log ac97.vcd

.PHONY: clean sim

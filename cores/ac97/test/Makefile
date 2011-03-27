SOURCES=tb_ac97.v $(wildcard ../rtl/*.v) ../../asfifo/rtl/asfifo.v ../../asfifo/rtl/asfifo_graycounter.v

all: sim

sim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f verilog.log ac97.vcd

.PHONY: clean sim

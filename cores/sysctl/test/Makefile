SOURCES=tb_sysctl.v icap.v $(wildcard ../rtl/*.v)

all: sim

sim:
	cver $(SOURCES)

isim: runsim
	./runsim

runsim: $(SOURCES)
	iverilog -o runsim $(SOURCES)

clean:
	rm -f verilog.log runsim sysctl.vcd

.PHONY: clean sim isim

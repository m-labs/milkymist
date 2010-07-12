SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

sim:
	cver +incdir+../rtl/ $(SOURCES)

clean:
	rm -f verilog.log

.PHONY: clean sim

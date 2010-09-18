SOURCES=tb_fmlbrg.v $(wildcard ../rtl/*.v)

all: fmlbrg

fmlbrg: $(SOURCES)
	cver $(SOURCES)
	
runsim: $(SOURCES)
	iverilog -o runsim $(SOURCES)

isim: runsim
	./runsim

clean:
	rm -f verilog.log runsim

.PHONY: clean fmlbrg isim

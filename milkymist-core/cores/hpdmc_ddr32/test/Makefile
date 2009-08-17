SOURCES_MODEL=tb_model.v ddr.v
SOURCES_HPDMC=tb_hpdmc.v ddr.v oddr.v iddr.v idelay.v $(wildcard ../rtl/*.v)

all: hpdmc

model: $(SOURCES_MODEL)
	cver $(SOURCES_MODEL)

hpdmc: $(SOURCES)
	cver $(SOURCES_HPDMC)

clean:
	rm -f verilog.log hpdmc.vcd

.PHONY: clean model hpdmc

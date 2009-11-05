TBDIR=$(shell pwd)
VPIDIR=$(TBDIR)/../vpi
RTLDIR=$(TBDIR)/../../rtl
SOURCES=$(TBDIR)/tb_pfpu.v $(wildcard $(RTLDIR)/*.v)

all: sim

# work around stupidity of cver which only searches memory initialization
# files from the current directory...
sim: $(SOURCES)
	cd $(RTLDIR) && cver +loadvpi=$(VPIDIR)/floatconv.so:vpi_register $(SOURCES)

isim: $(RTLDIR)/tb_pfpu
	cd $(RTLDIR) && ./tb_pfpu

$(RTLDIR)/tb_pfpu: $(SOURCES)
	iverilog -o $(RTLDIR)/tb_pfpu $(SOURCES) -m$(VPIDIR)/floatconv.so

clean:
	rm -f $(RTLDIR)/verilog.log $(RTLDIR)/tb_pfpu

.PHONY: clean sim

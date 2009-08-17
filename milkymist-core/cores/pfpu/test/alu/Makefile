TBDIR=$(shell pwd)
VPIDIR=$(TBDIR)/../vpi
RTLDIR=$(TBDIR)/../../rtl
SOURCES=$(TBDIR)/tb_alu.v \
	$(RTLDIR)/pfpu_alu.v \
	$(RTLDIR)/pfpu_clz32.v \
	$(RTLDIR)/pfpu_faddsub.v \
	$(RTLDIR)/pfpu_fmul.v \
	$(RTLDIR)/pfpu_fdiv.v \
	$(RTLDIR)/pfpu_f2i.v \
	$(RTLDIR)/pfpu_i2f.v \
	$(RTLDIR)/pfpu_vect.v \
	$(RTLDIR)/pfpu_sincos.v \
	$(RTLDIR)/pfpu_above.v \
	$(RTLDIR)/pfpu_equal.v \
	$(RTLDIR)/pfpu_copy.v

all: sim

# work around stupidity of cver which only searches memory initialization
# files from the current directory...
sim: $(SOURCES)
	cd $(RTLDIR) && cver +loadvpi=$(VPIDIR)/floatconv.so:vpi_register $(SOURCES)

isim: $(RTLDIR)/tb_alu
	cd $(RTLDIR) && ./tb_alu

$(RTLDIR)/tb_alu: $(SOURCES)
	iverilog -o $(RTLDIR)/tb_alu $(SOURCES) -m$(VPIDIR)/floatconv.so

clean:
	rm -f $(RTLDIR)/verilog.log $(RTLDIR)/tb_alu

.PHONY: clean sim

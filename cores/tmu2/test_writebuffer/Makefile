SOURCES=tb_writebuffer.v \
../rtl/tmu2_wb_datamem.v \
../rtl/tmu2_wb_tagmem.v \
../rtl/tmu2_writebuffer.v

all: sim

sim:
	cver $(SOURCES)

xsim: tb_writebuffer xsimrun.tcl
	./tb_writebuffer -tclbatch xsimrun.tcl

tb_writebuffer: xsim.prj $(SOURCES)
	fuse -prj xsim.prj tb_writebuffer -o tb_writebuffer

xsim.prj: Makefile
	rm -f xsim.prj
	for i in `echo $(SOURCES)`; do \
	    echo "verilog work $$i" >> xsim.prj; \
	done

clean:
	rm -f verilog.log tb_writebuffer xsim.prj
	# you can always count on Xilinx tools to leave a bunch of crap in their working directories
	rm -f fuse.log isim.wdb isim.log
	rm -rf isim

.PHONY: clean sim

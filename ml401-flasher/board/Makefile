TOPDIR?=$(shell pwd)

include sources.mak

# Various intermediate files and garbage the ISE tools
# generously stuff your filesystem with.
SYNCLEAN=flasher.bgn flasher.drc flasher.mrp flasher.ngd flasher.pcf \
	flasher.bld flasher.lso flasher.ncd flasher.ngm flasher.srp \
	flasher.bit flasher_signalbrowser.* flasher-routed_pad.tx \
	flasher.map flasher_summary.xml timing.twr flasher-routed* \
	flasher_usage* flasher.ngc param.opt netlist.lst xst flasher.prj \
	xlnx_auto_0.ise flasher_par.xrpt smartpreview.twr flasher.ngc_xst.xrpt \
	flasher_ngdbuild.xrpt flasher_map.xrpt xlnx_auto_0_xdb _impactbatch.log \
	_impact.log _impact.cmd flasher_fpga_editor.out

all: flasher.bit

timing: flasher-routed.twr

usage: flasher-routed.xdl
	xdlanalyze.pl flasher-routed.xdl 0

load: flasher.bit
	impact -batch impact.batch

flasher.prj: $(SRC)
	rm -f flasher.prj
	@for i in `echo $^`; do \
	    echo "verilog work $$i" >> flasher.prj; \
	done

flasher.ngc: flasher.prj $(RAMFILES)
	xst -ifn flasher.xst

flasher.ngd: flasher.ngc flasher.ucf
	ngdbuild -uc flasher.ucf flasher.ngc

flasher.ncd: flasher.ngd
	map flasher.ngd

flasher-routed.ncd: flasher.ncd
	par -ol high -w flasher.ncd flasher-routed.ncd

flasher.bit: flasher-routed.ncd
	bitgen -w flasher-routed.ncd flasher.bit

flasher-routed.xdl: flasher-routed.ncd
	xdl -ncd2xdl flasher-routed.ncd flasher-routed.xdl

flasher-routed.twr: flasher-routed.ncd
	trce -v 10 flasher-routed.ncd flasher.pcf

clean:
	rm -Rf $(SYNCLEAN)

.PHONY: timing usage load clean

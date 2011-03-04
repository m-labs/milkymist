MMDIR?=../../..

SRC=standby.v

all: build/standby.fpg

build/standby.ncd: build/standby.ngd
	cd build && map -w standby.ngd

build/standby-routed.ncd: build/standby.ncd
	cd build && par -w standby.ncd standby-routed.ncd

build/standby.bit: build/standby-routed.ncd
	cd build && bitgen -g compress -g Binary:Yes -w standby-routed.ncd standby.bit

build/standby.bin: build/standby.bit

build/standby.fpg: build/standby.bin
	$(MMDIR)/tools/byteswap build/standby.bin build/standby.fpg

build/standby-routed.xdl: build/standby-routed.ncd
	cd build && xdl -ncd2xdl standby-routed.ncd standby-routed.xdl

build/standby.prj: $(SRC)
	rm -f build/standby.prj
	for i in `echo $^`; do \
	    echo "verilog work ../$$i" >> build/standby.prj; \
	done

build/standby.ngc: build/standby.prj
	cd build && xst -ifn ../standby.xst

build/standby.ngd: build/standby.ngc standby.ucf
	cd build && ngdbuild -uc ../standby.ucf standby.ngc

clean:
	rm -rf build/*

.PHONY: clean

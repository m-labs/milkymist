timing: build/system-routed.twr

usage: build/system-routed.xdl
	../../../tools/xdlanalyze.pl build/system-routed.xdl 0

load: build/system.bit
	cd build && impact -batch ../load.cmd

build/system.ncd: build/system.ngd
	cd build && map -w system.ngd

build/system-routed.ncd: build/system.ncd
	cd build && par -ol high -w system.ncd system-routed.ncd

build/system.bit: build/system-routed.ncd
	cd build && bitgen -w system-routed.ncd system.bit

build/system-routed.xdl: build/system-routed.ncd
	cd build && xdl -ncd2xdl system-routed.ncd system-routed.xdl

build/system-routed.twr: build/system-routed.ncd
	cd build && trce -v 10 system-routed.ncd system.pcf

clean:
	rm -rf build/*

.PHONY: timing usage load clean

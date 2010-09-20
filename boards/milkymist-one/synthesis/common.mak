ifeq ($(RESCUE),1)
	BUILDDIR=build-rescue
else
	BUILDDIR=build
endif

all: $(BUILDDIR)/system.bit

timing: $(BUILDDIR)/system-routed.twr

usage: $(BUILDDIR)/system-routed.xdl
	../../../tools/xdlanalyze.pl $(BUILDDIR)/system-routed.xdl 0

load: $(BUILDDIR)/system.bit
	cd $(BUILDDIR) && impact -batch ../load.cmd

$(BUILDDIR)/system.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -xt 3 -w system.ngd

$(BUILDDIR)/system-routed.ncd: $(BUILDDIR)/system.ncd
	cd $(BUILDDIR) && par -ol high -w system.ncd system-routed.ncd

$(BUILDDIR)/system.bit: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && bitgen -g LCK_cycle:6 -w system-routed.ncd system.bit

$(BUILDDIR)/system-routed.xdl: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && xdl -ncd2xdl system-routed.ncd system-routed.xdl

$(BUILDDIR)/system-routed.twr: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && trce -e 100 system-routed.ncd system.pcf

clean:
	rm -rf build/* build-rescue/*

.PHONY: timing usage load clean

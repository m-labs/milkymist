MMDIR?=../../..

ifeq ($(RESCUE),1)
	BUILDDIR=build-rescue
else
	BUILDDIR=build
endif

all: $(BUILDDIR)/system.bit $(BUILDDIR)/system.fpg

timing: $(BUILDDIR)/system-routed.twr

usage: $(BUILDDIR)/system-routed.xdl
	../../../tools/xdlanalyze.pl $(BUILDDIR)/system-routed.xdl 0

load: $(BUILDDIR)/system.bit
	jtag -n load.batch

# Sometimes different options are needed to meet timing
build/system.ncd: build/system.ngd
	cd build && map -ol high -t 2 -w system.ngd

build/system-routed.ncd: build/system.ncd
	cd build && par -ol high -w system.ncd system-routed.ncd

build-rescue/system.ncd: build-rescue/system.ngd
	cd build-rescue && map -ol high -w system.ngd

build-rescue/system-routed.ncd: build-rescue/system.ncd
	cd build-rescue && par -ol high -w system.ncd system-routed.ncd

$(BUILDDIR)/system.bit: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && bitgen -g LCK_cycle:6 -g Binary:Yes -g INIT_9K:Yes -w system-routed.ncd system.bit

$(BUILDDIR)/system.bin: $(BUILDDIR)/system.bit

$(BUILDDIR)/system.fpg: $(BUILDDIR)/system.bin
	$(MMDIR)/tools/byteswap $(BUILDDIR)/system.bin $(BUILDDIR)/system.fpg

$(BUILDDIR)/system-routed.xdl: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && xdl -ncd2xdl system-routed.ncd system-routed.xdl

$(BUILDDIR)/system-routed.twr: $(BUILDDIR)/system-routed.ncd
	cd $(BUILDDIR) && trce -e 100 system-routed.ncd system.pcf

# MPPR targets
mppr: $(BUILDDIR)/system-routed0.ncd $(BUILDDIR)/system-routed1.ncd $(BUILDDIR)/system-routed2.ncd $(BUILDDIR)/system-routed3.ncd $(BUILDDIR)/system-routed4.ncd $(BUILDDIR)/system-routed5.ncd

$(BUILDDIR)/system0.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 1 -w system.ngd -o system0.ncd
$(BUILDDIR)/system1.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 20 -w system.ngd -o system1.ncd
$(BUILDDIR)/system2.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 40 -w system.ngd -o system2.ncd
$(BUILDDIR)/system3.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 60 -w system.ngd -o system3.ncd
$(BUILDDIR)/system4.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 80 -w system.ngd -o system4.ncd
$(BUILDDIR)/system5.ncd: $(BUILDDIR)/system.ngd
	cd $(BUILDDIR) && map -ol high -t 99 -w system.ngd -o system5.ncd

$(BUILDDIR)/system-routed0.ncd: $(BUILDDIR)/system0.ncd
	cd $(BUILDDIR) && par -ol high -w system0.ncd system-routed0.ncd > par0
$(BUILDDIR)/system-routed1.ncd: $(BUILDDIR)/system1.ncd
	cd $(BUILDDIR) && par -ol high -w system1.ncd system-routed1.ncd > par1
$(BUILDDIR)/system-routed2.ncd: $(BUILDDIR)/system2.ncd
	cd $(BUILDDIR) && par -ol high -w system2.ncd system-routed2.ncd > par2
$(BUILDDIR)/system-routed3.ncd: $(BUILDDIR)/system3.ncd
	cd $(BUILDDIR) && par -ol high -w system3.ncd system-routed3.ncd > par3
$(BUILDDIR)/system-routed4.ncd: $(BUILDDIR)/system4.ncd
	cd $(BUILDDIR) && par -ol high -w system4.ncd system-routed4.ncd > par4
$(BUILDDIR)/system-routed5.ncd: $(BUILDDIR)/system5.ncd
	cd $(BUILDDIR) && par -ol high -w system5.ncd system-routed5.ncd > par5

clean:
	rm -rf build/* build-rescue/*

.PHONY: timing usage load mppr clean

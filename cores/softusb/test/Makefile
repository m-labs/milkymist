MMDIR?=../../..
SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

firmware.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware0.rom 1024 16

sim: firmware.rom
	cver $(SOURCES)

sim-navre:
	cver ../rtl/softusb_navre.v tb_navre.v

clean:
	rm -f verilog.log firmware.rom

.PHONY: clean sim sim-navre

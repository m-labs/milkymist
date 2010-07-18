MMDIR?=../../..
SOURCES=tb_softusb.v $(wildcard ../rtl/*.v)

all: sim

firmware0.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware0.rom 8192 0

firmware1.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware1.rom 8192 1

firmware2.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware2.rom 8192 2

firmware3.rom: $(MMDIR)/softusb-ohci/softusb-ohci.bin
	$(MMDIR)/tools/bin2hex $(MMDIR)/softusb-ohci/softusb-ohci.bin firmware3.rom 8192 3

sim: firmware0.rom firmware1.rom firmware2.rom firmware3.rom
	cver +incdir+../rtl/ $(SOURCES)

clean:
	rm -f verilog.log firmware0.rom firmware1.rom firmware2.rom firmware3.rom

.PHONY: clean sim

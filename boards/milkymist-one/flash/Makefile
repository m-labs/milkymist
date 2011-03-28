MMDIR?=../../..

TARGETS=standby.fpg soc-rescue.fpg bios-rescue.bin splash-rescue.raw soc.fpg bios.bin splash.raw
SERIAL?=/dev/ttyUSB0

all: $(TARGETS)
clean:
	rm -f $(TARGETS)

standby.fpg:
	$(MAKE) -C $(MMDIR)/tools
	$(MAKE) -C $(MMDIR)/boards/milkymist-one/standby
	cp $(MMDIR)/boards/milkymist-one/standby/build/standby.fpg .

soc-rescue.fpg:
	$(MAKE) -C $(MMDIR)/tools
	$(MAKE) -C $(MMDIR)/boards/milkymist-one/synthesis -f Makefile.xst RESCUE=1
	cp $(MMDIR)/boards/milkymist-one/synthesis/build-rescue/system.fpg soc-rescue.fpg

bios-rescue.bin:
	$(MAKE) -C $(MMDIR)/tools
	$(MAKE) -C $(MMDIR)/software/libhpdmc
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libhal
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/bios
	cp $(MMDIR)/software/bios/bios-rescue.bin .

splash-rescue.raw: splash-rescue.png
	$(MAKE) -C $(MMDIR)/tools
	$(MMDIR)/tools/makeraw splash-rescue.png

soc.fpg:
	$(MAKE) -C $(MMDIR)/tools
	$(MAKE) -C $(MMDIR)/boards/milkymist-one/synthesis -f Makefile.xst
	cp $(MMDIR)/boards/milkymist-one/synthesis/build/system.fpg soc.fpg

bios.bin:
	$(MAKE) -C $(MMDIR)/tools
	$(MAKE) -C $(MMDIR)/software/libhpdmc
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libhal
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/bios
	cp $(MMDIR)/software/bios/bios.bin .

splash.raw: splash.png
	$(MAKE) -C $(MMDIR)/tools
	$(MMDIR)/tools/makeraw splash.png

flash: all
	jtag -n flashall.batch

connect:
	stty -F $(SERIAL) raw 115200
	while : ; do cat $(SERIAL) ; done & cat > $(SERIAL)

.PHONY: flash clean connect

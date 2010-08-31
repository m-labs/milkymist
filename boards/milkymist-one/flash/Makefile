MMDIR=../../..

all: bitstream.mcs bios.mcs splash.mcs
all-rescue: bitstream-rescue.mcs bios-rescue.mcs splash-rescue.mcs
all-prod: standby.mcs all all-rescue

flash-rescue: flash-bitstream-rescue flash-bios-rescue flash-splash-rescue
flash-regular: flash-bitstream flash-bios flash-splash
flash-prod: flash-standby flash-rescue flash-regular

clean:
	rm -rf impact_sucks
	rm -f bitstream-rescue.mcs bitstream-rescue.prm bitstream-rescue.cfi
	rm -f bios-rescue.mcs
	rm -f splash-rescue.raw splash-rescue.mcs
	rm -f demo-rescue.mcs
	rm -f bitstream.mcs bitstream.prm bitstream.cfi
	rm -f bios.mcs
	rm -f splash.raw splash.mcs
	rm -f demo.mcs
	rm -f standby.mcs standby.prm standby.cfi

.PHONY: flash-rescue flash-bitstream-rescue flash-bios-rescue flash-splash-rescue flash-demo-rescue flash-regular flash-bitstream flash-bios flash-splash flash-demo flash-prod all-rescue all-prod clean

# rescue images

bitstream-rescue.mcs: # WARNING: promgen multiplies address by 2!!!
	$(MAKE) -C ../synthesis -f Makefile.xst RESCUE=1
	promgen -w -p mcs -o bitstream-rescue.mcs -s 32768 -u 0x00050000 ../synthesis/build-rescue/system.bit -bpi_dc parallel -data_width 16

bios-rescue.mcs:
	$(MAKE) -C $(MMDIR)/software/libhpdmc
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/bios
	srec_cat -Output bios-rescue.mcs -Intel $(MMDIR)/software/bios/bios-rescue.bin -Binary -offset 0x00220000 --byte-swap 2

splash-rescue.mcs: splash-rescue.raw
	srec_cat -Output splash-rescue.mcs -Intel splash-rescue.raw -Binary -offset 0x00240000 --byte-swap 2

splash-rescue.raw: splash-rescue.png
	$(MMDIR)/tools/makeraw splash-rescue.png

demo-rescue.mcs:
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libhal
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/libfpvm
	$(MAKE) -C $(MMDIR)/software/libmath
	$(MAKE) -C $(MMDIR)/software/demo
	srec_cat -Output demo-rescue.mcs -Intel $(MMDIR)/software/demo/boot.fbi -Binary -offset 0x002E0000 --byte-swap 2

# regular images

bitstream.mcs: # WARNING: promgen multiplies address by 2!!!
	$(MAKE) -C ../synthesis -f Makefile.xst
	promgen -w -p mcs -o bitstream.mcs -s 32768 -u 0x00370000 ../synthesis/build/system.bit -bpi_dc parallel -data_width 16

bios.mcs:
	$(MAKE) -C $(MMDIR)/software/libhpdmc
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/bios
	srec_cat -Output bios.mcs -Intel $(MMDIR)/software/bios/bios.bin -Binary -offset 0x00860000 --byte-swap 2

splash.mcs: splash.raw
	srec_cat -Output splash.mcs -Intel splash.raw -Binary -offset 0x00880000 --byte-swap 2


splash.raw: splash.png
	$(MMDIR)/tools/makeraw splash.png

demo.mcs:
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libhal
	$(MAKE) -C $(MMDIR)/software/libnet
	$(MAKE) -C $(MMDIR)/software/libfpvm
	$(MAKE) -C $(MMDIR)/software/libmath
	$(MAKE) -C $(MMDIR)/software/demo
	srec_cat -Output demo.mcs -Intel $(MMDIR)/software/demo/boot.fbi -Binary -offset 0x00920000 --byte-swap 2

# standby bitstream

standby.mcs: # WARNING: promgen multiplies address by 2!!!
	$(MAKE) -C ../standby
	promgen -w -p mcs -o standby.mcs -s 32768 -u 0x00000000 ../standby/build/standby.bit -bpi_dc parallel -data_width 16

# flash targets

flash-bitstream-rescue: bitstream-rescue.mcs
	./flash-mcs.sh bitstream-rescue.mcs

flash-bios-rescue: bios-rescue.mcs
	./flash-mcs.sh bios-rescue.mcs

flash-splash-rescue: splash-rescue.mcs
	./flash-mcs.sh splash-rescue.mcs

flash-demo-rescue: demo-rescue.mcs
	./flash-mcs.sh demo-rescue.mcs

flash-bitstream: bitstream.mcs
	./flash-mcs.sh bitstream.mcs

flash-bios: bios.mcs
	./flash-mcs.sh bios.mcs

flash-splash: splash.mcs
	./flash-mcs.sh splash.mcs

flash-demo: demo.mcs
	./flash-mcs.sh demo.mcs

flash-standby: standby.mcs
	./flash-mcs.sh standby.mcs

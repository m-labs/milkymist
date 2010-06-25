MMDIR=../../..

all: bitstream.mcs bios.mcs splash.mcs userfs.mcs

bitstream.mcs:
	$(MAKE) -C ../synthesis -f Makefile.xst
	promgen -w -p mcs -o bitstream.mcs -s 32768 -u 0x00000000 ../synthesis/build/system.bit -bpi_dc parallel -data_width 16

bios.mcs:
	$(MAKE) -C $(MMDIR)/software/bios
	srec_cat -Output bios.mcs -Intel $(MMDIR)/software/bios/bios.bin -Binary -offset 0x00180000

splash.mcs: splash.raw
	srec_cat -Output splash.mcs -Intel splash.raw -Binary -offset 0x001C0000

userfs.mcs: userfs.bin
	srec_cat -Output userfs.mcs -Intel userfs.bin -Binary -offset 0x00260000

splash.raw: splash.png
	$(MMDIR)/tools/makeraw splash.png

userfs.bin:
	$(MAKE) -C $(MMDIR)/software/demo
	srec_cat -Output userfs.bin -Binary /dev/null -Binary -fill 0xFF 0x000000 0x300000
	/sbin/mkdosfs -F 16 -s 1 userfs.bin
	mcopy -i userfs.bin $(MMDIR)/patches/* $(MMDIR)/software/demo/boot.bin ::

# Run the Xilinx crapware in a separate directory that we can simply rm -rf
# to get rid of the garbage it puts all over the filesystem.
flash_bitstream: bitstream.mcs
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash_bitstream.cmd

flash_bios: bios.mcs
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash_bios.cmd

flash_splash: splash.mcs
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash_splash.cmd

flash_userfs: userfs.mcs
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash_userfs.cmd

flash_all: flash_bitstream flash_bios flash_splash flash_userfs

clean:
	rm -rf impact_sucks
	rm -f bitstream.mcs bitstream.prm bitstream.cfi
	rm -f bios.mcs
	rm -f splash.raw splash.mcs
	rm -f userfs.bin userfs.mcs

.PHONY: flash_bitstream flash_bios flash_splash flash_userfs flash_all clean

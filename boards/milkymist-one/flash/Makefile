all: bitstream.mcs bios.mcs splash.mcs

bitstream.mcs:
	make -C ../synthesis -f Makefile.xst
	promgen -w -p mcs -o bitstream.mcs -s 32768 -u 0x00000000 ../synthesis/build/system.bit -bpi_dc parallel -data_width 16

bios.mcs:
	make -C ../../../software/bios
	promgen -w -p mcs -o bios.mcs -s 32768 -b -data_file up 0x000C0000 ../../../software/bios/bios.bin -bpi_dc parallel -data_width 16

splash.mcs: splash.raw
	promgen -w -p mcs -o splash.mcs -s 32768 -b -data_file up 0x000D0000 splash.raw -bpi_dc parallel -data_width 16

splash.raw: splash.png
	$(MMDIR)/tools/makeraw splash.png

# Run the Xilinx crapware in a separate directory that we can simply rm -rf
# to get rid of the garbage it puts all over the filesystem.
flash: all
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash.cmd

clean:
	rm -rf impact_sucks
	rm -f bitstream.mcs bitstream.prm bitstream.cfi
	rm -f bios.mcs bios.prm bios.cfi
	rm -f splash.raw splash.mcs splash.prm splash.cfi

.PHONY: flash clean

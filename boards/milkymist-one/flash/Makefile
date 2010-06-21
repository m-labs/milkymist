all: flash.mcs

flash.mcs:
	make -C ../../../software/bios
	srec_cat -Output flash.mcs -Intel ../../../software/bios/bios.bin -Binary

# Run the Xilinx crapware in a separate directory that we can simply rm -rf
# to get rid of the garbage it puts all over the filesystem.
flash: flash.mcs
	mkdir -p impact_sucks
	cd impact_sucks && impact -batch ../flash.cmd

clean:
	rm -rf impact_sucks flash.mcs

.PHONY: flash clean

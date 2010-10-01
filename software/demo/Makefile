MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o tick.o wave.o analyzer.o eval.o line.o apipe.o rpipe.o renderer.o cpustats.o memstats.o shell.o vera20_tff.o font.o osd.o main.o
SEGMENTS=-j .text -j .data -j .rodata

all: boot.bin boot.fbi

bandfilters.h: bandfilters.sce
	scilab -nw -nwni -nogui -nb -f bandfilters.sce

logo.raw: logo.png
	$(MAKE) -C $(MMDIR)/tools
	$(MMDIR)/tools/makeraw logo.png

logo.h: logo.raw
	xxd -i logo.raw logo.h

%.bin: %.elf
	$(MAKE) -C $(MMDIR)/tools
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@

%.fbi: %.bin
	$(MMDIR)/tools/crc32 $< write $@

boot.elf: linker.ld $(OBJECTS)
	$(MAKE) -C $(MMDIR)/software/libbase
	$(MAKE) -C $(MMDIR)/software/libmath
	$(MAKE) -C $(MMDIR)/software/libhal
	$(MAKE) -C $(MMDIR)/software/libfpvm
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libmath -L$(MMDIR)/software/libhal -L$(MMDIR)/software/libfpvm --start-group $(OBJECTS) -lbase -lmath -lhal -lfpvm --end-group
	chmod -x $@

.PHONY: clean depend boot.elf

depend: bandfilters.h logo.h
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) bandfilters.h logo.raw logo.h boot.elf boot.bin boot.fbi .*~ *~ Makefile.bak

# DO NOT DELETE

analyzer.o: ../../software/include/base/stdio.h
analyzer.o: ../../software/include/base/stdlib.h analyzer.h bandfilters.h
apipe.o: ../../software/include/base/stdio.h
apipe.o: ../../software/include/base/stdlib.h
apipe.o: ../../software/include/base/board.h ../../software/include/hal/brd.h
apipe.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
apipe.o: ../../software/include/hw/common.h ../../software/include/hal/pfpu.h
apipe.o: ../../software/include/hw/pfpu.h ../../software/include/hal/time.h
apipe.o: ../../software/include/hal/dmx.h analyzer.h eval.h
apipe.o: ../../software/include/hw/tmu.h cpustats.h rpipe.h
apipe.o: ../../software/include/hal/tmu.h apipe.h
cpustats.o: ../../software/include/base/stdio.h
cpustats.o: ../../software/include/base/stdlib.h
cpustats.o: ../../software/include/base/irq.h
cpustats.o: ../../software/include/hal/time.h cpustats.h
eval.o: ../../software/include/base/stdio.h
eval.o: ../../software/include/base/stdlib.h
eval.o: ../../software/include/base/string.h ../../software/include/hw/pfpu.h
eval.o: ../../software/include/hw/common.h ../../software/include/hw/tmu.h
eval.o: ../../software/include/hal/pfpu.h ../../software/include/fpvm/fpvm.h
eval.o: ../../software/include/fpvm/is.h ../../software/include/fpvm/gfpus.h
eval.o: ../../software/include/fpvm/pfpu.h eval.h renderer.h
font.o: color.h font.h
isr.o: ../../software/include/hw/interrupts.h
isr.o: ../../software/include/base/irq.h ../../software/include/base/uart.h
isr.o: ../../software/include/hal/time.h ../../software/include/hal/snd.h
isr.o: ../../software/include/hw/ac97.h ../../software/include/hw/common.h
isr.o: ../../software/include/hal/pfpu.h ../../software/include/hw/pfpu.h
isr.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
isr.o: ../../software/include/hal/usb.h cpustats.h
line.o: ../../software/include/base/stdlib.h
line.o: ../../software/include/base/math.h color.h line.h
main.o: ../../software/include/base/stdio.h
main.o: ../../software/include/base/stdlib.h
main.o: ../../software/include/base/console.h
main.o: ../../software/include/base/uart.h
main.o: ../../software/include/base/system.h
main.o: ../../software/include/base/irq.h ../../software/include/base/board.h
main.o: ../../software/include/base/version.h
main.o: ../../software/include/hal/brd.h ../../software/include/hal/mem.h
main.o: ../../software/include/hal/time.h ../../software/include/hal/vga.h
main.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
main.o: ../../software/include/hw/common.h ../../software/include/hal/pfpu.h
main.o: ../../software/include/hw/pfpu.h ../../software/include/hal/tmu.h
main.o: ../../software/include/hw/tmu.h ../../software/include/hal/vin.h
main.o: ../../software/include/hal/dmx.h ../../software/include/hal/usb.h
main.o: apipe.h rpipe.h renderer.h cpustats.h memstats.h osd.h shell.h
memstats.o: ../../software/include/base/board.h
memstats.o: ../../software/include/hal/brd.h
memstats.o: ../../software/include/hw/fmlmeter.h
memstats.o: ../../software/include/hw/common.h
osd.o: ../../software/include/hal/vga.h ../../software/include/hal/tmu.h
osd.o: ../../software/include/hw/tmu.h ../../software/include/hw/common.h
osd.o: ../../software/include/hw/sysctl.h ../../software/include/hw/gpio.h
osd.o: ../../software/include/hw/rc5.h ../../software/include/hw/interrupts.h
osd.o: ../../software/include/base/irq.h ../../software/include/base/math.h
osd.o: ../../software/include/base/system.h
osd.o: ../../software/include/base/string.h
osd.o: ../../software/include/base/stdlib.h
osd.o: ../../software/include/base/fatfs.h
osd.o: ../../software/include/base/blockdev.h font.h logo.h renderer.h
osd.o: ../../software/include/base/version.h osd.h
renderer.o: ../../software/include/base/stdio.h
renderer.o: ../../software/include/base/stdlib.h
renderer.o: ../../software/include/base/string.h
renderer.o: ../../software/include/base/math.h
renderer.o: ../../software/include/base/system.h
renderer.o: ../../software/include/hal/pfpu.h
renderer.o: ../../software/include/hw/pfpu.h
renderer.o: ../../software/include/hw/common.h
renderer.o: ../../software/include/hal/vga.h eval.h
renderer.o: ../../software/include/hw/tmu.h apipe.h renderer.h
rpipe.o: ../../software/include/base/stdio.h
rpipe.o: ../../software/include/base/stdlib.h
rpipe.o: ../../software/include/base/irq.h
rpipe.o: ../../software/include/base/system.h
rpipe.o: ../../software/include/base/math.h
rpipe.o: ../../software/include/hw/interrupts.h
rpipe.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
rpipe.o: ../../software/include/hw/common.h ../../software/include/hal/vga.h
rpipe.o: ../../software/include/hal/dmx.h renderer.h wave.h cpustats.h
rpipe.o: color.h line.h osd.h rpipe.h
shell.o: ../../software/include/base/stdio.h
shell.o: ../../software/include/base/stdlib.h
shell.o: ../../software/include/base/string.h
shell.o: ../../software/include/base/console.h
shell.o: ../../software/include/base/uart.h
shell.o: ../../software/include/base/blockdev.h
shell.o: ../../software/include/base/fatfs.h
shell.o: ../../software/include/base/system.h
shell.o: ../../software/include/base/math.h ../../software/include/base/irq.h
shell.o: ../../software/include/base/board.h ../../software/include/hw/pfpu.h
shell.o: ../../software/include/hw/common.h ../../software/include/hw/tmu.h
shell.o: ../../software/include/hw/sysctl.h ../../software/include/hw/gpio.h
shell.o: ../../software/include/hw/interrupts.h
shell.o: ../../software/include/hw/minimac.h
shell.o: ../../software/include/hw/bt656cap.h ../../software/include/hw/rc5.h
shell.o: ../../software/include/hw/midi.h ../../software/include/hw/memcard.h
shell.o: ../../software/include/hw/memtest.h ../../software/include/hal/vga.h
shell.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
shell.o: ../../software/include/hal/tmu.h ../../software/include/hal/time.h
shell.o: ../../software/include/hal/brd.h ../../software/include/hal/vin.h
shell.o: ../../software/include/hal/usb.h line.h wave.h rpipe.h cpustats.h
shell.o: memstats.h shell.h renderer.h
tick.o: ../../software/include/hal/time.h rpipe.h
tick.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
tick.o: ../../software/include/hw/common.h cpustats.h memstats.h
wave.o: ../../software/include/base/stdio.h
wave.o: ../../software/include/base/stdlib.h
wave.o: ../../software/include/base/math.h line.h color.h wave.h renderer.h

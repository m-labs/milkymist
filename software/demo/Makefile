MMDIR=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o tick.o wave.o analyzer.o eval.o line.o apipe.o rpipe.o renderer.o cpustats.o memstats.o shell.o ui.o main.o
SEGMENTS=-j .text -j .data -j .rodata

all: boot.bin

bandfilters.h: bandfilters.sce
	scilab -nw -nwni -nogui -nb -f bandfilters.sce

spam.raw: spam.png
	$(MMDIR)/tools/makeraw spam.png

spam.h: spam.raw
	xxd -i spam.raw spam.h

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	chmod -x $@
	$(MMDIR)/tools/crc32 $@

boot.elf: linker.ld $(OBJECTS) $(MMDIR)/software/libbase/libbase.a $(MMDIR)/software/libmath/libmath.a $(MMDIR)/software/libhal/libhal.a $(MMDIR)/software/libfpvm/libfpvm.a
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libmath -L$(MMDIR)/software/libhal -L$(MMDIR)/software/libfpvm --start-group $(OBJECTS) -lbase -lmath -lhal -lfpvm --end-group
	chmod -x $@

.PHONY: clean depend

depend: bandfilters.h spam.h
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) bandfilters.h spam.raw spam.h boot.elf boot.bin .*~ *~ Makefile.bak

# DO NOT DELETE

analyzer.o: ../../software/include/base/stdio.h
analyzer.o: ../../software/include/base/stdlib.h analyzer.h bandfilters.h
apipe.o: ../../software/include/base/stdio.h
apipe.o: ../../software/include/base/stdlib.h
apipe.o: ../../software/include/base/board.h ../../software/include/hal/brd.h
apipe.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
apipe.o: ../../software/include/hw/common.h ../../software/include/hal/pfpu.h
apipe.o: ../../software/include/hw/pfpu.h ../../software/include/hal/time.h
apipe.o: analyzer.h eval.h ../../software/include/hw/tmu.h cpustats.h rpipe.h
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
eval.o: eval.h renderer.h
isr.o: ../../software/include/hw/interrupts.h
isr.o: ../../software/include/base/irq.h ../../software/include/base/uart.h
isr.o: ../../software/include/hal/time.h ../../software/include/hal/slowout.h
isr.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
isr.o: ../../software/include/hw/common.h ../../software/include/hal/pfpu.h
isr.o: ../../software/include/hw/pfpu.h ../../software/include/hal/tmu.h
isr.o: ../../software/include/hw/tmu.h ui.h cpustats.h
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
main.o: ../../software/include/hw/tmu.h ../../software/include/hal/slowout.h
main.o: ../../software/include/hal/hdlcd.h apipe.h rpipe.h renderer.h ui.h
main.o: cpustats.h memstats.h shell.h
memstats.o: ../../software/include/base/board.h
memstats.o: ../../software/include/hal/brd.h
memstats.o: ../../software/include/hw/fmlmeter.h
memstats.o: ../../software/include/hw/common.h
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
rpipe.o: ../../software/include/hal/vga.h ../../software/include/hal/tmu.h
rpipe.o: ../../software/include/hw/tmu.h ../../software/include/hw/common.h
rpipe.o: renderer.h wave.h cpustats.h color.h line.h rpipe.h spam.h
shell.o: ../../software/include/base/stdio.h
shell.o: ../../software/include/base/stdlib.h
shell.o: ../../software/include/base/string.h
shell.o: ../../software/include/base/console.h
shell.o: ../../software/include/base/uart.h
shell.o: ../../software/include/base/cffat.h
shell.o: ../../software/include/base/system.h
shell.o: ../../software/include/base/math.h ../../software/include/base/irq.h
shell.o: ../../software/include/base/board.h ../../software/include/hw/pfpu.h
shell.o: ../../software/include/hw/common.h ../../software/include/hw/tmu.h
shell.o: ../../software/include/hw/sysctl.h ../../software/include/hw/gpio.h
shell.o: ../../software/include/hw/interrupts.h
shell.o: ../../software/include/hw/minimac.h ../../software/include/hal/vga.h
shell.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
shell.o: ../../software/include/hal/tmu.h ../../software/include/hal/time.h
shell.o: ../../software/include/hal/brd.h line.h wave.h rpipe.h cpustats.h
shell.o: memstats.h shell.h ui.h
tick.o: ../../software/include/hal/time.h rpipe.h
tick.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
tick.o: ../../software/include/hw/common.h cpustats.h memstats.h ui.h
ui.o: ../../software/include/base/stdio.h
ui.o: ../../software/include/base/stdlib.h
ui.o: ../../software/include/base/string.h
ui.o: ../../software/include/base/cffat.h ../../software/include/base/irq.h
ui.o: ../../software/include/base/version.h
ui.o: ../../software/include/hw/interrupts.h
ui.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
ui.o: ../../software/include/hw/gpio.h ../../software/include/hal/hdlcd.h
ui.o: ../../software/include/hal/time.h renderer.h rpipe.h
ui.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
ui.o: cpustats.h ui.h
wave.o: ../../software/include/base/math.h line.h color.h wave.h renderer.h

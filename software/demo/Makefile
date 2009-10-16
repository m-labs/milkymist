MMDIR?=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o tick.o wave.o analyzer.o scanner.o parser.o parser_helper.o compiler.o scheduler.o eval.o line.o apipe.o rpipe.o renderer.o cpustats.o shell.o ui.o main.o
SEGMENTS=-j .text -j .data -j .rodata

all: boot.bin

%.c: %.re
	re2c -o $@ $<

scanner.c: parser.h

parser.h: parser.c

%.c: %.y
	lemon $<

bandfilters.h: bandfilters.sce
	scilab -nw -nwni -nogui -nb -f bandfilters.sce

spam.raw: spam.png
	$(MMDIR)/tools/makeraw spam.png

spam.h: spam.raw
	xxd -i spam.raw spam.h

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	$(MMDIR)/tools/crc32 $@

boot.elf: linker.ld $(OBJECTS)
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libmath -L$(MMDIR)/software/libbase -L$(MMDIR)/software/libhal --start-group $(OBJECTS) -lbase -lmath -lhal --end-group

.PHONY: clean depend

depend: parser.c scanner.c bandfilters.h spam.h
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) scanner.c parser.c parser.h parser.out bandfilters.h spam.raw spam.h boot.elf boot.bin .*~ *~ Makefile.bak

# DO NOT DELETE

analyzer.o: ../../software/include/libc.h ../../software/include/console.h
analyzer.o: analyzer.h bandfilters.h
apipe.o: ../../software/include/libc.h ../../software/include/console.h
apipe.o: ../../software/include/board.h ../../software/include/hal/brd.h
apipe.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
apipe.o: ../../software/include/hw/common.h ../../software/include/hal/pfpu.h
apipe.o: ../../software/include/hw/pfpu.h ../../software/include/hal/time.h
apipe.o: analyzer.h eval.h ../../software/include/hw/tmu.h ast.h cpustats.h
apipe.o: rpipe.h ../../software/include/hal/tmu.h apipe.h
compiler.o: ../../software/include/hw/pfpu.h
compiler.o: ../../software/include/hw/common.h ../../software/include/libc.h
compiler.o: ../../software/include/console.h compiler.h ast.h
cpustats.o: ../../software/include/libc.h ../../software/include/irq.h
cpustats.o: ../../software/include/hal/time.h cpustats.h
eval.o: ../../software/include/libc.h ../../software/include/console.h
eval.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
eval.o: ../../software/include/hal/pfpu.h ast.h compiler.h scheduler.h eval.h
eval.o: ../../software/include/hw/tmu.h
isr.o: ../../software/include/hw/interrupts.h ../../software/include/irq.h
isr.o: ../../software/include/uart.h ../../software/include/hal/time.h
isr.o: ../../software/include/hal/slowout.h ../../software/include/hal/snd.h
isr.o: ../../software/include/hw/ac97.h ../../software/include/hw/common.h
isr.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
isr.o: ../../software/include/hal/pfpu.h ../../software/include/hw/pfpu.h
isr.o: ui.h cpustats.h
line.o: ../../software/include/libc.h ../../software/include/math.h
line.o: ../../software/include/console.h color.h line.h
main.o: ../../software/include/libc.h ../../software/include/console.h
main.o: ../../software/include/uart.h ../../software/include/system.h
main.o: ../../software/include/irq.h ../../software/include/board.h
main.o: ../../software/include/version.h ../../software/include/hw/sysctl.h
main.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
main.o: ../../software/include/hw/interrupts.h
main.o: ../../software/include/hal/brd.h ../../software/include/hal/mem.h
main.o: ../../software/include/hal/time.h ../../software/include/hal/vga.h
main.o: ../../software/include/hal/snd.h ../../software/include/hw/ac97.h
main.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
main.o: ../../software/include/hal/pfpu.h ../../software/include/hw/pfpu.h
main.o: ../../software/include/hal/slowout.h
main.o: ../../software/include/hal/hdlcd.h apipe.h rpipe.h renderer.h ui.h
main.o: cpustats.h shell.h
parser.o: ../../software/include/stdio.h ../../software/include/libc.h
parser.o: ../../software/include/console.h ../../software/include/malloc.h
parser.o: ../../software/include/math.h ast.h
parser_helper.o: ../../software/include/libc.h
parser_helper.o: ../../software/include/malloc.h
parser_helper.o: ../../software/include/console.h scanner.h parser.h ast.h
parser_helper.o: parser_helper.h
renderer.o: ../../software/include/libc.h ../../software/include/console.h
renderer.o: ../../software/include/math.h ../../software/include/system.h
renderer.o: ../../software/include/hal/pfpu.h
renderer.o: ../../software/include/hw/pfpu.h
renderer.o: ../../software/include/hw/common.h
renderer.o: ../../software/include/hal/vga.h parser_helper.h ast.h eval.h
renderer.o: ../../software/include/hw/tmu.h apipe.h renderer.h
rpipe.o: ../../software/include/libc.h ../../software/include/console.h
rpipe.o: ../../software/include/irq.h ../../software/include/system.h
rpipe.o: ../../software/include/math.h ../../software/include/hw/interrupts.h
rpipe.o: ../../software/include/hal/vga.h ../../software/include/hal/tmu.h
rpipe.o: ../../software/include/hw/tmu.h ../../software/include/hw/common.h
rpipe.o: renderer.h wave.h cpustats.h rpipe.h spam.h
scanner.o: ../../software/include/libc.h ../../software/include/malloc.h
scanner.o: scanner.h parser.h
scheduler.o: ../../software/include/libc.h ../../software/include/console.h
scheduler.o: ../../software/include/hw/pfpu.h
scheduler.o: ../../software/include/hw/common.h scheduler.h compiler.h ast.h
shell.o: ../../software/include/libc.h ../../software/include/console.h
shell.o: ../../software/include/uart.h ../../software/include/cffat.h
shell.o: ../../software/include/system.h ../../software/include/math.h
shell.o: ../../software/include/irq.h ../../software/include/board.h
shell.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
shell.o: ../../software/include/hw/tmu.h ../../software/include/hw/sysctl.h
shell.o: ../../software/include/hw/gpio.h
shell.o: ../../software/include/hw/interrupts.h
shell.o: ../../software/include/hal/vga.h ../../software/include/hal/snd.h
shell.o: ../../software/include/hw/ac97.h ../../software/include/hal/tmu.h
shell.o: ../../software/include/hal/time.h ../../software/include/hal/brd.h
shell.o: line.h wave.h rpipe.h cpustats.h shell.h ui.h
tick.o: ../../software/include/hal/time.h rpipe.h
tick.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
tick.o: ../../software/include/hw/common.h cpustats.h ui.h
ui.o: ../../software/include/libc.h ../../software/include/console.h
ui.o: ../../software/include/cffat.h ../../software/include/irq.h
ui.o: ../../software/include/version.h ../../software/include/hw/interrupts.h
ui.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
ui.o: ../../software/include/hw/gpio.h ../../software/include/hal/hdlcd.h
ui.o: ../../software/include/hal/time.h renderer.h rpipe.h
ui.o: ../../software/include/hal/tmu.h ../../software/include/hw/tmu.h
ui.o: cpustats.h ui.h
wave.o: ../../software/include/libc.h ../../software/include/math.h
wave.o: ../../software/include/console.h line.h color.h wave.h renderer.h

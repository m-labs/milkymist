MMDIR?=../..
include $(MMDIR)/software/include.mak

OBJECTS=crt0.o isr.o brd.o time.o mem.o vga.o snd.o slowout.o hdlcd.o tmu.o pfpu.o wave.o analyzer.o scanner.o parser.o parser_helper.o compiler.o scheduler.o eval.o line.o apipe.o rpipe.o renderer.o cpustats.o shell.o ui.o main.o
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

%.bin: %.elf
	$(OBJCOPY) $(SEGMENTS) -O binary $< $@
	$(MMDIR)/tools/crc32 $@

boot.elf: linker.ld $(OBJECTS) $(MMDIR)/software/baselib/baselib.a $(MMDIR)/software/mathlib/mathlib.a
	$(LD) $(LDFLAGS) -T linker.ld -N -o $@ $(OBJECTS) $(MMDIR)/software/baselib/baselib.a $(MMDIR)/software/mathlib/mathlib.a

.PHONY: clean depend

depend: parser.c scanner.c bandfilters.h
	makedepend -Y -- $(CFLAGS) -- *.c

clean:
	rm -f $(OBJECTS) scanner.c parser.c parser.h parser.out bandfilters.h boot.elf boot.bin .*~ *~ Makefile.bak

# DO NOT DELETE

analyzer.o: ../../software/include/libc.h ../../software/include/console.h
analyzer.o: analyzer.h bandfilters.h
apipe.o: ../../software/include/libc.h ../../software/include/console.h
apipe.o: ../../software/include/board.h brd.h snd.h
apipe.o: ../../software/include/hw/ac97.h ../../software/include/hw/common.h
apipe.o: analyzer.h eval.h ../../software/include/hw/pfpu.h
apipe.o: ../../software/include/hw/tmu.h pfpu.h ast.h time.h cpustats.h
apipe.o: rpipe.h tmu.h apipe.h
brd.o: ../../software/include/libc.h ../../software/include/console.h
brd.o: ../../software/include/board.h brd.h
compiler.o: ../../software/include/hw/pfpu.h
compiler.o: ../../software/include/hw/common.h ../../software/include/libc.h
compiler.o: ../../software/include/console.h compiler.h ast.h
cpustats.o: ../../software/include/libc.h ../../software/include/irq.h time.h
cpustats.o: cpustats.h
eval.o: ../../software/include/libc.h ../../software/include/console.h
eval.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
eval.o: pfpu.h ast.h compiler.h scheduler.h eval.h
eval.o: ../../software/include/hw/tmu.h
hdlcd.o: ../../software/include/libc.h ../../software/include/board.h
hdlcd.o: ../../software/include/console.h ../../software/include/hw/sysctl.h
hdlcd.o: ../../software/include/hw/common.h ../../software/include/hw/gpio.h
hdlcd.o: brd.h slowout.h hdlcd.h
isr.o: ../../software/include/hw/interrupts.h ../../software/include/irq.h
isr.o: ../../software/include/uart.h time.h slowout.h snd.h
isr.o: ../../software/include/hw/ac97.h ../../software/include/hw/common.h
isr.o: tmu.h ../../software/include/hw/tmu.h pfpu.h
isr.o: ../../software/include/hw/pfpu.h ui.h cpustats.h
line.o: ../../software/include/libc.h ../../software/include/math.h
line.o: ../../software/include/console.h color.h line.h
main.o: ../../software/include/libc.h ../../software/include/console.h
main.o: ../../software/include/uart.h ../../software/include/cffat.h
main.o: ../../software/include/system.h ../../software/include/irq.h
main.o: ../../software/include/board.h ../../software/include/version.h
main.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
main.o: ../../software/include/hw/gpio.h
main.o: ../../software/include/hw/interrupts.h brd.h mem.h time.h vga.h snd.h
main.o: ../../software/include/hw/ac97.h tmu.h
main.o: ../../software/include/hw/tmu.h pfpu.h
main.o: ../../software/include/hw/pfpu.h apipe.h rpipe.h renderer.h slowout.h
main.o: hdlcd.h ui.h cpustats.h shell.h
mem.o: ../../software/include/libc.h ../../software/include/console.h
mem.o: ../../software/include/malloc.h ../../software/include/hw/sram.h mem.h
parser.o: ../../software/include/stdio.h ../../software/include/libc.h
parser.o: ../../software/include/console.h ../../software/include/malloc.h
parser.o: ../../software/include/math.h ast.h
parser_helper.o: ../../software/include/libc.h
parser_helper.o: ../../software/include/malloc.h
parser_helper.o: ../../software/include/console.h scanner.h parser.h ast.h
parser_helper.o: parser_helper.h
pfpu.o: ../../software/include/libc.h ../../software/include/console.h
pfpu.o: ../../software/include/irq.h ../../software/include/hw/interrupts.h
pfpu.o: ../../software/include/hw/pfpu.h ../../software/include/hw/common.h
pfpu.o: pfpu.h
renderer.o: ../../software/include/libc.h ../../software/include/console.h
renderer.o: ../../software/include/math.h ../../software/include/system.h
renderer.o: ../../software/include/hw/sysctl.h
renderer.o: ../../software/include/hw/common.h
renderer.o: ../../software/include/hw/uart.h ../../software/include/hw/ac97.h
renderer.o: ../../software/include/hw/tmu.h parser_helper.h ast.h pfpu.h
renderer.o: ../../software/include/hw/pfpu.h vga.h eval.h apipe.h renderer.h
rpipe.o: ../../software/include/libc.h ../../software/include/console.h
rpipe.o: ../../software/include/irq.h ../../software/include/system.h
rpipe.o: ../../software/include/math.h ../../software/include/hw/interrupts.h
rpipe.o: renderer.h vga.h tmu.h ../../software/include/hw/tmu.h
rpipe.o: ../../software/include/hw/common.h wave.h cpustats.h rpipe.h
rpipe.o: spam.xpm
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
shell.o: ../../software/include/hw/interrupts.h vga.h snd.h
shell.o: ../../software/include/hw/ac97.h tmu.h line.h wave.h time.h brd.h
shell.o: rpipe.h cpustats.h shell.h ui.h
slowout.o: ../../software/include/libc.h ../../software/include/console.h
slowout.o: ../../software/include/irq.h
slowout.o: ../../software/include/hw/interrupts.h
slowout.o: ../../software/include/hw/sysctl.h
slowout.o: ../../software/include/hw/common.h
snd.o: ../../software/include/libc.h ../../software/include/console.h
snd.o: ../../software/include/irq.h ../../software/include/hw/ac97.h
snd.o: ../../software/include/hw/common.h
snd.o: ../../software/include/hw/interrupts.h snd.h
time.o: ../../software/include/libc.h ../../software/include/console.h
time.o: ../../software/include/irq.h ../../software/include/board.h
time.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
time.o: ../../software/include/hw/interrupts.h brd.h rpipe.h tmu.h
time.o: ../../software/include/hw/tmu.h cpustats.h ui.h time.h
tmu.o: ../../software/include/libc.h ../../software/include/console.h
tmu.o: ../../software/include/irq.h ../../software/include/board.h
tmu.o: ../../software/include/hw/interrupts.h ../../software/include/hw/tmu.h
tmu.o: ../../software/include/hw/common.h brd.h tmu.h
ui.o: ../../software/include/libc.h ../../software/include/console.h
ui.o: ../../software/include/cffat.h ../../software/include/irq.h
ui.o: ../../software/include/version.h ../../software/include/hw/interrupts.h
ui.o: ../../software/include/hw/sysctl.h ../../software/include/hw/common.h
ui.o: ../../software/include/hw/gpio.h renderer.h hdlcd.h time.h rpipe.h
ui.o: tmu.h ../../software/include/hw/tmu.h cpustats.h ui.h
vga.o: ../../software/include/console.h ../../software/include/hw/vga.h
vga.o: ../../software/include/hw/common.h
wave.o: ../../software/include/libc.h ../../software/include/math.h
wave.o: ../../software/include/console.h line.h color.h wave.h renderer.h

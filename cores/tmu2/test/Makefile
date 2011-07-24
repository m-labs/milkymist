# Usage: make TB=test_bench_file.v [ARBSRC=/path_to/fmlarb.v]
#

ARBSRC?=$(wildcard ../../fmlarb/rtl/*)
SOURCES=$(wildcard ../rtl/*) $(ARBSRC)

all: sim

sim: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(TB) $(SOURCES)

vpi_images.so: vpi_images.o
	$(LD) -G -shared -export-dynamic -o vpi_images.so vpi_images.o -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_images.o: vpi_images.c
	$(CC) -I/usr/include/cver -fPIC -Wall -O2 -c -o vpi_images.o vpi_images.c

clean:
	rm -f verilog.log vpi_images.o vpi_images.so out.png

.PHONY: clean sim

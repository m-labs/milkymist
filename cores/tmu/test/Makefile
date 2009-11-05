SOURCES=tb_tmu.v $(wildcard ../rtl/*.v)

all: sim

sim: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(SOURCES)

vpi_images.so: vpi_images.o
	$(LD) -G -shared -export-dynamic -o vpi_images.so vpi_images.o -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_images.o: vpi_images.c
	$(CC) -fPIC -Wall -g -O2 -c -o vpi_images.o vpi_images.c

clean:
	rm -f verilog.log vpi_images.o vpi_images.so out.png

.PHONY: clean sim

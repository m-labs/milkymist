SOURCES=$(wildcard ../rtl/*.v) $(wildcard ../../asfifo/rtl/*.v) tb_bt656cap.v

all: sim

sim: vpi_imageout.so
	cver +loadvpi=./vpi_imageout.so:vpi_register $(SOURCES)

vpi_imageout.so: vpi_imageout.o
	$(LD) -G -shared -export-dynamic -o vpi_imageout.so vpi_imageout.o -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_imageout.o: vpi_imageout.c
	$(CC) -I/usr/include/cver -fPIC -Wall -O2 -c -o vpi_imageout.o vpi_imageout.c

clean:
	rm -f verilog.log vpi_imageout.o vpi_imageout.so out.png

.PHONY: clean sim

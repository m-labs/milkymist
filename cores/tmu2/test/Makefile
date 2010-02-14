SOURCES=tb_tmu2.v \
../rtl/tmu2_adrgen.v \
../rtl/tmu2_clamp.v \
../rtl/tmu2_dpram.v \
../rtl/tmu2_dpram_sw.v \
../rtl/tmu2_hdiv.v \
../rtl/tmu2_wb_datamem.v \
../rtl/tmu2_wb_tagmem.v \
../rtl/tmu2_writebuffer.v \
../rtl/tmu2.v\
../rtl/tmu2_ctlif.v \
../rtl/tmu2_fetchvertex.v \
../rtl/tmu2_hinterp.v \
../rtl/tmu2_qpram32.v \
../rtl/tmu2_vdivops.v \
../rtl/tmu2_blend.v \
../rtl/tmu2_mult2.v \
../rtl/tmu2_decay.v \
../rtl/tmu2_geninterp18.v \
../rtl/tmu2_mask.v \
../rtl/tmu2_qpram.v \
../rtl/tmu2_vdiv.v \
../rtl/tmu2_divider17.v \
../rtl/tmu2_hdivops.v \
../rtl/tmu2_texcache.v \
../rtl/tmu2_vinterp.v

SOURCES_VIRTEX4=tb_tmu2.v \
DSP48.v \
../rtl/tmu2_adrgen.v \
../rtl/tmu2_clamp.v \
../rtl/tmu2_dpram.v \
../rtl/tmu2_dpram_sw.v \
../rtl/tmu2_hdiv.v \
../rtl/tmu2_wb_datamem.v \
../rtl/tmu2_wb_tagmem.v \
../rtl/tmu2_writebuffer.v \
../rtl/tmu2.v \
../rtl/tmu2_ctlif.v \
../rtl/tmu2_fetchvertex.v \
../rtl/tmu2_hinterp.v \
../rtl/tmu2_qpram32.v \
../rtl/tmu2_vdivops.v \
../rtl/tmu2_decay.v \
../rtl/tmu2_geninterp18.v \
../rtl/tmu2_mask.v \
../rtl/tmu2_qpram.v \
../rtl/tmu2_vdiv.v \
../rtl/tmu2_divider17.v \
../rtl/tmu2_hdivops.v \
../rtl/tmu2_texcache.v \
../rtl/tmu2_vinterp.v \
../rtl/tmu2_blend.v \
../rtl/tmu2_mult2_virtex4.v

all: sim

sim: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(SOURCES)

sim_virtex4: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(SOURCES_VIRTEX4)

isim: tb_tmu2 vpi_images_icarus.vpi
	vvp -M. -mvpi_images_icarus tb_tmu2

tb_tmu2: $(SOURCES)
	iverilog -o tb_tmu2 $(SOURCES)

vpi_images.so: vpi_images.o
	$(LD) -G -shared -export-dynamic -o vpi_images.so vpi_images.o -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_images.o: vpi_images.c
	$(CC) -I/usr/include/cver -fPIC -Wall -O2 -c -o vpi_images.o vpi_images.c

vpi_images_icarus.vpi: vpi_images_icarus.o
	$(CC) -shared -o vpi_images_icarus.vpi vpi_images_icarus.o -lvpi -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_images_icarus.o: vpi_images.c
	$(CC) -I/usr/include/iverilog -fPIC -Wall -O2 -c -o vpi_images_icarus.o vpi_images.c

clean:
	rm -f verilog.log vpi_images.o vpi_images.so out.png tb_tmu2 vpi_images_icarus.o vpi_images_icarus.vpi

.PHONY: clean sim sim_virtex4

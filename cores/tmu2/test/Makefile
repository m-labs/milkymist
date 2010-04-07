SOURCES= \
../rtl/tmu2_adrgen.v \
../rtl/tmu2_clamp.v \
../rtl/tmu2_dpram.v \
../rtl/tmu2_dpram_sw.v \
../rtl/tmu2_hdiv.v \
../rtl/tmu2_burst.v \
../rtl/tmu2_pixout.v \
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
../rtl/tmu2_vinterp.v \
../rtl/tmu2_fdest.v \
../rtl/tmu2_alpha.v \
../../fmlarb/rtl/fmlarb.v

SOURCES_VIRTEX4= \
DSP48.v \
../rtl/tmu2_adrgen.v \
../rtl/tmu2_clamp.v \
../rtl/tmu2_dpram.v \
../rtl/tmu2_dpram_sw.v \
../rtl/tmu2_hdiv.v \
../rtl/tmu2_burst.v \
../rtl/tmu2_pixout.v \
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
../rtl/tmu2_mult2_virtex4.v \
../rtl/tmu2_fdest.v \
../rtl/tmu2_alpha.v \
../../fmlarb/rtl/fmlarb.v

all: sim

sim: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(TB) $(SOURCES)

sim_virtex4: vpi_images.so
	cver +loadvpi=./vpi_images.so:vpi_register $(TB) $(SOURCES_VIRTEX4)

vpi_images.so: vpi_images.o
	$(LD) -G -shared -export-dynamic -o vpi_images.so vpi_images.o -lgd -lpng -lz -ljpeg -lfreetype -lm

vpi_images.o: vpi_images.c
	$(CC) -I/usr/include/cver -fPIC -Wall -O2 -c -o vpi_images.o vpi_images.c

clean:
	rm -f verilog.log vpi_images.o vpi_images.so out.png

.PHONY: clean sim sim_virtex4

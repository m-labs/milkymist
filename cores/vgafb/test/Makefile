SOURCES_PIXELFEED=tb_pixelfeed.v ../rtl/vgafb_pixelfeed.v ../rtl/vgafb_fifo64to16.v

all: pixelfeed

pixelfeed: $(SOURCES_PIXELFEED)
	cver $(SOURCES_PIXELFEED)

clean:
	rm -f verilog.log

.PHONY: clean pixelfeed

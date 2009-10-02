SOURCES=tb_clz32.v ../../rtl/pfpu_clz32.v

all: tb_clz32

sim: tb_clz32
	./tb_clz32

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_clz32 verilog.log

tb_clz32: $(SOURCES)
	iverilog -o tb_clz32 $(SOURCES)

.PHONY: clean sim cversim

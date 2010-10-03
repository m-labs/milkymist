MMDIR?=../../..
SOURCES=tb_monitor.v $(wildcard ../rtl/*.v)

all: tb_monitor

isim: tb_monitor monitor.rom
	./tb_monitor

cversim: $(SOURCES) monitor.rom
	cver $(SOURCES)

monitor.rom:
	make -C $(MMDIR)/software/monitor
	cp $(MMDIR)/software/monitor/monitor.rom .

clean:
	rm -f tb_monitor verilog.log monitor.vcd monitor.rom

tb_monitor: $(SOURCES)
	iverilog -o tb_monitor $(SOURCES)

.PHONY: clean sim cversim

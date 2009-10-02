TOPDIR?=$(shell pwd)
BOARD_DIR=$(TOPDIR)/../rtl
CORES_DIR=$(TOPDIR)/../../../cores

include ../sources.mak

SIM_SRC=$(TOPDIR)/system_tb.v $(CORES_DIR)/hpdmc_ddr32/test/iddr.v $(CORES_DIR)/hpdmc_ddr32/test/oddr.v $(CORES_DIR)/hpdmc_ddr32/test/idelay.v

SRC=$(SIM_SRC) $(BOARD_SRC) $(CORES_SRC)

all: isim

cversim: $(SRC) bios.rom
	cver +define+SIMULATION +incdir+$(BOARD_DIR) +incdir+$(CORES_DIR)/lm32/rtl $(SRC)

isim: system bios.rom
	./system

system: $(SRC)
	iverilog -D SIMULATION -I $(BOARD_DIR) -I $(CORES_DIR)/lm32/rtl -o system $(SRC)

bios.rom: ../../../software/bios/bios.bin
	../../../tools/bin2hex ../../../software/bios/bios.bin bios.rom 32768

clean:
	rm -f verilog.log system

.PHONY: clean cversim isim

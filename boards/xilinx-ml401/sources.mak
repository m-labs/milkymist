BOARD_SRC=$(wildcard $(BOARD_DIR)/*.v)

CONBUS_SRC=$(wildcard $(CORES_DIR)/conbus/rtl/*.v)
LM32_SRC=						\
	$(CORES_DIR)/lm32/rtl/lm32_cpu.v		\
	$(CORES_DIR)/lm32/rtl/lm32_instruction_unit.v	\
	$(CORES_DIR)/lm32/rtl/lm32_decoder.v		\
	$(CORES_DIR)/lm32/rtl/lm32_load_store_unit.v	\
	$(CORES_DIR)/lm32/rtl/lm32_adder.v		\
	$(CORES_DIR)/lm32/rtl/lm32_addsub.v		\
	$(CORES_DIR)/lm32/rtl/lm32_logic_op.v		\
	$(CORES_DIR)/lm32/rtl/lm32_shifter.v		\
	$(CORES_DIR)/lm32/rtl/lm32_multiplier.v		\
	$(CORES_DIR)/lm32/rtl/lm32_mc_arithmetic.v	\
	$(CORES_DIR)/lm32/rtl/lm32_interrupt.v		\
	$(CORES_DIR)/lm32/rtl/lm32_ram.v		\
	$(CORES_DIR)/lm32/rtl/lm32_icache.v		\
	$(CORES_DIR)/lm32/rtl/lm32_dcache.v		\
	$(CORES_DIR)/lm32/rtl/lm32_top.v
FMLARB_SRC=$(wildcard $(CORES_DIR)/fmlarb/rtl/*.v)
FMLBRG_SRC=$(wildcard $(CORES_DIR)/fmlbrg/rtl/*.v)
CSRBRG_SRC=$(wildcard $(CORES_DIR)/csrbrg/rtl/*.v)
NORFLASH_SRC=$(wildcard $(CORES_DIR)/norflash32/rtl/*.v)
BRAM_SRC=$(wildcard $(CORES_DIR)/bram/rtl/*.v)
UART_SRC=$(wildcard $(CORES_DIR)/uart/rtl/*.v)
SYSCTL_SRC=$(wildcard $(CORES_DIR)/sysctl/rtl/*.v)
ACEUSB_SRC=$(wildcard $(CORES_DIR)/aceusb/rtl/*.v)
HPDMC_SRC=$(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/*.v) $(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/virtex4/*.v)
VGAFB_SRC=						\
	$(CORES_DIR)/vgafb/rtl/vgafb_graycounter.v	\
	$(CORES_DIR)/vgafb/rtl/vgafb_asfifo.v		\
	$(CORES_DIR)/vgafb/rtl/vgafb_pixelfeed.v	\
	$(CORES_DIR)/vgafb/rtl/vgafb_ctlif.v		\
	$(CORES_DIR)/vgafb/rtl/vgafb_fifo64to16.v	\
	$(CORES_DIR)/vgafb/rtl/vgafb.v
AC97_SRC=$(wildcard $(CORES_DIR)/ac97/rtl/*.v)
PFPU_SRC=$(wildcard $(CORES_DIR)/pfpu/rtl/*.v)
TMU_SRC=$(wildcard $(CORES_DIR)/tmu/rtl/*.v)
PS2_SRC=$(wildcard $(CORES_DIR)/ps2/rtl/*.v)

CORES_SRC=$(CONBUS_SRC) $(LM32_SRC) $(FMLARB_SRC) $(FMLBRG_SRC) $(CSRBRG_SRC) $(NORFLASH_SRC) $(BRAM_SRC) $(UART_SRC) $(SYSCTL_SRC) $(ACEUSB_SRC) $(HPDMC_SRC) $(VGAFB_SRC) $(AC97_SRC) $(PFPU_SRC) $(TMU_SRC) $(PS2_SRC)

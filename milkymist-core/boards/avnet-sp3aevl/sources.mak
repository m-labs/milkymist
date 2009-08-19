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
CSRBRG_SRC=$(wildcard $(CORES_DIR)/csrbrg/rtl/*.v)
NORFLASH_SRC=$(wildcard $(CORES_DIR)/norflash8/rtl/*.v)
BRAM_SRC=$(wildcard $(CORES_DIR)/bram/rtl/*.v)
UART_SRC=$(wildcard $(CORES_DIR)/uart/rtl/*.v)
SYSCTL_SRC=$(wildcard $(CORES_DIR)/sysctl/rtl/*.v)

CORES_SRC=$(CONBUS_SRC) $(LM32_SRC) $(CSRBRG_SRC) $(NORFLASH_SRC) $(BRAM_SRC) $(UART_SRC) $(SYSCTL_SRC)

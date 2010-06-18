BOARD_SRC=$(wildcard $(BOARD_DIR)/*.v) $(BOARD_DIR)/../../gen_capabilities.v

ASFIFO_SRC=$(wildcard $(CORES_DIR)/asfifo/rtl/*.v)
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
UART_SRC=$(wildcard $(CORES_DIR)/uart/rtl/*.v)
SYSCTL_SRC=$(wildcard $(CORES_DIR)/sysctl/rtl/*.v)
ACEUSB_SRC=$(wildcard $(CORES_DIR)/aceusb/rtl/*.v)
HPDMC_SRC=$(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/*.v) $(wildcard $(CORES_DIR)/hpdmc_ddr32/rtl/virtex4/*.v)
VGAFB_SRC=						\
	$(CORES_DIR)/vgafb/rtl/vgafb_pixelfeed.v	\
	$(CORES_DIR)/vgafb/rtl/vgafb_ctlif.v		\
	$(CORES_DIR)/vgafb/rtl/vgafb_fifo64to16.v	\
	$(CORES_DIR)/vgafb/rtl/vgafb.v
AC97_SRC=$(wildcard $(CORES_DIR)/ac97/rtl/*.v)
PFPU_SRC=$(wildcard $(CORES_DIR)/pfpu/rtl/*.v)
TMU_SRC=						\
	$(CORES_DIR)/tmu2/rtl/tmu2_adrgen.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_clamp.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_dpram_sw.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_hdiv.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_burst.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_pixout.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2.v			\
	$(CORES_DIR)/tmu2/rtl/tmu2_ctlif.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_fetchvertex.v	\
	$(CORES_DIR)/tmu2/rtl/tmu2_hinterp.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_qpram32_ss.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_vdivops.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_decay.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_geninterp18.v	\
	$(CORES_DIR)/tmu2/rtl/tmu2_mask.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_qpram.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_vdiv.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_divider17.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_hdivops.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_texcache.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_vinterp.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_blend.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_mult2_virtex4.v	\
	$(CORES_DIR)/tmu2/rtl/tmu2_fdest.v		\
	$(CORES_DIR)/tmu2/rtl/tmu2_alpha.v
PS2_SRC=$(wildcard $(CORES_DIR)/ps2/rtl/*.v)
ETHERNET_SRC=$(wildcard $(CORES_DIR)/minimac/rtl/*.v)
FMLMETER_SRC=$(wildcard $(CORES_DIR)/fmlmeter/rtl/*.v)

CORES_SRC=$(ASFIFO_SRC) $(CONBUS_SRC) $(LM32_SRC) $(FMLARB_SRC) $(FMLBRG_SRC) $(CSRBRG_SRC) $(NORFLASH_SRC) $(UART_SRC) $(SYSCTL_SRC) $(ACEUSB_SRC) $(HPDMC_SRC) $(VGAFB_SRC) $(AC97_SRC) $(PFPU_SRC) $(TMU_SRC) $(PS2_SRC) $(ETHERNET_SRC) $(FMLMETER_SRC)

SOURCES=tb_lm32.v lm32_config.v
SOURCES+=../rtl/lm32_adder.v ../rtl/lm32_addsub.v ../rtl/lm32_cpu.v ../rtl/lm32_dcache.v ../rtl/lm32_debug.v ../rtl/lm32_decoder.v ../rtl/lm32_dp_ram.v ../rtl/lm32_icache.v ../rtl/lm32_instruction_unit.v ../rtl/lm32_interrupt.v ../rtl/lm32_jtag.v ../rtl/lm32_load_store_unit.v ../rtl/lm32_logic_op.v ../rtl/lm32_mc_arithmetic.v ../rtl/lm32_multiplier.v ../rtl/lm32_ram.v ../rtl/lm32_shifter.v ../rtl/lm32_top.v

all: tb_lm32

sim_%: %.vh tb_lm32
	@vvp tb_lm32 +prog=$<

trace_%: %.vh tb_lm32
	@vvp tb_lm32 +trace=trace_$*.txt +prog=$<

hello_world.elf: crt.S hello_world.c
	lm32-elf-gcc -Tlinker.ld -fno-builtin -o $@ $^

pipe1.elf: pipe1.S
	lm32-elf-gcc -Tlinker.ld -fno-builtin -o $@ $^

%.vh: %.elf
	lm32-elf-objcopy -O verilog $< $@

clean:
	rm -f tb_lm32 *.vcd *.elf *.vh trace*.txt

tb_lm32: $(SOURCES)
	iverilog -I. -I../rtl -o tb_lm32 $(SOURCES)

.PHONY: clean sim

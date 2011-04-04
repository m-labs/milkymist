OUTPUT_FORMAT("elf32-lm32")
ENTRY(_start)

__DYNAMIC = 0;

MEMORY {
    rom : ORIGIN = 0x10000000, LENGTH = 0x00001800 /* 6k */
    ram : ORIGIN = 0x10001800, LENGTH = 0x00000800 /* 2k */
}

SECTIONS
{
	.text :
	{
		_ftext = .;
		*(.text .stub .text.* .gnu.linkonce.t.*)
		_etext = .;
	} > rom

	.rodata :
	{
		. = ALIGN(4);
		_frodata = .;
		*(.rodata .rodata.* .gnu.linkonce.r.*)
		*(.rodata1)
		_erodata = .;
	} > rom

	.bss :
	{
		. = ALIGN(4);
		_fbss = .;
		*(.dynsbss)
		*(.sbss .sbss.* .gnu.linkonce.sb.*)
		*(.scommon)
		*(.dynbss)
		*(.bss .bss.* .gnu.linkonce.b.*)
		*(COMMON)
		. = ALIGN(4);
		_ebss = .;
		_end = .;
	} > ram
}

PROVIDE(_debug_stack = ORIGIN(ram) + LENGTH(ram) - 4);

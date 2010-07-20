.section ".vectors","ax"
.globl _start
.org 0x00
_start:
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16

	rcall main

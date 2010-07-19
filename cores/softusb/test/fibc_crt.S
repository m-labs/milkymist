.global _start
_start:
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16
	/* call C function */
	ldi r24, 11
	rcall fib
	/* output result to port 1 */
	out 0x01, r24
	/* terminate simulation */
	ldi r16, 0xfe
	out 0x00, r16

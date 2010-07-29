/* test for Navre core - compute Fibonacci numbers recursively */

_start:
	/* test STS instruction */
	ldi r24, 0x42 
	sts 0x100, r24
	/* test IN instruction */
	in r16, 0x01
	out 0x01, r16
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16
	/* compute number */
	ldi r16, 11
	rcall fib
	/* output result to port 1 */
	out 0x01, r16
	/* terminate simulation */
	ldi r16, 0xfe
	out 0x00, r16

fib:
	cpi r16, 0
	breq fib01
	cpi r16, 1
	breq fib01
	dec r16
	push r16
	rcall fib
	pop r17
	push r16
	mov r16, r17
	dec r16
	rcall fib
	pop r17
	add r16, r17
	ret

fib01:
	ldi r16, 1
	ret

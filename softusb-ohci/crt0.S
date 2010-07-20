#include "sie.h" /* HACK */

.section ".vectors","ax"
.globl _start
.org 0x00
_start:
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16

	/* HACK */

	/** transmit byte 1 **/
	ldi r16, 0x69
	out SIE_TX_DATA, r16
wait1:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait1

	/** transmit byte 2 **/
	ldi r16, 0x80
	out SIE_TX_DATA, r16
wait2:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait2

	/** transmit byte 3 **/
	ldi r16, 0x28
	out SIE_TX_DATA, r16
wait3:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait3
	
	clr r16
	out SIE_TX_VALID, r16

	/* END HACK */

	rcall main

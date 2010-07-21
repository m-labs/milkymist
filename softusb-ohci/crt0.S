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

	ldi r16, 0x03
	out SIE_SEL_TX, r16

	/** bus reset **/
	/* bus reset for ~50ms */
	ldi r16, 0x01
	out SIE_TX_BUSRESET, r16

	ldi r18, 0x1a
reset3:
	ldi r17, 0xff
reset2:
	ldi r16, 0xff
reset1:
	dec r16
	brne reset1
	dec r17
	brne reset2
	dec r18
	brne reset3
	

	/* release bus reset for 10ms */
	ldi r16, 0x00
	out SIE_TX_BUSRESET, r16

	ldi r18, 0x05
unreset3:
	ldi r17, 0xff
unreset2:
	ldi r16, 0xff
unreset1:
	dec r16
	brne unreset1
	dec r17
	brne unreset2
	dec r18
	brne unreset3

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

	/** transmit EOP **/
	clr r16
	out SIE_TX_VALID, r16

	/* Now, receive */
	clr r30
	clr r31

waitrx:
	in r16, SIE_RX_PENDING
	cpi r16, 0x00
	breq waitrx
	in r16, SIE_RX_DATA
	ldi r16, 0x42
	st Z, r16
	inc r30
	rjmp waitrx

	/* END HACK */

	rcall main

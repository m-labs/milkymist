#include "sie.h" /* HACK */

.section ".vectors","ax"
.globl _start
.org 0x00
_start:
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16

#define HACK
#ifdef HACK
	ldi r16, 0x03
	out SIE_SEL_TX, r16

#define BUSRESET
#ifdef BUSRESET
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

//	ldi r18, 0x05
//unreset3:
	ldi r17, 0x2
unreset2:
	ldi r16, 0xff
unreset1:
	dec r16
	brne unreset1
	dec r17
	brne unreset2
//	dec r18
//	brne unreset3
#endif

	/***** SOF *****/
	ldi r16, 0xa5
	out SIE_TX_DATA, r16
sofwait1:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq sofwait1

	/** transmit byte 2 **/
	ldi r16, 0x01
	out SIE_TX_DATA, r16
sofwait2:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq sofwait2

	/** transmit byte 3 **/
	ldi r16, 0xe8
	out SIE_TX_DATA, r16
sofwait3:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq sofwait3

	/** transmit EOP **/
	clr r16
	out SIE_TX_VALID, r16

	ldi r16, 0xff
sofwait4:
	dec r16
	brne sofwait4

	/***** SETUP *****/
	/** transmit byte 1 **/
	ldi r16, 0x2d
	out SIE_TX_DATA, r16
wait1:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait1

	/** transmit byte 2 **/
	ldi r16, 0x00
	out SIE_TX_DATA, r16
wait2:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait2

	/** transmit byte 3 **/
	ldi r16, 0x10
	out SIE_TX_DATA, r16
wait3:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq wait3

	/** transmit EOP **/
	clr r16
	out SIE_TX_VALID, r16

	/***** DATA0 *****/
	/** transmit byte 1 **/
	ldi r16, 0xc3
	out SIE_TX_DATA, r16
xwait1:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait1

	/** transmit byte 2 **/
	ldi r16, 0x80
	out SIE_TX_DATA, r16
xwait2:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait2

	/** transmit byte 3 **/
	ldi r16, 0x06
	out SIE_TX_DATA, r16
xwait3:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait3

	/** transmit byte 4 **/
	ldi r16, 0x00
	out SIE_TX_DATA, r16
xwait4:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait4

	/** transmit byte 5 **/
	ldi r16, 0x01
	out SIE_TX_DATA, r16
xwait5:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait5

	/** transmit byte 6 **/
	ldi r16, 0x00
	out SIE_TX_DATA, r16
xwait6:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait6

	/** transmit byte 7 **/
	ldi r16, 0x00
	out SIE_TX_DATA, r16
xwait7:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait7

	/** transmit byte 8 **/
	ldi r16, 0x40
	out SIE_TX_DATA, r16
xwait8:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait8

	/** transmit byte 9 **/
	ldi r16, 0x00
	out SIE_TX_DATA, r16
xwait9:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait9

	/** transmit byte 10 **/
	ldi r16, 0xdd
	out SIE_TX_DATA, r16
xwait10:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait10

	/** transmit byte 11 **/
	ldi r16, 0x94
	out SIE_TX_DATA, r16
xwait11:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq xwait11

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
	st Z, r16
	inc r30
	rjmp waitrx
#endif

	rcall main

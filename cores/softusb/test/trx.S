#define SIE_LINE_STATUS_A	0x00
#define SIE_LINE_STATUS_B	0x01
#define SIE_DISCON_A		0x02
#define SIE_DISCON_B		0x03

#define SIE_SEL_RX		0x04
#define SIE_SEL_TX		0x05

#define SIE_TX_DATA		0x06
#define SIE_TX_PENDING		0x07
#define SIE_TX_VALID		0x08
#define SIE_TX_BUSRESET		0x09

#define SIE_RX_DATA		0x0a
#define SIE_RX_PENDING		0x0b
#define SIE_RX_ACTIVE		0x0c

#define SIE_TX_LOW_SPEED	0x0d
#define SIE_LOW_SPEED		0x0e
#define SIE_GENERATE_EOP	0x0f

.section ".vectors","ax"
.globl _start
.org 0x00
_start:
	/* set stack pointer */
	ldi r16, 0xff
	out 0x3e, r16
	out 0x3d, r16

	ldi r16, 0x03
	out SIE_SEL_TX, r16

	/***** SOF *****/
	ldi r16, 0x80
	out SIE_TX_DATA, r16
sofwait0:
	in r16, SIE_TX_PENDING
	cpi r16, 0x01
	breq sofwait0

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

/* 
 * libHPDMC - SDRAM initialization runtime for Milkymist bootloaders
 * Copyright (C) 2010 Sebastien Bourdeauducq
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 3 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses>.
 */

#include <hw/uart.h>
#include <hw/hpdmc.h>
#include <hw/vga.h>
#include <hw/interrupts.h>

/*
 * GLOBAL VARIABLES
 * r25: Input delay
 * r24: DQS phase
 * r23: return address
 */

.section .text, "ax", @progbits 
.global _sdram_init
_sdram_init:
	mv	r23, ra
	mvhi	r1, hi(banner)
	ori	r1, r1, lo(banner)
	calli	print
	
	bi send_init
send_init_return:
	mvhi	r1, hi(seqcomplete)
	ori	r1, r1, lo(seqcomplete)
	calli	print
	
	xor	r25, r25, r25
	xor	r24, r24, r24
	bi	autocalibrate
autocalibrate_fail_return:
	mvhi	r1, hi(autocalfail)
	ori	r1, r1, lo(autocalfail)
	calli	print
	bi	mancal /* does not return */
autocalibrate_success_return:
	mvhi	r1, hi(autocalok)
	ori	r1, r1, lo(autocalok)
	calli	print
	
	/* big memory test */
	mvi	r1, 1
	xor	r2, r2, r2
	calli	memtest
	be	r1, r0, memtest_fail
	mvhi	r1, hi(continueboot)
	ori	r1, r1, lo(continueboot)
	calli	print
	
	b	r23
memtest_fail:
	mvhi	r1, hi(testfailmsg)
	ori	r1, r1, lo(testfailmsg)
	calli	print
	bi	mancal /* does not return */

/* clobbers: r1, r2, r3 */
send_init:
	/* Bring CKE high */
	mvhi	r2, hi(CSR_HPDMC_SYSTEM)
	ori	r2, r2, lo(CSR_HPDMC_SYSTEM)
	mvu	r3, (HPDMC_SYSTEM_BYPASS|HPDMC_SYSTEM_RESET|HPDMC_SYSTEM_CKE)
	sw 	(r2+0), r3
	
	ori	r1, r0, 2
	calli	delay
	
	mvhi	r2, hi(CSR_HPDMC_BYPASS)
	ori	r2, r2, lo(CSR_HPDMC_BYPASS)
	
	/* Precharge All */
	mvu	r3, 0x400B
	sw 	(r2+0), r3
	mvu	r1, 2
	calli	delay
	
	/* Load Extended Mode Register */
	mvhi	r3, 0x2
	ori	r3, r3, 0x000F
	sw 	(r2+0), r3
	mvu	r1, 2
	calli	delay
	
	/* Load Mode Register */
	mvu	r3, 0x123F
	sw 	(r2+0), r3
	mvu	r1, 200
	calli	delay
	
	/* Precharge All */
	mvu	r3, 0x400B
	sw 	(r2+0), r3
	mvu	r1, 2
	calli	delay
	
	/* Auto Refresh */
	mvu	r3, 0xD
	sw 	(r2+0), r3
	mvu	r1, 8
	calli	delay
	
	/* Auto Refresh */
	mvu	r3, 0xD
	sw 	(r2+0), r3
	mvu	r1, 8
	calli	delay
	
	/* Load Mode Register, Enable DLL */
	mvu	r3, 0x23F
	sw 	(r2+0), r3
	mvu	r1, 200
	calli	delay

	/* All done, get the controller into gear */
	mvhi	r2, hi(CSR_HPDMC_SYSTEM)
	ori	r2, r2, lo(CSR_HPDMC_SYSTEM)
	mvu	r3, (HPDMC_SYSTEM_CKE)
	sw 	(r2+0), r3

	bi	send_init_return

/* clobbers: */
autocalibrate:
	bi	autocalibrate_fail_return

/* does not return */
mancal:
	/* enable VGA out */
	mvhi	r1, hi(CSR_VGA_BASEADDRESS)
	ori	r1, r1, lo(CSR_VGA_BASEADDRESS)
	mvhi	r2, 0x4000
	sw 	(r1+0), r2
	mvhi	r1, hi(CSR_VGA_RESET)
	ori	r1, r1, lo(CSR_VGA_RESET)
	sw 	(r1+0), r0
mancal_loop:
	mvhi	r1, hi(manualkeys)
	ori	r1, r1, lo(manualkeys)
	calli	print
	mv	r1, r25
	calli	printint
	mvhi	r1, hi(spacer)
	ori	r1, r1, lo(spacer)
	calli	print
	mv	r1, r24
	calli	printint
	mvhi	r1, hi(nl)
	ori	r1, r1, lo(nl)
	calli	print
	calli	getkey
	mvu	r2, 'u'
	be	r1, r2, inc_input_delay
	mvu	r2, 'd'
	be	r1, r2, dec_input_delay
	mvu	r2, 'U'
	be	r1, r2, inc_dqs_phase
	mvu	r2, 'D'
	be	r1, r2, dec_dqs_phase
	mvu	r2, 't'
	be	r1, r2, small_test
	mvu	r2, 'T'
	be	r1, r2, big_test
	mvu	r2, 'p'
	be	r1, r2, disp_pattern
	mvu	r2, 'b'
	be	r1, r2, boot
	bi mancal_loop
inc_input_delay:
	mvu	r1, 63
	be	r25, r1, mancal_loop
	addi	r25, r25, 1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_CE|HPDMC_IDELAY_INC)
	sw	(r1+0), r2
	bi	mancal_loop
dec_input_delay:
	be	r25, r0, mancal_loop
	addi	r25, r25, -1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_CE)
	sw	(r1+0), r2
	bi	mancal_loop
inc_dqs_phase:
	mvu	r1, 255
	be	r24, r1, mancal_loop
	addi	r24, r24, 1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_DQSDELAY_CE|HPDMC_DQSDELAY_INC)
	sw	(r1+0), r2
	bi	wait_dqs
dec_dqs_phase:
	be	r24, r0, mancal_loop
	addi	r24, r24, -1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_DQSDELAY_CE)
	sw	(r1+0), r2
wait_dqs:
	lw	r2, (r1+0)
	andi	r2, r2, HPDMC_DQSDELAY_RDY
	be	r2, r0, wait_dqs
	bi	mancal_loop
small_test:
	xor	r1, r1, r1
	xor	r2, r2, r2
	calli	memtest
	bi	after_test
big_test:
	mvu	r1, 1
	xor	r2, r2, r2
	calli memtest
after_test:
	be	r1, r0, print_test_fail
	mvhi	r1, hi(memtestpassed)
	ori	r1, r1, lo(memtestpassed)
	calli	print
	bi	mancal_loop
print_test_fail:
	mvhi	r1, hi(memtestfailed)
	ori	r1, r1, lo(memtestfailed)
	calli	print
	bi	mancal_loop
disp_pattern:
	mvu	r1, 640
	mvu	r2, 480
	mvu	r7, 12
	mvu	r8, 6
	xor	r4, r4, r4 /* current Y pos */
	mvhi	r5, 0x4000 /* current address */
yloop:
	xor	r3, r3, r3 /* current X pos */
xloop:
	add	r6, r3, r4
	modu	r9, r6, r7
	mvu	r6, 0xffff
	bge	r9, r8, staywhite
	xor	r6, r6, r6
staywhite:
	sh	(r5+0), r6
	addi	r5, r5, 2
	addi	r3, r3, 1
	bne	r3, r1, xloop
	addi	r4, r4, 1
	bne	r4, r2, yloop
	bi	mancal_loop
boot:
	mvhi	r1, hi(CSR_VGA_RESET)
	ori	r1, r1, lo(CSR_VGA_RESET)
	mvi	r2, VGA_RESET
	sw 	(r1+0), r2
	b	r23

/* memtest - tests memory
 *
 * inputs:	r1 - 64MB/1MB
 *              r2 - PRNG seed
 * outputs:	r1 - pass/fail
 * clobbers:	r1, r3, r4, r5, r6, r7
 */
memtest:
	/* 1. fill with pattern */
	mvhi	r5, 0x4000	/* r5 - current address */
	mvhi	r3, 0x100	/* r3 - remaining words */
	mv	r4, r3		/* r4 - number of words to test */
	mv	r6, r2		/* r6 - current value of the PRNG */
	mvhi	r7, hi(22695477)
	ori	r7, r7, lo(22695477)
	bne	r1, r0, patloop
	mvhi	r3, 0x4
	mv	r4, r3
patloop:
	sw	(r5+0), r6
	mul	r6, r6, r7
	addi	r6, r6, 1
	addi	r5, r5, 4
	addi	r3, r3, -1
	bne	r3, r0, patloop
	/* 2. check pattern */
	mvhi	r5, 0x4000	/* r5 - current address */
	mv	r3, r4		/* r3 - remaining words */
	mv	r6, r2		/* r6 - current value of the PRNG */
chkloop:
	lw	r4, (r5+0)
	bne	r4, r6, testfail
	mul	r6, r6, r7
	addi	r6, r6, 1
	addi	r5, r5, 4
	addi	r3, r3, -1
	bne	r3, r0, chkloop
	mvu	r1, 1
	ret
testfail:
	xor r1, r1, r1
	ret

/* getkey - gets a character from the console
 *
 * inputs:	none
 * outputs:	r1 - character
 * clobbers:	r1
 */
getkey:
	rcsr	r1, IP
	andi	r1, r1, IRQ_UARTRX
	be	r1, r0, getkey
	wcsr	IP, r1
	mvhi	r1, hi(CSR_UART_RXTX)
	ori	r1, r1, lo(CSR_UART_RXTX)
	lw	r1, (r1+0)
	ret

/* printint - prints an integer 0-999
 *
 * inputs:	r1 - input
 * outputs:	none
 * clobbers:	r1, r2, r3, r4
 */
printint:
	mvhi	r2, hi(CSR_UART_RXTX)
	ori	r2, r2, lo(CSR_UART_RXTX)
	
	mvu	r4, 100
	divu	r3, r1, r4
	modu	r1, r1, r4
	addi	r3, r3, '0'
	sw	(r2+0), r3
writeintwait1:
	rcsr	r3, IP
	andi	r3, r3, IRQ_UARTTX
	be	r3, r0, writeintwait1
	wcsr	IP, r3
	
	mvu	r4, 10
	divu	r3, r1, r4
	modu	r1, r1, r4
	addi	r3, r3, '0'
	sw	(r2+0), r3
writeintwait2:
	rcsr	r3, IP
	andi	r3, r3, IRQ_UARTTX
	be	r3, r0, writeintwait2
	wcsr	IP, r3
	
	addi	r3, r1, '0'
	sw	(r2+0), r3
writeintwait3:
	rcsr	r3, IP
	andi	r3, r3, IRQ_UARTTX
	be	r3, r0, writeintwait3
	wcsr	IP, r3

	ret

/* print - prints a zero terminated string on the console
 *
 * inputs:	r1 - address of the string
 * outputs:	none
 * clobbers:	r1, r2, r3
 */
print:
	mvhi	r2, hi(CSR_UART_RXTX)
	ori	r2, r2, lo(CSR_UART_RXTX)
writeloop:
	lb	r3, (r1+0)
	be	r3, r0, print_endloop
	sw	(r2+0), r3
writewait:
	rcsr	r3, IP
	andi	r3, r3, IRQ_UARTTX
	be	r3, r0, writewait
	wcsr	IP, r3
	addi	r1, r1, 1
	bi	writeloop
print_endloop:
	ret

/* delay - delay loop
 *
 * inputs:	r1 - number of iterations
 * outputs:	none
 * clobbers:	r1
 */
delay:
	addi	r1, r1, -1
	bne	r1, r0, delay
	ret

.section .rodata, "a"
banner: .string "libHPDMC SDRAM initialization runtime\n(c) Copyright 2010 Sebastien Bourdeauducq, released under GNU LGPL version 3.\n\n\0"
seqcomplete: .string "Initialization sequence completed.\n\0"
autocalfail: .string "Autocalibration failed, entering manual mode.\n\0"
autocalok: .string "Autocalibration OK, testing memory...\n\0"
continueboot: .string "All SDRAM initialization completed, boot continuing.\n\0"
testfailmsg: .string "Memory test failed, entering manual mode.\n\0"
manualkeys: .string "\nu: inc. input delay // d: dec. input delay\nU: inc. DQS phase   // D: dec. DQS phase\nt: test 1MB         // T: test 64MB\np: display pattern\nb: boot\n\0"
memtestfailed: .string "Memory test failed.\n\0"
memtestpassed: .string "Memory test passed.\n\0"
spacer: .string " -- \0"
nl: .string "\n\0"
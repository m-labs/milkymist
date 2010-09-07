/*
 * libHPDMC - SDRAM initialization runtime for Milkymist SoC bootloaders
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
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <version.h>

#include "libhpdmc.h"

/* evaluate feature dependencies */
#if defined(FEAT_MANUAL_CALIBRATION) && defined(FEAT_NO_OUTPUT)
#  error "Can't use FEAT_MANUAL_CALIBRATION with FEAT_NO_OUTPUT"
#endif

#if defined(FEAT_PBC_MANUAL_CALIBRATION) && ! defined(FEAT_MANUAL_CALIBRATION)
#  error "FEAT_PBC_MANUAL_CALIBRATION needs FEAT_MANUAL_CALIBRATION"
#endif

/*
 * GLOBAL VARIABLES
 * r24: DQS delay
 * r23: return address
 */

#ifndef FEAT_NO_OUTPUT
.macro PRINT str
	mvhi	r1, hi(\str)
	ori	r1, r1, lo(\str)
	calli	print
.endm
#else
.macro PRINT str
.endm
#endif

.macro RETURN rc
	mvi	r1, \rc
	b	r23
.endm

.section .text, "ax", @progbits
.global _sdram_init
_sdram_init:
	mv	r23, ra
	PRINT(banner)
	PRINT(version)
	PRINT(nl)
	PRINT(nl)

	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)

	/* calibrate and set IDELAY=0 */
	mvu	r2, (HPDMC_IDELAY_CAL)
	sw	(r1+0), r2
	mvu	r1, 20
	calli	delay
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_RST)
	sw	(r1+0), r2
	mvu	r1, 20
	calli	delay
	sw	(r1+0), r2

	xor	r24, r24, r24

	/* send init sequence */
	bi send_init
send_init_return:
	PRINT(seqcomplete)

#ifdef FEAT_PBC_MANUAL_CALIBRATION
	/* if BTN3 is pushed, go into debug/manual mode */
	mvhi	r1, hi(CSR_GPIO_IN)
	ori	r1, r1, lo(CSR_GPIO_IN)
	lw	r2, (r1+0)
	andi	r2, r2, (GPIO_BTN3)
	bne	r2, r0, mancal
#endif

	bi	autocalibrate
autocalibrate_fail_return:
	PRINT(autocalfail)
#ifdef FEAT_MANUAL_CALIBRATION
	bi	mancal /* does not return */
#endif
#ifdef FEAT_RETURN_STATUS
	RETURN(LIBHPDMC_CALIBRATION_FAILED)
#endif
	bi	autocalibrate_fail_return

autocalibrate_success_return:
	PRINT(autocalok)
	
	/* small memory test */
	mvi	r1, 0
	xor	r2, r2, r2
	calli	memtest
	be	r1, r0, memtest_fail
	PRINT(continueboot)
	
	RETURN(LIBHPDMC_SUCCESS)

memtest_fail:
	PRINT(testfailmsg)
#ifdef FEAT_MANUAL_CALIBRATION
	bi	mancal /* does not return */
#endif
#ifdef FEAT_RETURN_STATUS
	RETURN(LIBHPDMC_MEMTEST_FAILED)
#endif
memtest_fail_loop:
	bi	memtest_fail_loop

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

/* clobbers: r1, r2, r3, r4 */
autocalibrate:
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r24, 30 /* input delay, change this number for your board */
	xor	r2, r2, r2
	mvu	r3, (HPDMC_IDELAY_CE|HPDMC_IDELAY_INC)
	be	r2, r24, idelay_loop_end
idelay_loop:
	sw	(r1+0), r3
	addi	r2, r2, 1
	bne	r2, r24, idelay_loop
idelay_loop_end:
	bi	autocalibrate_success_return

#ifdef FEAT_MANUAL_CALIBRATION
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
	PRINT(manualkeys)
	mv	r1, r24
	calli	printint
	PRINT(nl)
	calli	getkey
	mvu	r2, 'u'
	be	r1, r2, inc_input_delay
	mvu	r2, 'd'
	be	r1, r2, dec_input_delay
	mvu	r2, 't'
	be	r1, r2, small_test
	mvu	r2, 'T'
	be	r1, r2, big_test
	mvu	r2, 'c'
	be	r1, r2, iodelay_calibrate
	mvu	r2, 'r'
	be	r1, r2, iodelay_reset
	mvu	r2, 'p'
	be	r1, r2, disp_pattern
	mvu	r2, 'b'
	be	r1, r2, boot
	bi mancal_loop
inc_input_delay:
	addi	r24, r24, 1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_CE|HPDMC_IDELAY_INC)
	sw	(r1+0), r2
	bi	mancal_loop
dec_input_delay:
	addi	r24, r24, -1
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_CE)
	sw	(r1+0), r2
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
	PRINT(memtestpassed)
	bi	mancal_loop
print_test_fail:
	PRINT(memtestfailed)
	bi	mancal_loop
iodelay_calibrate:
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_CAL)
	sw	(r1+0), r2
	bi	mancal_loop
iodelay_reset:
	mvhi	r1, hi(CSR_HPDMC_IODELAY)
	ori	r1, r1, lo(CSR_HPDMC_IODELAY)
	mvu	r2, (HPDMC_IDELAY_RST)
	sw	(r1+0), r2
	xor	r25, r25, r25
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
	RETURN(LIBHPDMC_SUCCESS)

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
#endif /* FEAT_MANUAL_CALIBRATION */

/* memtest - tests memory
 *
 * inputs:	r1 - big/small
 *              r2 - PRNG seed
 * outputs:	r1 - pass/fail
 * clobbers:	r1, r3, r4, r5, r6, r7
 */
memtest:
	/* 1. fill with pattern */
	mvhi	r5, 0x4000	/* r5 - current address */
	mvhi	r3, 0x200	/* r3 - remaining words */
	mv	r4, r3		/* r4 - number of words to test */
	mv	r6, r2		/* r6 - current value of the PRNG */
	mvhi	r7, hi(22695477)
	ori	r7, r7, lo(22695477)
	bne	r1, r0, patloop
	mvhi	r3, 0x10
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
	xor	r1, r1, r1
	ret

#ifndef FEAT_NO_OUTPUT
/* printint - prints an integer between -999 and 999
 *
 * inputs:	r1 - input
 * outputs:	none
 * clobbers:	r1, r2, r3, r4
 */
printint:
	mvhi	r2, hi(CSR_UART_RXTX)
	ori	r2, r2, lo(CSR_UART_RXTX)

	bge	r1, r0, positive
	xnor	r1, r0, r1
	addi	r1, r1, 1
	
	mvu	r3, '-'
	sw	(r2+0), r3
writeintwait0:
	rcsr	r3, IP
	andi	r3, r3, IRQ_UARTTX
	be	r3, r0, writeintwait0
	wcsr	IP, r3

positive:
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
#endif /* FEAT_NO_OUTPUT */

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

#ifndef FEAT_NO_OUTPUT
.section .rodata, "a"
banner: .string "\nlibHPDMC SDRAM initialization runtime\n(c) Copyright 2010 Sebastien Bourdeauducq, released under GNU LGPL version 3.\nVersion "
version: .string VERSION
seqcomplete: .string "Initialization sequence completed.\n"
autocalfail: .string "Autocalibration failed, entering manual mode.\n"
autocalok: .string "Autocalibration OK, testing memory...\n"
continueboot: .string "All SDRAM initialization completed, boot continuing.\n\n"
testfailmsg: .string "Memory test failed, entering manual mode.\n"
manualkeys: .string "\nu: inc. DQS delay // d: dec. DQS delay\nt: test (small)   // T: test (large)\nc: calibrate IODELAY2s\nr: reset IODELAY2s\np: display pattern\nb: boot\n"
memtestfailed: .string "Memory test failed.\n"
memtestpassed: .string "Memory test passed.\n"
nl: .string "\n"
#endif /* FEAT_NO_OUTPUT */


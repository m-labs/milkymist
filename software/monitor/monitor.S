/*
 * lm32 JTAG monitor
 * 
 * Copyright (C) 2009 by Michael Walle <michael@walle.cc>
 * Loosly based on Jon Beniston's LatticeMico32 JTAG monitor.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the
 * Free Software Foundation, Inc.,
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/* Exception handlers - Must be 32 bytes long. */

.section    .text, "ax", @progbits
.global     _start  

_start:    
_reset_handler:
	xor	r0, r0, r0		/* Clear r0 */
	mvi	ba, 0
	bi	_breakpoint_handler	/* Just call our bp handler */
	nop
	nop
	nop
	nop
	nop

_breakpoint_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ba		/* Save pc */
	calli	handle_exception
	bi	b_restore_and_return

_instruction_bus_error_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ea		/* Save pc */
	calli	handle_exception
	bi	e_restore_and_return

_watchpoint_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ba		/* Save pc */
	calli	handle_exception
	bi	b_restore_and_return

_data_bus_error_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ea		/* Save pc */
	calli	handle_exception
	bi	e_restore_and_return

_divide_by_zero_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ea		/* Save pc */
	calli	handle_exception
	bi	e_restore_and_return

_interrupt_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ea		/* Save pc */
	calli	handle_exception
	bi	e_restore_and_return

_system_call_handler:
	xor	r0, r0, r0		/* Clear r0, in case its corrupted */
	mvhi	r0, hi(_debug_stack)	/* Temporary stack pointer */
	ori	r0, r0, lo(_debug_stack)
	sw	(r0+0), ra		/* Save ra, calli overwrites it */
	calli	save_all		/* After this sp is our debug stack */
	sw	(sp+128), ea		/* Save pc */
	calli	handle_exception
	bi	e_restore_and_return

/* Save all registers onto the stack */ 
save_all:        
	/* Save origin sp */
	addi	r0, r0, -144
	/* Save registers */
	/* 0 - R0 - saved below */
	sw	(r0+4), r1
	sw	(r0+8), r2
	sw	(r0+12), r3
	sw	(r0+16), r4
	sw	(r0+20), r5
	sw	(r0+24), r6
	sw	(r0+28), r7
	sw	(r0+32), r8
	sw	(r0+36), r9
	sw	(r0+40), r10
	sw	(r0+44), r11
	sw	(r0+48), r12
	sw	(r0+52), r13
	sw	(r0+56), r14
	sw	(r0+60), r15
	sw	(r0+64), r16
	sw	(r0+68), r17
	sw	(r0+72), r18
	sw	(r0+76), r19
	sw	(r0+80), r20
	sw	(r0+84), r21
	sw	(r0+88), r22
	sw	(r0+92), r23
	sw	(r0+96), r24
	sw	(r0+100), r25
	sw	(r0+104), r26
	sw	(r0+108), r27
	sw	(r0+112), sp
	/* 116 - RA - saved below */
	sw	(r0+120), ea
	sw	(r0+124), ba
	/* 128 - PC - saved in handler code above */
	/* 132 - EID - saved below */
	rcsr	r1, EBA
	sw	(r0+136), r1
	rcsr	r1, DEBA
	sw	(r0+140), r1
		       
	/* Work out EID from exception entry point address */
	andi	r1, ra, 0xff
	srui	r1, r1, 5
	sw	(r0+132), r1

	/* Switch to sp for debug stack
	 * we can't use mv yet, as r0 is not 0
	 * temorarily store it at r0+116 */
	sw	(r0+116), r0
	lw	sp, (r0+116)

	/* Restore r0 to 0 */
	xor	r0, r0, r0

	/* Fix ra */
	lw	r1, (sp+144)
	sw	(sp+116), r1

	/* Save r0 (hardcoded to 0) */
	sw	(sp+0), r0

	/* Save pointer to registers */
	mv	r22, sp

	ret

/* Restore gp registers */
restore_gp:
	lw	r1, (sp+4)
	lw	r2, (sp+8) 
	lw	r3, (sp+12) 
	lw	r4, (sp+16) 
	lw	r5, (sp+20) 
	lw	r6, (sp+24) 
	lw	r7, (sp+28) 
	lw	r8, (sp+32) 
	lw	r9, (sp+36) 
	lw	r10, (sp+40)
	lw	r11, (sp+44)
	lw	r12, (sp+48)
	lw	r13, (sp+52)
	lw	r14, (sp+56)
	lw	r15, (sp+60)
	lw	r16, (sp+64)
	lw	r17, (sp+68)
	lw	r18, (sp+72)
	lw	r19, (sp+76)
	lw	r20, (sp+80)
	lw	r21, (sp+84)
	lw	r22, (sp+88)
	lw	r23, (sp+92)
	lw	r24, (sp+96)
	lw	r25, (sp+100)
	lw	r26, (sp+104)
	lw	r27, (sp+108)
	ret

/* Restore registers and return from exception */
e_restore_and_return:
	/* first restore gp registers */
	calli	restore_gp
	lw      ra, (sp+116)
	lw      ba, (sp+124)
	lw      ea, (sp+136)
	wcsr    EBA, ea
	lw      ea, (sp+140)
	wcsr    DEBA, ea
	/* Restore EA from PC */        
	lw      ea, (sp+128)
	/* Stack pointer must be restored last, in case it has been updated */
	lw      sp, (sp+112)
	eret

/* Restore registers and return from breakpoint */
b_restore_and_return:
	/* first restore gp registers */
	calli	restore_gp
	lw	ra, (sp+116)
	lw	ea, (sp+120)
	lw	ba, (sp+136)
	wcsr	EBA, ba
	lw	ba, (sp+140)
	wcsr	DEBA, ba
	/* Restore BA from PC */        
	lw 	ba, (sp+128)
	/* Stack pointer must be restored last, in case it has been updated */
	lw	sp, (sp+112)
	bret

jtag_get_byte:
	rcsr	r2, JRX
	andi	r1, r2, 0x100
	be	r1, r0, jtag_get_byte
	wcsr	JRX, r0
	andi	r1, r2, 0xff
	ret

jtag_put_byte:
	rcsr	r2, JTX
	bne	r2, r0, jtag_put_byte
	andi	r2, r1, 0xff
	wcsr	JTX, r2
	ret

jtag_get_reg:
	addi	sp, sp, -8
	sw	(sp+4), ra
	calli	jtag_get_byte
	sb	(sp+11), r1
	calli	jtag_get_byte
	sb	(sp+10), r1
	calli	jtag_get_byte
	sb	(sp+9), r1
	calli	jtag_get_byte
	sb	(sp+8), r1
	lw	r1, (sp+8)
	lw	ra, (sp+4)
	addi	sp, sp, 8
	ret

jtag_put_reg:
	addi	sp, sp, -8
	sw	(sp+4), ra
	sw	(sp+8), r1
	lbu	r1, (sp+11)
	calli	jtag_put_byte
	lbu	r1, (sp+10)
	calli	jtag_put_byte
	lbu	r1, (sp+9)
	calli	jtag_put_byte
	lbu	r1, (sp+8)
	calli	jtag_put_byte
	lw	ra, (sp+4)
	addi	sp, sp, 8
	ret

handle_exception:
	addi	sp, sp, -4
	sw	(sp+4), ra
	/* r22: registers address, set in save_all */
	/* r23: csr_write dispachter base address */
	mvhi	r23, hi(_T_csr_write)
	ori	r23, r23, lo(_T_csr_write)
	/* r24: csr_read dispachter base address */
	mvhi	r24, hi(_T_csr_read)
	ori	r24, r24, lo(_T_csr_read)
	/* r25: dispachter base address */
	mvhi	r25, hi(_T_func)
	ori	r25, r25, lo(_T_func)
	mvi	r1, 'T'
	calli	jtag_put_byte
_get_selection:
	calli	jtag_get_byte
	mvi	r2, 5
	bg	r1, r2, _get_selection
	sli	r1, r1, 2
	add	r1, r1, r25
	b	r1
_continue:
	wcsr	ICC, r0
	nop
	nop
	nop
	wcsr	DCC, r0
	nop
	nop
	nop
	lw	ra, (sp+4)
	addi	sp, sp, 4
	ret

put_registers_address:
	mv	r1, r22
	calli	jtag_put_reg
	bi	_get_selection

read_csr:
	calli	jtag_get_byte
	mvi	r2, 0
	bg	r1, r2, _get_selection
	muli	r2, r1, 8
	add	r2, r2, r24
	b	r2
_put_csr:
	calli	jtag_put_reg
	bi	_get_selection

write_csr:
	calli	jtag_get_byte		/* csr selection */
	mvi	r2, 10
	bg	r1, r2, _get_selection
	muli	r11, r1, 8		/* r11: offset */
	calli	jtag_get_reg		/* r1: value */
	add	r11, r11, r23
	b	r11
	bi	_get_selection

read_memory:
	calli	jtag_get_reg		/* r11: base address */
	mv	r11, r1
	calli	jtag_get_reg		/* r12: length */
	mv	r12, r1
_read_mem:
	be	r12, r0, _read_end
	lbu	r1, (r11+0)
	calli	jtag_put_byte
	addi	r11, r11, 1
	addi	r12, r12, -1
	bi	_read_mem
_read_end:
	bi	_get_selection

write_memory:
	calli	jtag_get_reg		/* r11: base address */
	mv	r11, r1
	calli	jtag_get_reg		/* r12: length */
	mv	r12, r1
_write_mem:
	be	r12, r0, _write_end
	calli	jtag_get_byte
	sb	(r11+0), r1
	addi	r11, r11, 1
	addi	r12, r12, -1
	bi	_write_mem
_write_end:
	bi	_get_selection

_T_func:
	bi	put_registers_address
	bi	read_csr
	bi	write_csr
	bi	read_memory
	bi	write_memory
	bi	_continue

_T_csr_read:
	rcsr	r1, CFG
	bi	_put_csr

_T_csr_write:
	wcsr	EBA, r1
	bi	_get_selection
	wcsr	DC, r1
	bi	_get_selection
	wcsr	DEBA, r1
	bi	_get_selection
	wcsr	BP0, r1
	bi	_get_selection
	wcsr	BP1, r1
	bi	_get_selection
	wcsr	BP2, r1
	bi	_get_selection
	wcsr	BP3, r1
	bi	_get_selection
	wcsr	WP0, r1
	bi	_get_selection
	wcsr	WP1, r1
	bi	_get_selection
	wcsr	WP1, r1
	bi	_get_selection
	wcsr	WP2, r1
	bi	_get_selection
	wcsr	WP3, r1
	bi	_get_selection


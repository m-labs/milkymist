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

.section .text, "ax", @progbits
.global _start, _sdram_init_return
_start:
_reset_handler:
	xor	r0, r0, r0
	wcsr	IE, r0
	mvhi	r1, hi(_reset_handler)
	ori	r1, r1, lo(_reset_handler)
	wcsr	EBA, r1
	xor	r2, r2, r2
	calli	_sdram_init
	bi	done

_breakpoint_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop

_instruction_bus_error_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop

_watchpoint_hander:
	nop; nop; nop; nop
	nop; nop; nop; nop

_data_bus_error_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop

_divide_by_zero_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop

_interrupt_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop

_system_call_handler:
	nop; nop; nop; nop
	nop; nop; nop; nop 

done:
	mvhi	r1, hi(CSR_UART_RXTX)
	ori	r1, r1, lo(CSR_UART_RXTX)
	mvhi	r2, hi(endmsg)
	ori	r2, r2, lo(endmsg)
writeloop:
	lb	r3, (r2+0)
	be	r3, r0, endloop
	sw 	(r1+0), r3
	addi	r2, r2, 1
	bi	writeloop
endloop:
	bi	endloop

.section .rodata, "a"
endmsg: .string "*** returned from libHPDMC\n\0"

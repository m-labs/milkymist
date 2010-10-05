/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

.section .text, "ax", @progbits
.global irq_enable, irq_isenabled, irq_setmask, irq_getmask, irq_pending
.global irq_ack, irq_getie, irq_setie

/* Parameter: 1=enable, 0=disable */
irq_enable:
	wcsr	IE, r1
	ret

/* Parameter: the mask */
irq_setmask:
	wcsr	IM, r1
	ret

/* No parameter */
/* Return value: the mask */
irq_getmask:
	rcsr	r1, IM
	ret

/* No parameter */
/* Return value: pending IRQs */
irq_pending:
	rcsr	r1, IP
	ret

/* Parameter: the mask */
irq_ack:
	wcsr	IP, r1
	ret

/* No parameter */
/* Return value: IE */
irq_getie:
	rcsr	r1, IE
	ret

/* Parameter: IE */
irq_setie:
	wcsr	IE, r1
	ret

/*
 * Milkymist VJ SoC (Software support library)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 3 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 */

.section .text, "ax", @progbits
.global irq_enable, irq_isenabled, irq_setmask, irq_getmask, irq_pending, irq_ack

/* Parameter: 1=enable, 0=disable */
irq_enable:
	wcsr	IE, r1
	ret

/* No parameter */
/* Return value: 1/0 */
irq_isenabled:
	rcsr	r1, IE
	andi	r1, r1, 1
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

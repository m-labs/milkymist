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

#ifndef __IRQ_H
#define __IRQ_H

void irq_enable(unsigned int en);
unsigned int irq_isenabled(); /* < can we get interrupted? returns 0 within ISRs */
void irq_setmask(unsigned int mask);
unsigned int irq_getmask();
unsigned int irq_pending();
void irq_ack(unsigned int mask);

#endif /* __IRQ_H */

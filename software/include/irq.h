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

#ifndef __IRQ_H
#define __IRQ_H

void irq_enable(unsigned int en);
unsigned int irq_isenabled(); /* < can we get interrupted? returns 0 within ISRs */
void irq_setmask(unsigned int mask);
unsigned int irq_getmask();
unsigned int irq_pending();
void irq_ack(unsigned int mask);

#endif /* __IRQ_H */

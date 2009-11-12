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

#ifndef __INTERRUPTS_H
#define __INTERRUPTS_H

#define IRQ_GPIO		(0x00000001)
#define IRQ_TIMER0		(0x00000002)
#define IRQ_TIMER1		(0x00000004)
#define IRQ_UARTRX		(0x00000008)
#define IRQ_UARTTX		(0x00000010)
#define IRQ_AC97CRREQUEST	(0x00000020)
#define IRQ_AC97CRREPLY		(0x00000040)
#define IRQ_AC97DMAR		(0x00000080)
#define IRQ_AC97DMAW		(0x00000100)
#define IRQ_PFPU		(0x00000200)
#define IRQ_TMU			(0x00000400)
#define IRQ_PS2			(0x00000800)

#endif /* __INTERRUPTS_H */

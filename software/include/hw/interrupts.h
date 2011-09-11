/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

#ifndef __HW_INTERRUPTS_H
#define __HW_INTERRUPTS_H

#define IRQ_UART		(0x00000001) /* 0 */
#define IRQ_GPIO		(0x00000002) /* 1 */
#define IRQ_TIMER0		(0x00000004) /* 2 */
#define IRQ_TIMER1		(0x00000008) /* 3 */
#define IRQ_AC97CRREQUEST	(0x00000010) /* 4 */
#define IRQ_AC97CRREPLY		(0x00000020) /* 5 */
#define IRQ_AC97DMAR		(0x00000040) /* 6 */
#define IRQ_AC97DMAW		(0x00000080) /* 7 */
#define IRQ_PFPU		(0x00000100) /* 8 */
#define IRQ_TMU			(0x00000200) /* 9 */
#define IRQ_ETHRX		(0x00000400) /* 10 */
#define IRQ_ETHTX		(0x00000800) /* 11 */
#define IRQ_VIDEOIN		(0x00001000) /* 12 */
#define IRQ_MIDI		(0x00002000) /* 13 */
#define IRQ_IR			(0x00004000) /* 14 */
#define IRQ_USB			(0x00008000) /* 15 */

#endif /* __HW_INTERRUPTS_H */

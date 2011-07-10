/*
 * Milkymist SoC (USB firmware)
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

#ifndef __IO_H
#define __IO_H

#define CPPSUCKS(x) #x

#define rio8(addr)						\
	(__extension__({					\
		unsigned char __result;				\
		__asm__ volatile(					\
			"in %0, " CPPSUCKS(addr) " \n\t"	\
			: "=r" (__result)			\
		);						\
		__result;					\
	}))

#define wio8(addr, value)					\
		__asm__ volatile(					\
			"out " CPPSUCKS(addr) ", %0" "\n\t"	\
			:					\
			: "r" (value)				\
		)

#endif /* __IO_H */

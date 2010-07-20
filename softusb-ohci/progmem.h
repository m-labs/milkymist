/*
 * Milkymist VJ SoC (OHCI firmware)
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

#ifndef __PROGMEM_H
#define __PROGMEM_H

#define PROGMEM __attribute__((__progmem__))

#define read_pgm_byte(addr)					\
	(__extension__({					\
		unsigned int __addr16 = (unsigned int)(addr);	\
		unsigned char __result;				\
		__asm__(					\
			"lpm" "\n\t"				\
			"mov %0, r0" "\n\t"			\
			: "=r" (__result)			\
			: "z" (__addr16)			\
			: "r0"					\
		);						\
		__result;					\
	}))

#endif /* __PROGMEM_H */

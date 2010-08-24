/*
 * Milkymist VJ SoC (USB firmware)
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

#ifndef __COMLOC_H
#define __COMLOC_H

#define COMLOC(x)	(*(char *)(x))
#define COMLOCV(x)	(*(volatile char *)(x))

#define COMLOC_DEBUG_PRODUCE	COMLOC(0x1000)
#define COMLOC_DEBUG(offset)	COMLOC(0x1001+offset)
#define COMLOC_MEVT_PRODUCE	COMLOC(0x1101)
#define COMLOC_MEVT(offset)	COMLOC(0x1102+offset)

#endif /* __COMLOC_H */

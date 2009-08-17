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

#ifndef __ENDIAN_H
#define __ENDIAN_H

#define __LITTLE_ENDIAN 0
#define __BIG_ENDIAN 1
#define __BYTE_ORDER __BIG_ENDIAN

static inline unsigned int le32toh(unsigned int val)
{
	return (val & 0xff) << 24 |
		(val & 0xff00) << 8 |
		(val & 0xff0000) >> 8 |
		(val & 0xff000000) >> 24;
}

static inline unsigned short le16toh(unsigned short val)
{
	return (val & 0xff) << 8 |
		(val & 0xff00) >> 8;
}

#endif /* __ENDIAN_H */

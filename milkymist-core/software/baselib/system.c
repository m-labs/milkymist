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

#include <hw/fmlbrg.h>
#include <system.h>

void flush_bridge_cache()
{
	volatile char *flushbase = (char *)FMLBRG_FLUSH_BASE;
	int i, offset;
	
	offset = 0;
	for(i=0;i<FMLBRG_LINE_COUNT;i++) {
		flushbase[offset] = 0;
		offset += FMLBRG_LINE_LENGTH;
	}
}

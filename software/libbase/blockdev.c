/*
 * Milkymist VJ SoC (Software)
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

#include <hw/flash.h>
#include <string.h>

#include <blockdev.h>

int bd_init(int devnr)
{
	/* Only flash is supported for now */
	if(devnr != BLOCKDEV_FLASH) return 0;
	return 1;
}

int bd_readblock(int block, void *buffer)
{
	memcpy(buffer, (char *)(FLASH_OFFSET_USERFS + block*512), 512);
	return 1;
}

void bd_done()
{
}

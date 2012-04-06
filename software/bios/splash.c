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

#include <stdio.h>
#include <hal/vga.h>
#include <hw/flash.h>

#include "splash.h"

extern int rescue;

void splash_display(void)
{
	int i;
	unsigned short *splash_src = rescue ? (unsigned short *)FLASH_OFFSET_RESCUE_SPLASH : (unsigned short *)FLASH_OFFSET_REGULAR_SPLASH;
	
	printf("I: Displaying splash screen...");

	for(i=0;i<vga_hres*vga_vres;i++)
		vga_backbuffer[i] = splash_src[i];
	vga_swap_buffers();

	printf("OK\n");
}

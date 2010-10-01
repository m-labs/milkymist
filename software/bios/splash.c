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

#include <stdio.h>
#include <hal/vga.h>
#include <hw/flash.h>

#include "splash.h"

extern int rescue;

void splash_display()
{
	int i;
	unsigned short *splash_src = rescue ? (unsigned short *)FLASH_OFFSET_RESCUE_SPLASH : (unsigned short *)FLASH_OFFSET_REGULAR_SPLASH;
	
	printf("I: Displaying splash screen...");

	for(i=0;i<vga_hres*vga_vres;i++)
		vga_backbuffer[i] = splash_src[i];
	vga_swap_buffers();

	printf("OK\n");
}

void splash_showerr()
{
	int x, y;
	unsigned short color = 0xF800;

	for(y=0;y<5;y++)
		for(x=0;x<vga_hres;x++)
			vga_frontbuffer[vga_hres*y+x] = color;
	for(;y<(vga_vres-5);y++) {
		for(x=0;x<5;x++)
			vga_frontbuffer[vga_hres*y+x] = color;
		for(x=vga_hres-5;x<vga_hres;x++)
			vga_frontbuffer[vga_hres*y+x] = color;
	}
	for(;y<vga_vres;y++)
		for(x=0;x<vga_hres;x++)
			vga_frontbuffer[vga_hres*y+x] = color;
}

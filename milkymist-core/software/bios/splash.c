/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <libc.h>
#include <console.h>
#include <system.h>
#include <hw/vga.h>

#include "splash.h"

static int splash_hres;
static int splash_vres;
static unsigned short *splash_fb = NULL;

void splash_display(void *fbadr)
{
	int i;
	unsigned short *splash_src = (unsigned short *)65536;
	
	printf("I: Displaying splash screen...");

	splash_fb = (unsigned short *)fbadr;
	splash_hres = 640;
	splash_vres = 480;

	for(i=0;i<splash_hres*splash_vres;i++)
		splash_fb[i] = splash_src[i];
	flush_bridge_cache();

	CSR_VGA_BASEADDRESS = (unsigned int)splash_fb;
	CSR_VGA_RESET = 0;

	printf("OK\n");
}

void splash_showerr()
{
	int x, y;
	unsigned short color = 0xF800;

	if(splash_fb == NULL) return;
	for(y=0;y<5;y++)
		for(x=0;x<splash_hres;x++)
			splash_fb[splash_hres*y+x] = color;
	for(;y<(splash_vres-5);y++) {
		for(x=0;x<5;x++)
			splash_fb[splash_hres*y+x] = color;
		for(x=splash_hres-5;x<splash_hres;x++)
			splash_fb[splash_hres*y+x] = color;
	}
	for(;y<splash_vres;y++)
		for(x=0;x<splash_hres;x++)
			splash_fb[splash_hres*y+x] = color;
	flush_bridge_cache();
}

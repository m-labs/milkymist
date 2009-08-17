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

#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <libc.h>
#include <console.h>
#include <cffat.h>
#include <system.h>

#include "vga.h"

static int current_slide;

static int load_slide(int slide)
{
	char buffer[16];
	
	sprintf(buffer, "PR%04d.RAW", slide);
	if(!cffat_load(buffer, (char *)vga_backbuffer, 2*vga_hres*vga_vres, NULL)) return 0;
	flush_bridge_cache();
	vga_swap_buffers();
	return 1;
}

static unsigned int previous_keys;

static void check_keys()
{
	static unsigned int current_keys;
	static unsigned int new_keys;
	
	current_keys = CSR_GPIO_IN;
	new_keys = current_keys & (current_keys ^ previous_keys);
	previous_keys = current_keys;
	
	if(new_keys & GPIO_PBW) {
		if(current_slide > 1) {
			current_slide--;
			load_slide(current_slide);
		}
	}
	if(new_keys & GPIO_PBE) {
		if(load_slide(current_slide+1))
			current_slide++;
	}
}

int main()
{
	printf("Milkymist Presenter demo\n");
	printf("Use left and right pushbuttons to switch slides...\n");

	vga_init();
	cffat_init();

	current_slide = 1;
	load_slide(current_slide);
	previous_keys = 0;
	
	while(1) {
		check_keys();
	}
	return 0;
}

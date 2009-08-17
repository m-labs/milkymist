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
#include <uart.h>
#include <cffat.h>
#include <system.h>
#include <irq.h>
#include <board.h>
#include <version.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <hw/interrupts.h>

#include "brd.h"
#include "mem.h"
#include "time.h"
#include "vga.h"
#include "snd.h"
#include "tmu.h"
#include "pfpu.h"
#include "apipe.h"
#include "rpipe.h"
#include "renderer.h"
#include "slowout.h"
#include "hdlcd.h"
#include "ui.h"
#include "cpustats.h"
#include "shell.h"

static void splash()
{
	cffat_init();
	cffat_load("SPLASH.RAW", (char *)vga_backbuffer, 2*vga_hres*vga_vres, NULL);
	cffat_done();
	flush_bridge_cache();
	vga_swap_buffers();
}

static void banner()
{
	putsnonl("\n\n\e[1m     |\\  /|'||      |\\  /|'   |\n"
			  "     | \\/ ||||_/\\  /| \\/ ||(~~|~\n"
			  "     |    |||| \\ \\/ |    ||_) |\n"
			  "                _/          v"VERSION"\n"
			  "\e[0m           SoC demo program\n\n\n");
}

int main()
{
	irq_setmask(0);
	irq_enable(1);
	uart_async_init();
	banner();
	brd_init();
	cpustats_init();
	time_init();
	mem_init();
	vga_init();
	splash();
	snd_init();
	tmu_init();
	pfpu_init();
	renderer_init();
	apipe_init();
	rpipe_init();
	slowout_init();
	hdlcd_init();
	ui_init();
	shell_init();
	
	while(1) {
		if(readchar_nonblock())
			shell_input(readchar());
		apipe_service();
		rpipe_service();
	}
	
	return 0;
}

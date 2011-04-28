/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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
#include <console.h>
#include <uart.h>
#include <system.h>
#include <irq.h>
#include <version.h>

#include <hal/brd.h>
#include <hal/mem.h>
#include <hal/time.h>
#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/pfpu.h>
#include <hal/tmu.h>
#include <hal/vin.h>
#include <hal/dmx.h>
#include <hal/usb.h>
#include <hal/ukb.h>

#include "apipe.h"
#include "rpipe.h"
#include "renderer.h"
#include "cpustats.h"
#include "memstats.h"
#include "osd.h"
#include "shell.h"

static void banner()
{
	printf("\n\n\e[1m     |\\  /|'||      |\\  /|'   |\n"
			  "     | \\/ ||||_/\\  /| \\/ ||(~~|~\n"
			  "     |    |||| \\ \\/ |    ||_) |\n"
			  "                _/          v"VERSION"\n"
			  "\e[0m           SoC demo program\n\n\n");
}

static void welcome()
{
	printf("\n\e[1mIMPORTANT: This program is proof of concept only,\n"
	"IMPORTANT: and is not intended as a demonstration of the\n"
	"IMPORTANT: usability of the final software.\e[0m\n"
	"Questions/feedback: mail devel AT lists.milkymist.org\n"
	"Have fun!\n\n");
}

int main()
{
	irq_setmask(0);
	irq_enable(1);
	uart_init();
	vga_init(0);
	vga_set_console(1);
	banner();
	brd_init();
	usb_init();
	ukb_init();
	cpustats_init();
	memstats_init();
	time_init();
	mem_init();
	snd_init();
	vin_init();
	dmx_init();
	pfpu_init();
	tmu_init();
	renderer_init();
	apipe_init();
	rpipe_init();
	osd_init();
	welcome();
	shell_init();

	while(1) {
		if(readchar_nonblock())
			shell_input(readchar());
		apipe_service();
		rpipe_service();
		osd_service();
	}
	
	return 0;
}

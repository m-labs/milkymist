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
#include <console.h>
#include <uart.h>
#include <system.h>
#include <irq.h>
#include <board.h>
#include <version.h>

#include <hal/brd.h>
#include <hal/mem.h>
#include <hal/time.h>
#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/pfpu.h>
#include <hal/tmu.h>
#include <hal/slowout.h>
#include <hal/hdlcd.h>

#include <net/microudp.h>

#include "apipe.h"
#include "rpipe.h"
#include "renderer.h"
#include "ui.h"
#include "cpustats.h"
#include "shell.h"

static void banner()
{
	putsnonl("\n\n\e[1m     |\\  /|'||      |\\  /|'   |\n"
			  "     | \\/ ||||_/\\  /| \\/ ||(~~|~\n"
			  "     |    |||| \\ \\/ |    ||_) |\n"
			  "                _/          v"VERSION"\n"
			  "\e[0m           SoC demo program\n\n\n");
}

static unsigned char macadr[] = {0xf8, 0x71, 0xfe, 0x01, 0x02, 0x03};

int main()
{
	irq_setmask(0);
	irq_enable(1);
	uart_async_init();
	banner();
	microudp_start(macadr, IPTOINT(192,168,0,42));
	if(microudp_arp_resolve(IPTOINT(192,168,0,15)))
		microudp_send(568, 9374, 45);
	brd_init();
	cpustats_init();
	time_init();
	mem_init();
	//vga_init();
	//snd_init();
	//pfpu_init();
	//tmu_init();
	//renderer_init();
	//apipe_init();
	//rpipe_init();
	//slowout_init();
	//hdlcd_init();
	//ui_init();
	shell_init();
	
	while(1) {
		if(readchar_nonblock())
			shell_input(readchar());
		microudp_service();
		//apipe_service();
		//rpipe_service();
	}
	
	return 0;
}

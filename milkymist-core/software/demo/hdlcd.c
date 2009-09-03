/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

#include <libc.h>
#include <board.h>
#include <console.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>

#include "brd.h"
#include "slowout.h"
#include "hdlcd.h"

/* In tenths of microseconds */
#define SETUP_DELAY 3
#define CLOCK_DELAY 130
#define OP_DELAY 10000

/* In clock cycles */
static unsigned int setup_delay;
static unsigned int clock_delay;
static unsigned int op_delay;

static void hdlcd_send_byte(char c, int isdata)
{
	unsigned int mask;
	unsigned int b = c;

	if(isdata)
		mask = GPIO_HDLCDRS;
	else
		mask = 0;

	slowout_queue(setup_delay, mask|(((b & 0xf0) >> 4) << GPIO_HDLCDD_SHIFT));
	slowout_queue(clock_delay, mask|GPIO_HDLCDE|(((b & 0xf0) >> 4) << GPIO_HDLCDD_SHIFT));
	slowout_queue(clock_delay, mask|(((b & 0xf0) >> 4) << GPIO_HDLCDD_SHIFT));

	slowout_queue(setup_delay, mask|((b & 0x0f) << GPIO_HDLCDD_SHIFT));
	slowout_queue(clock_delay, mask|GPIO_HDLCDE|((b & 0x0f) << GPIO_HDLCDD_SHIFT));
	slowout_queue(clock_delay+op_delay, mask|((b & 0x0f) << GPIO_HDLCDD_SHIFT));
}

void hdlcd_init()
{
	setup_delay = SETUP_DELAY*(brd_desc->clk_frequency/10000000);
	clock_delay = CLOCK_DELAY*(brd_desc->clk_frequency/10000000);
	op_delay = OP_DELAY*(brd_desc->clk_frequency/10000000);

	if(!(CSR_GPIO_IN & GPIO_DIP3)) {
		/* Select 4-bit operation on the LCD */
		slowout_queue(setup_delay, GPIO_HDLCDD5);
		slowout_queue(clock_delay, GPIO_HDLCDE|GPIO_HDLCDD5);
		slowout_queue(clock_delay+op_delay, GPIO_HDLCDD5);
	}
	
	/* Set up the LCD */
	hdlcd_send_byte(0x28, 0);
	hdlcd_send_byte(0x0c, 0);
	hdlcd_send_byte(0x06, 0);
	hdlcd_send_byte(0x01, 0);

	printf("LCD: ready\n");
}

void hdlcd_clear()
{
	hdlcd_send_byte(0x01, 0);
}

int hdlcd_printf(const char *fmt, ...)
{
	va_list args;
	char buffer[34];
	unsigned i;
	int len;

	va_start(args, fmt);
	len = vscnprintf(buffer, sizeof(buffer), fmt, args);
	va_end(args);
	
	hdlcd_send_byte(0x80, 0);

	for(i=0;i<len;i++) {
		if(buffer[i] == '\n')
			hdlcd_send_byte(0xc0, 0);
		else
			hdlcd_send_byte(buffer[i], 1);
	}

	return len;
}

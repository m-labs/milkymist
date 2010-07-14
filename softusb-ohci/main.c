/*
 * Milkymist VJ SoC (OHCI firmware)
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

#include "../software/include/base/version.h"
#include "debug.h"

#define TIMER *((unsigned int *)0x40000000)

#define SIE_LINE_STATUS_A *((unsigned int *)0xc0000000)
#define SIE_LINE_STATUS_B *((unsigned int *)0xc0000004)

enum {
	PORT_STATE_DISCONNECTED,
	PORT_STATE_LOW_SPEED,
	PORT_STATE_FULL_SPEED
};

static char port_a_stat;
static char port_b_stat;

int main()
{
	print_string("softusb-ohci v"VERSION"\n");
	port_a_stat = port_b_stat = PORT_STATE_DISCONNECTED;
	while(1) {
		if(port_a_stat == PORT_STATE_DISCONNECTED) {
			if(SIE_LINE_STATUS_A == 0x01) {
				print_string("full speed device on port A\n");
				port_a_stat = PORT_STATE_FULL_SPEED;
			}
			if(SIE_LINE_STATUS_A == 0x02) {
				print_string("low speed device on port A\n");
				port_a_stat = PORT_STATE_LOW_SPEED;
			}
		} else if(SIE_LINE_STATUS_A == 0x00) {
			print_string("device disconnect on port A\n");
			port_a_stat = PORT_STATE_DISCONNECTED;
		}
		if(port_b_stat == PORT_STATE_DISCONNECTED) {
			if(SIE_LINE_STATUS_B == 0x01) {
				print_string("full speed device on port B\n");
				port_b_stat = PORT_STATE_FULL_SPEED;
			}
			if(SIE_LINE_STATUS_B == 0x02) {
				print_string("low speed device on port B\n");
				port_b_stat = PORT_STATE_LOW_SPEED;
			}
		} else if(SIE_LINE_STATUS_B == 0x00) {
			print_string("device disconnect on port B\n");
			port_b_stat = PORT_STATE_DISCONNECTED;
		}
		debug_service();
	}
	return 0;
}

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
#include "sie.h"
#include "crc.h"

static void tx(const unsigned char *buffer, int len)
{
	int i;

	//for(i=0;i<len;i++) {
		while(SIE_TX_PENDING);
		SIE_TX_DATA = buffer[0];
		while(SIE_TX_PENDING);
		SIE_TX_DATA = buffer[1];
		while(SIE_TX_PENDING);
		SIE_TX_DATA = buffer[2];
	//}
	//while(SIE_TX_PENDING);
	SIE_TX_VALID = 0;
}

static int rx(unsigned char *buffer)
{
	int r;

	r = 0;
	//do {
		while(!(SIE_RX_PENDING));
		buffer[r] = SIE_RX_DATA;
		r++;
	//} while(SIE_RX_ACTIVE);
	//if(SIE_RX_ERROR) return -1;
	return r;
}

unsigned char b[128];
static void test()
{
	int r;
	int i;

	SIE_SEL_TX = 3;
	SIE_TX_BUSRESET = 1;
	b[0] = 0x69;
	b[1] = 0x80;
	b[2] = 0x28;
	print_hex(b[0]);
	print_hex(b[1]);
	print_hex(b[2]);
	print_char('\n');
#ifndef FOR_SIMULATION
	for(i=0;i<100000;i++) debug_service();
#endif
	SIE_TX_BUSRESET = 0;
	for(i=0;i<40;i++) debug_service();
	tx(b, 3);
	r = rx(b);
	r = 0;
	print_string("length:");
	print_hex(r);
	print_char('\n');
	for(i=0;i<r;i++) {
		print_hex(b[i]);
		print_char(' ');
		debug_service();
		debug_service();
		debug_service();
		debug_service();
		debug_service();
		debug_service();
	}
	print_char('\n');
}

enum {
	PORT_STATE_DISCONNECTED = 0,
	PORT_STATE_LOW_SPEED,
	PORT_STATE_FULL_SPEED
};

static char port_a_stat;
static char port_b_stat;

int main()
{
#ifdef FOR_SIMULATION
	test();
	while(1);
#else
	print_string("softusb-ohci v"VERSION"\n");
	while(1) {
		if(port_a_stat == PORT_STATE_DISCONNECTED) {
			if(SIE_LINE_STATUS_A == 0x01) {
				print_string("full speed device on port A\n");
				port_a_stat = PORT_STATE_FULL_SPEED;
				test();
			}
			if(SIE_LINE_STATUS_A == 0x02) {
				print_string("low speed device on port A\n");
				port_a_stat = PORT_STATE_LOW_SPEED;
			}
		} else if(SIE_DISCON_A) {
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
		} else if(SIE_DISCON_B) {
			print_string("device disconnect on port B\n");
			port_b_stat = PORT_STATE_DISCONNECTED;
		}
		debug_service();
	}
#endif
	return 0;
}

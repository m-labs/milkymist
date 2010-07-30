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

#include "progmem.h"
#include "../software/include/base/version.h"
#include "debug.h"
#include "sie.h"
#include "timer.h"
#include "crc.h"

enum {
	PORT_STATE_DISCONNECTED = 0,
	PORT_STATE_LOW_SPEED,
	PORT_STATE_FULL_SPEED
};

static char port_a_stat;
static char port_b_stat;

static const char banner[] PROGMEM = "softusb-ohci v"VERSION"\n";
static const char connect_fs[] PROGMEM = "full speed device on port ";
static const char connect_ls[] PROGMEM = "low speed device on port ";
static const char disconnect[] PROGMEM = "device disconnect on port ";

static unsigned int frame_nr;

static void make_usb_token(unsigned int pid, unsigned int elevenbits, unsigned char *out)
{
	unsigned int crcval;

	out[0] = pid;
	out[1] = elevenbits & 0xff;
	out[2] = (elevenbits & 0x700) >> 8;
	out[2] |= usb_crc5(out[1], out[2]) << 3;
}

static void usb_tx(unsigned char *buf, unsigned int len)
{
	int i;

	for(i=0;i<len;i++) {
		SIE_TX_DATA = buf[i];
		while(SIE_TX_PENDING);
	}
	SIE_TX_VALID = 0;
}

int main()
{
	char usb_buffer[3];
	unsigned int t;
	
	frame_nr = 1;
	SIE_SEL_TX = 3;
	print_string(banner);
	while(1) {
		/* wait for the next frame */
		do {
			t = ((unsigned int)TIMER1 << 8)|TIMER0;
		} while(t < 0xbb70);
		TIMER0 = 0;

		/* send SOF */
		make_usb_token(0xa5, frame_nr, usb_buffer);
		usb_tx(usb_buffer, 3);

		/* handle connections */
		/*if(port_a_stat == PORT_STATE_DISCONNECTED) {
			if(SIE_LINE_STATUS_A == 0x01) {
				print_string(connect_fs); print_char('A'); print_char('\n');
				port_a_stat = PORT_STATE_FULL_SPEED;
			}
			if(SIE_LINE_STATUS_A == 0x02) {
				print_string(connect_ls); print_char('A'); print_char('\n');
				port_a_stat = PORT_STATE_LOW_SPEED;
			}
		} else if(SIE_DISCON_A) {
			print_string(disconnect); print_char('A'); print_char('\n');
			port_a_stat = PORT_STATE_DISCONNECTED;
		}
		if(port_b_stat == PORT_STATE_DISCONNECTED) {
			if(SIE_LINE_STATUS_B == 0x01) {
				print_string(connect_fs); print_char('B'); print_char('\n');
				port_b_stat = PORT_STATE_FULL_SPEED;
			}
			if(SIE_LINE_STATUS_B == 0x02) {
				print_string(connect_ls); print_char('B'); print_char('\n');
				port_b_stat = PORT_STATE_LOW_SPEED;
			}
		} else if(SIE_DISCON_B) {
			print_string(disconnect); print_char('B'); print_char('\n');
			port_b_stat = PORT_STATE_DISCONNECTED;
		}*/
		debug_service();
		frame_nr = (frame_nr + 1) & 0x7ff;
	}
	return 0;
}

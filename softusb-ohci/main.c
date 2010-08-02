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

	SIE_TX_DATA = 0x80; /* send SYNC */
	while(SIE_TX_PENDING);
	for(i=0;i<len;i++) {
		SIE_TX_DATA = buf[i];
		while(SIE_TX_PENDING);
	}
	SIE_TX_VALID = 0;
}

static void usb_rx()
{
	unsigned char c[32];
	unsigned char i, j;
	unsigned int timeout;

	i = 0;
	do {
		timeout = 2000;
		while(!SIE_RX_PENDING) {
			if(timeout-- == 0) {
				print_char('T');
				print_char('\n');
				return;
			}
		}
		c[i] = SIE_RX_DATA;
		i++;
	} while(SIE_RX_ACTIVE);
	for(j=0;j<i;j++)
		print_hex(c[j]);
	print_char('\n');
}

int main()
{
	char usb_buffer[11];
	unsigned int t;
	int i;
	
	frame_nr = 1;
	SIE_SEL_TX = 3;
	SIE_TX_LOW_SPEED = 1;
	SIE_LOW_SPEED = 3;
	print_string(banner);
	SIE_TX_BUSRESET = 1;
	for(i=0;i<50;i++) {
		TIMER0 = 0;
		do {
			t = ((unsigned int)TIMER1 << 8)|TIMER0;
		} while(t < 0xbb70);
	}
	TIMER0 = 0;
	SIE_TX_BUSRESET = 0;
	while(1) {
		/* wait for the next frame */
		do {
			t = ((unsigned int)TIMER1 << 8)|TIMER0;
		} while(t < 0xbb70);
		TIMER0 = 0;

		/* send SOF */
		//make_usb_token(0xa5, frame_nr, usb_buffer);
		//usb_tx(usb_buffer, 3);
		SIE_GENERATE_EOP = 1;
		
		if((frame_nr & 0xff) == 0xff) {
			usb_buffer[0] = 0x2d;
			usb_buffer[1] = 0x00;
			usb_buffer[2] = 0x10;
			usb_tx(usb_buffer, 3);
			usb_buffer[0] = 0xc3;
			usb_buffer[1] = 0x80;
			usb_buffer[2] = 0x06;
			usb_buffer[3] = 0x00;
			usb_buffer[4] = 0x01;
			usb_buffer[5] = 0x00;
			usb_buffer[6] = 0x00;
			usb_buffer[7] = 0x40;
			usb_buffer[8] = 0x00;
			usb_buffer[9] = 0xdd;
			usb_buffer[10] = 0x94;
			usb_tx(usb_buffer, 11);
			usb_rx();
			usb_buffer[0] = 0x69;
			usb_buffer[1] = 0x00;
			usb_buffer[2] = 0x10;
			usb_tx(usb_buffer, 3);
			usb_rx();
			usb_buffer[0] = 0xd2;
			usb_tx(usb_buffer, 1);
			usb_buffer[0] = 0xe1;
			usb_buffer[1] = 0x00;
			usb_buffer[2] = 0x10;
			usb_tx(usb_buffer, 3);
			usb_buffer[0] = 0x4b;
			usb_buffer[1] = 0x00;
			usb_buffer[2] = 0x00;
			usb_tx(usb_buffer, 3);
			usb_rx();
		}

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

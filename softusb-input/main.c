/*
 * Milkymist VJ SoC (USB firmware)
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
#include "progmem.h"
#include "comloc.h"
#include "io.h"
#include "debug.h"
#include "sie.h"
#include "timer.h"
#include "crc.h"

enum {
	PORT_STATE_DISCONNECTED = 0,
	PORT_STATE_BUS_RESET,
	PORT_STATE_RUNNING,
	PORT_STATE_UNSUPPORTED
};

struct port_status {
	char state;
	char fs;
	unsigned long int unreset_frame;
};

static struct port_status port_a;
static struct port_status port_b;

static const char banner[] PROGMEM = "softusb-input v"VERSION"\n";
static const char connect_fs[] PROGMEM = "full speed device on port ";
static const char connect_ls[] PROGMEM = "low speed device on port ";
static const char disconnect[] PROGMEM = "device disconnect on port ";

static unsigned long int frame_nr;

static void make_usb_token(unsigned char pid, unsigned long int elevenbits, unsigned char *out)
{
	out[0] = pid;
	out[1] = elevenbits & 0xff;
	out[2] = (elevenbits & 0x700) >> 8;
	out[2] |= usb_crc5(out[1], out[2]) << 3;
}

static void usb_tx(unsigned char *buf, unsigned long int len)
{
	unsigned long int i;

	wio8(SIE_TX_DATA, 0x80); /* send SYNC */
	while(rio8(SIE_TX_PENDING));
	for(i=0;i<len;i++) {
		wio8(SIE_TX_DATA, buf[i]);
		while(rio8(SIE_TX_PENDING));
	}
	wio8(SIE_TX_VALID, 0);
}

static unsigned long int usb_rx(unsigned char *buf, unsigned int maxlen)
{
	unsigned long int timeout;
	unsigned long int i;

	i = 0;
	timeout = 0xfff;
	while(!rio8(SIE_RX_PENDING)) {
		if(timeout-- == 0)
			return 0;
	}
	while(1) {
		timeout = 0xfff;
		while(!rio8(SIE_RX_PENDING)) {
			if(!rio8(SIE_RX_ACTIVE))
				return i;
			if(timeout-- == 0)
				return 0;
		}
		if(i == maxlen)
			return 0;
		buf[i] = rio8(SIE_RX_DATA);
		i++;
	}
}

static void set_address()
{
	unsigned char usb_buffer[11];
	unsigned long int len;

	/* Set Address (1) */
	/* SETUP */
	make_usb_token(0x2d, 0x000, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATA0 */
	usb_buffer[ 0] = 0xc3; usb_buffer[ 1] = 0x00; usb_buffer[ 2] = 0x05; usb_buffer[ 3] = 0x01;
	usb_buffer[ 4] = 0x00; usb_buffer[ 5] = 0x00; usb_buffer[ 6] = 0x00; usb_buffer[ 7] = 0x00;
	usb_buffer[ 8] = 0x00; usb_buffer[ 9] = 0xeb; usb_buffer[10] = 0x25;
	usb_tx(usb_buffer, 11);
	/* ACK */
	len = usb_rx(usb_buffer, 11);
	if((len != 1) || (usb_buffer[0] != 0xd2)) return;
	/* IN */
	make_usb_token(0x69, 0x000, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATA1 */
	len = usb_rx(usb_buffer, 11);
	if((len != 3) || (usb_buffer[0] != 0x4b)) return;
	/* ACK */
	usb_buffer[0] = 0xd2;
	usb_tx(usb_buffer, 1);
}

static void set_configuration()
{
	unsigned char usb_buffer[11];
	unsigned long int len;

	/* Set Configuration (1) */
	/* SETUP */
	make_usb_token(0x2d, 0x001, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATA0 */
	usb_buffer[ 0] = 0x4b; usb_buffer[ 1] = 0x00; usb_buffer[ 2] = 0x09; usb_buffer[ 3] = 0x01;
	usb_buffer[ 4] = 0x00; usb_buffer[ 5] = 0x00; usb_buffer[ 6] = 0x00; usb_buffer[ 7] = 0x00;
	usb_buffer[ 8] = 0x00; usb_buffer[ 9] = 0x27; usb_buffer[10] = 0x25;
	usb_tx(usb_buffer, 11);
	/* ACK */
	len = usb_rx(usb_buffer, 11);
	if((len != 1) || (usb_buffer[0] != 0xd2)) return;
	/* IN */
	make_usb_token(0x69, 0x001, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATA1 */
	len = usb_rx(usb_buffer, 11);
	if((len != 3) || (usb_buffer[0] != 0x4b)) return;
	/* ACK */
	usb_buffer[0] = 0xd2;
	usb_tx(usb_buffer, 1);
}

static void poll()
{
	unsigned char usb_buffer[11];
	unsigned long int len;
	unsigned char m;

	/* IN */
	make_usb_token(0x69, 0x081, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATAx */
	len = usb_rx(usb_buffer, 11);
	if(len < 7) return;
	/* ACK */
	usb_buffer[0] = 0xd2;
	usb_tx(usb_buffer, 1);
	/* send to host */
	m = COMLOC_MEVT_PRODUCE;
	COMLOC_MEVT(4*m+0) = usb_buffer[1];
	COMLOC_MEVT(4*m+1) = usb_buffer[2];
	COMLOC_MEVT(4*m+2) = usb_buffer[3];
	COMLOC_MEVT(4*m+3) = usb_buffer[4];
	COMLOC_MEVT_PRODUCE = (m + 1) & 0x0f;
}

static void port_service(struct port_status *p, char name)
{
	while(rio8(SIE_TX_BUSY));
	/* writing SIE_SEL_TX here fucks up port A... why? */
	if(name == 'A') {
		//wio8(SIE_SEL_TX, 0x01);
		wio8(SIE_SEL_RX, 0);
	} else {
		//wio8(SIE_SEL_TX, 0x02);
		wio8(SIE_SEL_RX, 1);
	}

	switch(p->state) {
		case PORT_STATE_DISCONNECTED: {
			char linestat;
			if(name == 'A')
				linestat = rio8(SIE_LINE_STATUS_A);
			else
				linestat = rio8(SIE_LINE_STATUS_B);
			if(linestat == 0x01) {
				print_string(connect_fs); print_char(name); print_char('\n');
				p->fs = 1;
				p->state = PORT_STATE_UNSUPPORTED;
			}
			if(linestat == 0x02) {
				print_string(connect_ls); print_char(name); print_char('\n');
				p->fs = 0;
				if(name == 'A')
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) | 0x01);
				else
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) | 0x02);
				p->state = PORT_STATE_BUS_RESET;
				p->unreset_frame = (frame_nr + 50) & 0x7ff;
			}
			break;
		}
		case PORT_STATE_BUS_RESET:
			switch(frame_nr - p->unreset_frame) {
				case 0:
					if(name == 'A')
						wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x02);
					else
						wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x01);
					break;
				case 10:
					set_address();
					break;
				case 11:
					set_configuration();
					p->state = PORT_STATE_RUNNING;
					break;
			}
			break;
		case PORT_STATE_RUNNING:
		case PORT_STATE_UNSUPPORTED: {
			char discon;
			if(name == 'A')
				discon = rio8(SIE_DISCON_A);
			else
				discon = rio8(SIE_DISCON_B);
			if(discon) {
				print_string(disconnect); print_char(name); print_char('\n');
				p->state = PORT_STATE_DISCONNECTED;
			}
			if(p->state == PORT_STATE_RUNNING)
				poll();
			break;
		}
	}
}

int main()
{
	unsigned char mask;
	
	print_string(banner);
	
	/* we only support low speed operation */
	wio8(SIE_TX_LOW_SPEED, 1);
	wio8(SIE_LOW_SPEED, 3);

	wio8(TIMER0, 0);
	while(1) {
		/* wait for the next frame */
		while((rio8(TIMER1) < 0xbb) || (rio8(TIMER0) < 0x70));
		wio8(TIMER0, 0);

		/* send keepalive */
		mask = 0;
		if(port_a.state != PORT_STATE_DISCONNECTED)
			mask |= 0x01;
		if(port_b.state != PORT_STATE_DISCONNECTED)
			mask |= 0x02;
		wio8(SIE_SEL_TX, mask);
		wio8(SIE_GENERATE_EOP, 1);

		port_service(&port_a, 'A');
		port_service(&port_b, 'B');

		frame_nr = (frame_nr + 1) & 0x7ff;
	}
	return 0;
}

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
#include "libc.h"
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
	PORT_STATE_SET_ADDRESS,
	PORT_STATE_GET_DEVICE_DESCRIPTOR,
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

static unsigned long int frame_nr;

static void make_usb_token(unsigned char pid, unsigned long int elevenbits, unsigned char *out)
{
	out[0] = pid;
	out[1] = elevenbits & 0xff;
	out[2] = (elevenbits & 0x700) >> 8;
	out[2] |= usb_crc5(out[1], out[2]) << 3;
}

//#define DUMP

static void usb_tx(unsigned char *buf, unsigned long int len)
{
	unsigned long int i;

#ifdef DUMP
	print_char('>');
	print_char(' ');
	for(i=0;i<len;i++)
		print_hex(buf[i]);
	print_char('\n');
#endif
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
	timeout = 0x1fff;
	while(!rio8(SIE_RX_PENDING)) {
		if(timeout-- == 0) {
			print_char('T');
			print_char('\n');
			return 0;
		}
	}
	while(1) {
		timeout = 0x1fff;
		while(!rio8(SIE_RX_PENDING)) {
			if(!rio8(SIE_RX_ACTIVE)) {
#ifdef DUMP
				unsigned long int j;
				print_char('<');
				print_char(' ');
				for(j=0;j<i;j++)
					print_hex(buf[j]);
				print_char('\n');
#endif
				return i;
}
			if(timeout-- == 0) {
				print_char('t');
				print_char('\n');
				return i;
			}
		}
		if(i == maxlen)
			return 0;
		buf[i] = rio8(SIE_RX_DATA);
		i++;
	}
}

struct setup_packet {
	unsigned char bmRequestType;
	unsigned char bRequest;
	unsigned char wValue[2];
	unsigned char wIndex[2];
	unsigned char wLength[2];
} __attribute__((packed));

static inline unsigned char get_data_token(int *toggle)
{
	*toggle = !(*toggle);
	if(*toggle)
		return 0xc3;
	else
		return 0x4b;
}

static const char control_failed[] PROGMEM = "Control transfer failed:\n";
static const char end_of_transfer[] PROGMEM = "(end of transfer)\n";
static const char setup_reply[] PROGMEM = "SETUP reply:";
static const char in_reply[] PROGMEM = "OUT/DATA reply:\n";
static const char out_reply[] PROGMEM = "IN reply:\n";

static long int control_transfer(unsigned char addr, struct setup_packet *p, int out, unsigned char *payload, long int maxlen)
{
	unsigned char usb_buffer[11];
	int toggle;
	int rxlen;
	long int transferred;
	long int chunklen;
	
	toggle = 0;
	
	/* send SETUP token */
	make_usb_token(0x2d, addr, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* send setup packet */
	usb_buffer[0] = get_data_token(&toggle);
	memcpy(&usb_buffer[1], p, 8);
	usb_crc16(&usb_buffer[1], 8, &usb_buffer[9]);
	usb_tx(usb_buffer, 11);
	/* get ACK token from device */
	rxlen = usb_rx(usb_buffer, 11);
	if((rxlen != 1) || (usb_buffer[0] != 0xd2)) {
		print_string(control_failed);
		print_string(setup_reply);
		dump_hex(usb_buffer, rxlen);
		return -1;
	}
	
	/* data phase */
	transferred = 0;
	if(out) {
		while(1) {
			chunklen = maxlen - transferred;
			if(chunklen == 0)
				break;
			if(chunklen > 8)
				chunklen = 8;
			
			/* send OUT token */
			make_usb_token(0xe1, addr, usb_buffer);
			usb_tx(usb_buffer, 3);
			/* send DATAx packet */
			usb_buffer[0] = get_data_token(&toggle);
			memcpy(&usb_buffer[1], payload, chunklen);
			usb_crc16(&usb_buffer[1], chunklen, &usb_buffer[chunklen+1]);
			usb_tx(usb_buffer, chunklen+3);
			/* get ACK from device */
			rxlen = usb_rx(usb_buffer, 11);
			if((rxlen != 1) || (usb_buffer[0] != 0xd2)) {
				if((rxlen > 0) && (usb_buffer[0] == 0x5a))
					continue; /* NAK: retry */
				print_string(control_failed);
				print_string(out_reply);
				dump_hex(usb_buffer, rxlen);
				return -1;
			}
			
			transferred += chunklen;
			payload += chunklen;
			if(chunklen < 8)
				break;
		}
	} else if(maxlen != 0) {
		while(1) {
			/* send IN token */
			make_usb_token(0x69, addr, usb_buffer);
			usb_tx(usb_buffer, 3);
			/* get DATAx packet */
			rxlen = usb_rx(usb_buffer, 11);
			if((rxlen < 3) || ((usb_buffer[0] != 0xc3) && (usb_buffer[0] != 0x4b))) {
				if((rxlen > 0) && (usb_buffer[0] == 0x5a))
					continue; /* NAK: retry */
				print_string(control_failed);
				print_string(in_reply);
				dump_hex(usb_buffer, rxlen);
				return -1;
			}
			chunklen = rxlen - 3; /* strip token and CRC */
			if(chunklen > (maxlen - transferred))
				chunklen = maxlen - transferred;
			memcpy(payload, &usb_buffer[1], chunklen);
			
			/* send ACK token */
			usb_buffer[0] = 0xd2;
			usb_tx(usb_buffer, 1);
			
			transferred += chunklen;
			payload += chunklen;
			if(chunklen < 8)
				break;
		}
	}
	
	/* send IN/OUT token in the opposite direction to end transfer */
retry:
	make_usb_token(out ? 0x69 : 0xe1, addr, usb_buffer);
	usb_tx(usb_buffer, 3);
	if(out) {
		/* get DATAx packet */
		rxlen = usb_rx(usb_buffer, 11);
		if((rxlen != 3) || ((usb_buffer[0] != 0xc3) && (usb_buffer[0] != 0x4b))) {
			if((rxlen > 0) && (usb_buffer[0] == 0x5a))
				goto retry; /* NAK: retry */
			print_string(control_failed);
			print_string(end_of_transfer);
			print_string(in_reply);
			dump_hex(usb_buffer, rxlen);
			return -1;
		}
		/* send ACK token */
		usb_buffer[0] = 0xd2;
		usb_tx(usb_buffer, 1);
	} else {
		/* send DATAx packet */
		usb_buffer[0] = get_data_token(&toggle);
		usb_buffer[1] = usb_buffer[2] = 0x00; /* CRC is 0x0000 without data */
		usb_tx(usb_buffer, 3);
		/* get ACK token from device */
		rxlen = usb_rx(usb_buffer, 11);
		if((rxlen != 1) || (usb_buffer[0] != 0xd2)) {
			if((rxlen > 0) && (usb_buffer[0] == 0x5a))
				goto retry; /* NAK: retry */
			print_string(control_failed);
			print_string(end_of_transfer);
			print_string(out_reply);
			dump_hex(usb_buffer, rxlen);
			return -1;
		}
	}
	
	return transferred;
}

static void set_configuration()
{
	struct setup_packet p;
	
	p.bmRequestType = 0x00;
	p.bRequest = 0x09;
	p.wValue[0] = 0x01;
	p.wValue[1] = 0x00;
	p.wIndex[0] = 0x00;
	p.wIndex[1] = 0x00;
	p.wLength[0] = 0x00;
	p.wLength[1] = 0x00;
	
	control_transfer(0x01, &p, 1, NULL, 0);
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

static const char connect_fs[] PROGMEM = "full speed device on port ";
static const char connect_ls[] PROGMEM = "low speed device on port ";
static const char disconnect[] PROGMEM = "device disconnect on port ";

static void check_discon(struct port_status *p, char name)
{
	char discon;

	if(name == 'A')
		discon = rio8(SIE_LINE_STATUS_A) == 0x00;
	else
		discon = rio8(SIE_LINE_STATUS_B) == 0x00;
	if(discon) {
		print_string(disconnect); print_char(name); print_char('\n');
		p->state = PORT_STATE_DISCONNECTED;
	}
}

static void port_service(struct port_status *p, char name)
{
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
				p->unreset_frame = (frame_nr + 350) & 0x7ff;
			}
			break;
		}
		case PORT_STATE_BUS_RESET:
			if(frame_nr == p->unreset_frame) {
				if(name == 'A')
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x02);
				else
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x01);
			}
			if(frame_nr == ((p->unreset_frame + 125) & 0x7ff))
				p->state = PORT_STATE_SET_ADDRESS;
			break;
		case PORT_STATE_SET_ADDRESS: {
			struct setup_packet packet;
			
			packet.bmRequestType = 0x00;
			packet.bRequest = 0x05;
			packet.wValue[0] = 0x01;
			packet.wValue[1] = 0x00;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 0x00;
			packet.wLength[1] = 0x00;

			if(control_transfer(0x00, &packet, 1, NULL, 0) == 0)
				p->state = PORT_STATE_GET_DEVICE_DESCRIPTOR;
			else
				p->state = PORT_STATE_UNSUPPORTED;
			break;
		}
		case PORT_STATE_GET_DEVICE_DESCRIPTOR: {
			struct setup_packet packet;
			unsigned char device_descriptor[18];
			
			packet.bmRequestType = 0x80;
			packet.bRequest = 0x06;
			packet.wValue[0] = 0x00;
			packet.wValue[1] = 0x01;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 0x40;
			packet.wLength[1] = 0x00;

			if(control_transfer(0x01, &packet, 0, device_descriptor, 18) >= 0) {
				print_hex(device_descriptor[9]);
				print_hex(device_descriptor[8]);
				print_char('\n');
				print_hex(device_descriptor[11]);
				print_hex(device_descriptor[10]);
				print_char('\n');
				p->state = PORT_STATE_UNSUPPORTED; // XXX
			} else
				p->state = PORT_STATE_UNSUPPORTED;
			break;
		}
		case PORT_STATE_RUNNING:
			check_discon(p, name);
			poll();
			break;
		case PORT_STATE_UNSUPPORTED:
			check_discon(p, name);
			break;
	}
}

static const char banner[] PROGMEM = "softusb-input v"VERSION"\n";

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

		while(rio8(SIE_TX_BUSY));
		wio8(SIE_SEL_RX, 0);
		wio8(SIE_SEL_TX, 0x01);
		port_service(&port_a, 'A');
		while(rio8(SIE_TX_BUSY));
		wio8(SIE_SEL_RX, 1);
		wio8(SIE_SEL_TX, 0x02);
		port_service(&port_b, 'B');

		frame_nr = (frame_nr + 1) & 0x7ff;
	}
	return 0;
}

/*
 * Milkymist SoC (USB firmware)
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
#include "host.h"
#include "crc.h"

enum {
	USB_PID_OUT	= 0xe1,
	USB_PID_IN	= 0x69,
	USB_PID_SETUP	= 0x2d,
	USB_PID_DATA0	= 0xc3,
	USB_PID_DATA1	= 0x4b,
	USB_PID_ACK	= 0xd2,
	USB_PID_NAK	= 0x5a,
};

enum {
	PORT_STATE_DISCONNECTED = 0,
	PORT_STATE_BUS_RESET,
	PORT_STATE_WARMUP,
	PORT_STATE_SET_ADDRESS,
	PORT_STATE_GET_DEVICE_DESCRIPTOR,
	PORT_STATE_GET_CONFIGURATION_DESCRIPTOR,
	PORT_STATE_SET_CONFIGURATION,
	PORT_STATE_RUNNING,
	PORT_STATE_UNSUPPORTED
};

struct port_status {
	char state;
	char fs;
	char keyboard;
	char retry_count;
	unsigned int unreset_frame;

	unsigned char expected_data;
};

static struct port_status port_a;
static struct port_status port_b;

static unsigned int frame_nr;

#define	ADDR_EP(addr, ep)	((addr) | (ep) << 7)

static void make_usb_token(unsigned char pid, unsigned int elevenbits, unsigned char *out)
{
	out[0] = pid;
	out[1] = elevenbits & 0xff;
	out[2] = (elevenbits & 0x700) >> 8;
	out[2] |= usb_crc5(out[1], out[2]) << 3;
}

static void usb_tx(unsigned char *buf, unsigned char len)
{
	unsigned char i;

	wio8(SIE_TX_DATA, 0x80); /* send SYNC */
	while(rio8(SIE_TX_PENDING));
	for(i=0;i<len;i++) {
		wio8(SIE_TX_DATA, buf[i]);
		while(rio8(SIE_TX_PENDING));
	}
	wio8(SIE_TX_VALID, 0);
	while(rio8(SIE_TX_BUSY));
}

static const char transfer_start[] PROGMEM = "Transfer start: ";
static const char timeout_error[] PROGMEM = "RX timeout error\n";
static const char bitstuff_error[] PROGMEM = "RX bitstuff error\n";

static unsigned char usb_rx(unsigned char *buf, unsigned char maxlen)
{
	unsigned int timeout;
	unsigned char i;

	i = 0;
	timeout = 0xfff;
	while(!rio8(SIE_RX_PENDING)) {
		if(timeout-- == 0) {
			print_string(transfer_start);
			print_string(timeout_error);
			return 0;
		}
		if(rio8(SIE_RX_ERROR)) {
			print_string(transfer_start);
			print_string(bitstuff_error);
			return 0;
		}
	}
	while(1) {
		timeout = 0xfff;
		while(!rio8(SIE_RX_PENDING)) {
			if(rio8(SIE_RX_ERROR)) {
				print_string(bitstuff_error);
				return 0;
			}
			if(!rio8(SIE_RX_ACTIVE))
				return i;
			if(timeout-- == 0) {
				print_string(timeout_error);
				return 0;
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

static inline unsigned char get_data_token(char *toggle)
{
	*toggle = !(*toggle);
	if(*toggle)
		return USB_PID_DATA0;
	else
		return USB_PID_DATA1;
}

static const char control_failed[] PROGMEM = "Control transfer failed:\n";
static const char termination[] PROGMEM = "(termination)\n";
static const char setup_reply[] PROGMEM = "SETUP reply:\n";
static const char in_reply[] PROGMEM = "OUT/DATA reply:\n";
static const char out_reply[] PROGMEM = "IN reply:\n";

static char control_transfer(unsigned char addr, struct setup_packet *p, char out, unsigned char *payload, int maxlen)
{
	unsigned char usb_buffer[11];
	char toggle;
	char rxlen;
	char transferred;
	char chunklen;

	toggle = 0;

	/* send SETUP token */
	make_usb_token(USB_PID_SETUP, addr, usb_buffer);
	usb_tx(usb_buffer, 3);
	/* send setup packet */
	usb_buffer[0] = get_data_token(&toggle);
	memcpy(&usb_buffer[1], p, 8);
	usb_crc16(&usb_buffer[1], 8, &usb_buffer[9]);
	usb_tx(usb_buffer, 11);
	/* get ACK token from device */
	rxlen = usb_rx(usb_buffer, 11);
	if((rxlen != 1) || (usb_buffer[0] != USB_PID_ACK)) {
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
			make_usb_token(USB_PID_OUT, addr, usb_buffer);
			usb_tx(usb_buffer, 3);
			/* send DATAx packet */
			usb_buffer[0] = get_data_token(&toggle);
			memcpy(&usb_buffer[1], payload, chunklen);
			usb_crc16(&usb_buffer[1], chunklen, &usb_buffer[chunklen+1]);
			usb_tx(usb_buffer, chunklen+3);
			/* get ACK from device */
			rxlen = usb_rx(usb_buffer, 11);
			if((rxlen != 1) || (usb_buffer[0] != USB_PID_ACK)) {
				if((rxlen > 0) &&
				    (usb_buffer[0] == USB_PID_NAK))
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
			make_usb_token(USB_PID_IN, addr, usb_buffer);
			usb_tx(usb_buffer, 3);
			/* get DATAx packet */
			rxlen = usb_rx(usb_buffer, 11);
			if((rxlen < 3) || ((usb_buffer[0] != USB_PID_DATA0) &&
			    (usb_buffer[0] != USB_PID_DATA1))) {
				if((rxlen > 0) &&
				    (usb_buffer[0] == USB_PID_NAK))
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
			usb_buffer[0] = USB_PID_ACK;
			usb_tx(usb_buffer, 1);

			transferred += chunklen;
			payload += chunklen;
			if(chunklen < 8)
				break;
		}
	}

	/* send IN/OUT token in the opposite direction to end transfer */
retry:
	make_usb_token(out ? USB_PID_IN : USB_PID_OUT, addr, usb_buffer);
	usb_tx(usb_buffer, 3);
	if(out) {
		/* get DATAx packet */
		rxlen = usb_rx(usb_buffer, 11);
		if((rxlen != 3) || ((usb_buffer[0] != USB_PID_DATA0) &&
		    (usb_buffer[0] != USB_PID_DATA1))) {
			if((rxlen > 0) && (usb_buffer[0] == USB_PID_NAK))
				goto retry; /* NAK: retry */
			print_string(control_failed);
			print_string(termination);
			print_string(in_reply);
			dump_hex(usb_buffer, rxlen);
			return -1;
		}
		/* send ACK token */
		usb_buffer[0] = USB_PID_ACK;
		usb_tx(usb_buffer, 1);
	} else {
		/* send DATAx packet */
		usb_buffer[0] = get_data_token(&toggle);
		usb_buffer[1] = usb_buffer[2] = 0x00; /* CRC is 0x0000 without data */
		usb_tx(usb_buffer, 3);
		/* get ACK token from device */
		rxlen = usb_rx(usb_buffer, 11);
		if((rxlen != 1) || (usb_buffer[0] != USB_PID_ACK)) {
			if((rxlen > 0) && (usb_buffer[0] == USB_PID_NAK))
				goto retry; /* NAK: retry */
			print_string(control_failed);
			print_string(termination);
			print_string(out_reply);
			dump_hex(usb_buffer, rxlen);
			return -1;
		}
	}

	return transferred;
}

static const char datax_mismatch[] PROGMEM = "DATAx mismatch\n";
static void poll(struct port_status *p)
{
	unsigned char usb_buffer[11];
	unsigned char len;
	unsigned char m;
	char i;

	/* IN */
	make_usb_token(USB_PID_IN, ADDR_EP(1, 1), usb_buffer);
	usb_tx(usb_buffer, 3);
	/* DATAx */
	len = usb_rx(usb_buffer, 11);
	if(len < 6)
		return;
	if(usb_buffer[0] != p->expected_data) {
		if((usb_buffer[0] == USB_PID_DATA0) ||
		    (usb_buffer[0] == USB_PID_DATA1)) {
			/* ACK */
			usb_buffer[0] = USB_PID_ACK;
			usb_tx(usb_buffer, 1);
			print_string(datax_mismatch);
		}
		return; /* drop */
	}
	/* ACK */
	usb_buffer[0] = USB_PID_ACK;
	usb_tx(usb_buffer, 1);
	if(p->expected_data == USB_PID_DATA0)
		p->expected_data = USB_PID_DATA1;
	else
		p->expected_data = USB_PID_DATA0;
	/* send to host */
	if(p->keyboard) {
		if(len >= 9) {
			m = COMLOC_KEVT_PRODUCE;
			for(i=0;i<8;i++)
				COMLOC_KEVT(8*m+i) = usb_buffer[i+1];
			COMLOC_KEVT_PRODUCE = (m + 1) & 0x07;
		}
	} else {
		if(len >= 6) {
			if(len > 7)
				len = 7;
			m = COMLOC_MEVT_PRODUCE;
			for(i=0;i<len-3;i++)
				COMLOC_MEVT(4*m+i) = usb_buffer[i+1];
			while(i < 4) {
				COMLOC_MEVT(4*m+i) = 0;
				i++;
			}
			COMLOC_MEVT_PRODUCE = (m + 1) & 0x0f;
		}
	}
	/* trigger host IRQ */
	wio8(HOST_IRQ, 1);
}

static const char connect_fs[] PROGMEM = "Full speed device on port ";
static const char connect_ls[] PROGMEM = "Low speed device on port ";
static const char disconnect[] PROGMEM = "Device disconnect on port ";

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

static char validate_configuration_descriptor(unsigned char *descriptor, char len, char *keyboard)
{
	char offset;

	offset = 0;
	while(offset < len) {
		if(descriptor[offset+1] == 0x04) {
			/* got an interface descriptor */
			/* check for bInterfaceClass=3 and bInterfaceSubClass=1 (HID) */
			if((descriptor[offset+5] != 0x03) || (descriptor[offset+6] != 0x01))
				return 0;
			/* check bInterfaceProtocol */
			switch(descriptor[offset+7]) {
				case 0x01:
					*keyboard = 1;
					return 1;
				case 0x02:
					*keyboard = 0;
					return 1;
				default:
					/* unknown protocol, fail */
					return 0;
			}
		}
		offset += descriptor[offset+0];
	}
	/* no interface descriptor found, fail */
	return 0;
}

static const char retry_exceed[] PROGMEM = "Retry count exceeded, disabling device.\n";
static void check_retry(struct port_status *p)
{
	if(p->retry_count++ > 20) {
		print_string(retry_exceed);
		p->state = PORT_STATE_UNSUPPORTED;
	}
}

static const char vid[] PROGMEM = "VID: ";
static const char pid[] PROGMEM = ", PID: ";

static const char found[] PROGMEM = "Found ";
static const char unsupported_device[] PROGMEM = "unsupported device\n";
static const char mouse[] PROGMEM = "mouse\n";
static const char keyboard[] PROGMEM = "keyboard\n";

static void port_service(struct port_status *p, char name)
{
	if(p->state > PORT_STATE_BUS_RESET)
		/* Must be first, so the line is sampled when no
		 * transmission takes place.
		 */
		check_discon(p, name);
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
				p->state = PORT_STATE_WARMUP;
			}
			break;
		case PORT_STATE_WARMUP:
			if(frame_nr == ((p->unreset_frame + 250) & 0x7ff)) {
				p->retry_count = 0;
				p->state = PORT_STATE_SET_ADDRESS;
			}
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

			if(control_transfer(0x00, &packet, 1, NULL, 0) == 0) {
				p->retry_count = 0;
				p->state = PORT_STATE_GET_DEVICE_DESCRIPTOR;
			}
			check_retry(p);
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
			packet.wLength[0] = 18;
			packet.wLength[1] = 0x00;

			if(control_transfer(0x01, &packet, 0, device_descriptor, 18) >= 0) {
				p->retry_count = 0;
				print_string(vid);
				print_hex(device_descriptor[9]);
				print_hex(device_descriptor[8]);
				print_string(pid);
				print_hex(device_descriptor[11]);
				print_hex(device_descriptor[10]);
				print_char('\n');
				/* check for bDeviceClass=0 and bDeviceSubClass=0.
				 * HID devices have those.
				 */
				if((device_descriptor[4] != 0) || (device_descriptor[5] != 0)) {
					print_string(found); print_string(unsupported_device);
					p->state = PORT_STATE_UNSUPPORTED;
				} else
					p->state = PORT_STATE_GET_CONFIGURATION_DESCRIPTOR;
			}
			check_retry(p);
			break;
		}
		case PORT_STATE_GET_CONFIGURATION_DESCRIPTOR: {
			struct setup_packet packet;
			unsigned char configuration_descriptor[127];
			char len;

			packet.bmRequestType = 0x80;
			packet.bRequest = 0x06;
			packet.wValue[0] = 0x00;
			packet.wValue[1] = 0x02;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 127;
			packet.wLength[1] = 0x00;

			len = control_transfer(0x01, &packet, 0, configuration_descriptor, 127);
			if(len >= 0) {
				p->retry_count = 0;
				if(!validate_configuration_descriptor(configuration_descriptor, len, &p->keyboard)) {
					print_string(found); print_string(unsupported_device);
					p->state = PORT_STATE_UNSUPPORTED;
				} else {
					print_string(found);
					if(p->keyboard)
						print_string(keyboard);
					else
						print_string(mouse);
					p->state = PORT_STATE_SET_CONFIGURATION;
				}
			}
			check_retry(p);
			break;
		}
		case PORT_STATE_SET_CONFIGURATION: {
			struct setup_packet packet;

			packet.bmRequestType = 0x00;
			packet.bRequest = 0x09;
			packet.wValue[0] = 0x01;
			packet.wValue[1] = 0x00;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 0x00;
			packet.wLength[1] = 0x00;

			if(control_transfer(0x01, &packet, 1, NULL, 0) == 0) {
				p->retry_count = 0;
				p->expected_data = USB_PID_DATA0;
				    /* start with DATA0 */
				p->state = PORT_STATE_RUNNING;
			}
			check_retry(p);
			break;
		}
		case PORT_STATE_RUNNING:
			poll(p);
			break;
		case PORT_STATE_UNSUPPORTED:
			break;
	}
}

static const char banner[] PROGMEM = "softusb-input v"VERSION"\n";

int main()
{
	unsigned char mask;
	unsigned char i;

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
		if(port_a.state == PORT_STATE_WARMUP)
			mask |= 0x01;
		if(port_b.state == PORT_STATE_WARMUP)
			mask |= 0x02;
		wio8(SIE_SEL_TX, mask);
		wio8(SIE_GENERATE_EOP, 1);
		while(rio8(SIE_TX_BUSY));

		/*
		 * wait extra time to allow the USB cable
		 * capacitance to discharge (otherwise some disconnects
		 * aren't properly detected)
		 */
		for(i=0;i<128;i++)
			asm("nop");

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

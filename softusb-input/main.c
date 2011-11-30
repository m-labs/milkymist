/*
 * Milkymist SoC (USB firmware)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 * Copyright (C) 2011 Werner Almesberger
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

//#define	TRIGGER

#ifdef TRIGGER

#define	TRIGGER_ON()	wio8(SIE_SEL_TX, 3)
#define	TRIGGER_OFF()	wio8(SIE_SEL_TX, 2)

#else

#define	TRIGGER_ON()	((void) 0)
#define	TRIGGER_OFF()	((void) 0)

#endif /* !TRIGGER */

enum {
	USB_PID_OUT	= 0xe1,
	USB_PID_IN	= 0x69,
	USB_PID_SETUP	= 0x2d,
	USB_PID_DATA0	= 0xc3,
	USB_PID_DATA1	= 0x4b,
	USB_PID_SOF	= 0xa5,
	USB_PID_ACK	= 0xd2,
	USB_PID_NAK	= 0x5a,
};

enum {
	USB_DT_DEVICE		= 1,
	USB_DT_CONFIG		= 2,
	USB_DT_INTERFACE	= 4,
	USB_DT_ENDPOINT		= 5,
};

enum {
	USB_CLASS_AUDIO		= 1,
	USB_CLASS_HID		= 3,
};

enum {
	USB_SUBCLASS_BOOT	= 1,	/* HID */
};

enum {
	USB_SUBCLASS_MIDISTREAMING = 3,	/* AUDIO */
};

enum {
	USB_PROTO_KEYBOARD	= 1,	/* HID */
	USB_PROTO_MOUSE		= 2,
};

enum {
	PORT_STATE_DISCONNECTED = 0,
	PORT_STATE_BUS_RESET,
	PORT_STATE_RESET_WAIT,
	PORT_STATE_SET_ADDRESS,
	PORT_STATE_GET_EP0_SIZE,
	PORT_STATE_GET_DEVICE_DESCRIPTOR,
	PORT_STATE_GET_CONFIGURATION_DESCRIPTOR,
	PORT_STATE_SET_CONFIGURATION,
	PORT_STATE_RUNNING,
	PORT_STATE_UNSUPPORTED
};

#define	RESET_RECOVERY_MS	50	/* USB 2.0, 7.1.7.5: >= 10 ms */

struct ep_status {
	char ep;
	unsigned char expected_data;
};

struct port_status {
	char state;
	char full_speed;
	char retry_count;
	unsigned int unreset_frame;
	unsigned char ep0_size;
	struct ep_status keyboard;
	struct ep_status mouse;
	struct ep_status midi;
};

static struct port_status port_a;
static struct port_status port_b;

static unsigned int frame_nr;

#define	ADDR_EP(addr, ep)	((addr) | (ep) << 7)
#define	ADDR	1


static void make_usb_token(unsigned char pid, unsigned int elevenbits, unsigned char *out)
{
	out[0] = pid;
	out[1] = elevenbits & 0xff;
	out[2] = (elevenbits & 0x700) >> 8;
	out[2] |= usb_crc5(out[1], out[2]) << 3;
}

static void usb_tx_nowait(const unsigned char *buf, unsigned char len)
{
	unsigned char i;

	wio8(SIE_TX_DATA, 0x80); /* send SYNC */
	for(i=0;i<len;i++) {
		while(rio8(SIE_TX_PENDING));
		wio8(SIE_TX_DATA, buf[i]);
	}
	while(rio8(SIE_TX_PENDING));
	wio8(SIE_TX_VALID, 0);
}

static void usb_tx(const unsigned char *buf, unsigned char len)
{
	usb_tx_nowait(buf, len);
	while(rio8(SIE_TX_BUSY));
}


static inline void usb_ack(void)
{
	wio8(SIE_TX_DATA, 0x80); /* send SYNC */
	while(rio8(SIE_TX_PENDING));
	wio8(SIE_TX_DATA, USB_PID_ACK); /* send SYNC */
	while(rio8(SIE_TX_PENDING));
	wio8(SIE_TX_VALID, 0);
	while(rio8(SIE_TX_BUSY));
}

static const char ack_error[] PROGMEM = "ACK: ";
static const char timeout_error[] PROGMEM = "RX timeout error\n";
static const char bitstuff_error[] PROGMEM = "RX bitstuff error\n";

#define	WAIT_ACTIVE()						\
	do {							\
		unsigned timeout = 0x200;			\
		while(!rio8(SIE_RX_ACTIVE)) {			\
			if(!--timeout)				\
				goto timeout;			\
			if(rio8(SIE_RX_ERROR))			\
				goto error;			\
		}						\
	} while (0)

#define	WAIT_RX(end)						\
	do {							\
		unsigned timeout = 0x200;			\
		unsigned char status;				\
		while(1) {					\
			status = rio8(SIE_RX_STATUS); 		\
			if(status & RX_PENDING)			\
				break;				\
			if(!(status & RX_ACTIVE))		\
				goto end;			\
			if(!--timeout)				\
				goto timeout;			\
			if(rio8(SIE_RX_ERROR))			\
				goto error;			\
		}						\
	} while (0)


static char usb_rx_ack(void)
{
	unsigned char pid;
	unsigned char i;

	/* SYNC */
	WAIT_ACTIVE();

	/* PID */
	WAIT_RX(nothing);
	pid = rio8(SIE_RX_DATA);

	/* wait for idle, or simply time out and fall foward */
	for(i = 200; i; i--)
		if(!rio8(SIE_RX_ACTIVE))
			break;

	if(pid == USB_PID_ACK)
		return 1;
	if(pid == USB_PID_NAK)
		return 0;

	for(i = 200; i; i--)
		WAIT_RX(out);
out:
	print_string(ack_error);
	print_hex(pid);
	print_char('\n');
	return -1;

timeout:
	print_string(timeout_error);
nothing:
	return 0;
error:
	print_string(bitstuff_error);
	return 0;
}

static const char in_reply[] PROGMEM = "IN reply:\n";
static const char datax_mismatch[] PROGMEM = "DATAx mismatch\n";

static int usb_in(unsigned addr, unsigned char expected_data,
    unsigned char *buf, unsigned char maxlen)
{
	unsigned char in[3];
	unsigned char len = 1;
	unsigned char i;

	/* send IN */
	make_usb_token(USB_PID_IN, addr, in);
	usb_tx(in, 3);

	/* SYNC */
	WAIT_ACTIVE();

	/* PID */
	WAIT_RX(nothing);
	buf[0] = rio8(SIE_RX_DATA);

	if(buf[0] == expected_data)
		goto receive;
	if(buf[0] == USB_PID_DATA0 || buf[0] == USB_PID_DATA1)
		goto ignore;
	if(buf[0] == USB_PID_NAK)
		return 0;

	/* unknown packet: try to receive for debug purposes, then dump */

	while(len != maxlen) {
		WAIT_RX(fail);
		buf[len++] = rio8(SIE_RX_DATA);
	}
fail:
	print_string(in_reply);
	dump_hex(buf, len);
	return -1;

	/* bad sequence bit: wait until packet has arrived, then ack */

ignore:
	for(i = 200; i; i--)
		WAIT_RX(ignore_eop);
	goto complain; /* this doesn't stop - just quit silently */
ignore_eop:
	usb_ack();
complain:
	print_string(datax_mismatch);
	return 0;

	/* receive the rest of the (good) packet */

receive:
	while(1) {
		WAIT_RX(eop);
		if(len == maxlen)
			goto discard;
		buf[len++] = rio8(SIE_RX_DATA);
	}
eop:
	usb_ack();
	return len;

discard:
	for(i = 200; i; i--)
		WAIT_RX(nothing);
nothing:
	return 0;

timeout:
	print_string(timeout_error);
	return 0;

error:
	print_string(bitstuff_error);
	return 0;
}

static const char out_reply[] PROGMEM = "OUT/DATA reply:\n";

static char usb_out(unsigned addr, const unsigned char *buf, unsigned char len)
{
	unsigned char out[3];

	/* send OUT */
	make_usb_token(USB_PID_OUT, addr, out);
	usb_tx_nowait(out, 3);

	/* send DATAx */
	usb_tx(buf, len);

	/* receive ACK */
	return usb_rx_ack();
}

struct setup_packet {
	unsigned char bmRequestType;
	unsigned char bRequest;
	unsigned char wValue[2];
	unsigned char wIndex[2];
	unsigned char wLength[2];
} __attribute__((packed));

static inline unsigned char toggle(unsigned char old)
{
	return old ^ USB_PID_DATA0 ^ USB_PID_DATA1;
}

static const char setup_ack[] PROGMEM = "SETUP not ACKed\n";

static int control_transfer(unsigned char addr, struct setup_packet *p,
    char out, unsigned char *payload, int maxlen, unsigned char ep0_size)
{
	unsigned char setup[11];
	unsigned char usb_buffer[64+2+1]; /* DATA + max EP0 size + CRC */
	unsigned char expected_data = USB_PID_DATA1;
	char rxlen;
	char transferred;
	char chunklen;

	/* generate SETUP token */
	make_usb_token(USB_PID_SETUP, addr, setup);
	/* generate setup packet */
	usb_buffer[0] = USB_PID_DATA0;
	memcpy(&usb_buffer[1], p, 8);
	usb_crc16(&usb_buffer[1], 8, &usb_buffer[9]);

	TRIGGER_ON();

	/* send them back-to-back */
	usb_tx_nowait(setup, 3);
	usb_tx(usb_buffer, 11);

	TRIGGER_OFF();

	/* get ACK token from device */
	if(usb_rx_ack() != 1) {
		print_string(setup_ack);
		return -1;
	}

	/* data phase */
	transferred = 0;
	if(out) {
		while(1) {
			chunklen = maxlen - transferred;
			if(chunklen == 0)
				break;
			if(chunklen > ep0_size)
				chunklen = ep0_size;

			/* make DATAx packet */
			usb_buffer[0] = expected_data;
			memcpy(&usb_buffer[1], payload, chunklen);
			usb_crc16(&usb_buffer[1], chunklen, &usb_buffer[chunklen+1]);
			rxlen = usb_out(addr, usb_buffer, chunklen+3);
			if(!rxlen)
				continue;
			if(rxlen < 0)
				return -1;

			expected_data = toggle(expected_data);
			transferred += chunklen;
			payload += chunklen;
			if(chunklen < ep0_size)
				break;
		}
	} else
		while(transferred != maxlen) {
			rxlen = usb_in(addr, expected_data, usb_buffer,
			    ep0_size+3);
			if(!rxlen)
				continue;
			if(rxlen <0)
				return rxlen;

			expected_data = toggle(expected_data);
			chunklen = rxlen - 3; /* strip token and CRC */
			if(chunklen > (maxlen - transferred))
				chunklen = maxlen - transferred;
			memcpy(payload, &usb_buffer[1], chunklen);

			transferred += chunklen;
			payload += chunklen;
			if(chunklen < ep0_size)
				break;
		}

	/* send IN/OUT token in the opposite direction to end transfer */
retry:
	if(out) {
		rxlen = usb_in(addr, USB_PID_DATA1, usb_buffer, 11);
		if(!rxlen)
			goto retry;
		if(rxlen < 0)
			return -1;
	} else {
		/* make DATA1 packet */
		usb_buffer[0] = USB_PID_DATA1;
		usb_buffer[1] = usb_buffer[2] = 0x00; /* CRC is 0x0000 without data */

		rxlen = usb_out(addr, usb_buffer, 3);
		if(!rxlen)
			goto retry;
		if(!rxlen < 0)
			return -1;
	}

	return transferred;
}

static char process_keyboard(unsigned char *buf, unsigned char len)
{
	unsigned char m, i;

	if(len < 6)
		return 0;
	m = COMLOC_KEVT_PRODUCE;
	for(i = 0; i < 8; i++)
		COMLOC_KEVT(8*m+i) = buf[i];
	COMLOC_KEVT_PRODUCE = (m + 1) & 0x07;
	return 1;
}

static char process_mouse(unsigned char *buf, unsigned char len)
{
	unsigned char m, i;

	if(len < 3)
		return 0;
	/*
	 * HACK: The Rii RF mini-keyboard sends ten byte messages with
	 * a report ID and 16 bit coordinates. We're too lazy to parse
	 * report descriptors, so we just hard-code that report layout.
	 */
	if(len == 7) {
		buf[0] = buf[1];	/* buttons */
		buf[1] = buf[2];	/* X LSB */
		buf[2] = buf[4];	/* Y LSB */
	}
	if(len > 4)
		len = 4;
	m = COMLOC_MEVT_PRODUCE;
	for(i = 0; i < len; i++)
		COMLOC_MEVT(4*m+i) = buf[i];
	while(i < 4) {
		COMLOC_MEVT(4*m+i) = 0;
		i++;
	}
	COMLOC_MEVT_PRODUCE = (m + 1) & 0x0f;
	return 1;
}

static char process_midi(unsigned char *buf, unsigned char len)
{
	unsigned char end = len & ~3;
	unsigned char i, m, j;

	for(i = 0; i != end; i += 4) {
		if((buf[i] & 0xf) != 0xb) /* not a control change */
			continue;
		m = COMLOC_MIDI_PRODUCE;
		for(j = 0; j != 4; j++)
			COMLOC_MIDI(4*m+j) = buf[i+j];
		COMLOC_MIDI_PRODUCE = (m + 1) & 15;
	}
	return 0;
}

static void poll(struct ep_status *ep,
    char (*process)(unsigned char *buf, unsigned char len))
{
	unsigned char usb_buffer[1+64+2]; /* DATAx + payload + CRC */
	int len;

	len = usb_in(ADDR_EP(ADDR, ep->ep), ep->expected_data, usb_buffer, 11);
	if(len <= 0)
		return;
	ep->expected_data = toggle(ep->expected_data);

	if(len <= 3)
		return;
	if(process(usb_buffer+1, len-3))	/* send to host */
		wio8(HOST_IRQ, 1);		/* trigger host IRQ */
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
		p->keyboard.ep = p->mouse.ep = p->midi.ep = 0;
	}
}

static struct ep_status *identify_protocol(const unsigned char *itf,
    struct port_status *p)
{
	/* check for bInterfaceClass=3 and bInterfaceSubClass=1 (HID) */
	if (itf[5] == USB_CLASS_HID && itf[6] == USB_SUBCLASS_BOOT)
		switch(itf[7]) { /* check bInterfaceProtocol */
			case USB_PROTO_KEYBOARD:
				return &p->keyboard;
			case USB_PROTO_MOUSE:
				return &p->mouse;
			default:
				/* unknown protocol, fail */
				return NULL;
		}
	if (itf[5] == USB_CLASS_AUDIO && itf[6] == USB_SUBCLASS_MIDISTREAMING)
		return &p->midi;

	return NULL;
}

static const char found[] PROGMEM = "Found ";
static const char unsupported_device[] PROGMEM = "unsupported device\n";
static const char mouse[] PROGMEM = "mouse\n";
static const char keyboard[] PROGMEM = "keyboard\n";
static const char midi[] PROGMEM = "MIDI\n";

static char validate_configuration_descriptor(const unsigned char *descriptor,
    char len, struct port_status *p)
{
	struct ep_status *ep = NULL;
	char offset;

	offset = 0;
	while(offset < len) {
		if(descriptor[offset+1] == USB_DT_INTERFACE) {
			ep = identify_protocol(descriptor+offset, p);
		} else if(descriptor[offset+1] == USB_DT_ENDPOINT &&
		    (descriptor[offset+2] & 0x80) && ep) {
				ep->ep = descriptor[offset+2] & 0x7f;
				ep->expected_data = USB_PID_DATA0;
				    /* start with DATA0 */
				ep = NULL;
		}
		offset += descriptor[offset+0];
	}
	if(p->keyboard.ep) {
		print_string(found);
		print_string(keyboard);
	}
	if(p->mouse.ep) {
		print_string(found);
		print_string(mouse);
	}
	if(p->midi.ep) {
		print_string(found);
		print_string(midi);
	}
	return p->keyboard.ep || p->mouse.ep || p->midi.ep;
}

static void unsupported(struct port_status *p)
{
	print_string(found);
	print_string(unsupported_device);
	p->state = PORT_STATE_UNSUPPORTED;
}

static const char retry_exceed[] PROGMEM = "Retry count exceeded, disabling device.\n";
static void check_retry(struct port_status *p)
{
	if(p->retry_count++ > 4) {
		print_string(retry_exceed);
		p->state = PORT_STATE_UNSUPPORTED;
	}
}

static const char vid[] PROGMEM = "VID: ";
static const char pid[] PROGMEM = ", PID: ";

static int get_device_descriptor(unsigned char *buf, int size,
    unsigned char ep0_size)
{
	struct setup_packet packet;

	packet.bmRequestType = 0x80;
	packet.bRequest = 0x06;
	packet.wValue[0] = 0x00;
	packet.wValue[1] = USB_DT_DEVICE;
	packet.wIndex[0] = 0x00;
	packet.wIndex[1] = 0x00;
	packet.wLength[0] = size;
	packet.wLength[1] = 0x00;

	return control_transfer(ADDR, &packet, 0, buf, size, ep0_size);
}

static char get_ep0_size(struct port_status *p)
{
	unsigned char device_descriptor[8];
	unsigned char size;

	if(get_device_descriptor(device_descriptor, 8, 8) != 8)
		return 0;

	size = device_descriptor[7];
	if (size != 8 && size != 16 && size != 32 && size != 64)
		return 0;

	p->ep0_size = size;

	return 1;
}

static void port_service(struct port_status *p, char name)
{
	if(p->state > PORT_STATE_BUS_RESET)
		/* Must be first, so the line is sampled when no
		 * transmission takes place.
		 */
		check_discon(p, name);
	if(p->full_speed)
		wio8(SIE_TX_LOW_SPEED, 0);
	else
		wio8(SIE_TX_LOW_SPEED, 1);
	switch(p->state) {
		case PORT_STATE_DISCONNECTED: {
			char linestat;
			if(name == 'A')
				linestat = rio8(SIE_LINE_STATUS_A);
			else
				linestat = rio8(SIE_LINE_STATUS_B);
			if(linestat == 0x01) {
				print_string(connect_fs); print_char(name); print_char('\n');
				p->full_speed = 1;
			}
			if(linestat == 0x02) {
				print_string(connect_ls); print_char(name); print_char('\n');
				p->full_speed = 0;
			}
			if((linestat == 0x01)||(linestat == 0x02)) {
				if(name == 'A')
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) | 0x01);
				else
					wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) | 0x02);
				p->state = PORT_STATE_BUS_RESET;
				p->unreset_frame = (frame_nr + 350) & 0x7ff;
			}
			p->ep0_size = 8;
			break;
		}
		case PORT_STATE_BUS_RESET:
			if(frame_nr != p->unreset_frame)
				break;
			if(name == 'A')
				wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x02);
			else
				wio8(SIE_TX_BUSRESET, rio8(SIE_TX_BUSRESET) & 0x01);
			p->state = PORT_STATE_RESET_WAIT;
			p->unreset_frame =
			    (frame_nr + RESET_RECOVERY_MS) & 0x7ff;
			break;
		case PORT_STATE_RESET_WAIT:
			if(frame_nr != p->unreset_frame)
				break;
			p->state = PORT_STATE_SET_ADDRESS;
			p->retry_count = 0;
			break;
		case PORT_STATE_SET_ADDRESS: {
			struct setup_packet packet;

			packet.bmRequestType = 0x00;
			packet.bRequest = 0x05;
			packet.wValue[0] = ADDR;
			packet.wValue[1] = 0x00;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 0x00;
			packet.wLength[1] = 0x00;

			if(control_transfer(0x00, &packet, 1, NULL, 0,
			    p->ep0_size) == 0) {
				p->retry_count = 0;
				p->state = PORT_STATE_GET_EP0_SIZE;
			}
			check_retry(p);
			break;
		}
		case PORT_STATE_GET_EP0_SIZE:
			if(get_ep0_size(p)) {
				p->state = PORT_STATE_GET_DEVICE_DESCRIPTOR;
				p->retry_count = 0;
			}
			check_retry(p);
			break;
		case PORT_STATE_GET_DEVICE_DESCRIPTOR: {
			unsigned char device_descriptor[18];

			if(get_device_descriptor(device_descriptor, 18,
			    p->ep0_size) >= 0) {
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
				if((device_descriptor[4] != 0) || (device_descriptor[5] != 0))
					unsupported(p);
				else
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
			packet.wValue[1] = USB_DT_CONFIG;
			packet.wIndex[0] = 0x00;
			packet.wIndex[1] = 0x00;
			packet.wLength[0] = 127;
			packet.wLength[1] = 0x00;

			len = control_transfer(ADDR, &packet, 0,
			    configuration_descriptor, 127, p->ep0_size);
			if(len >= 0) {
				p->retry_count = 0;
				if(!validate_configuration_descriptor(
				    configuration_descriptor, len, p))
					unsupported(p);
				else
					p->state = PORT_STATE_SET_CONFIGURATION;
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

			if(control_transfer(ADDR, &packet, 1, NULL, 0,
			    p->ep0_size) == 0) {
				p->retry_count = 0;
				p->state = PORT_STATE_RUNNING;
			}
			check_retry(p);
			break;
		}
		case PORT_STATE_RUNNING:
			if(p->keyboard.ep)
				poll(&p->keyboard, process_keyboard);
			if(p->mouse.ep)
				poll(&p->mouse, process_mouse);
			if(p->midi.ep)
				poll(&p->midi, process_midi);
			break;
		case PORT_STATE_UNSUPPORTED:
			break;
	}
	while(rio8(SIE_TX_BUSY));
}

static const char banner[] PROGMEM = "softusb-input v"VERSION"\n";

static void sof()
{
	unsigned char mask;
	unsigned char usb_buffer[3];

	mask = 0;
#ifndef TRIGGER
	if(port_a.full_speed && (port_a.state > PORT_STATE_BUS_RESET))
		mask |= 0x01;
#endif
	if(port_b.full_speed && (port_b.state > PORT_STATE_BUS_RESET))
		mask |= 0x02;
	if(mask != 0) {
		wio8(SIE_TX_LOW_SPEED, 0);
		wio8(SIE_SEL_TX, mask);
		make_usb_token(USB_PID_SOF, frame_nr, usb_buffer);
		usb_tx(usb_buffer, 3);
	}
}

static void keepalive()
{
	unsigned char mask;

	mask = 0;
#ifndef TRIGGER
	if(!port_a.full_speed && (port_a.state == PORT_STATE_RESET_WAIT))
		mask |= 0x01;
#endif
	if(!port_b.full_speed && (port_b.state == PORT_STATE_RESET_WAIT))
		mask |= 0x02;
	if(mask != 0) {
		wio8(SIE_TX_LOW_SPEED, 1);
		wio8(SIE_SEL_TX, mask);
		wio8(SIE_GENERATE_EOP, 1);
		while(rio8(SIE_TX_BUSY));
	}
}

static void set_rx_speed()
{
	unsigned char mask;

	mask = 0;
	if(!port_a.full_speed) mask |= 0x01;
	if(!port_b.full_speed) mask |= 0x02;
	wio8(SIE_LOW_SPEED, mask);
}

int main()
{
	unsigned char i;

	print_string(banner);

	wio8(TIMER0, 0);
	while(1) {
		/* wait for the next frame */
		while((rio8(TIMER1) < 0xbb) || (rio8(TIMER0) < 0x70));
		wio8(TIMER0, 0);

		sof();
		keepalive();

		/*
		 * wait extra time to allow the USB cable
		 * capacitance to discharge (otherwise some disconnects
		 * aren't properly detected)
		 */
		for(i=0;i<128;i++)
			asm("nop");

#ifndef TRIGGER
		wio8(SIE_SEL_RX, 0);
		wio8(SIE_SEL_TX, 0x01);
		port_service(&port_a, 'A');
#endif

		wio8(SIE_SEL_RX, 1);
		wio8(SIE_SEL_TX, 0x02);
		port_service(&port_b, 'B');

		/* set RX speed for new detected devices */
		set_rx_speed();

		frame_nr = (frame_nr + 1) & 0x7ff;
	}
	return 0;
}

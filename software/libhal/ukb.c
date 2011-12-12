/*
 * Milkymist SoC (Software)
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
#include <hal/usb.h>
#include <hal/ukb.h>

#define UKB_RINGBUFFER_SIZE_RX 32
#define UKB_RINGBUFFER_MASK_RX (UKB_RINGBUFFER_SIZE_RX-1)

static char rx_buf[UKB_RINGBUFFER_SIZE_RX];
static volatile unsigned int rx_produce;
static volatile unsigned int rx_consume;

static char ukb_readchar(void)
{
	char c;

	while(rx_consume == rx_produce);
	c = rx_buf[rx_consume];
	rx_consume = (rx_consume + 1) & UKB_RINGBUFFER_MASK_RX;
	return c;
}

static int ukb_readchar_nonblock(void)
{
	return (rx_consume != rx_produce);
}

static char get_base_key(unsigned char key)
{
	switch(key) {
		case 0x14: return 'q';
		case 0x1a: return 'w';
		case 0x08: return 'e';
		case 0x15: return 'r';
		case 0x17: return 't';
		case 0x1c: return 'z';
		case 0x18: return 'u';
		case 0x0c: return 'i';
		case 0x12: return 'o';
		case 0x13: return 'p';
		case 0x04: return 'a';
		case 0x16: return 's';
		case 0x07: return 'd';
		case 0x09: return 'f';
		case 0x0a: return 'g';
		case 0x0b: return 'h';
		case 0x0d: return 'j';
		case 0x0e: return 'k';
		case 0x0f: return 'l';
		case 0x1d: return 'y';
		case 0x1b: return 'x';
		case 0x06: return 'c';
		case 0x19: return 'v';
		case 0x05: return 'b';
		case 0x11: return 'n';
		case 0x10: return 'm';
		case 0x2c: return ' ';
		case 0x62: return '0';
		case 0x59: return '1';
		case 0x5a: return '2';
		case 0x5b: return '3';
		case 0x5c: return '4';
		case 0x5d: return '5';
		case 0x5e: return '6';
		case 0x5f: return '7';
		case 0x60: return '8';
		case 0x61: return '9';
		case 0x54: return '/';
		case 0x55: return '*';
		case 0x56: return '-';
		case 0x57: return '+';
		case 0x1e: return '!';
		case 0x1f: return '"';
		case 0x21: return '$';
		case 0x22: return '%';
		case 0x23: return '&';
		case 0x24: return '/';
		case 0x25: return '(';
		case 0x26: return ')';
		case 0x27: return '=';
		case 0x2d: return '?';
		case 0x2e: return '\'';
		case 0x38: return '-';
		case 0x2a: return 0x08;
		case 0x37:
		case 0x63: return '.';
		case 0x58:
		case 0x28: return '\n';
		case 0x29: return '\e';
		case 0x41: return 0x07;
		default: return 0x00;
	}
}

static char translate_key(unsigned char modifiers, unsigned char key)
{
	unsigned char r;
	r = get_base_key(key);
	if((modifiers & 0x02)||(modifiers & 0x20)) {
		if((r >= 'a') && (r <= 'z'))
			r -= 'a' - 'A';
		if(r == '-')
			r = '_';
	}
	return r;
}

static void keyboard_cb(unsigned char modifiers, unsigned char key)
{
	char c;

	c = translate_key(modifiers, key);
	if(c != 0x00) {
		rx_buf[rx_produce] = c;
		rx_produce = (rx_produce + 1) & UKB_RINGBUFFER_MASK_RX;
	}
}

void ukb_init(void)
{
	rx_produce = 0;
	rx_consume = 0;
	console_set_read_hook(ukb_readchar, ukb_readchar_nonblock);
	usb_set_keyboard_cb(keyboard_cb);
	printf("UKB: USB keyboard connected to console\n");
}

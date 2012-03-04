/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2012 Sebastien Bourdeauducq
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

#include <hw/softusb.h>
#include <hw/sysctl.h>
#include <hw/capabilities.h>
#include <hw/interrupts.h>
#include <uart.h>
#include <irq.h>
#include <stdio.h>

#include <hal/usb.h>
#include "input-comloc.h"

static const unsigned char input_firmware[] = {
#include <softusb-input/softusb-input.h>
};

static int debug_enable;
static char debug_buffer[256];
static int debug_len;
static int debug_consume;

static mouse_event_cb mouse_cb;
static int mouse_consume;

unsigned char previous_keys[5];
static keyboard_event_cb keyboard_cb;
static int keyboard_consume;

void usb_init(void)
{
	int nwords;
	int i;
	unsigned int *usb_dmem = (unsigned int *)SOFTUSB_DMEM_BASE;
	unsigned int *usb_pmem = (unsigned int *)SOFTUSB_PMEM_BASE;
	unsigned int mask;

	if(!(CSR_CAPABILITIES & CAP_USB)) {
		printf("USB: not supported by SoC, giving up.\n");
		return;
	}

	printf("USB: loading Navre firmware\n");
	CSR_SOFTUSB_CONTROL = SOFTUSB_CONTROL_RESET;
	for(i=0;i<SOFTUSB_DMEM_SIZE/4;i++)
		usb_dmem[i] = 0;
	for(i=0;i<SOFTUSB_PMEM_SIZE/2;i++)
		usb_pmem[i] = 0;
	nwords = (sizeof(input_firmware)+1)/2;
	for(i=0;i<nwords;i++)
		usb_pmem[i] = ((unsigned int)(input_firmware[2*i]))
			|((unsigned int)(input_firmware[2*i+1]) << 8);
	printf("USB: starting host controller\n");
	CSR_SOFTUSB_CONTROL = 0;

	debug_enable = 1;
	debug_len = 0;
	debug_consume = 0;
	mouse_consume = 0;
	mouse_cb = NULL;
	keyboard_consume = 0;
	keyboard_cb = NULL;

	mask = irq_getmask();
	mask |= IRQ_USB;
	irq_setmask(mask);
}

void usb_debug_enable(int en)
{
	debug_enable = en;
}

static void flush_debug_buffer(void)
{
	char debug_buffer_fmt[266];
	int i;

	if(debug_enable) {
		debug_buffer[debug_len] = 0;
		/* send USB debug messages to UART only */
		sprintf(debug_buffer_fmt, "USB: HC: %s\n", debug_buffer);
		i = 0;
		while(debug_buffer_fmt[i])
			uart_write(debug_buffer_fmt[i++]);
	}
	debug_len = 0;
}

void usb_set_mouse_cb(mouse_event_cb cb)
{
	mouse_cb = cb;
}

void usb_set_keyboard_cb(keyboard_event_cb cb)
{
	keyboard_cb = cb;
}

void usb_isr(void)
{
	char c;

	irq_ack(IRQ_USB);

	while(debug_consume != COMLOC_DEBUG_PRODUCE) {
		c = COMLOC_DEBUG(debug_consume);
		if(c == '\n')
			flush_debug_buffer();
		else {
			debug_buffer[debug_len] = c;
			debug_len++;
			if(debug_len == (sizeof(debug_buffer)-1))
				flush_debug_buffer();
		}
		debug_consume = (debug_consume + 1) & 0xff;
	}

	while(mouse_consume != COMLOC_MEVT_PRODUCE) {
		if(mouse_cb != NULL)
			mouse_cb(
				COMLOC_MEVT(4*mouse_consume+0),
				(char)COMLOC_MEVT(4*mouse_consume+1),
				(char)COMLOC_MEVT(4*mouse_consume+2),
				COMLOC_MEVT(4*mouse_consume+3));
		mouse_consume = (mouse_consume + 1) & 0x0f;
	}

	while(keyboard_consume != COMLOC_KEVT_PRODUCE) {
		if(keyboard_cb != NULL) {
			if(COMLOC_KEVT(8*keyboard_consume+7) == 0x00) {
				unsigned char modifiers;
				unsigned char current_keys[5];
				int i, j;
				int already_pressed;

				/* no error */
				modifiers = COMLOC_KEVT(8*keyboard_consume+0);
				for(i=0;i<5;i++)
					current_keys[i] = COMLOC_KEVT(8*keyboard_consume+2+i);
				for(i=0;i<5;i++) {
					if(current_keys[i] != 0x00) {
						already_pressed = 0;
						for(j=0;j<5;j++)
							if(previous_keys[j] == current_keys[i]) {
								already_pressed = 1;
								break;
							}
						if(!already_pressed)
							keyboard_cb(modifiers, current_keys[i]);
					}
				}
				for(i=0;i<5;i++)
					previous_keys[i] = current_keys[i];
			}

		}
		keyboard_consume = (keyboard_consume + 1) & 0x07;
	}
}

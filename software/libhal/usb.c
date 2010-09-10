/*
 * Milkymist VJ SoC (Software)
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

#include <hw/softusb.h>
#include <hw/sysctl.h>
#include <hw/capabilities.h>
#include <stdio.h>

#include <hal/usb.h>
#include "input-comloc.h"

static const unsigned char input_firmware[] = {
#include "softusb-input.h"
};

static char debug_buffer[256];
static int debug_len;
static int debug_consume;

static mouse_event_cb mouse_cb;
static int mouse_consume;

void usb_init()
{
	int nwords;
	int i;
	unsigned int *usb_dmem = (unsigned int *)SOFTUSB_DMEM_BASE;
	unsigned int *usb_pmem = (unsigned int *)SOFTUSB_PMEM_BASE;

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

	debug_len = 0;
	debug_consume = 0;
	mouse_consume = 0;
	mouse_cb = NULL;
}

static void flush_debug_buffer()
{
	debug_buffer[debug_len] = 0;
	printf("USB: HC: %s\n", debug_buffer);
	debug_len = 0;
}

void usb_service()
{
	char c;

	if(!(CSR_CAPABILITIES & CAP_USB))
		return;

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
}

void usb_set_mouse_cb(mouse_event_cb cb)
{
	mouse_cb = cb;
}

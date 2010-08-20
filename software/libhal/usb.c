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

static const unsigned char ohci_firmware[] = {
#include "softusb-ohci.h"
};

static char hc_debug_buffer[256];
static int hc_debug_buffer_len;

static mouse_event_cb mouse_cb;
static int hc_msg_consume;

void usb_init()
{
	int nwords;
	int i;
	unsigned int *usb_dmem = (unsigned int *)SOFTUSB_DMEM_BASE;
	unsigned int *usb_pmem = (unsigned int *)SOFTUSB_PMEM_BASE;

	if(!(CSR_CAPABILITIES & CAP_USB)) {
		printf("USB: not supported, skipping initialization\n");
		return;
	}

	printf("USB: loading Navre firmware\n");
	CSR_SOFTUSB_CONTROL = SOFTUSB_CONTROL_RESET;
	for(i=0;i<SOFTUSB_DMEM_SIZE/4;i++)
		usb_dmem[i] = 0;
	for(i=0;i<SOFTUSB_PMEM_SIZE/2;i++)
		usb_pmem[i] = 0;
	nwords = (sizeof(ohci_firmware)+1)/2;
	for(i=0;i<nwords;i++)
		usb_pmem[i] = ((unsigned int)(ohci_firmware[2*i]))
			|((unsigned int)(ohci_firmware[2*i+1]) << 8);
	printf("USB: starting host controller\n");
	CSR_SOFTUSB_CONTROL = 0;

	hc_debug_buffer_len = 0;
	hc_msg_consume = 0;
	mouse_cb = NULL;
}

static void flush_debug_buffer()
{
	hc_debug_buffer[hc_debug_buffer_len] = 0;
	printf("USB: HC: %s\n", hc_debug_buffer);
	hc_debug_buffer_len = 0;
}

#define HCREG_DEBUG	*((volatile unsigned char *)(SOFTUSB_DMEM_BASE+0x1000))
#define HCREG_NMSG	*((volatile unsigned char *)(SOFTUSB_DMEM_BASE+0x1001))

void usb_service()
{
	char c;
	int m;

	if(!(CSR_CAPABILITIES & CAP_USB))
		return;

	c = HCREG_DEBUG;
	if(c != 0x00) {
		if(c == '\n')
			flush_debug_buffer();
		else {
			hc_debug_buffer[hc_debug_buffer_len] = c;
			hc_debug_buffer_len++;
			if(hc_debug_buffer_len == (sizeof(hc_debug_buffer)-1))
				flush_debug_buffer();
		}
		HCREG_DEBUG = 0;
	}

	m = HCREG_NMSG;
	while(hc_msg_consume != m) {
		if(mouse_cb != NULL)
			mouse_cb(
				*((unsigned char *)(SOFTUSB_DMEM_BASE+0x1002+4*hc_msg_consume)),
				*((char *)(SOFTUSB_DMEM_BASE+0x1003+4*hc_msg_consume)),
				*((char *)(SOFTUSB_DMEM_BASE+0x1004+4*hc_msg_consume)),
				*((unsigned char *)(SOFTUSB_DMEM_BASE+0x1005+4*hc_msg_consume)));
		hc_msg_consume = (hc_msg_consume + 1) & 0x0f;
	}
}

void usb_set_mouse_cb(mouse_event_cb cb)
{
	mouse_cb = cb;
}

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
#include <stdio.h>

static const unsigned char ohci_firmware[] = {
#include "softusb-ohci.h"
};

static char hc_debug_buffer[256];
static int hc_debug_buffer_len;

void usb_init()
{
	int nwords;
	int i;
	unsigned int *usb_dmem = (unsigned int *)SOFTUSB_DMEM_BASE;
	unsigned int *usb_pmem = (unsigned int *)SOFTUSB_PMEM_BASE;

	printf("USB: loading OHCI firmware\n");
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
}

static void flush_debug_buffer()
{
	hc_debug_buffer[hc_debug_buffer_len] = 0;
	printf("USB: HC: %s\n", hc_debug_buffer);
	hc_debug_buffer_len = 0;
}

void usb_service()
{
	/*
	char c;

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
	*/
}

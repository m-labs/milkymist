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

void usb_init()
{
	int nwords;
	int i;
	unsigned int *usb_ram = (unsigned int *)SOFTUSB_RAM_BASE;

	printf("USB: loading OHCI firmware\n");
	CSR_SOFTUSB_CONTROL = SOFTUSB_CONTROL_RESET;
	nwords = (sizeof(ohci_firmware)+3)/4;
	for(i=0;i<nwords;i++)
		usb_ram[i] = ((unsigned int)(ohci_firmware[4*i]))
			|((unsigned int)(ohci_firmware[4*i+1]) << 8)
			|((unsigned int)(ohci_firmware[4*i+2]) << 16)
			|((unsigned int)(ohci_firmware[4*i+3]) << 24);
	printf("USB: starting host controller\n");
	CSR_SOFTUSB_CONTROL = 0;
}

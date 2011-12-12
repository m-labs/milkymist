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
#include <hw/dmx.h>

#include <hal/dmx.h>

void dmx_init(void)
{
	int i;

	for(i=0;i<512;i++)
		CSR_DMX_TX(i) = 0;
	CSR_DMX_THRU = 0;
	printf("DMX: initialized\n");
}

void dmx_thru_mode(int thru)
{
	if(thru)
		CSR_DMX_THRU = 1;
	else
		CSR_DMX_THRU = 0;
}

void dmx_set(int channel, int value)
{
	if(value < 0)
		value = 0;
	if(value > 255)
		value = 255;
	CSR_DMX_TX(channel) = value;
}

int dmx_get(int channel)
{
	return CSR_DMX_RX(channel);
}

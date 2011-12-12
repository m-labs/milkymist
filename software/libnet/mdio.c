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

#include <hw/minimac.h>
#include <net/mdio.h>

static void delay(void)
{
	volatile int i;
	for(i=0;i<1000;i++);
}

static void raw_write(unsigned int word, int bitcount)
{
	word <<= 32 - bitcount;
	while(bitcount > 0) {
		if(word & 0x80000000) {
			CSR_MINIMAC_MDIO = MINIMAC_MDIO_CLK|MINIMAC_MDIO_DO|MINIMAC_MDIO_OE;
			delay();
			CSR_MINIMAC_MDIO = MINIMAC_MDIO_DO|MINIMAC_MDIO_OE;
			delay();
		} else {
			CSR_MINIMAC_MDIO = MINIMAC_MDIO_CLK|MINIMAC_MDIO_OE;
			delay();
			CSR_MINIMAC_MDIO = MINIMAC_MDIO_OE;
			delay();
		}
		word <<= 1;
		bitcount--;
	}
}

static unsigned int raw_read(void)
{
	unsigned int word;
	unsigned int i;

	word = 0;
	for(i=0;i<16;i++) {
		word <<= 1;
		CSR_MINIMAC_MDIO = MINIMAC_MDIO_CLK;
		delay();
		CSR_MINIMAC_MDIO = 0;
		delay();
		if(CSR_MINIMAC_MDIO & MINIMAC_MDIO_DI)
			word |= 1;
	}
	return word;
}

static void raw_turnaround(void)
{
	CSR_MINIMAC_MDIO = MINIMAC_MDIO_CLK;
	delay();
	CSR_MINIMAC_MDIO = 0;
	delay();
	CSR_MINIMAC_MDIO = MINIMAC_MDIO_CLK;
	delay();
	CSR_MINIMAC_MDIO = 0;
	delay();
}

void mdio_write(int phyadr, int reg, int val)
{
	CSR_MINIMAC_MDIO = MINIMAC_MDIO_OE;
	raw_write(0xffffffff, 32); /* < sync */
	raw_write(0x05, 4); /* < start + write */
	raw_write(phyadr, 5);
	raw_write(reg, 5);
	raw_write(0x02, 2); /* < turnaround */
	raw_write(val, 16);
	raw_turnaround();
}

int mdio_read(int phyadr, int reg)
{
	int r;
	
	CSR_MINIMAC_MDIO = MINIMAC_MDIO_OE;
	raw_write(0xffffffff, 32); /* < sync */
	raw_write(0x06, 4); /* < start + read */
	raw_write(phyadr, 5);
	raw_write(reg, 5);
	raw_turnaround();
	r = raw_read();
	raw_turnaround();
	
	return r;
}


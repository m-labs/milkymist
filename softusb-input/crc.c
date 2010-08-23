/*
 * Milkymist VJ SoC (USB firmware)
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

unsigned char usb_crc5(unsigned char b1, unsigned char b2)
{
	unsigned char crc;
	unsigned char nextb;
	unsigned char so;
	unsigned char i;

	crc = 0x1f;

	for(i=0;i<8;i++) {
		nextb = b1 & 0x01;
		b1 >>= 1;
		so = crc & 0x01;
		crc >>= 1;
		if(nextb != so)
			crc ^= 0x14;
	}
	for(i=0;i<3;i++) {
		nextb = b2 & 0x01;
		b2 >>= 1;
		so = crc & 0x01;
		crc >>= 1;
		if(nextb != so)
			crc ^= 0x14;
	}

	crc &= 0x1f;
	crc ^= 0x1f;

	return crc;
}

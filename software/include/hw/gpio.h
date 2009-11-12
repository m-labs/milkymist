/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

#ifndef __HW_GPIO_H
#define __HW_GPIO_H

/* Inputs */
#define GPIO_PBN	(0x00000001)
#define GPIO_PBW	(0x00000002)
#define GPIO_PBS	(0x00000004)
#define GPIO_PBE	(0x00000008)
#define GPIO_PBC	(0x00000010)

#define GPIO_DIP1	(0x00000020)
#define GPIO_DIP2	(0x00000040)
#define GPIO_DIP3	(0x00000080)
#define GPIO_DIP4	(0x00000100)
#define GPIO_DIP5	(0x00000200)
#define GPIO_DIP6	(0x00000400)
#define GPIO_DIP7	(0x00000800)
#define GPIO_DIP8	(0x00001000)

/* Outputs */
#define GPIO_LED2	(0x00000001)
#define GPIO_LED3	(0x00000002)

#define GPIO_LEDN	(0x00000004)
#define GPIO_LEDW	(0x00000008)
#define GPIO_LEDS	(0x00000010)
#define GPIO_LEDE	(0x00000020)
#define GPIO_LEDC	(0x00000040)

#define GPIO_HDLCDE	(0x00000080)
#define GPIO_HDLCDRS	(0x00000100)
#define GPIO_HDLCDRW	(0x00000200)

#define GPIO_HDLCDD_SHIFT	(10)

#define GPIO_HDLCDD4	(0x00000400)
#define GPIO_HDLCDD5	(0x00000800)
#define GPIO_HDLCDD6	(0x00001000)
#define GPIO_HDLCDD7	(0x00002000)

#endif /* __HW_GPIO_H */

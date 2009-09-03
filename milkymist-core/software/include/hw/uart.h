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

#ifndef __HW_UART_H
#define __HW_UART_H

#include <hw/common.h>

#define CSR_UART_UCR 		MMPTR(0x80000000)
#define CSR_UART_RXTX 		MMPTR(0x80000004)
#define CSR_UART_DIVISOR	MMPTR(0x80000008)

#define UART_RXAVAIL		(0x01)
#define UART_RXERROR		(0x02)
#define UART_RXACK		(0x04)

#define UART_TXBUSY		(0x08)
#define UART_TXDONE		(0x10)
#define UART_TXACK		(0x20)

#endif /* __HW_UART_H */

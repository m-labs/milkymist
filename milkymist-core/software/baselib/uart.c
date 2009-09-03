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

#include <hw/uart.h>
#include <uart.h>

void writechar(char c)
{
	while(CSR_UART_UCR & UART_TXBUSY);
	CSR_UART_RXTX = c;
}

char readchar()
{
	char c;

	while(!(CSR_UART_UCR & UART_RXAVAIL));
	c = CSR_UART_RXTX;
	CSR_UART_UCR = UART_RXACK;
	return c;
}

int readchar_nonblock()
{
	if(CSR_UART_UCR & UART_RXAVAIL)
		return 1;
	else
		return 0;
}

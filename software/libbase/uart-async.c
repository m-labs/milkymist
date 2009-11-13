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

#include <uart.h>
#include <irq.h>
#include <hw/uart.h>
#include <hw/interrupts.h>

/*
 * Buffer sizes must be a power of 2 so that modulos can be computed
 * with logical AND.
 * RX functions are written in such a way that they do not require locking.
 * TX functions already implement locking.
 */

#define UART_RINGBUFFER_SIZE_RX 4096
#define UART_RINGBUFFER_MASK_RX (UART_RINGBUFFER_SIZE_RX-1)

static char rx_buf[UART_RINGBUFFER_SIZE_RX];
static volatile unsigned int rx_produce;
static volatile unsigned int rx_consume;

void uart_async_isr_rx()
{
	irq_ack(IRQ_UARTRX);
	rx_buf[rx_produce] = CSR_UART_RXTX;
	rx_produce = (rx_produce + 1) & UART_RINGBUFFER_MASK_RX;
}

char readchar()
{
	char c;
	
	while(rx_consume == rx_produce);
	c = rx_buf[rx_consume];
	rx_consume = (rx_consume + 1) & UART_RINGBUFFER_MASK_RX;
	return c;
}

int readchar_nonblock()
{
	return (rx_consume != rx_produce);
}

#define UART_RINGBUFFER_SIZE_TX 131072
#define UART_RINGBUFFER_MASK_TX (UART_RINGBUFFER_SIZE_TX-1)

static char tx_buf[UART_RINGBUFFER_SIZE_TX];
static unsigned int tx_produce;
static unsigned int tx_consume;
static volatile int tx_cts;

static int force_sync;

void uart_async_isr_tx()
{
	irq_ack(IRQ_UARTTX);
	if(tx_produce != tx_consume) {
		CSR_UART_RXTX = tx_buf[tx_consume];
		tx_consume = (tx_consume + 1) & UART_RINGBUFFER_MASK_TX;
	} else
		tx_cts = 1;
}

void writechar(char c)
{
	unsigned int oldmask = 0;
	
	/* Synchronization required because of CTS */
	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_UARTTX));
	if(force_sync) {
		CSR_UART_RXTX = c;
		while(!(irq_pending() & IRQ_UARTTX));
		irq_ack(IRQ_UARTTX);
	} else {
		if(tx_cts) {
			tx_cts = 0;
			CSR_UART_RXTX = c;
		} else {
			tx_buf[tx_produce] = c;
			tx_produce = (tx_produce + 1) & UART_RINGBUFFER_MASK_TX;
		}
	}
	irq_setmask(oldmask);
}

void uart_async_init()
{
	unsigned int mask;
	
	rx_produce = 0;
	rx_consume = 0;
	tx_produce = 0;
	tx_consume = 0;
	tx_cts = 1;

	irq_ack(IRQ_UARTRX|IRQ_UARTTX);

	mask = irq_getmask();
	mask |= IRQ_UARTRX|IRQ_UARTTX;
	irq_setmask(mask);
}

void uart_force_sync(int f)
{
	if(f) while(!tx_cts);
	force_sync = f;
}

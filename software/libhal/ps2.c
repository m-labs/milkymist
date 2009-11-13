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

#include <stdio.h>
#include <irq.h>
#include <hw/interrupts.h>
#include <hw/ps2.h>

#include <hal/ps2.h>

#define QSIZE 64 /* < must be a power of 2 */
#define QMASK (QSIZE-1)

static unsigned char queue[QSIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;

void ps2_init()
{
	unsigned int mask;

	produce = 0;
	consume = 0;
	level = 0;

	irq_ack(IRQ_PS2);

	mask = irq_getmask();
	mask |= IRQ_PS2;
	irq_setmask(mask);

	printf("PS2: ready\n");
}

void ps2_isr()
{
	irq_ack(IRQ_PS2);
	if(level >= QSIZE) {
		printf("PS2: queue overflow\n");
		return;
	}

	queue[produce] = CSR_PS2_RX;
	produce = (produce + 1) & QMASK;
	level++;
}

int ps2_read()
{
	unsigned int oldmask;
	int r;

	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_PS2));

	if(level == 0) {
		irq_setmask(oldmask);
		return -1;
	}

	r = queue[consume];
	consume = (consume + 1) & QMASK;
	level--;

	irq_setmask(oldmask);

	return r;
}

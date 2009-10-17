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

/* Asynchronous slow outputs - Using HW timer 1 */

#include <stdio.h>
#include <irq.h>
#include <hw/interrupts.h>
#include <hw/sysctl.h>

#include <hal/slowout.h>

struct slowout_operation {
	unsigned int duration;
	unsigned int mask;
};

#define OPQ_SIZE 1024 /* < must be a power of 2 */
#define OPQ_MASK (OPQ_SIZE-1)

static struct slowout_operation queue[OPQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

void slowout_init()
{
	unsigned int mask;

	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	CSR_TIMER1_CONTROL = 0; /* Disable timer + ack any pending IRQ */

	mask = irq_getmask();
	mask |= IRQ_TIMER1;
	irq_setmask(mask);

	printf("SLO: slow outputs initialized\n");
}

static void slowout_start(struct slowout_operation *op)
{
	CSR_GPIO_OUT = op->mask;
	CSR_TIMER1_COUNTER = 0;
	CSR_TIMER1_COMPARE = op->duration;
	CSR_TIMER1_CONTROL = TIMER_ENABLE;
}

void slowout_isr()
{
	consume = (consume + 1) & OPQ_MASK;
	level--;
	if(level > 0)
		slowout_start(&queue[consume]);
	else {
		CSR_TIMER1_CONTROL = 0; /* Ack IRQ */
		cts = 1;
	}
}

int slowout_queue(unsigned int duration, unsigned int mask)
{
	unsigned int oldmask;

	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_TIMER1));

	if(level >= OPQ_SIZE) {
		irq_setmask(oldmask);
		printf("SLO: opq overflow\n");
		return 0;
	}

	queue[produce].duration = duration;
	queue[produce].mask = mask;
	if(cts) {
		cts = 0;
		slowout_start(&queue[produce]);
	}
	produce = (produce + 1) & OPQ_MASK;
	level++;

	irq_setmask(oldmask);

	return 1;
}


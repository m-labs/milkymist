/*
 * Milkymist SoC (Software)
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

/* SYSTEM CLOCK - Using HW timer 0 */

#include <stdio.h>
#include <irq.h>
#include <board.h>
#include <hw/sysctl.h>
#include <hw/interrupts.h>

#include <hal/time.h>

static int sec;

void time_init(void)
{
	unsigned int mask;
	
	CSR_TIMER0_COUNTER = 0;
	CSR_TIMER0_COMPARE = CSR_FREQUENCY;
	CSR_TIMER0_CONTROL = TIMER_AUTORESTART|TIMER_ENABLE;
	irq_ack(IRQ_TIMER0);

	mask = irq_getmask();
	mask |= IRQ_TIMER0;
	irq_setmask(mask);

	printf("TIM: system timer started\n");
}

void time_isr(void)
{
	irq_ack(IRQ_TIMER0);
	sec++;
	time_tick();
}

void time_get(struct timestamp *ts)
{
	unsigned int oldmask = 0;
	unsigned int pending, counter, sec2;

	oldmask = irq_getmask();
	irq_setmask(oldmask & ~(IRQ_TIMER0));
	counter = CSR_TIMER0_COUNTER;
	pending = irq_pending() & IRQ_TIMER0;
	sec2 = sec;
	irq_setmask(oldmask);

	ts->sec = sec2;
	ts->usec = counter/(CSR_FREQUENCY/1000000);
	
	/*
	 * If the counter is less than half a second, we consider that
	 * the overflow was already present when we read the counter
	 * value.
	 */
	if(pending) {
		if(counter < (CSR_FREQUENCY/2))
			ts->sec++;
	}
}

void time_add(struct timestamp *dest, struct timestamp *delta)
{
	dest->sec += delta->sec;
	dest->usec += delta->usec;
	if(dest->usec >= 1000000) {
		dest->sec++;
		dest->usec -= 1000000;
	}
}

void time_diff(struct timestamp *dest, struct timestamp *t1, struct timestamp *t0)
{
	dest->sec = t1->sec - t0->sec;
	dest->usec = t1->usec - t0->usec;
	if(dest->usec < 0) {
		dest->sec--;
		dest->usec += 1000000;
	}
}

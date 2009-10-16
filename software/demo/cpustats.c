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

#include <libc.h>
#include <irq.h>

#include <hal/time.h>

#include "cpustats.h"

static int enter_count;
static struct timestamp acc;
static struct timestamp first_enter;
static int load;

void cpustats_init()
{
	enter_count = 0;
	acc.sec = 0;
	acc.usec = 0;
	load = 0;
}

/*
 * Must be called with interrupts disabled,
 * and with the CPU time counter counting.
 */
void cpustats_tick()
{
	struct timestamp ts;
	struct timestamp diff;
	int usec;

	time_get(&ts);
	time_diff(&diff, &ts, &first_enter);
	time_add(&acc, &diff);

	usec = acc.sec*1000000+acc.usec;
	load = usec/10000;

	first_enter.sec = ts.sec;
	first_enter.usec = ts.usec;
	acc.sec = 0;
	acc.usec = 0;
}

void cpustats_enter()
{
	unsigned int oldmask = 0;

	oldmask = irq_getmask();
	irq_setmask(0);

	enter_count++;
	if(enter_count == 1)
		time_get(&first_enter);

	irq_setmask(oldmask);
}

void cpustats_leave()
{
	unsigned int oldmask = 0;

	oldmask = irq_getmask();
	irq_setmask(0);

	enter_count--;
	if(enter_count == 0) {
		struct timestamp ts;
		struct timestamp diff;
		time_get(&ts);
		time_diff(&diff, &ts, &first_enter);
		time_add(&acc, &diff);
	}

	irq_setmask(oldmask);
}

int cpustats_load()
{
	return load;
}


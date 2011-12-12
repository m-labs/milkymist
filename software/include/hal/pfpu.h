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

#ifndef __HAL_PFPU_H
#define __HAL_PFPU_H

#include <hw/pfpu.h>

struct pfpu_td;

typedef void (*pfpu_callback)(struct pfpu_td *);

struct pfpu_td {
	unsigned int *output;
	unsigned int hmeshlast;
	unsigned int vmeshlast;
	pfpu_instruction *program;
	unsigned int progsize;
	float *registers;
	int update; /* < shall we update the "registers" array after completion */
	int invalidate; /* < shall we invalidate L1 data cache after completion */
	pfpu_callback callback;
	void *user; /* < for application use */
};

void pfpu_init(void);
void pfpu_isr(void);
int pfpu_submit_task(struct pfpu_td *td);

#endif /* __HAL_PFPU_H */

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

#ifndef __TMU_H
#define __TMU_H

#include <hw/tmu.h>

struct tmu_td;

typedef void (*tmu_callback)(struct tmu_td *);

struct tmu_td {
	unsigned int flags;
	unsigned int hmeshlast;
	unsigned int vmeshlast;
	unsigned int brightness;
	unsigned short chromakey;
	struct tmu_vertex *srcmesh;
	unsigned short *srcfbuf;
	unsigned int srchres;
	unsigned int srcvres;
	struct tmu_vertex *dstmesh;
	unsigned short *dstfbuf;
	unsigned int dsthres;
	unsigned int dstvres;

	int profile; /* < prints profiling info after completion */
	tmu_callback callback;
	void *user; /* < for application use */
};

void tmu_init();
void tmu_isr();
int tmu_submit_task(struct tmu_td *td);

#endif /* __TMU_H */

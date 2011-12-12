/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
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

#ifndef __HAL_TMU_H
#define __HAL_TMU_H

#include <hw/tmu.h>

struct tmu_td;

typedef void (*tmu_callback)(struct tmu_td *);

struct tmu_td {
	unsigned int flags;
	unsigned int hmeshlast;
	unsigned int vmeshlast;
	unsigned int brightness;
	unsigned short chromakey;
	struct tmu_vertex *vertices;
	unsigned short *texfbuf;
	unsigned int texhres;
	unsigned int texvres;
	unsigned int texhmask;
	unsigned int texvmask;
	unsigned short *dstfbuf;
	unsigned int dsthres;
	unsigned int dstvres;
	int dsthoffset;
	int dstvoffset;
	unsigned int dstsquarew;
	unsigned int dstsquareh;
	unsigned int alpha;

	tmu_callback callback;
	void *user; /* < for application use */
};

int tmu_ready;

void tmu_init(void);
void tmu_isr(void);
int tmu_submit_task(struct tmu_td *td);

#endif /* __HAL_TMU_H */

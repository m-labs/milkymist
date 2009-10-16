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
#include <console.h>
#include <irq.h>
#include <board.h>
#include <hw/interrupts.h>
#include <hw/tmu.h>

#include <hal/brd.h>
#include <hal/tmu.h>

#define TMU_TASKQ_SIZE 4 /* < must be a power of 2 */
#define TMU_TASKQ_MASK (TMU_TASKQ_SIZE-1)

static struct tmu_td *queue[TMU_TASKQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

void tmu_init()
{
	unsigned int mask;

	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	CSR_TMU_CTL = 0; /* Ack any pending IRQ */

	mask = irq_getmask();
	mask |= IRQ_TMU;
	irq_setmask(mask);

	printf("TMU: texture mapping unit initialized\n");
}

static void tmu_start(struct tmu_td *td)
{
	CSR_TMU_HMESHLAST = td->hmeshlast;
	CSR_TMU_VMESHLAST = td->vmeshlast;
	CSR_TMU_BRIGHTNESS = td->brightness;
	CSR_TMU_CHROMAKEY = td->chromakey;
	CSR_TMU_SRCMESH = (unsigned int)td->srcmesh;
	CSR_TMU_SRCFBUF = (unsigned int)td->srcfbuf;
	CSR_TMU_SRCHRES = td->srchres;
	CSR_TMU_SRCVRES = td->srcvres;
	CSR_TMU_DSTMESH = (unsigned int)td->dstmesh;
	CSR_TMU_DSTFBUF = (unsigned int)td->dstfbuf;
	CSR_TMU_DSTHRES = td->dsthres;
	CSR_TMU_DSTVRES = td->dstvres;

	CSR_TMU_CTL = td->flags|TMU_CTL_START;
	//printf("write %d read %d\n", td->flags|TMU_CTL_START, CSR_TMU_CTL);
}

void tmu_isr()
{
	if(queue[consume]->callback)
		queue[consume]->callback(queue[consume]);
	if(queue[consume]->profile) {
		int pixels, clocks, misses, hits;

		printf("TMU: ====================================================\n");
		pixels = CSR_TMUP_PIXELS;
		clocks = CSR_TMUP_CLOCKS;
		printf("TMU: Drawn pixels:                         %d\n", pixels);
		printf("TMU: Processing time (clock cycles):       %d\n", clocks);
		printf("TMU: Fill rate (Mpixels/s):                %d\n", (brd_desc->clk_frequency/1000000)*pixels/clocks);
		printf("TMU: Frames per second:                    %d\n", brd_desc->clk_frequency/clocks);
		printf("TMU: Geometry rate (Kvertices/s):          %d\n", (brd_desc->clk_frequency/1000)*((CSR_TMU_HMESHLAST+1)*(CSR_TMU_VMESHLAST+1))/clocks);
		printf("TMU: At point 1:\n");
		printf("TMU:   - stalled transactions:             %d\n", CSR_TMUP_STALL1);
		printf("TMU:   - completed transactions:           %d\n", CSR_TMUP_COMPLETE1);
		printf("TMU: At point 2:\n");
		printf("TMU:   - stalled transactions:             %d\n", CSR_TMUP_STALL2);
		printf("TMU:   - completed transactions:           %d\n", CSR_TMUP_COMPLETE2);
		printf("TMU: Texel cache:\n");
		misses = CSR_TMUP_MISSES;
		hits = pixels-misses;
		printf("TMU:   - hits:                             %d\n", hits);
		printf("TMU:   - misses:                           %d\n", misses);
		printf("TMU:   - hit rate:                         %d%%\n", 100*hits/(hits+misses));
		printf("TMU: ====================================================\n");
	}
	consume = (consume + 1) & TMU_TASKQ_MASK;
	level--;
	if(level > 0)
		tmu_start(queue[consume]); /* IRQ automatically acked */
	else {
		cts = 1;
		CSR_TMU_CTL = 0; /* Ack IRQ */
	}
}

int tmu_submit_task(struct tmu_td *td)
{
	unsigned int oldmask;

	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_TMU));

	if(level >= TMU_TASKQ_SIZE) {
		irq_setmask(oldmask);
		printf("TMU: taskq overflow\n");
		return 0;
	}

	queue[produce] = td;
	produce = (produce + 1) & TMU_TASKQ_MASK;
	level++;

	if(cts) {
		cts = 0;
		tmu_start(td);
	}

	irq_setmask(oldmask);

	return 1;
}


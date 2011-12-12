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

#include <stdio.h>
#include <irq.h>
#include <board.h>
#include <hw/interrupts.h>
#include <hw/sysctl.h>
#include <hw/capabilities.h>
#include <hw/tmu.h>

#include <hal/brd.h>
#include <hal/tmu.h>

#define TMU_TASKQ_SIZE 8 /* < must be a power of 2 */
#define TMU_TASKQ_MASK (TMU_TASKQ_SIZE-1)

int tmu_ready;

static struct tmu_td *queue[TMU_TASKQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

void tmu_init(void)
{
	unsigned int mask;
	
	if(!(CSR_CAPABILITIES & CAP_TMU)) {
		printf("TMU: not supported by SoC, giving up.\n");
		return;
	}

	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	CSR_TMU_CTL = 0;
	irq_ack(IRQ_TMU);

	mask = irq_getmask();
	mask |= IRQ_TMU;
	irq_setmask(mask);

	printf("TMU: texture mapping unit initialized\n");
	
	tmu_ready = 1;
}

static void tmu_start(struct tmu_td *td)
{
	CSR_TMU_HMESHLAST = td->hmeshlast;
	CSR_TMU_VMESHLAST = td->vmeshlast;
	CSR_TMU_BRIGHTNESS = td->brightness;
	CSR_TMU_CHROMAKEY = td->chromakey;

	CSR_TMU_VERTICESADR = (unsigned int)td->vertices;
	CSR_TMU_TEXFBUF = (unsigned int)td->texfbuf;
	CSR_TMU_TEXHRES = td->texhres;
	CSR_TMU_TEXVRES = td->texvres;
	CSR_TMU_TEXHMASK = td->texhmask;
	CSR_TMU_TEXVMASK = td->texvmask;

	CSR_TMU_DSTFBUF = (unsigned int)td->dstfbuf;
	CSR_TMU_DSTHRES = td->dsthres;
	CSR_TMU_DSTVRES = td->dstvres;
	CSR_TMU_DSTHOFFSET = td->dsthoffset;
	CSR_TMU_DSTVOFFSET = td->dstvoffset;
	CSR_TMU_DSTSQUAREW = td->dstsquarew;
	CSR_TMU_DSTSQUAREH = td->dstsquareh;

	CSR_TMU_ALPHA = td->alpha;

	CSR_TMU_CTL = td->flags|TMU_CTL_START;
}

void tmu_isr(void)
{
	if(queue[consume]->callback)
		queue[consume]->callback(queue[consume]);
	consume = (consume + 1) & TMU_TASKQ_MASK;
	level--;

	irq_ack(IRQ_TMU);

	if(level > 0)
		tmu_start(queue[consume]);
	else
		cts = 1;
}

int tmu_submit_task(struct tmu_td *td)
{
	unsigned int oldmask;

	oldmask = irq_getmask();
	irq_setmask(0);

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


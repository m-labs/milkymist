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
#include <system.h>
#include <hw/interrupts.h>
#include <hw/pfpu.h>

#include <hal/pfpu.h>

#define PFPU_TASKQ_SIZE 4 /* < must be a power of 2 */
#define PFPU_TASKQ_MASK (PFPU_TASKQ_SIZE-1)

static struct pfpu_td *queue[PFPU_TASKQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

void pfpu_init(void)
{
	unsigned int mask;

	/* Reset PFPU */
	CSR_PFPU_CTL = 0;
	irq_ack(IRQ_PFPU);

	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	mask = irq_getmask();
	mask |= IRQ_PFPU;
	irq_setmask(mask);

	printf("FPU: programmable floating point unit initialized\n");
}

static void load_program(pfpu_instruction *program, int size)
{
	int page;
	int word;
	volatile pfpu_instruction *pfpu_prog = (pfpu_instruction *)CSR_PFPU_CODEBASE;

	for(page=0;page<(PFPU_PROGSIZE/PFPU_PAGESIZE);page++) {
		CSR_PFPU_CODEPAGE = page;
		for(word=0;word<PFPU_PAGESIZE;word++) {
			if(size == 0) return;
			pfpu_prog[word] = *program;
			program++;
			size--;
		}
	}
}

static void load_registers(float *registers)
{
	volatile float *pfpu_regs = (float *)CSR_PFPU_DREGBASE;
	int i;

	for(i=PFPU_SPREG_COUNT;i<PFPU_REG_COUNT;i++)
		pfpu_regs[i] = registers[i];
}

static void update_registers(float *registers)
{
	volatile float *pfpu_regs = (float *)CSR_PFPU_DREGBASE;
	int i;

	for(i=PFPU_SPREG_COUNT;i<PFPU_REG_COUNT;i++)
		registers[i] = pfpu_regs[i];
}

static void pfpu_start(struct pfpu_td *td)
{
	load_program(td->program, td->progsize);
	load_registers(td->registers);
	CSR_PFPU_MESHBASE = (unsigned int)td->output;
	CSR_PFPU_HMESHLAST = td->hmeshlast;
	CSR_PFPU_VMESHLAST = td->vmeshlast;

	CSR_PFPU_CTL = PFPU_CTL_START;
}

void pfpu_isr(void)
{
	if(queue[consume]->update)
		update_registers(queue[consume]->registers);
	if(queue[consume]->invalidate)
		flush_cpu_dcache();
	queue[consume]->callback(queue[consume]);
	consume = (consume + 1) & PFPU_TASKQ_MASK;
	level--;

	irq_ack(IRQ_PFPU);

	if(level > 0)
		pfpu_start(queue[consume]);
	else
		cts = 1;
}

int pfpu_submit_task(struct pfpu_td *td)
{
	unsigned int oldmask;

	oldmask = irq_getmask();
	irq_setmask(0);

	if(level >= PFPU_TASKQ_SIZE) {
		irq_setmask(oldmask);
		printf("FPU: taskq overflow\n");
		return 0;
	}

	queue[produce] = td;
	produce = (produce + 1) & PFPU_TASKQ_MASK;
	level++;

	if(cts) {
		cts = 0;
		pfpu_start(td);
	}

	irq_setmask(oldmask);

	return 1;
}

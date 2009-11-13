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

#include <hw/interrupts.h>
#include <irq.h>
#include <uart.h>

#include <hal/time.h>
#include <hal/slowout.h>
#include <hal/snd.h>
#include <hal/pfpu.h>
#include <hal/tmu.h>
#include <hal/ps2.h>

#include "ui.h"
#include "cpustats.h"

void isr()
{
	unsigned int irqs;

	cpustats_enter();

	irqs = irq_pending() & irq_getmask();

	if(irqs & IRQ_UARTRX)
		uart_async_isr_rx();
	if(irqs & IRQ_UARTTX)
		uart_async_isr_tx();

	if(irqs & IRQ_TIMER0)
		time_isr();
	if(irqs & IRQ_TIMER1)
		slowout_isr();

	if(irqs & IRQ_AC97CRREQUEST)
		snd_isr_crrequest();
	if(irqs & IRQ_AC97CRREPLY)
		snd_isr_crreply();
	if(irqs & IRQ_AC97DMAR)
		snd_isr_dmar();
	if(irqs & IRQ_AC97DMAW)
		snd_isr_dmaw();

	if(irqs & IRQ_PFPU)
		pfpu_isr();

	if(irqs & IRQ_TMU)
		tmu_isr();

	if(irqs & IRQ_PS2)
		ps2_isr();

	if(irqs & IRQ_GPIO) {
		irq_ack(IRQ_GPIO);
		ui_isr_key();
	}

	cpustats_leave();
}

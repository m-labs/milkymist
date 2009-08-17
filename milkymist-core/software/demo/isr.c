/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <hw/interrupts.h>
#include <irq.h>
#include <uart.h>

#include "time.h"
#include "slowout.h"
#include "snd.h"
#include "tmu.h"
#include "pfpu.h"
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

	if(irqs & IRQ_TMU)
		tmu_isr();

	if(irqs & IRQ_PFPU)
		pfpu_isr();

	if(irqs & IRQ_GPIO)
		ui_isr_key();

	irq_ack(irqs);

	cpustats_leave();
}

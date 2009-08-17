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

#include <libc.h>
#include <console.h>
#include <irq.h>
#include <system.h>
#include <hw/interrupts.h>

#include "renderer.h"
#include "vga.h"
#include "tmu.h"
#include "wave.h"
#include "cpustats.h"
#include "rpipe.h"

#include "spam.xpm"

#define SPAM_PERIOD	300
#define SPAM_W		305
#define SPAM_H		128
#define SPAM_ON		'.'

#define RPIPE_FRAMEQ_SIZE 4 /* < must be a power of 2 */
#define RPIPE_FRAMEQ_MASK (RPIPE_FRAMEQ_SIZE-1)

static struct rpipe_frame *queue[RPIPE_FRAMEQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

struct rpipe_frame *bh_frame;
static int run_bottom_half;

static unsigned int frames;
static unsigned int fps;
static unsigned int spam_counter;

static struct tmu_vertex dst_vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE];

void rpipe_init()
{
	unsigned int x, y;
	
	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	frames = 0;
	fps = 0;
	spam_counter = 0;

	run_bottom_half = 0;

	for(y=0;y<=renderer_vmeshlast;y++)
		for(x=0;x<=renderer_hmeshlast;x++) {
			dst_vertices[y][x].x = x*vga_hres/renderer_hmeshlast;
			dst_vertices[y][x].y = y*vga_vres/renderer_vmeshlast;
		}
	
	printf("RPI: rendering pipeline ready\n");
}

static struct tmu_td tmu_task;

static void rpipe_tmu_callback(struct tmu_td *td)
{
	bh_frame = (struct rpipe_frame *)td->user;
	run_bottom_half = 1;
}

static void rpipe_start(struct rpipe_frame *frame)
{
	tmu_task.hmeshlast = renderer_hmeshlast;
	tmu_task.vmeshlast = renderer_vmeshlast;
	tmu_task.brightness = frame->brightness;
	tmu_task.srcmesh = &frame->vertices[0][0];
	tmu_task.srcfbuf = vga_frontbuffer;
	tmu_task.srchres = vga_hres;
	tmu_task.srcvres = vga_vres;
	tmu_task.dstmesh = &dst_vertices[0][0];
	tmu_task.dstfbuf = vga_backbuffer;
	tmu_task.dsthres = vga_hres;
	tmu_task.dstvres = vga_vres;

	tmu_task.profile = 0;
	tmu_task.callback = rpipe_tmu_callback;
	tmu_task.user = frame;
	tmu_submit_task(&tmu_task);
}

int rpipe_input(struct rpipe_frame *frame)
{
	if(level >= RPIPE_FRAMEQ_SIZE) {
		printf("RPI: taskq overflow\n");
		return 0;
	}

	queue[produce] = frame;
	produce = (produce + 1) & RPIPE_FRAMEQ_MASK;
	level++;

	if(cts) {
		rpipe_start(frame);
		cts = 0;
	}
	return 1;
}

static void rpipe_bottom_half()
{
	struct wave_vertex vertices[100];
	struct wave_params params;
	int i;
	unsigned int oldmask;

	/*
	 * We assume that the VGA back buffer is not in any cache
	 * (such a cached copy would be incoherent because the TMU
	 * has just written it, straight to SDRAM).
	 */

	/* Draw waves */
	params.wave_mode = 5;
	params.wave_r = bh_frame->wave_r;
	params.wave_g = bh_frame->wave_g;
	params.wave_b = bh_frame->wave_b;
	params.wave_alpha = bh_frame->wave_a;
	params.maximize_wave_color = 1;
	params.wave_dots = bh_frame->wave_usedots;
	params.wave_thick = 1;
	params.additive_waves = bh_frame->wave_additive;
	params.wave_loop = 0;
	params.treb = 0.2;

	for(i=0;i<40;i++) {
		int a;
		vertices[i].x = 639*i/39;
		a = 240 + 200*(int)bh_frame->samples[16*i]/32768;
		if(a < 0) a = 0;
		if(a > 479) a = 479;
		vertices[i].y = a;
	}

	wave_draw(vga_backbuffer, vga_hres, vga_vres, &params, vertices, 40);
	
	/* Draw spam */
	spam_counter++;
	if(spam_counter > SPAM_PERIOD) {
		int dx, dy;
		int x, y;
		
		dx = (vga_hres-SPAM_W)/2;
		dy = vga_vres/2-SPAM_H;
		
		for(y=0;y<SPAM_H;y++)
			for(x=0;x<SPAM_W;x++) {
				if(spam_xpm[y+3][x] == SPAM_ON)
					vga_backbuffer[vga_hres*(dy+y)+dx+x] = 0xffff;
		}
		
		spam_counter = 0;
	}

	/* Update statistics */
	oldmask = irq_getmask();
	irq_setmask(oldmask & ~(IRQ_TIMER0));
	frames++;
	irq_setmask(oldmask);

	/* Update display */
	flush_bridge_cache();
	vga_swap_buffers();
}

void rpipe_service()
{
	if(run_bottom_half) {
		cpustats_enter();
		rpipe_bottom_half();
		run_bottom_half = 0;

		queue[consume]->callback(queue[consume]);
		consume = (consume + 1) & RPIPE_FRAMEQ_MASK;
		level--;
		if(level > 0)
			rpipe_start(queue[consume]);
		else
			cts = 1;
		cpustats_leave();
	}
}

void rpipe_tick()
{
	fps = frames;
	frames = 0;
}

int rpipe_fps()
{
	return fps;
}

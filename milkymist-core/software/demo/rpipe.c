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
#include <math.h>
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
int spam_enabled;

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
	spam_enabled = 0;

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

/* TODO: implement missing wave modes */

static int wave_mode_0(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_1(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_2(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_3(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_4(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_5(struct wave_vertex *vertices)
{
	int nvertices;
	int i;
	float s1, s2;
	float x0, y0;
	float cos_rot, sin_rot;

	nvertices = 128-64;

	cos_rot = cosf(bh_frame->time*0.3f);
	sin_rot = sinf(bh_frame->time*0.3f);

	for(i=0;i<nvertices;i++) {
		s1 = bh_frame->samples[8*i     ]/32768.0;
		s2 = bh_frame->samples[8*i+64+1]/32768.0;
		x0 = 2.0*s1*s2;
		y0 = s1*s1 - s2*s2;

		vertices[i].x = (float)vga_hres*((x0*cos_rot - y0*sin_rot)*bh_frame->wave_scale*0.5 + bh_frame->wave_x);
		vertices[i].y = (float)vga_vres*((x0*sin_rot + y0*cos_rot)*bh_frame->wave_scale*0.5 + bh_frame->wave_y);
	}

	return nvertices;
}

static int wave_mode_6(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_7(struct wave_vertex *vertices)
{
	return 0;
}

static void rpipe_draw_waves()
{
	struct wave_params params;
	struct wave_vertex vertices[256];
	int nvertices;

	/*
	 * We assume that the VGA back buffer is not in any cache
	 * (such a cached copy would be incoherent because the TMU
	 * has just written it, straight to SDRAM).
	 */

	params.wave_mode = bh_frame->wave_mode;
	params.wave_additive = bh_frame->wave_additive;
	params.wave_dots = bh_frame->wave_usedots;
	params.wave_maximize_color = bh_frame->wave_maximize_color;
	params.wave_thick = bh_frame->wave_thick;
	
	params.wave_r = bh_frame->wave_r;
	params.wave_g = bh_frame->wave_g;
	params.wave_b = bh_frame->wave_b;
	params.wave_a = bh_frame->wave_a;
	
	params.treb = bh_frame->treb;

	switch(bh_frame->wave_mode) {
		case 0:
			nvertices = wave_mode_0(vertices);
			break;
		case 1:
			nvertices = wave_mode_1(vertices);
			break;
		case 2:
			nvertices = wave_mode_2(vertices);
			break;
		case 3:
			nvertices = wave_mode_3(vertices);
			break;
		case 4:
			nvertices = wave_mode_4(vertices);
			break;
		case 5:
			nvertices = wave_mode_5(vertices);
			break;
		case 6:
			nvertices = wave_mode_6(vertices);
			break;
		case 7:
			nvertices = wave_mode_7(vertices);
			break;
		default:
			nvertices = 0;
			break;
	}

	wave_draw(vga_backbuffer, vga_hres, vga_vres, &params, vertices, nvertices);
}

static void rpipe_draw_spam()
{
	int dx, dy;
	int x, y;

	spam_counter++;
	if(spam_counter > SPAM_PERIOD) {
		if(spam_enabled) {
			dx = (vga_hres-SPAM_W)/2;
			dy = vga_vres/2-SPAM_H;

			for(y=0;y<SPAM_H;y++)
				for(x=0;x<SPAM_W;x++) {
					if(spam_xpm[y+3][x] == SPAM_ON)
						vga_backbuffer[vga_hres*(dy+y)+dx+x] = 0xffff;
			}
		}

		spam_counter = 0;
	}
}

static void rpipe_bottom_half()
{
	unsigned int oldmask;

	rpipe_draw_waves();
	rpipe_draw_spam();

	/* Update display */
	flush_bridge_cache();
	vga_swap_buffers();

	/* Update statistics */
	oldmask = irq_getmask();
	irq_setmask(oldmask & ~(IRQ_TIMER0));
	frames++;
	irq_setmask(oldmask);
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

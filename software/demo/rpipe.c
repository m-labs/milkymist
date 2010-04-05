/*
 * Milkymist VJ SoC (Software)
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
#include <math.h>
#include <hw/interrupts.h>

#include <hal/vga.h>
#include <hal/tmu.h>

#include "renderer.h"
#include "wave.h"
#include "cpustats.h"
#include "color.h"
#include "line.h"
#include "rpipe.h"

#include "spam.h"

#define RPIPE_FRAMEQ_SIZE 4 /* < must be a power of 2 */
#define RPIPE_FRAMEQ_MASK (RPIPE_FRAMEQ_SIZE-1)

static struct rpipe_frame *queue[RPIPE_FRAMEQ_SIZE];
static unsigned int produce;
static unsigned int consume;
static unsigned int level;
static int cts;

struct rpipe_frame *bh_frame;
static int run_wave_bottom_half;
static int run_swap_bottom_half;

static unsigned int frames;
static unsigned int fps;
static unsigned int spam_counter;
int spam_enabled;

static unsigned short texbufferA[512*512];
static unsigned short texbufferB[512*512];
static unsigned short *tex_frontbuffer;
static unsigned short *tex_backbuffer;

static struct tmu_vertex scale_tex_vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));

#define SPAM_W		75
#define SPAM_H		75
#define SPAM_X		545
#define SPAM_Y		30
#define SPAM_CHROMAKEY	0x001f

static struct tmu_vertex spam_vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));

void rpipe_init()
{
	produce = 0;
	consume = 0;
	level = 0;
	cts = 1;

	frames = 0;
	fps = 0;
	spam_counter = 0;
	spam_enabled = 1;

	run_wave_bottom_half = 0;
	run_swap_bottom_half = 0;

	scale_tex_vertices[0][0].x = 0;
	scale_tex_vertices[0][0].y = 0;
	scale_tex_vertices[0][1].x = renderer_texsize << TMU_FIXEDPOINT_SHIFT;
	scale_tex_vertices[0][1].y = 0;
	scale_tex_vertices[1][0].x = 0;
	scale_tex_vertices[1][0].y = renderer_texsize << TMU_FIXEDPOINT_SHIFT;
	scale_tex_vertices[1][1].x = renderer_texsize << TMU_FIXEDPOINT_SHIFT;
	scale_tex_vertices[1][1].y = renderer_texsize << TMU_FIXEDPOINT_SHIFT;

	spam_vertices[0][0].x = 0;
	spam_vertices[0][0].y = 0;
	spam_vertices[0][1].x = SPAM_W << TMU_FIXEDPOINT_SHIFT;
	spam_vertices[0][1].y = 0;
	spam_vertices[1][0].x = 0;
	spam_vertices[1][0].y = SPAM_H << TMU_FIXEDPOINT_SHIFT;
	spam_vertices[1][1].x = SPAM_W << TMU_FIXEDPOINT_SHIFT;
	spam_vertices[1][1].y = SPAM_H << TMU_FIXEDPOINT_SHIFT;

	tex_frontbuffer = texbufferA;
	tex_backbuffer = texbufferB;
	
	printf("RPI: rendering pipeline ready\n");
}

static struct tmu_td tmu_task1;
static struct tmu_td tmu_task2;

static void rpipe_tmu_warpdone(struct tmu_td *td)
{
	bh_frame = (struct rpipe_frame *)td->user;
	run_wave_bottom_half = 1;
}

static unsigned int get_tmu_wrap_mask(unsigned int x)
{
	unsigned int s;

	s = 1 << TMU_FIXEDPOINT_SHIFT;
	return (x-1)*s+s-1;
}

static void rpipe_start(struct rpipe_frame *frame)
{
	unsigned int mask;
	
	if(frame->tex_wrap)
		mask = get_tmu_wrap_mask(renderer_texsize);
	else
		mask = TMU_MASK_FULL;

	tmu_task1.flags = 0;
	tmu_task1.hmeshlast = renderer_hmeshlast;
	tmu_task1.vmeshlast = renderer_vmeshlast;
	tmu_task1.brightness = frame->brightness;
	tmu_task1.chromakey = 0;
	tmu_task1.vertices = &frame->vertices[0][0];
	tmu_task1.texfbuf = tex_frontbuffer;
	tmu_task1.texhres = renderer_texsize;
	tmu_task1.texvres = renderer_texsize;
	tmu_task1.texhmask = mask;
	tmu_task1.texvmask = mask;
	tmu_task1.dstfbuf = tex_backbuffer;
	tmu_task1.dsthres = renderer_texsize;
	tmu_task1.dstvres = renderer_texsize;
	tmu_task1.dsthoffset = 0;
	tmu_task1.dstvoffset = 0;
	tmu_task1.dstsquarew = renderer_texsize/renderer_hmeshlast;
	tmu_task1.dstsquareh = renderer_texsize/renderer_vmeshlast;

	tmu_task1.callback = rpipe_tmu_warpdone;
	tmu_task1.user = frame;
	tmu_submit_task(&tmu_task1);
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

static void draw_dot(struct line_context *ctx, int x, int y, unsigned int l)
{
	// TODO: make them round and nice looking
	l >>= 1;
	hline(ctx, y, x-l, x+l);
}

static void rpipe_draw_motion_vectors()
{
	int x, y;
	struct line_context ctx;
	float offsetx;
	float intervalx;
	float offsety;
	float intervaly;
	int nx, ny;
	int l;

	if(bh_frame->mv_a == 0.0) return;
	if(bh_frame->mv_x == 0.0) return;
	if(bh_frame->mv_y == 0.0) return;
	
	l = bh_frame->mv_l;
	if(l > 10) l = 10;
	
	line_init_context(&ctx, tex_backbuffer, renderer_texsize, renderer_texsize);
	ctx.color = float_to_rgb565(bh_frame->mv_r, bh_frame->mv_g, bh_frame->mv_b);
	ctx.alpha = 64.0*bh_frame->mv_a;
	ctx.thickness = l;

	offsetx = bh_frame->mv_dx*(float)renderer_texsize;
	intervalx = (float)renderer_texsize/bh_frame->mv_x;
	offsety = bh_frame->mv_dy*renderer_texsize;
	intervaly = (float)renderer_texsize/bh_frame->mv_y;

	nx = bh_frame->mv_x+0.5;
	ny = bh_frame->mv_y+0.5;
	for(y=0;y<ny;y++)
		for (x=0;x<nx;x++)
			draw_dot(&ctx, offsetx+x*intervalx, offsety+y*intervaly, l);
}

static void border_rect(int x0, int y0, int x1, int y1, short int color, unsigned int alpha)
{
	int y;
	struct line_context ctx;

	line_init_context(&ctx, tex_backbuffer, renderer_texsize, renderer_texsize);
	ctx.color = color;
	ctx.alpha = alpha;
	for(y=y0;y<=y1;y++)
		hline(&ctx, y, x0, x1);
}

static void rpipe_draw_borders()
{
	unsigned int of;
	unsigned int iff;
	unsigned int texof;
	short int ob_color, ib_color;
	unsigned int ob_alpha, ib_alpha;
	int cmax;

	of = renderer_texsize*bh_frame->ob_size*.5;
	iff = renderer_texsize*bh_frame->ib_size*.5;

	if(of > 30) of = 30;
	if(iff > 30) iff = 30;
	
	texof = renderer_texsize-of;
	cmax = renderer_texsize-1;

	if((of != 0) && (bh_frame->ob_a != 0.0)) {
		ob_color = float_to_rgb565(bh_frame->ob_r, bh_frame->ob_g, bh_frame->ob_b);
		ob_alpha = 80.0*bh_frame->ob_a;

		border_rect(0, 0, of, cmax, ob_color, ob_alpha);
		border_rect(of, 0, texof, of, ob_color, ob_alpha);
		border_rect(texof, 0, cmax, cmax, ob_color, ob_alpha);
		border_rect(of, texof, texof, cmax, ob_color, ob_alpha);
	}

	if((iff != 0) && (bh_frame->ib_a != 0.0)) {
		ib_color = float_to_rgb565(bh_frame->ib_r, bh_frame->ib_g, bh_frame->ib_b);
		ib_alpha = 80.0*bh_frame->ib_a;

		border_rect(of, of, of+iff-1, texof-1, ib_color, ib_alpha);
		border_rect(of+iff, of, texof-iff-1, of+iff-1, ib_color, ib_alpha);
		border_rect(texof-iff, of, texof-1, texof-1, ib_color, ib_alpha);
		border_rect(of+iff, texof-iff, texof-iff-1, texof-1, ib_color, ib_alpha);
	}
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

static int wave_mode_23(struct wave_vertex *vertices)
{
	int nvertices;
	int i;
	float s1, s2;

	nvertices = 128-32;

	for(i=0;i<nvertices;i++) {
		s1 = bh_frame->samples[8*i     ]/32768.0;
		s2 = bh_frame->samples[8*i+32+1]/32768.0;
		
		vertices[i].x = (s1*bh_frame->wave_scale*0.5 + bh_frame->wave_x)*renderer_texsize;
		vertices[i].y = (s2*bh_frame->wave_scale*0.5 + bh_frame->wave_x)*renderer_texsize;
	}
	
	return nvertices;
}

static int wave_mode_4(struct wave_vertex *vertices)
{
	int nvertices;
	float wave_x;
	int i;
	float dy_adj;
	float s1, s2;
	float scale;

	nvertices = 128;

	// TODO: rotate using wave_mystery
	wave_x = bh_frame->wave_x*.75 + .125;
	scale = 4.0*(float)renderer_texsize/505.0;

	for(i=1;i<=nvertices;i++) {
		s1 = bh_frame->samples[8*i]/32768.0;
		s2 = bh_frame->samples[8*i-2]/32768.0;
		
		dy_adj = s1*20.0*bh_frame->wave_scale-s2*20.0*bh_frame->wave_scale;
		// nb: x and y reversed to simulate default rotation from wave_mystery
		vertices[i-1].y = s1*20.0*bh_frame->wave_scale+(float)renderer_texsize*bh_frame->wave_x;
		vertices[i-1].x = (i*scale)+dy_adj;
	}

	return nvertices;
}

static int wave_mode_5(struct wave_vertex *vertices)
{
	int nvertices;
	int i;
	float s1, s2;
	float x0, y0;
	float cos_rot, sin_rot;

	nvertices = 128-64;

	cos_rot = cosf(bh_frame->time*0.3);
	sin_rot = sinf(bh_frame->time*0.3);

	for(i=0;i<nvertices;i++) {
		s1 = bh_frame->samples[8*i     ]/32768.0;
		s2 = bh_frame->samples[8*i+64+1]/32768.0;
		x0 = 2.0*s1*s2;
		y0 = s1*s1 - s2*s2;

		vertices[i].x = (float)renderer_texsize*((x0*cos_rot - y0*sin_rot)*bh_frame->wave_scale*0.5 + bh_frame->wave_x);
		vertices[i].y = (float)renderer_texsize*((x0*sin_rot + y0*cos_rot)*bh_frame->wave_scale*0.5 + bh_frame->wave_y);
	}

	return nvertices;
}

static int wave_mode_6(struct wave_vertex *vertices)
{
	int nvertices;
	int i;
	float inc;
	float offset;
	float s;

	nvertices = 128;

	// TODO: rotate/scale by wave_mystery

	inc = (float)renderer_texsize/(float)nvertices;
	offset = (float)renderer_texsize*(1.0-bh_frame->wave_x);
	for(i=0;i<nvertices;i++) {
		s = bh_frame->samples[8*i]/32768.0;
		// nb: x and y reversed to simulate default rotation from wave_mystery
		vertices[i].y = s*20.0*bh_frame->wave_scale+offset;
		vertices[i].x = i*inc;
	}
	
	return nvertices;
}

static int wave_mode_7(struct wave_vertex *vertices)
{
	return 0;
}

static int wave_mode_8(struct wave_vertex *vertices)
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
		case 3:
			nvertices = wave_mode_23(vertices);
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
		case 8:
			nvertices = wave_mode_8(vertices);
			break;
		default:
			nvertices = 0;
			break;
	}

	wave_draw(tex_backbuffer, renderer_texsize, renderer_texsize, &params, vertices, nvertices);
}

static void rpipe_tmu_copydone(struct tmu_td *td)
{
	run_swap_bottom_half = 1;
}

static void rpipe_wave_bottom_half()
{
	rpipe_draw_motion_vectors();
	rpipe_draw_borders();
	rpipe_draw_waves();
	flush_bridge_cache();

	tmu_task2.flags = 0;
	tmu_task2.hmeshlast = 1;
	tmu_task2.vmeshlast = 1;
	tmu_task2.brightness = TMU_BRIGHTNESS_MAX;
	tmu_task2.chromakey = 0;
	tmu_task2.vertices = &scale_tex_vertices[0][0];
	tmu_task2.texfbuf = tex_backbuffer;
	tmu_task2.texhres = renderer_texsize;
	tmu_task2.texvres = renderer_texsize;
	tmu_task2.texhmask = TMU_MASK_FULL;
	tmu_task2.texvmask = TMU_MASK_FULL;
	tmu_task2.dstfbuf = vga_backbuffer;
	tmu_task2.dsthres = vga_hres;
	tmu_task2.dstvres = vga_vres;
	tmu_task2.dsthoffset = 0;
	tmu_task2.dstvoffset = 0;
	tmu_task2.dstsquarew = vga_hres;
	tmu_task2.dstsquareh = vga_vres;
	if(spam_enabled)
		tmu_task2.callback = NULL;
	else
		tmu_task2.callback = rpipe_tmu_copydone;
	tmu_task2.user = NULL;
	
	tmu_submit_task(&tmu_task2);

	if(spam_enabled) {
		tmu_task1.flags = TMU_CTL_CHROMAKEY;
		tmu_task1.hmeshlast = 1;
		tmu_task1.vmeshlast = 1;
		tmu_task1.brightness = TMU_BRIGHTNESS_MAX;
		tmu_task1.chromakey = SPAM_CHROMAKEY;
		tmu_task1.vertices = &spam_vertices[0][0];
		tmu_task1.texfbuf = (unsigned short *)spam_raw;
		tmu_task1.texhres = SPAM_W;
		tmu_task1.texvres = SPAM_H;
		tmu_task1.texhmask = TMU_MASK_FULL;
		tmu_task1.texvmask = TMU_MASK_FULL;
		tmu_task1.dstfbuf = vga_backbuffer;
		tmu_task1.dsthres = vga_hres;
		tmu_task1.dstvres = vga_vres;
		tmu_task1.dsthoffset = SPAM_X;
		tmu_task1.dstvoffset = SPAM_Y;
		tmu_task1.dstsquarew = SPAM_W;
		tmu_task1.dstsquareh = SPAM_H;
		tmu_task1.callback = rpipe_tmu_copydone;
		tmu_task1.user = NULL;
		tmu_submit_task(&tmu_task1);
	}
}

void rpipe_swap_bottom_half()
{
	unsigned short *b;
	unsigned int oldmask;
	
	/* Swap texture buffers */
	b = tex_backbuffer;
	tex_backbuffer = tex_frontbuffer;
	tex_frontbuffer = b;

	/* Update display */
	vga_swap_buffers();

	/* Update statistics */
	oldmask = irq_getmask();
	irq_setmask(oldmask & ~(IRQ_TIMER0));
	frames++;
	irq_setmask(oldmask);

	/* Ready to process the next frame ! */
	queue[consume]->callback(queue[consume]);
	consume = (consume + 1) & RPIPE_FRAMEQ_MASK;
	level--;
	if(level > 0)
		rpipe_start(queue[consume]);
	else
		cts = 1;
}

void rpipe_service()
{
	if(run_wave_bottom_half) {
		cpustats_enter();
		run_wave_bottom_half = 0;
		rpipe_wave_bottom_half();
		cpustats_leave();
	}

	if(run_swap_bottom_half) {
		cpustats_enter();
		run_swap_bottom_half = 0;
		rpipe_swap_bottom_half();
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

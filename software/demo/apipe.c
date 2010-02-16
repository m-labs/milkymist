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
#include <board.h>

#include <hal/brd.h>
#include <hal/snd.h>
#include <hal/pfpu.h>
#include <hal/time.h>

#include "analyzer.h"
#include "eval.h"
#include "cpustats.h"
#include "rpipe.h"
#include "apipe.h"

/* Also used as frame rate limiter */
#define NSAMPLES (48000/30)

static short audiobuffer1[NSAMPLES*2];
static short audiobuffer2[NSAMPLES*2];
static short audiobuffer3[NSAMPLES*2];

static int run_analyzer_bottom_half;
static short *analyzer_buffer;
static int peak_bass, peak_mid, peak_treb;
static float bass_att, mid_att, treb_att;

static struct eval_state *eval;
static int eval_ready;

static struct rpipe_frame frame1 __attribute__((aligned(8)));
static struct rpipe_frame frame2 __attribute__((aligned(8)));
static int frame1_free;
static int frame2_free;

static unsigned int all_frames;

static struct rpipe_frame *alloc_rpipe_frame()
{
	if(frame1_free) return &frame1;
	if(frame2_free) return &frame2;
	return NULL;
}

static void refill_rpipe_frame(struct rpipe_frame *rpipe_frame)
{
	if(rpipe_frame == &frame1) frame1_free = 1;
	else if(rpipe_frame == &frame2) frame2_free = 1;
	else printf("API: trying to refill unknown rpipe frame\n");
}

static void free_rpipe_frame(struct rpipe_frame *rpipe_frame)
{
	snd_record_refill(rpipe_frame->samples);
	refill_rpipe_frame(rpipe_frame);
}

void apipe_init()
{
	run_analyzer_bottom_half = 0;
	peak_bass = 0;
	peak_mid = 0;
	peak_treb = 0;
	bass_att = 0.0f;
	mid_att = 0.0f;
	treb_att = 0.0f;
	eval_ready = 1;
	frame1_free = 1;
	frame2_free = 1;
	all_frames = 0;
	printf("API: analysis pipeline ready\n");
}

static void apipe_snd_callback(short *buffer, void *user)
{
	if(run_analyzer_bottom_half) {
		/* Skip this buffer */
		snd_record_refill(buffer);
		return;
	}
	analyzer_buffer = buffer;
	run_analyzer_bottom_half = 1;
}

void apipe_start(struct eval_state *e)
{
	snd_record_empty();
	snd_record_refill(audiobuffer1);
	snd_record_refill(audiobuffer2);
	snd_record_refill(audiobuffer3);
	eval = e;
	snd_record_start(apipe_snd_callback, NSAMPLES, NULL);
}

void apipe_stop()
{
	snd_record_stop();
}

static struct pfpu_td pfpu_td;

//#define DUMP_MESH

static void pvv_callback(struct pfpu_td *td)
{
	struct rpipe_frame *rpipe_frame;
	#ifdef DUMP_MESH
	int x, y;
	#endif

	rpipe_frame = (struct rpipe_frame *)td->user;

	#ifdef DUMP_MESH
	for(y=10;y<13;y++) {
		for(x=10;x<13;x++)
			printf("(%02d %02d) ", rpipe_frame->vertices[y][x].y, rpipe_frame->vertices[y][x].x);
		printf("\n");
	}
	printf("\n");
	#endif

	if(!rpipe_input(rpipe_frame)) free_rpipe_frame(rpipe_frame);
	eval_ready = 1;
}

static void pfv_callback(struct pfpu_td *td)
{
	struct rpipe_frame *rpipe_frame;
	int brightness256, brightness64, frame_mod;

	rpipe_frame = (struct rpipe_frame *)td->user;

	brightness256 = 257.0f*eval_read_pfv(eval, pfv_decay);
	brightness64 = brightness256 >> 2;
	brightness256 &= 3;
	frame_mod = rpipe_frame->framenr & 3;
	if((brightness256 == 1) && (frame_mod == 0))
		brightness64++;
	if((brightness256 == 2) && ((frame_mod == 0)||(frame_mod == 2)))
		brightness64++;
	if((brightness256 == 3) && (frame_mod != 3))
		brightness64++;
	if(brightness64 > 63) brightness64 = 63;
	rpipe_frame->brightness = brightness64;

	rpipe_frame->wave_mode = eval_read_pfv(eval, pfv_wave_mode);
	rpipe_frame->wave_scale = eval_read_pfv(eval, pfv_wave_scale);
	rpipe_frame->wave_additive = eval_read_pfv(eval, pfv_wave_additive) != 0.0f;
	rpipe_frame->wave_usedots = eval_read_pfv(eval, pfv_wave_usedots) != 0.0f;
	rpipe_frame->wave_maximize_color = eval_read_pfv(eval, pfv_wave_maximize_color) != 0.0f;
	rpipe_frame->wave_thick = eval_read_pfv(eval, pfv_wave_thick) != 0.0f;
	rpipe_frame->wave_x = eval_read_pfv(eval, pfv_wave_x);
	rpipe_frame->wave_y = eval_read_pfv(eval, pfv_wave_y);
	rpipe_frame->wave_r = eval_read_pfv(eval, pfv_wave_r);
	rpipe_frame->wave_g = eval_read_pfv(eval, pfv_wave_g);
	rpipe_frame->wave_b = eval_read_pfv(eval, pfv_wave_b);
	rpipe_frame->wave_a = eval_read_pfv(eval, pfv_wave_a);
	rpipe_frame->tex_wrap = eval_read_pfv(eval, pfv_tex_wrap);

	eval_pfv_to_pvv(eval);
	eval_pvv_fill_td(eval, &pfpu_td, &rpipe_frame->vertices[0][0], pvv_callback, rpipe_frame);
	pfpu_submit_task(&pfpu_td);
}

static void analyzer_bottom_half()
{
	struct analyzer_state analyzer;
	int bass, mid, treb;
	float fbass, fmid, ftreb;
	float time;
	int i;
	struct rpipe_frame *rpipe_frame;
	struct timestamp ts;

	rpipe_frame = alloc_rpipe_frame();
	if(rpipe_frame == NULL) {
		snd_record_refill(analyzer_buffer);
		return; /* drop this buffer */
	}

	rpipe_frame->nsamples = NSAMPLES;
	rpipe_frame->samples = analyzer_buffer;
	rpipe_frame->callback = free_rpipe_frame;

	analyzer_init(&analyzer);
	for(i=0;i<NSAMPLES;i++)
		analyzer_put_sample(&analyzer, analyzer_buffer[2*i], analyzer_buffer[2*i+1]);

	bass = analyzer_get_bass(&analyzer);
	mid = analyzer_get_mid(&analyzer);
	treb = analyzer_get_treb(&analyzer);
	// TODO: appropriate scaling
	if(bass > peak_bass) peak_bass = bass;
	if(mid > peak_mid) peak_mid = mid;
	if(treb > peak_treb) peak_treb = treb;
	fbass = 5.0f*(float)bass/(float)peak_bass;
	fmid = 5.0f*(float)mid/(float)peak_mid;
	ftreb = 5.0f*(float)treb/(float)peak_treb;

	treb_att = 0.6f*treb_att + 0.4f*ftreb;
	mid_att = 0.6f*mid_att + 0.4f*fmid;
	bass_att = 0.6f*bass_att + 0.4f*fbass;

	time_get(&ts);
	time = (float)ts.sec + (float)ts.usec/1000000.0f;

	eval_reinit_all_pfv(eval);
	
	eval_write_pfv(eval, pfv_time, time);
	eval_write_pfv(eval, pfv_bass, fbass);
	eval_write_pfv(eval, pfv_mid, fmid);
	eval_write_pfv(eval, pfv_treb, ftreb);
	eval_write_pfv(eval, pfv_bass_att, bass_att);
	eval_write_pfv(eval, pfv_mid_att, mid_att);
	eval_write_pfv(eval, pfv_treb_att, treb_att);

	rpipe_frame->time = time;
	rpipe_frame->treb = ftreb;
	rpipe_frame->framenr = all_frames++;

	eval_pfv_fill_td(eval, &pfpu_td, pfv_callback, rpipe_frame);
	pfpu_submit_task(&pfpu_td);
}

void apipe_service()
{
	if(run_analyzer_bottom_half && eval_ready) {
		cpustats_enter();
		analyzer_bottom_half();
		eval_ready = 0;
		run_analyzer_bottom_half = 0;
		cpustats_leave();
	}
}

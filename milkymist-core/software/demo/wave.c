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

/* Original code from projectM 1.2.0 */

#include <libc.h>
#include <math.h>
#include <console.h>

#include "line.h"
#include "color.h"
#include "wave.h"
#include "renderer.h"

void wave_draw(unsigned short *framebuffer, unsigned int hres, unsigned int vres,
	struct wave_params *params,
	struct wave_vertex *vertices, unsigned int nvertices)
{
	struct line_context ctx;
	float wave_r, wave_g, wave_b;
	unsigned int r, g, b;
	float wave_o;
	int i;

	line_init_context(&ctx, framebuffer, hres, vres);

	//TODO: implement modulate_opacity_by_volume
	wave_o = params->wave_alpha;
	// Original code: maximize_colors
	wave_r = params->wave_r;
	wave_g = params->wave_g;
	wave_b = params->wave_b;
	if((params->wave_mode == 2) || (params->wave_mode == 5)) {
		switch(renderer_texsize) {
			case 256:  wave_o *= 0.07f; break;
			case 512:  wave_o *= 0.09f; break;
			case 1024: wave_o *= 0.11f; break;
			case 2048: wave_o *= 0.13f; break;
		}
	} else if(params->wave_mode == 3) {
		switch(renderer_texsize) {
			case 256:  wave_o *= 0.075f; break;
			case 512:  wave_o *= 0.15f; break;
			case 1024: wave_o *= 0.22f; break;
			case 2048: wave_o *= 0.33f; break;
		}
		wave_o *= 1.3f;
		wave_o *= params->treb*params->treb;
	}

	if(params->maximize_wave_color) {
		// WARNING: softfloat ">=" operator is broken (says 0.5 >= 0.8)
		// ">" works fine
		if((wave_r > wave_g) && (wave_r > wave_b)) {
			wave_b = wave_b/wave_r;
			wave_g = wave_g/wave_r;
			wave_r = 1.0;
		} else if((wave_b > wave_g) && (wave_b > wave_r)) {
			wave_r = wave_r/wave_b;
			wave_g = wave_g/wave_b;
			wave_b = 1.0;
		} else {
			wave_b = wave_b/wave_g;
			wave_r = wave_r/wave_g;
			wave_g = 1.0;
		}
	}

	r = 31.0*wave_r;
	g = 63.0*wave_g;
	b = 31.0*wave_b;
	if(r > 31) r = 31;
	if(g > 63) g = 63;
	if(b > 31) b = 31;

	ctx.color = MAKERGB565(r, g, b);
	ctx.alpha = 64.0*wave_o; /* line drawing code treats >= 64 as 64, no need to clamp */

	// Original code:
	// glLineStipple(2, 0xAAAA);
	// if(presetOutputs->bWaveDots==1) glEnable(GL_LINE_STIPPLE);
	if(params->wave_dots)
		ctx.dash_size = 2;

	// Original code:
	// if (presetOutputs->bWaveThick==1)
	//  glLineWidth( (this->renderTarget->renderer_texsize < 512 ) ? 2 : 2*this->renderTarget->renderer_texsize/512);
	// else
	//  glLineWidth( (this->renderTarget->renderer_texsize < 512 ) ? 1 : this->renderTarget->renderer_texsize/512);
	if(params->wave_thick)
		ctx.thickness = renderer_texsize <= 512 ? 2 : 2*renderer_texsize/512;
	else
		ctx.thickness = renderer_texsize <= 512 ? 1 : renderer_texsize/512;

	// Original code:
	// if (presetOutputs->bAdditiveWaves==0)
	//  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	// else
	//  glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	if(params->additive_waves)
		ctx.additive = 1;

	// Original code:
	// glTranslatef(.5, .5, 0);
	// glRotatef(presetOutputs->wave_rot, 0, 0, 1);
	// glScalef(presetOutputs->wave_scale, 1.0, 1.0);
	// glTranslatef(-.5, -.5, 0);
	// TODO

	for(i=0;i<(nvertices-1);i++)
		line(&ctx, vertices[i].x, vertices[i].y, vertices[i+1].x, vertices[i+1].y);

	if(params->wave_loop)
		line(&ctx, vertices[0].x, vertices[0].y, vertices[nvertices-1].x, vertices[nvertices-1].y);

	// TODO: implement two_waves
}

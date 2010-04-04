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

/* Original code from projectM 1.2.0 */

#include <stdio.h>
#include <math.h>

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
	float wave_o;
	int i;

	if(nvertices == 0) return;
	
	line_init_context(&ctx, framebuffer, hres, vres);

	//TODO: implement modulate_opacity_by_volume
	wave_o = params->wave_a;
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

	if(params->wave_maximize_color) {
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

	ctx.color = float_to_rgb565(wave_r, wave_g, wave_b);
	//printf("fc: %f %f %f / %d %d %d\n", &wave_r, &wave_g, &wave_b, GETR(ctx.color), GETG(ctx.color), GETB(ctx.color));

	/*
	 * HACK: Boost wave opacity (100 instead of 64).
	 * Line drawing code treats >= 64 as 64, no need to clamp
	 */
	ctx.alpha = 100.0*wave_o;

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
	if(params->wave_additive)
		ctx.additive = 1;

	// Original code:
	// glTranslatef(.5, .5, 0);
	// glRotatef(presetOutputs->wave_rot, 0, 0, 1);
	// glScalef(presetOutputs->wave_scale, 1.0, 1.0);
	// glTranslatef(-.5, -.5, 0);
	// TODO

	for(i=0;i<(nvertices-1);i++)
		line(&ctx, vertices[i].x, vertices[i].y, vertices[i+1].x, vertices[i+1].y);

	// draw_wave_as_loop
	if(params->wave_mode == 0)
		line(&ctx, vertices[0].x, vertices[0].y, vertices[nvertices-1].x, vertices[nvertices-1].y);

	// TODO: implement two_waves
}

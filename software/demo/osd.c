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

#include <hal/vga.h>
#include <hal/tmu.h>
#include <math.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>

#include "osd.h"
#include "font.h"
#include "logo.h"

int osd_x;
int osd_y;
#define OSD_W 600
#define OSD_H 160
#define OSD_CORNER 15
#define OSD_CHROMAKEY 0x001f

static struct tmu_vertex osd_vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));

static unsigned short int osd_fb[OSD_W*OSD_H] __attribute__((aligned(32)));

static struct font_context osd_font;

static void round_corners()
{
	int i;
	int d;
	int x;

	for(i=0;i<OSD_CORNER;i++) {
		d = OSD_CORNER - sqrtf(2*OSD_CORNER*i - i*i);
		for(x=0;x<d;x++) {
			osd_fb[i*OSD_W+x] = OSD_CHROMAKEY;
			osd_fb[i*OSD_W+(OSD_W-1-x)] = OSD_CHROMAKEY;
			osd_fb[(OSD_H-1-i)*OSD_W+x] = OSD_CHROMAKEY;
			osd_fb[(OSD_H-1-i)*OSD_W+(OSD_W-1-x)] = OSD_CHROMAKEY;
		}
	}
}

#define LOGO_W 46
#define LOGO_H 46

static void logo()
{
	int x, y;

	for(y=0;y<LOGO_H;y++)
		for(x=0;x<LOGO_W;x++)
			osd_fb[(x+OSD_W-LOGO_W-OSD_CORNER)+OSD_W*(y+OSD_CORNER)] = ((unsigned short *)logo_raw)[x+LOGO_W*y];
}

static int previous_keys;
static int osd_alpha;
static int osd_timer;

#define OSD_MAX_ALPHA 40

void osd_init()
{
	osd_x = (vga_hres - OSD_W) >> 1;
	osd_y = vga_vres - OSD_H - 20;
	
	osd_vertices[0][0].x = 0;
	osd_vertices[0][0].y = 0;
	osd_vertices[0][1].x = OSD_W << TMU_FIXEDPOINT_SHIFT;
	osd_vertices[0][1].y = 0;
	osd_vertices[1][0].x = 0;
	osd_vertices[1][0].y = OSD_H << TMU_FIXEDPOINT_SHIFT;
	osd_vertices[1][1].x = OSD_W << TMU_FIXEDPOINT_SHIFT;
	osd_vertices[1][1].y = OSD_H << TMU_FIXEDPOINT_SHIFT;

	round_corners();
	logo();

	previous_keys = 0;
	osd_alpha = OSD_MAX_ALPHA;
	osd_timer = 125;

	font_init_context(&osd_font, vera20_tff, osd_fb, OSD_W, OSD_H);
	font_draw_string(&osd_font, OSD_CORNER, OSD_CORNER, "Rovastar - Touchdown on Mars");
}

static void process_keys(unsigned int keys)
{
}

static void osd_service()
{
	unsigned int keys;
	unsigned int new_keys;

	keys = CSR_GPIO_IN & (GPIO_BTN1|GPIO_BTN2|GPIO_BTN3);
	new_keys = keys & ~previous_keys;
	previous_keys = keys;

	if(new_keys) {
		osd_timer = 125;
		if(osd_alpha != 0)
			process_keys(new_keys);
	}

	osd_timer--;
	if(osd_timer > 0) {
		osd_alpha += 4;
		if(osd_alpha > OSD_MAX_ALPHA)
			osd_alpha = OSD_MAX_ALPHA;
	} else {
		osd_alpha--;
		if(osd_alpha < 0)
			osd_alpha = 0;
	}
}

int osd_fill_blit_td(struct tmu_td *td, tmu_callback callback, void *user)
{
	osd_service();

	td->flags = TMU_CTL_CHROMAKEY;
	td->hmeshlast = 1;
	td->vmeshlast = 1;
	td->brightness = TMU_BRIGHTNESS_MAX;
	td->chromakey = OSD_CHROMAKEY;
	td->vertices = &osd_vertices[0][0];
	td->texfbuf = osd_fb;
	td->texhres = OSD_W;
	td->texvres = OSD_H;
	td->texhmask = TMU_MASK_NOFILTER;
	td->texvmask = TMU_MASK_NOFILTER;
	td->dstfbuf = vga_backbuffer;
	td->dsthres = vga_hres;
	td->dstvres = vga_vres;
	td->dsthoffset = osd_x;
	td->dstvoffset = osd_y;
	td->dstsquarew = OSD_W;
	td->dstsquareh = OSD_H;
	td->alpha = osd_alpha;
	td->callback = callback;
	td->user = user;

	return osd_alpha != 0;
}

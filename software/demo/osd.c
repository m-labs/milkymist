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
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <hw/rc5.h>
#include <hw/interrupts.h>
#include <irq.h>
#include <math.h>
#include <system.h>
#include <string.h>
#include <fatfs.h>
#include <blockdev.h>

#include "font.h"
#include "logo.h"
#include "renderer.h"
#include "version.h"
#include "osd.h"

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
	font_draw_string(&osd_font, OSD_W-LOGO_W-OSD_CORNER-16, OSD_H-font_get_height(&osd_font), 0, VERSION);
}

static void init_ui();

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

	memset(osd_fb, 0, sizeof(osd_fb));
	font_init_context(&osd_font, vera20_tff, osd_fb, OSD_W, OSD_H);
	round_corners();
	logo();

	init_ui();
}

static int previous_keys;
static int up1_last_toggle;
static int up2_last_toggle;
static int down1_last_toggle;
static int down2_last_toggle;
static int ok_last_toggle;
static int osd_alpha;
static int osd_timer;

#define OSD_DURATION 90
#define OSD_MAX_ALPHA 40

#define OSD_MAX_USER_X (OSD_W-OSD_CORNER-LOGO_W)

#define MAX_PATCH_TITLE 45
#define MAX_PATCHES 128
static char current_patch[MAX_PATCH_TITLE+1];
static char patchlist_filenames[MAX_PATCHES][13];
static char patchlist_titles[MAX_PATCHES][MAX_PATCH_TITLE+1];
static int patchlist_n;
static int patchlist_sel;
static int patchlist_page;

static int patchlist_maxpage;
static int patchlist_maxsel;

static int patchlist_pending;

static void clear_user_area()
{
	int x, y;
	
	for(y=OSD_CORNER;y<(OSD_H-OSD_CORNER);y++)
		for(x=OSD_CORNER;x<OSD_MAX_USER_X;x++)
			osd_fb[x+y*OSD_W] = 0;
}

static void draw_user_area()
{
	int i;
	int h;
	int nel;
	
	clear_user_area();
	h = font_get_height(&osd_font);
	font_draw_string(&osd_font, OSD_CORNER, OSD_CORNER, 0, current_patch);
	nel = patchlist_page < patchlist_maxpage ? 4 : patchlist_maxsel;
	for(i=0;i<nel;i++)
		font_draw_string(&osd_font, OSD_CORNER+20, OSD_CORNER+(i+1)*h, i == patchlist_sel, patchlist_titles[patchlist_page*4+i]);
	flush_bridge_cache();
}

static void start_patch_from_list(int n)
{
	strcpy(current_patch, patchlist_titles[n]);
	patchlist_pending = n;
}

static void process_keys(unsigned int keys)
{
	osd_timer = OSD_DURATION;
	if(osd_alpha == 0)
		return;

	if(keys & GPIO_BTN1) {
		if(patchlist_sel > 0)
			patchlist_sel--;
		else if(patchlist_page > 0) {
			patchlist_page--;
			patchlist_sel = 3;
		}
	}
	if(keys & GPIO_BTN3) {
		if(patchlist_page < patchlist_maxpage) {
			if(patchlist_sel < 3)
				patchlist_sel++;
			else {
				patchlist_page++;
				patchlist_sel = 0;
			}
		} else if(patchlist_sel < (patchlist_maxsel-1))
			patchlist_sel++;
	}
	if(keys & GPIO_BTN2)
		start_patch_from_list(patchlist_page*4+patchlist_sel);

	draw_user_area();
}

static int lscb(const char *filename, const char *longname, void *param)
{
	char *c;

	if(strlen(longname) < 5) return 1;
	c = (char *)longname + strlen(longname) - 5;
	if(strcmp(c, ".milk") != 0) return 1;
	strcpy(patchlist_filenames[patchlist_n], filename);
	strncpy(patchlist_titles[patchlist_n], longname, MAX_PATCH_TITLE);
	patchlist_titles[patchlist_n][MAX_PATCH_TITLE] = 0;
	c = patchlist_titles[patchlist_n] + strlen(patchlist_titles[patchlist_n]) - 5;
	if(strcmp(c, ".milk") == 0) *c = 0;
	patchlist_n++;
	return patchlist_n < MAX_PATCHES;
}

static void init_ui()
{
	previous_keys = 0;
	up1_last_toggle = 2;
	up2_last_toggle = 2;
	down1_last_toggle = 2;
	down2_last_toggle = 2;
	ok_last_toggle = 2;
	osd_alpha = 0;
	osd_timer = OSD_DURATION;

	patchlist_n = 0;
	patchlist_sel = 0;
	patchlist_page = 0;
	patchlist_pending = -1;

	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	fatfs_list_files(lscb, NULL);
	fatfs_done();

	patchlist_maxpage = (patchlist_n+3)/4 - 1;
	patchlist_maxsel = patchlist_n % 4;
	if(patchlist_maxsel == 0)
		patchlist_maxsel = 4;
	
	if(patchlist_n > 0)
		start_patch_from_list(0);

	draw_user_area();
}

void osd_service()
{
	if(patchlist_pending != -1) {
		char buffer[8192];
		int size;
		int n;

		n = patchlist_pending;
		patchlist_pending = -1;
		if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
		if(!fatfs_load(patchlist_filenames[n], buffer, sizeof(buffer), &size)) return;
		fatfs_done();
		buffer[size] = 0;

		renderer_start(buffer);
	}
}

int osd_fill_blit_td(struct tmu_td *td, tmu_callback callback, void *user)
{
	unsigned int keys;
	unsigned int new_keys;

	/* handle pushbuttons */
	keys = CSR_GPIO_IN & (GPIO_BTN1|GPIO_BTN2|GPIO_BTN3);
	new_keys = keys & ~previous_keys;
	previous_keys = keys;

	if(new_keys)
		process_keys(new_keys);

	/* handle IR remote */
	if(irq_pending() & IRQ_IR) {
		unsigned int r;
		int toggle;
		int cmd;

		r = CSR_RC5_RX;
		irq_ack(IRQ_IR);
		toggle = (r & 0x0800) >> 11;
		cmd = r & 0x003f;
		switch(cmd) {
			case 16:
				if(up1_last_toggle != toggle) {
					up1_last_toggle = toggle;
					process_keys(GPIO_BTN1);
				}
				break;
			case 32:
				if(up2_last_toggle != toggle) {
					up2_last_toggle = toggle;
					process_keys(GPIO_BTN1);
				}
				break;
			case 17:
				if(down1_last_toggle != toggle) {
					down1_last_toggle = toggle;
					process_keys(GPIO_BTN3);
				}
				break;
			case 33:
				if(down2_last_toggle != toggle) {
					down2_last_toggle = toggle;
					process_keys(GPIO_BTN3);
				}
				break;
			case 12:
				if(ok_last_toggle != toggle) {
					ok_last_toggle = toggle;
					process_keys(GPIO_BTN2);
				}
				break;
		}
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


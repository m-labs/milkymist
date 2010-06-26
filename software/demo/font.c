/*
 * Milkymist VJ SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * Copyright (C) 2002-2009 Norman Feske <norman.feske@genode-labs.com>
 * Genode Labs, Feske & Helmuth Systementwicklung GbR
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

#include "color.h"

#include "font.h"

struct tff_file_hdr {
	unsigned int otab[256];   /* glyph offset table   */
	unsigned int wtab[256];   /* glyph width table    */
	unsigned int img_w;       /* width of font image  */
	unsigned int img_h;       /* height of font image */
};

void font_init_context(struct font_context *ctx, unsigned char *font, unsigned short *fb, int fb_w, int fb_h)
{
	ctx->font = font;
	ctx->fb = fb;
	ctx->fb_w = fb_w;
	ctx->fb_h = fb_h;
}

static void draw_pixel(struct font_context *ctx, int x, int y, unsigned char i)
{
	if(x < 0) return;
	if(x >= ctx->fb_w) return;
	if(y < 0) return;
	if(y >= ctx->fb_h) return;
	ctx->fb[x+y*ctx->fb_w] = MAKERGB565(i >> 3, i >> 2, i >> 3);
}

static unsigned int i2u32(unsigned int *src)
{
	unsigned char *a = ((unsigned char *)src);
	unsigned char *b = ((unsigned char *)src) + 1;
	unsigned char *c = ((unsigned char *)src) + 2;
	unsigned char *d = ((unsigned char *)src) + 3;
	return ((unsigned int)(*a))      + (((unsigned int)(*b))<<8)
	    + (((unsigned int)(*c))<<16) + (((unsigned int)(*d))<<24);
}

int font_draw_char(struct font_context *ctx, int x, int y, unsigned char c)
{
	struct tff_file_hdr *tff = (struct tff_file_hdr *)ctx->font;
	unsigned char *font_img = ctx->font + sizeof(struct tff_file_hdr);
	int w, h;
	int fw;
	
	int dx, dy;

	w = i2u32(&tff->wtab[c]);
	h = i2u32(&tff->img_h);
	fw = i2u32(&tff->img_w);
	font_img += i2u32(&tff->otab[c]);

	for(dy=0;dy<h;dy++)
		for(dx=0;dx<w;dx++)
			draw_pixel(ctx, x+dx, y+dy, font_img[dx+dy*fw]);
	return w;
}

void font_draw_string(struct font_context *ctx, int x, int y, char *str)
{
	while(*str) {
		x += font_draw_char(ctx, x, y, (unsigned char)(*str));
		str++;
	}
}


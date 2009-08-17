/*
 * Line drawing code. Based on GD (http://www.boutell.com/gd)
 * adapted to Milkymist by Sebastien Bourdeauducq
 */

#ifndef __LINE_H
#define __LINE_H

struct line_context {
	unsigned short *framebuffer;
	unsigned int hres, vres;

	unsigned int dash_size;
	unsigned int thickness;
	int additive;
	unsigned int alpha;
	unsigned short int color;
};

void line_init_context(struct line_context *ctx, unsigned short int *framebuffer, unsigned int hres, unsigned int vres);
void line(struct line_context *ctx, int x1, int y1, int x2, int y2);

#endif /* __LINE_H */

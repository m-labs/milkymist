/*
 * Line drawing code. Based on GD (http://www.boutell.com/gd)
 * adapted to Milkymist by Sebastien Bourdeauducq
 */

#include <stdlib.h>
#include <math.h>

#include "color.h"
#include "line.h"

void line_init_context(struct line_context *ctx, unsigned short int *framebuffer, unsigned int hres, unsigned int vres)
{
	ctx->framebuffer = framebuffer;
	ctx->hres = hres;
	ctx->vres = vres;

	ctx->dash_size = 0;
	ctx->thickness = 1;
	ctx->additive = 0;
	ctx->alpha = 64;
	ctx->color = 0xFFFF;
}

typedef void (*pixelfun)(struct line_context *ctx, unsigned int x, unsigned int y);

static void setpixel_additive_alpha(struct line_context *ctx, unsigned int x, unsigned int y)
{
	unsigned int cs, cd;
	unsigned int r, g, b;

	if((x < 0)||(y < 0)||(x >= ctx->hres)||(y >= ctx->vres)) return;
	cd = ctx->framebuffer[y*ctx->hres+x];
	cs = ctx->color;
	r = (GETR(cs)*ctx->alpha >> 6) + GETR(cd);
	g = (GETG(cs)*ctx->alpha >> 6) + GETG(cd);
	b = (GETB(cs)*ctx->alpha >> 6) + GETB(cd);
	/* Saturate in case of overflow */
	if(r > 31) r = 31;
	if(g > 63) g = 63;
	if(b > 31) b = 31;
	ctx->framebuffer[y*ctx->hres+x] = MAKERGB565(r, g, b);
}

static void setpixel_additive_noalpha(struct line_context *ctx, unsigned int x, unsigned int y)
{
	unsigned int cs, cd;
	unsigned int r, g, b;

	if((x < 0)||(y < 0)||(x >= ctx->hres)||(y >= ctx->vres)) return;
	cd = ctx->framebuffer[y*ctx->hres+x];
	cs = ctx->color;
	r = GETR(cs) + GETR(cd);
	g = GETG(cs) + GETG(cd);
	b = GETB(cs) + GETB(cd);
	/* Saturate in case of overflow */
	if(r > 31) r = 31;
	if(g > 63) g = 63;
	if(b > 31) b = 31;
	ctx->framebuffer[y*ctx->hres+x] = MAKERGB565(r, g, b);
}

static void setpixel_alpha(struct line_context *ctx, unsigned int x, unsigned int y)
{
	unsigned int cs, cd;
	unsigned int r, g, b;

	if((x < 0)||(y < 0)||(x >= ctx->hres)||(y >= ctx->vres)) return;
	cd = ctx->framebuffer[y*ctx->hres+x];
	cs = ctx->color;
	r = (GETR(cs)*ctx->alpha >> 6) + (GETR(cd)*(64-ctx->alpha) >> 6);
	g = (GETG(cs)*ctx->alpha >> 6) + (GETG(cd)*(64-ctx->alpha) >> 6);
	b = (GETB(cs)*ctx->alpha >> 6) + (GETB(cd)*(64-ctx->alpha) >> 6);
	ctx->framebuffer[y*ctx->hres+x] = MAKERGB565(r, g, b);
}

static void setpixel_noalpha(struct line_context *ctx, unsigned int x, unsigned int y)
{
	if((x < 0)||(y < 0)||(x >= ctx->hres)||(y >= ctx->vres)) return;
	ctx->framebuffer[y*ctx->hres+x] = ctx->color;
}

static pixelfun get_pixelfun(struct line_context *ctx)
{
	if(ctx->additive) {
		if(ctx->alpha >= 64)
			return setpixel_additive_noalpha;
		else
			return setpixel_additive_alpha;
	} else {
		if(ctx->alpha >= 64)
			return setpixel_noalpha;
		else
			return setpixel_alpha;
	}
}

void hline(struct line_context *ctx, int y, int x1, int x2)
{
	pixelfun setpixel = get_pixelfun(ctx);
	int ymin = y - (ctx->thickness >> 1);
	int ymax = ymin + ctx->thickness - 1;
	if(ymin < 0) ymin = 0;
	if(ymax >= ctx->vres) ymax = ctx->vres-1;
	if(x2 < x1) {
		int t = x2;
		x2 = x1;
		x1 = t;
	}
	for(y=ymin;y<=ymax;y++) {
		int x;
		for(x = x1; x <= x2; x++)
			setpixel(ctx, x, y);
	}
}

void vline(struct line_context *ctx, int x, int y1, int y2)
{
	pixelfun setpixel = get_pixelfun(ctx);
	int xmin = x - (ctx->thickness >> 1);
	int xmax = xmin + ctx->thickness - 1;
	if(xmin < 0) xmin = 0;
	if(xmax >= ctx->hres) xmax = ctx->hres-1;
	if(y2 < y1) {
		int t = y1;
		y1 = y2;
		y2 = t;
	}
	for(x=xmin;x<=xmax;x++) {
		int y;
		for(y = y1; y <= y2; y++)
			setpixel(ctx, x, y);
	}
}

static void line_plain(struct line_context *ctx, int x1, int y1, int x2, int y2)
{
	pixelfun setpixel;
	int dx, dy, incr1, incr2, d, x, y, xend, yend, xdirflag, ydirflag;
	int wid;
	int w, wstart;
	int thick;

	thick = ctx->thickness;

	dx = abs(x2 - x1);
	dy = abs(y2 - y1);

	if(dx == 0) {
		vline(ctx, x1, y1, y2);
		return;
	} else if(dy == 0) {
		hline(ctx, y1, x1, x2);
		return;
	}

	setpixel = get_pixelfun(ctx);
	if(dy <= dx) {
		/* More-or-less horizontal. use wid for vertical stroke */
		/* Doug Claar: watch out for NaN in atan2 (2.0.5) */
		if((dx == 0) && (dy == 0)) {
			wid = 1;
		} else {
			/* 2.0.12: Michael Schwartz: divide rather than multiply;
			 * TBB: but watch out for /0!
			 */
			float ac = cosf(atan2f (dy, dx));
			if(ac != 0) {
				wid = thick / ac;
			} else {
				wid = 1;
			}
			if(wid == 0) {
				wid = 1;
			}
		}
		d = 2 * dy - dx;
		incr1 = 2 * dy;
		incr2 = 2 * (dy - dx);
		if(x1 > x2) {
			x = x2;
			y = y2;
			ydirflag = (-1);
			xend = x1;
		} else {
			x = x1;
			y = y1;
			ydirflag = 1;
			xend = x2;
		}

		/* Set up line thickness */
		wstart = y - (wid >> 1);
		for(w = wstart; w < wstart + wid; w++)
			setpixel(ctx, x, w);

		if(((y2 - y1) * ydirflag) > 0) {
			while(x < xend) {
				x++;
				if(d < 0) {
					d += incr1;
				} else {
					y++;
					d += incr2;
				}
				wstart = y - (wid >> 1);
				for(w = wstart; w < wstart + wid; w++)
					setpixel(ctx, x, w);
			}
		} else {
			while(x < xend) {
				x++;
				if(d < 0) {
					d += incr1;
				} else {
					y--;
					d += incr2;
				}
				wstart = y - (wid >> 1);
				for(w = wstart; w < wstart + wid; w++)
					setpixel(ctx, x, w);
			}
		}
	} else {
		/* More-or-less vertical. use wid for horizontal stroke */
		/* 2.0.12: Michael Schwartz: divide rather than multiply;
			TBB: but watch out for /0! */
		float as = sinf (atan2f (dy, dx));
		if(as != 0) {
			wid = thick / as;
		} else {
			wid = 1;
		}
		if(wid == 0)
		wid = 1;

		d = 2 * dx - dy;
		incr1 = 2 * dx;
		incr2 = 2 * (dx - dy);
		if(y1 > y2) {
			y = y2;
			x = x2;
			yend = y1;
			xdirflag = (-1);
		} else {
			y = y1;
			x = x1;
			yend = y2;
			xdirflag = 1;
		}

		/* Set up line thickness */
		wstart = x - (wid >> 1);
		for(w = wstart; w < wstart + wid; w++)
		setpixel(ctx, w, y);

		if(((x2 - x1) * xdirflag) > 0) {
			while(y < yend) {
				y++;
				if(d < 0) {
					d += incr1;
				} else {
					x++;
					d += incr2;
				}
				wstart = x - (wid >> 1);
				for(w = wstart; w < wstart + wid; w++)
					setpixel(ctx, w, y);
			}
		} else {
			while(y < yend) {
				y++;
				if(d < 0) {
					d += incr1;
				} else {
					x--;
					d += incr2;
				}
				wstart = x - (wid >> 1);
				for(w = wstart; w < wstart + wid; w++)
					setpixel(ctx, w, y);
			}
		}
	}
}

static void dashed_set(struct line_context *ctx, int x, int y, int *onP, int *dashStepP, int wid, int vert)
{
	pixelfun setpixel = get_pixelfun(ctx);
	int dashStep = *dashStepP;
	int on = *onP;
	int w, wstart, wend;

	dashStep++;
	if(dashStep == ctx->dash_size) {
		dashStep = 0;
		on = !on;
	}
	if(on) {
		if(vert) {
			wstart = y - (wid >> 1);
			wend = wstart + wid;
			for(w = wstart; w < wend; w++)
				setpixel(ctx, x, w);
		} else {
			wstart = x - (wid >> 1);
			wend = wstart + wid;
			for(w = wstart; w < wend; w++)
				setpixel(ctx, w, y);
		}
	}
	*dashStepP = dashStep;
	*onP = on;
}

static void line_dashed(struct line_context *ctx, int x1, int y1, int x2, int y2)
{
	int dx, dy, incr1, incr2, d, x, y, xend, yend, xdirflag, ydirflag;
	int dashStep = 0;
	int on = 1;
	int wid;
	int vert;
	int thick = ctx->thickness;

	dx = abs(x2 - x1);
	dy = abs(y2 - y1);
	if(dy <= dx) {
		/* More-or-less horizontal. use wid for vertical stroke */
		/* 2.0.12: Michael Schwartz: divide rather than multiply;
		 * TBB: but watch out for /0!
		 */
		float as = cosf (atan2f (dy, dx));
		if(as != 0) {
			wid = thick / as;
		} else {
			wid = 1;
		}
		vert = 1;

		d = 2 * dy - dx;
		incr1 = 2 * dy;
		incr2 = 2 * (dy - dx);
		if(x1 > x2) {
			x = x2;
			y = y2;
			ydirflag = (-1);
			xend = x1;
		} else {
			x = x1;
			y = y1;
			ydirflag = 1;
			xend = x2;
		}
		dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
		if(((y2 - y1) * ydirflag) > 0) {
			while(x < xend) {
				x++;
				if(d < 0) {
					d += incr1;
				} else {
					y++;
					d += incr2;
				}
				dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
			}
		} else {
			while(x < xend) {
				x++;
				if(d < 0)
				{
					d += incr1;
				} else {
					y--;
					d += incr2;
				}
				dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
			}
		}
	} else {
		/* 2.0.12: Michael Schwartz: divide rather than multiply;
		 * TBB: but watch out for /0!
		 */
		float as = sinf (atan2f (dy, dx));
		if(as != 0) {
			wid = thick / as;
		} else {
			wid = 1;
		}
		vert = 0;

		d = 2 * dx - dy;
		incr1 = 2 * dx;
		incr2 = 2 * (dx - dy);
		if(y1 > y2) {
			y = y2;
			x = x2;
			yend = y1;
			xdirflag = (-1);
		} else {
			y = y1;
			x = x1;
			yend = y2;
			xdirflag = 1;
		}
		dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
		if(((x2 - x1) * xdirflag) > 0) {
			while (y < yend) {
				y++;
				if(d < 0) {
					d += incr1;
				} else {
					x++;
					d += incr2;
				}
				dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
			}
		} else {
			while (y < yend) {
				y++;
				if(d < 0) {
					d += incr1;
				} else {
					x--;
					d += incr2;
				}
				dashed_set(ctx, x, y, &on, &dashStep, wid, vert);
			}
		}
	}
}

/* clip_1d function from GD */
static int clip_1d(int *x0, int *y0, int *x1, int *y1, int mindim, int maxdim)
{
	float m; /* gradient of line */

	if(*x0 < mindim) { /* start of line is left of window */
		if (*x1 < mindim) /* as is the end, so the line never cuts the window */
			return 0;
		m = (*y1 - *y0) / (float) (*x1 - *x0); /* calculate the slope of the line */
		/* adjust x0 to be on the left boundary (ie to be zero), and y0 to match */
		*y0 -= m * (*x0 - mindim);
		*x0 = mindim;
		/* now, perhaps, adjust the far end of the line as well */
		if(*x1 > maxdim) {
			*y1 += m * (maxdim - *x1);
			*x1 = maxdim;
		}
		return 1;
	}
	if(*x0 > maxdim) { /* start of line is right of window - complement of above */
		if(*x1 > maxdim) /* as is the end, so the line misses the window */
			return 0;
		m = (*y1 - *y0) / (float) (*x1 - *x0); /* calculate the slope of the line */
		*y0 += m * (maxdim - *x0); /* adjust so point is on the right boundary */
		*x0 = maxdim;
		/* now, perhaps, adjust the end of the line */
		if(*x1 < mindim) {
			*y1 -= m * (*x1 - mindim);
			*x1 = mindim;
		}
		return 1;
	}
	/* the final case - the start of the line is inside the window */
	if(*x1 > maxdim) { /* other end is outside to the right */
		m = (*y1 - *y0) / (float) (*x1 - *x0); /* calculate the slope of the line */
		*y1 += m * (maxdim - *x1);
		*x1 = maxdim;
		return 1;
	}
	if(*x1 < mindim) { /* other end is outside to the left */
		m = (*y1 - *y0) / (float) (*x1 - *x0); /* calculate the slope of the line */
		*y1 -= m * (*x1 - mindim);
		*x1 = mindim;
		return 1;
	}
	/* only get here if both points are inside the window */
	return 1;
}


void line(struct line_context *ctx, int x1, int y1, int x2, int y2)
{
	if(clip_1d(&x1, &y1, &x2, &y2, 0, ctx->hres) == 0)
		return;
	if(clip_1d(&y1, &x1, &y2, &x2, 0, ctx->vres) == 0)
		return;
	if(ctx->dash_size != 0)
		line_dashed(ctx, x1, y1, x2, y2);
	else
		line_plain(ctx, x1, y1, x2, y2);
}

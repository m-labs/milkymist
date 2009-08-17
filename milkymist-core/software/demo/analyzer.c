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

#include "analyzer.h"

#include "bandfilters.h"

void analyzer_init(struct analyzer_state *sc)
{
	int i;

	for(i=0;i<2*BANDFILTER_NCOEF;i++)
		sc->last_samples[i] = 0;
	sc->spointer = BANDFILTER_NCOEF-1;
	sc->decimation = 0;

	sc->bass_acc = 0;
	sc->mid_acc = 0;
	sc->treb_acc = 0;
}

void analyzer_put_sample(struct analyzer_state *sc, int left, int right)
{
	int sample;

	sample = (left + right) >> 1;
	sc->last_samples[sc->spointer                 ] = sample;
	sc->last_samples[sc->spointer+BANDFILTER_NCOEF] = sample;

	sc->decimation++;
	if(sc->decimation >= BANDFILTER_DECIMATION) {
		int r_bass, r_mid, r_treb;
		int p;
		int i;

		r_bass = 0;
		r_mid = 0;
		r_treb = 0;

		p = sc->spointer;
		for(i=0;i<BANDFILTER_NCOEF;i++) {
			r_bass += (bass_filter[i]*sc->last_samples[p+i]) >> 15;
			r_mid += (mid_filter[i]*sc->last_samples[p+i]) >> 15;
			r_treb += (treb_filter[i]*sc->last_samples[p+i]) >> 15;
		}

		sc->bass_acc += (r_bass*r_bass) >> 15;
		sc->mid_acc += (r_mid*r_mid) >> 15;
		sc->treb_acc += (r_treb*r_treb) >> 15;

		sc->decimation = 0;
	}

	sc->spointer--;
	if(sc->spointer == -1) sc->spointer = BANDFILTER_NCOEF-1;
}

int analyzer_get_bass(struct analyzer_state *sc)
{
	int r;
	r = sc->bass_acc;
	sc->bass_acc = 0;
	return r;
}

int analyzer_get_mid(struct analyzer_state *sc)
{
	int r;
	r = sc->mid_acc;
	sc->mid_acc = 0;
	return r;
}

int analyzer_get_treb(struct analyzer_state *sc)
{
	int r;
	r = sc->treb_acc;
	sc->treb_acc = 0;
	return r;
}

/*
 * Milkymist SoC (Software)
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

#ifndef __ANALYZER_H
#define __ANALYZER_H

#define BANDFILTER_NCOEF	(128)
#define BANDFILTER_DECIMATION	(8)

struct analyzer_state {
	int last_samples[BANDFILTER_NCOEF*2];
	int spointer;
	int decimation;
	int bass_acc;
	int mid_acc;
	int treb_acc;
};

void analyzer_init(struct analyzer_state *sc);
void analyzer_put_sample(struct analyzer_state *sc, int left, int right);
int analyzer_get_bass(struct analyzer_state *sc);
int analyzer_get_mid(struct analyzer_state *sc);
int analyzer_get_treb(struct analyzer_state *sc);

#endif /* __ANALYZER_H */

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

#ifndef __HAL_TIME_H
#define __HAL_TIME_H

struct timestamp {
	int sec;
	int usec;
};

void time_init(void);
void time_isr(void);

void time_get(struct timestamp *ts);

void time_add(struct timestamp *dest, struct timestamp *delta);
void time_diff(struct timestamp *dest, struct timestamp *t1, struct timestamp *t0);

void time_tick(void); /* provided by app */

#endif /* __HAL_TIME_H */

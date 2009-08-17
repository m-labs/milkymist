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

#ifndef __TIME_H
#define __TIME_H

struct timestamp {
	int sec;
	int usec;
};

void time_init();
void time_isr();

void time_get(struct timestamp *ts);

void time_add(struct timestamp *dest, struct timestamp *delta);
void time_diff(struct timestamp *dest, struct timestamp *t1, struct timestamp *t0);

#endif /* __TIME_H */

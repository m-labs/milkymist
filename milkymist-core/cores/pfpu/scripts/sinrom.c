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

#include <stdio.h>
#include <math.h>

#define PI 3.14159265358f
#define N 2048

int main(int argc, char *argv[])
{
	union {
		float f;
		unsigned int i;
	} u;
	int i;
	
	for(i=0;i<N;i++) {
		u.f = sinf((PI*(float)i)/(2.0f*N));
		printf("%08x\n", u.i);
	}
	return 0;
}

/*
 * Milkymist SoC
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

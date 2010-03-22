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

#include <stdio.h>

#include <fpvm/fpvm.h>

int main(int argc, char *argv)
{
	struct fpvm_fragment frag;

	printf("libFPVM version: %s\n\n", fpvm_version());

	printf("******* SIMPLE TEST *******\n");
	fpvm_init(&frag);
	fpvm_assign(&frag, "Xo", "(Xi+1)*5.8");
	fpvm_assign(&frag, "Yo", "(Yi+3)*1.4");
	fpvm_finalize(&frag);
	fpvm_dump(&frag);

	printf("\n******* TEST 2 *******\n");
	fpvm_init(&frag);
	printf("Variable foo bound to R%04d\n", fpvm_bind(&frag, "foo"));
	fpvm_set_xin(&frag, "x");
	fpvm_set_yin(&frag, "y");
	fpvm_set_xout(&frag, "dx");
	fpvm_set_yout(&frag, "dy");
	fpvm_assign(&frag, "bar", "foo+65+x");
	fpvm_assign(&frag, "dx", "(y-6)*cos((45+x)*sin(4*bar))");
	fpvm_assign(&frag, "dx", "troll*bar");
	fpvm_assign(&frag, "dy", "(troll+x)*above(bar, 6)");
	fpvm_finalize(&frag);
	fpvm_dump(&frag);
	
	return 0;
}

/*
 * Milkymist SoC (Software)
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
#include <hw/pfpu.h>
#include <fpvm/fpvm.h>

#include <fpvm/pfpu.h>

int pfpu_get_latency(int opcode)
{
	switch(opcode) {
		case PFPU_OPCODE_FADD: return PFPU_LATENCY_FADD;
		case PFPU_OPCODE_FSUB: return PFPU_LATENCY_FSUB;
		case PFPU_OPCODE_FMUL: return PFPU_LATENCY_FMUL;
		case PFPU_OPCODE_FABS: return PFPU_LATENCY_FABS;
		case PFPU_OPCODE_F2I: return PFPU_LATENCY_F2I;
		case PFPU_OPCODE_I2F: return PFPU_LATENCY_I2F;
		case PFPU_OPCODE_VECTOUT: return PFPU_LATENCY_VECTOUT;
		case PFPU_OPCODE_SIN: return PFPU_LATENCY_SIN;
		case PFPU_OPCODE_COS: return PFPU_LATENCY_COS;
		case PFPU_OPCODE_ABOVE: return PFPU_LATENCY_ABOVE;
		case PFPU_OPCODE_EQUAL: return PFPU_LATENCY_EQUAL;
		case PFPU_OPCODE_COPY: return PFPU_LATENCY_COPY;
		case PFPU_OPCODE_IF: return PFPU_LATENCY_IF;
		case PFPU_OPCODE_TSIGN: return PFPU_LATENCY_TSIGN;
		case PFPU_OPCODE_QUAKE: return PFPU_LATENCY_QUAKE;
		default: return -1;
	}
}

void pfpu_dump(unsigned int *code, unsigned int n)
{
	int i;
	int exits;
	pfpu_instruction *prog = (pfpu_instruction *)code;

	exits = 0;
	for(i=0;i<n;i++) {
		int latency;

		printf("%04d: ", i);

		fpvm_print_opcode(pfpu_to_fpvm(prog[i].i.opcode));

		switch(fpvm_get_arity(pfpu_to_fpvm(prog[i].i.opcode))) {
			case 3:
			case 2:
				printf("R%03d,R%03d ", prog[i].i.opa, prog[i].i.opb);
				break;
			case 1:
				printf("R%03d      ", prog[i].i.opa);
				break;
			case 0:
				printf("          ");
		}

		latency = pfpu_get_latency(prog[i].i.opcode);
		if(prog[i].i.opcode != PFPU_OPCODE_NOP)
			printf("<L=%d E=%04d> ", latency, i+latency);
		else
			printf("             ");

		if(prog[i].i.dest != 0) {
			printf("-> R%03d", prog[i].i.dest);
			exits++;
		}

		printf("\n");
	}
	if(n > 0)
		printf("Efficiency: %d%%\n", 100*exits/n);
}

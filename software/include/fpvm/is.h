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

#ifndef __FPVM_IS_H
#define __FPVM_IS_H

#define FPVM_OPCODE_NOP		(0x0)
#define FPVM_OPCODE_FADD	(0x1)
#define FPVM_OPCODE_FSUB	(0x2)
#define FPVM_OPCODE_FMUL	(0x3)
#define FPVM_OPCODE_FABS	(0x4)
#define FPVM_OPCODE_F2I		(0x5)
#define FPVM_OPCODE_I2F		(0x6)
#define FPVM_OPCODE_VECTOUT	(0x7)
#define FPVM_OPCODE_SIN		(0x8)
#define FPVM_OPCODE_COS		(0x9)
#define FPVM_OPCODE_ABOVE	(0xa)
#define FPVM_OPCODE_EQUAL	(0xb)
#define FPVM_OPCODE_COPY	(0xc)
#define FPVM_OPCODE_IF		(0xd)
#define FPVM_OPCODE_TSIGN	(0xe)
#define FPVM_OPCODE_QUAKE	(0xf)

#define FPVM_TRIG_CONV		(8192.0/(2.0*3.14159265358))

#define FPVM_REG_X		(0)
#define FPVM_REG_Y		(1)
#define FPVM_REG_IFB		(2)

struct fpvm_instruction {
	int opa;
	int opb;
	int opcode;
	int dest;
};

#endif /* __FPVM_IS_H */

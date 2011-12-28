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

#ifndef __FPVM_PFPU_H
#define __FPVM_PFPU_H

#define fpvm_to_pfpu(x) (x)
#define pfpu_to_fpvm(x) (x)

int pfpu_get_latency(int opcode);
void pfpu_dump(const unsigned int *code, unsigned int n);

#endif /* __FPVM_PFPU_H */

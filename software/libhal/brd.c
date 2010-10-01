/*
 * Milkymist VJ SoC (Software)
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

#include <stdlib.h>
#include <stdio.h>
#include <board.h>
#include <hw/sysctl.h>

#include <hal/brd.h>

const struct board_desc *brd_desc;

void brd_init()
{
	int rev;
	
	brd_desc = get_board_desc();

	if(brd_desc == NULL) {
		printf("BRD: Running on unknown board (ID=0x%08x), startup aborted.\n", CSR_SYSTEM_ID);
		while(1);
	}
	rev = get_pcb_revision();
	printf("BRD: Running on %s (PCB revision %d)\n", brd_desc->name, rev);
	if(rev > 1)
		printf("BRD: Unsupported PCB revision, please upgrade!\n");
}

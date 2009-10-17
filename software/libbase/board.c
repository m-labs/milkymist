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

#include <hw/sysctl.h>
#include <stdlib.h>
#include <board.h>

static const struct board_desc boards[3] = {
	{
		.id = 0x58343031, /* X401 */
		.name = "Xilinx ML401 development board",
		.clk_frequency = 100000000,
		.sdram_size = 64,
		.ddr_clkphase = 0,
		.ddr_idelay = 0,
		.ddr_dqsdelay = 244
	},
	{
		.id = 0x53334145, /* S3AE */
		.name = "Avnet Spartan-3A evaluation kit",
		.clk_frequency = 64000000,
		.sdram_size = 0
	},
	{
		.id = 0x4D4F4E45, /* MONE */
		.name = "Milkymist One",
		.clk_frequency = 80000000,
		.sdram_size = 64,
		.ddr_clkphase = 0,
		.ddr_idelay = 0,
		.ddr_dqsdelay = 244
	},
};

const struct board_desc *get_board_desc_id(unsigned int id)
{
	unsigned int i;
	
	for(i=0;i<sizeof(boards)/sizeof(boards[0]);i++)
		if(boards[i].id == id)
			return &boards[i];
	return NULL;
}

const struct board_desc *get_board_desc()
{
	return get_board_desc_id(CSR_SYSTEM_ID);
}


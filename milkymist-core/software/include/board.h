/*
 * Milkymist VJ SoC (Software support library)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 3 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 */

#ifndef __BOARD_H
#define __BOARD_H

#define BOARD_NAME_LEN 32

struct board_desc {
	unsigned int id;
	char name[BOARD_NAME_LEN];
	unsigned int clk_frequency;
	unsigned int sdram_size;
	unsigned int ddr_clkphase;
	unsigned int ddr_idelay;
	unsigned int ddr_dqsdelay;
};

const struct board_desc *get_board_desc_id(unsigned int id);
const struct board_desc *get_board_desc();

#endif /* __BOARD_H */

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

#include <libc.h>
#include <console.h>
#include <board.h>

#include "brd.h"

const struct board_desc *brd_desc;

void brd_init()
{
	brd_desc = get_board_desc();
	if(brd_desc == NULL) {
		printf("BRD: Fatal error, unknown board\n");
		while(1);
	}
	printf("BRD: detected %s\n", brd_desc->name);
}

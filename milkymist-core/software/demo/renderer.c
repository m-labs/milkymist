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
#include <math.h>
#include <system.h>
#include <hw/sysctl.h>
#include <hw/uart.h>
#include <hw/ac97.h>
#include <hw/tmu.h>

#include "parser_helper.h"
#include "pfpu.h"
#include "vga.h"
#include "eval.h"
#include "apipe.h"
#include "renderer.h"

unsigned int renderer_hmeshlast;
unsigned int renderer_vmeshlast;
unsigned int renderer_texsize;

void renderer_init()
{
	renderer_hmeshlast = 32;
	renderer_vmeshlast = 24;
	renderer_texsize = 512;
	printf("RDR: renderer ready (mesh:%dx%d, texsize:%d)\n", renderer_hmeshlast, renderer_vmeshlast, renderer_texsize);
}

static struct eval_state eval;

int renderer_start(char *preset_code)
{
	struct preset *ast;

	ast = generate_ast(preset_code);
	if(!ast) return 0;
	printf("RDR: preset parsing successful\n");

	eval_init(&eval, renderer_hmeshlast, renderer_vmeshlast, vga_hres, vga_vres);
	if(!eval_load_preset(&eval, ast)) return 0;
	printf("RDR: preset compilation successful\n");
	free_ast(ast);

	apipe_start(&eval);

	return 1;
}

void renderer_stop()
{
	apipe_stop();
}

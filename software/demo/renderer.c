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
#include <math.h>
#include <system.h>

#include <hal/pfpu.h>
#include <hal/vga.h>

#include "parser_helper.h"
#include "eval.h"
#include "apipe.h"
#include "renderer.h"

int renderer_hmeshlast;
int renderer_vmeshlast;
int renderer_texsize;

void renderer_init()
{
	renderer_hmeshlast = 32;
	renderer_vmeshlast = 32;
	renderer_texsize = 512;
	printf("RDR: renderer ready (mesh:%dx%d, texsize:%d)\n", renderer_hmeshlast, renderer_vmeshlast, renderer_texsize);
}

static struct eval_state eval;

int renderer_start(char *preset_code)
{
	struct preset *ast;

	ast = generate_ast(preset_code);
	if(!ast) {
		printf("RDR: preset parsing failed\n");
		return 0;
	}

	eval_init(&eval, renderer_hmeshlast, renderer_vmeshlast, renderer_texsize, renderer_texsize);
	if(!eval_load_preset(&eval, ast)) {
		printf("RDR: preset loading failed\n");
		return 0;
	}
	
	free_ast(ast);

	apipe_start(&eval);

	return 1;
}

void renderer_stop()
{
	apipe_stop();
}

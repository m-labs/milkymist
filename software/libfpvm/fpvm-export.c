/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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
#include <fpvm/ast.h>

#include "unique.h"
#include "parser_helper.h"


/* @@@ move later */
int fpvm_do_assign(struct fpvm_fragment *fragment, const char *dest,
    struct ast_node *n);
void fpvm_do_init(struct fpvm_fragment *fragment, int vector_mode);


void fpvm_init(struct fpvm_fragment *fragment, int vector_mode)
{
	/*
	 * We need to pass these through unique() because fpvm_assign does
	 * the same. Once things are in Flickernoise, we can get rid of these
	 * calls to unique().
	 */

	_Xi = unique("_Xi");
	_Xo = unique("_Xo");
	_Yi = unique("_Yi");
	_Yo = unique("_Yo");
	fpvm_do_init(fragment, vector_mode);
}


int fpvm_assign(struct fpvm_fragment *fragment, const char *dest,
    const char *expr)
{
	struct ast_node *n;
	int res;

	n = fpvm_parse(expr);
	if(n == NULL) {
		snprintf(fragment->last_error, FPVM_MAXERRLEN, "Parse error");
		return 0;
	}

	dest = unique(dest);

	res = fpvm_do_assign(fragment, dest, n);
	fpvm_parse_free(n);

	return res;
}

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

#ifndef __RENDERER_H
#define __RENDERER_H

extern int renderer_on;

extern int renderer_hmeshlast;
extern int renderer_vmeshlast;
extern int renderer_texsize;

void renderer_init();
int renderer_start(char *patch_code);
void renderer_istart();
int renderer_iinput(char *line);
int renderer_idone();
void renderer_stop();

#endif

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

#ifndef __CFFAT_H
#define __CFFAT_H

typedef int (*cffat_dir_callback)(const char *, const char *, void *);

int cffat_init();
int cffat_list_files(cffat_dir_callback cb, void *param);
int cffat_load(const char *filename, char *buffer, int size, int *realsize);
void cffat_done();

#endif /* __CFFAT_H */

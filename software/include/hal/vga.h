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

#ifndef __HAL_VGA_H
#define __HAL_VGA_H

extern int vga_hres;
extern int vga_vres;
extern int vga_blanked;
extern unsigned short int *vga_frontbuffer;
extern unsigned short int *vga_backbuffer;
extern unsigned short int *vga_lastbuffer;

enum {
	VGA_MODE_640_480 = 0,
	VGA_MODE_800_600,
	VGA_MODE_1024_768
};

void vga_init(int blanked);
void vga_blank(void);
void vga_unblank(void);
void vga_swap_buffers(void);
void vga_set_console(int console);
int vga_get_console(void);
int vga_read_edid(char *buffer);
void vga_set_mode(int mode);

#endif /* __HAL_VGA_H */

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

#ifndef __HAL_VGA_H
#define __HAL_VGA_H

extern int vga_hres;
extern int vga_vres;
extern unsigned short int *vga_frontbuffer;
extern unsigned short int *vga_backbuffer;
extern unsigned short int *vga_lastbuffer;

void vga_init();
void vga_disable();
void vga_swap_buffers();

#endif /* __HAL_VGA_H */

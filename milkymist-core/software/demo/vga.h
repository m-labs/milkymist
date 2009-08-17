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

#ifndef __VGA_H
#define __VGA_H

extern unsigned int vga_hres;
extern unsigned int vga_vres;
extern unsigned short int *vga_frontbuffer;
extern unsigned short int *vga_backbuffer;
extern unsigned short int *vga_lastbuffer;

void vga_init();
void vga_disable();
void vga_swap_buffers();

#endif /* __VGA_H */

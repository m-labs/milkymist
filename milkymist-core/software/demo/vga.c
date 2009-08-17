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

#include <console.h>
#include <hw/vga.h>

/*
 * RGB565 framebuffers.
 * We use page flipping triple buffering as described on
 * http://en.wikipedia.org/wiki/Triple_buffering
 *
 * Buffers must be aligned to the start of an FML burst
 * which is 4x64 bits, that is, 256 bits, or 32 bytes.
 */
static unsigned short int framebufferA[640*480] __attribute__((aligned(32)));
static unsigned short int framebufferB[640*480] __attribute__((aligned(32)));
static unsigned short int framebufferC[640*480] __attribute__((aligned(32)));

unsigned int vga_hres;
unsigned int vga_vres;

unsigned short int *vga_frontbuffer; /* < buffer currently displayed (or request sent to HW) */
unsigned short int *vga_backbuffer;  /* < buffer currently drawn to, never read by HW */
unsigned short int *vga_lastbuffer;  /* < buffer displayed just before (or HW finishing last scan) */

void vga_init()
{
	vga_hres = 640;
	vga_vres = 480;
	
	vga_frontbuffer = framebufferA;
	vga_backbuffer = framebufferB;
	vga_lastbuffer = framebufferC;
	
	CSR_VGA_BASEADDRESS = (unsigned int)vga_frontbuffer;

	/* by default, VGA core puts out 640x480@60Hz */
	CSR_VGA_RESET = 0;

	printf("VGA: initialized at resolution %dx%d\n", vga_hres, vga_vres);
	printf("VGA: framebuffers at 0x%08x 0x%08x 0x%08x\n",
		(unsigned int)&framebufferA, (unsigned int)&framebufferB, (unsigned int)&framebufferC);
}

void vga_disable()
{
	CSR_VGA_RESET = VGA_RESET;
}

void vga_swap_buffers()
{
	unsigned short int *p;

	/*
	 * Make sure last buffer swap has been executed.
	 * Beware, DMA address registers of vgafb are incomplete
	 * (only LSBs are present) so don't compare them directly
	 * with CPU pointers.
	 */
	while(CSR_VGA_BASEADDRESS_ACT != CSR_VGA_BASEADDRESS);

	p = vga_frontbuffer;
	vga_frontbuffer = vga_backbuffer;
	vga_backbuffer = vga_lastbuffer;
	vga_lastbuffer = p;
	
	CSR_VGA_BASEADDRESS = (unsigned int)vga_frontbuffer;
}

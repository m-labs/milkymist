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

#include <stdio.h>
#include <hw/vga.h>

#include <hal/vga.h>

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

int vga_hres;
int vga_vres;

unsigned short int *vga_frontbuffer; /* < buffer currently displayed (or request sent to HW) */
unsigned short int *vga_backbuffer;  /* < buffer currently drawn to, never read by HW */
unsigned short int *vga_lastbuffer;  /* < buffer displayed just before (or HW finishing last scan) */

static int i2c_init();

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
	if(i2c_init())
		printf("VGA: DDC I2C bus initialized\n");
	else
		printf("VGA: DDC I2C bus initialization problem\n");
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

/* DDC */
int i2c_started;

static int i2c_init()
{
	unsigned int timeout;

	i2c_started = 0;
	CSR_VGA_DDC = VGA_DDC_SDC;
	/* Check the I2C bus is ready */
	timeout = 1000;
	while((timeout > 0) && (!(CSR_VGA_DDC & VGA_DDC_SDAIN))) timeout--;

	return timeout;
}

static void i2c_delay()
{
	unsigned int i;

	for(i=0;i<1000;i++) __asm__("nop");
}

/* I2C bit-banging functions from http://en.wikipedia.org/wiki/I2c */
static unsigned int i2c_read_bit()
{
	unsigned int bit;

	/* Let the slave drive data */
	CSR_VGA_DDC = 0;
	i2c_delay();
	CSR_VGA_DDC = VGA_DDC_SDC;
	i2c_delay();
	bit = CSR_VGA_DDC & VGA_DDC_SDAIN;
	i2c_delay();
	CSR_VGA_DDC = 0;
	return bit;
}

static void i2c_write_bit(unsigned int bit)
{
	if(bit) {
		CSR_VGA_DDC = VGA_DDC_SDAOE|VGA_DDC_SDAOUT;
	} else {
		CSR_VGA_DDC = VGA_DDC_SDAOE;
	}
	i2c_delay();
	/* Clock stretching */
	CSR_VGA_DDC |= VGA_DDC_SDC;
	i2c_delay();
	CSR_VGA_DDC &= ~VGA_DDC_SDC;
}

static void i2c_start_cond()
{
	if(i2c_started) {
		/* set SDA to 1 */
		CSR_VGA_DDC = VGA_DDC_SDAOE|VGA_DDC_SDAOUT;
		i2c_delay();
		CSR_VGA_DDC |= VGA_DDC_SDC;
		i2c_delay();
	}
	/* SCL is high, set SDA from 1 to 0 */
	CSR_VGA_DDC = VGA_DDC_SDAOE|VGA_DDC_SDC;
	i2c_delay();
	CSR_VGA_DDC = VGA_DDC_SDAOE;
	i2c_started = 1;
}

static void i2c_stop_cond()
{
	/* set SDA to 0 */
	CSR_VGA_DDC = VGA_DDC_SDAOE;
	i2c_delay();
	/* Clock stretching */
	CSR_VGA_DDC = VGA_DDC_SDAOE|VGA_DDC_SDC;
	/* SCL is high, set SDA from 0 to 1 */
	CSR_VGA_DDC = VGA_DDC_SDC;
	i2c_delay();
	i2c_started = 0;
}

static unsigned int i2c_write(unsigned char byte)
{
	unsigned int bit;
	unsigned int ack;

	for(bit = 0; bit < 8; bit++) {
		i2c_write_bit(byte & 0x80);
		byte <<= 1;
	}
	ack = !i2c_read_bit();
	return ack;
}

static unsigned char i2c_read(int ack)
{
	unsigned char byte = 0;
	unsigned int bit;

	for(bit = 0; bit < 8; bit++) {
		byte <<= 1;
		byte |= i2c_read_bit();
	}
	i2c_write_bit(!ack);
	return byte;
}

int vga_read_edid(char *buffer)
{
	int i;

	i2c_start_cond();
	if(!i2c_write(0xA0)) {
		printf("VGA: No ack for 0xA0 address\n");
		return 0;
	}
	if(!i2c_write(0x00)) {
		printf("VGA: No ack for EDID offset\n");
		return 0;
	}
	i2c_start_cond();
	if(!i2c_write(0xA1)) {
		printf("VGA: No ack for 0xA1 address\n");
		return 0;
	}
	
	for(i=0;i<255;i++)
		buffer[i] = i2c_read(1);
	buffer[255] = i2c_read(0);
	i2c_stop_cond();

	return 1;
}

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
#include <string.h>
#include <console.h>
#include <system.h>
#include <irq.h>
#include <hw/interrupts.h>
#include <hw/vga.h>

#include <hal/tmu.h>
#include <hal/vga.h>

/*
 * RGB565 framebuffers.
 * We use page flipping triple buffering as described on
 * http://en.wikipedia.org/wiki/Triple_buffering
 *
 * Buffers must be aligned to the start of an FML burst
 * which is 4x64 bits, that is, 256 bits, or 32 bytes.
 */
static unsigned short int framebufferA[1024*768] __attribute__((aligned(32)));
static unsigned short int framebufferB[1024*768] __attribute__((aligned(32)));
static unsigned short int framebufferC[1024*768] __attribute__((aligned(32)));

int vga_blanked;
int vga_hres;
int vga_vres;

unsigned short int *vga_frontbuffer; /* < buffer currently displayed (or request sent to HW) */
unsigned short int *vga_backbuffer;  /* < buffer currently drawn to, never read by HW */
unsigned short int *vga_lastbuffer;  /* < buffer displayed just before (or HW finishing last scan) */

static int i2c_init(void);

/* Text mode framebuffer */
static unsigned short int framebuffer_text[1024*768] __attribute__((aligned(32)));
static unsigned int cursor_pos;
static unsigned int text_line_len;
static int console_mode;

static void write_hook(char c);

void vga_init(int blanked)
{
	vga_blanked = blanked;

	vga_frontbuffer = framebufferA;
	vga_backbuffer = framebufferB;
	vga_lastbuffer = framebufferC;

	CSR_VGA_BASEADDRESS = (unsigned int)vga_frontbuffer;

	printf("VGA: framebuffers at 0x%08x 0x%08x 0x%08x\n",
		(unsigned int)&framebufferA, (unsigned int)&framebufferB, (unsigned int)&framebufferC);

	if(i2c_init())
		printf("VGA: DDC I2C bus initialized\n");
	else
		printf("VGA: DDC I2C bus initialization problem\n");

	vga_set_mode(VGA_MODE_640_480);
	console_set_write_hook(write_hook);
}

void vga_blank(void)
{
	if(!vga_blanked) {
		CSR_VGA_RESET = VGA_RESET;
		vga_blanked = 1;
	}
}

void vga_unblank(void)
{
	if(vga_blanked) {
		CSR_VGA_RESET = 0;
		vga_blanked = 0;
	}
}

void vga_swap_buffers(void)
{
	unsigned short int *p;

	if(!console_mode && !vga_blanked) {
		/*
		 * Make sure last buffer swap has been executed.
		 */
		while(CSR_VGA_BASEADDRESS_ACT != CSR_VGA_BASEADDRESS);
	}

	p = vga_frontbuffer;
	vga_frontbuffer = vga_backbuffer;
	vga_backbuffer = vga_lastbuffer;
	vga_lastbuffer = p;
	
	if(!console_mode)
		CSR_VGA_BASEADDRESS = (unsigned int)vga_frontbuffer;
}

void vga_set_console(int console)
{
	console_mode = console;
	if(console)
		CSR_VGA_BASEADDRESS = (unsigned int)framebuffer_text;
	else
		CSR_VGA_BASEADDRESS = (unsigned int)vga_frontbuffer;
}

int vga_get_console(void)
{
	return console_mode;
}

/* DDC */
int i2c_started;

static int i2c_init(void)
{
	unsigned int timeout;

	i2c_started = 0;
	CSR_VGA_DDC = VGA_DDC_SDC;
	/* Check the I2C bus is ready */
	timeout = 1000;
	while((timeout > 0) && (!(CSR_VGA_DDC & VGA_DDC_SDAIN))) timeout--;

	return timeout;
}

static void i2c_delay(void)
{
	unsigned int i;

	for(i=0;i<1000;i++) __asm__("nop");
}

/* I2C bit-banging functions from http://en.wikipedia.org/wiki/I2c */
static unsigned int i2c_read_bit(void)
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

static void i2c_start_cond(void)
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

static void i2c_stop_cond(void)
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

/* http://web.mit.edu/6.111/www/s2004/NEWKIT/vga.shtml */
void vga_set_mode(int mode)
{
	CSR_VGA_RESET = VGA_RESET;
	switch(mode) {
		case VGA_MODE_640_480: // Pixel clock: 25MHz
			vga_hres = 640;
			vga_vres = 480;
			CSR_VGA_HRES = 640;
			CSR_VGA_HSYNC_START = 656;
			CSR_VGA_HSYNC_END = 752;
			CSR_VGA_HSCAN = 799;
			CSR_VGA_VRES = 480;
			CSR_VGA_VSYNC_START = 492;
			CSR_VGA_VSYNC_END = 494;
			CSR_VGA_VSCAN = 524;
			CSR_VGA_CLKSEL = 0;
			break;
		case VGA_MODE_800_600: // Pixel clock: 50MHz
			vga_hres = 800;
			vga_vres = 600;
			CSR_VGA_HRES = 800;
			CSR_VGA_HSYNC_START = 848;
			CSR_VGA_HSYNC_END = 976;
			CSR_VGA_HSCAN = 1040;
			CSR_VGA_VRES = 600;
			CSR_VGA_VSYNC_START = 636;
			CSR_VGA_VSYNC_END = 642;
			CSR_VGA_VSCAN = 665;
			CSR_VGA_CLKSEL = 1;
			break;
		case VGA_MODE_1024_768: // Pixel clock: 65MHz
			vga_hres = 1024;
			vga_vres = 768;
			CSR_VGA_HRES = 1024;
			CSR_VGA_HSYNC_START = 1048;
			CSR_VGA_HSYNC_END = 1184;
			CSR_VGA_HSCAN = 1344;
			CSR_VGA_VRES = 768;
			CSR_VGA_VSYNC_START = 772;
			CSR_VGA_VSYNC_END = 778;
			CSR_VGA_VSCAN = 807;
			CSR_VGA_CLKSEL = 2;
			break;
	}
	memset(framebufferA, 0, vga_hres*vga_vres*2);
	memset(framebufferB, 0, vga_hres*vga_vres*2);
	memset(framebufferC, 0, vga_hres*vga_vres*2);
	memset(framebuffer_text, 0, vga_hres*vga_vres*2);
	cursor_pos = 0;
	text_line_len = vga_hres/8;
	CSR_VGA_BURST_COUNT = vga_hres*vga_vres/16;
	printf("VGA: mode set to %dx%d\n", vga_hres, vga_vres);
	if(!vga_blanked)
		CSR_VGA_RESET = 0;
}

extern const unsigned char fontdata_8x16[];
#define FONT_HEIGHT 16

static void bitblit(unsigned short int fg, int x, int y, const unsigned char *origin)
{
	int dx, dy;
	unsigned short int line;
	int fbi;
	
	for(dy=0;dy<FONT_HEIGHT;dy++) {
		line = origin[dy];
		fbi = vga_hres*(y+dy)+x;
		for(dx=7;dx>=0;dx--) {
			framebuffer_text[fbi+dx] = (line & 0x0001)*fg;
			line >>= 1;
		}
	}
}

static int wait_tmu;
static struct tmu_vertex scroll_vertices[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));
static struct tmu_td scroll_td;

static void write_hook(char c);
static void raw_print(char c, unsigned short int bg);

#define Q_RINGBUFFER_SIZE 131072
#define Q_RINGBUFFER_MASK (Q_RINGBUFFER_SIZE-1)

static char q_buf[Q_RINGBUFFER_SIZE];
static unsigned int q_produce;
static unsigned int q_consume;

#define MAKERGB565N(r, g, b) ((((r) & 0xf8) << 8) | (((g) & 0xfc) << 3) | (((b) & 0xf8) >> 3))

static void scroll_callback(struct tmu_td *td)
{	
	unsigned int oldmask;
	unsigned int ie;
	
	/* HACK: allow nested UART interrupts to prevent data loss */
	ie = irq_getie();
	oldmask = irq_getmask();
	irq_setmask(IRQ_UART);
	irq_enable(1);
	
	flush_cpu_dcache();
	memset(framebuffer_text+vga_hres*(vga_vres-FONT_HEIGHT), 0, 2*vga_hres*FONT_HEIGHT);
	cursor_pos = 0;
	wait_tmu = 0;
	raw_print(0xdb, MAKERGB565N(192, 192, 192));
	while(q_consume != q_produce) {
		write_hook(q_buf[q_consume]);
		q_consume = (q_consume + 1) & Q_RINGBUFFER_MASK;
		if(wait_tmu)
			break;
	}
	
	irq_setie(ie);
	irq_setmask(oldmask);
}

static void scroll(void)
{
	if(tmu_ready) {
		/* Hardware-accelerated scrolling */		
		scroll_vertices[0][0].x = 0;
		scroll_vertices[0][0].y = FONT_HEIGHT << TMU_FIXEDPOINT_SHIFT;
		scroll_vertices[0][1].x = vga_hres << TMU_FIXEDPOINT_SHIFT;
		scroll_vertices[0][1].y = FONT_HEIGHT << TMU_FIXEDPOINT_SHIFT;
		scroll_vertices[1][0].x = 0;
		scroll_vertices[1][0].y = vga_vres << TMU_FIXEDPOINT_SHIFT;
		scroll_vertices[1][1].x = vga_hres << TMU_FIXEDPOINT_SHIFT;
		scroll_vertices[1][1].y = vga_vres << TMU_FIXEDPOINT_SHIFT;
		
		scroll_td.flags = 0;
		scroll_td.hmeshlast = 1;
		scroll_td.vmeshlast = 1;
		scroll_td.brightness = TMU_BRIGHTNESS_MAX;
		scroll_td.chromakey = 0;
		scroll_td.vertices = &scroll_vertices[0][0];
		scroll_td.texfbuf = framebuffer_text;
		scroll_td.texhres = vga_hres;
		scroll_td.texvres = vga_vres;
		scroll_td.texhmask = TMU_MASK_NOFILTER;
		scroll_td.texvmask = TMU_MASK_NOFILTER;
		scroll_td.dstfbuf = framebuffer_text;
		scroll_td.dsthres = vga_hres;
		scroll_td.dstvres = vga_vres;
		scroll_td.dsthoffset = 0;
		scroll_td.dstvoffset = 0;
		scroll_td.dstsquarew = vga_hres;
		scroll_td.dstsquareh = vga_vres-FONT_HEIGHT;
		scroll_td.alpha = TMU_ALPHA_MAX;
		scroll_td.callback = scroll_callback;
		scroll_td.user = NULL;
		
		flush_bridge_cache();
		tmu_submit_task(&scroll_td);
		
		wait_tmu = 1;
	} else {
		/* Software fallback */
		/* WARNING: may not work with all memcpy's! */
		memcpy(framebuffer_text, framebuffer_text+vga_hres*FONT_HEIGHT, 2*vga_hres*(vga_vres-FONT_HEIGHT));
		memset(framebuffer_text+vga_hres*(vga_vres-FONT_HEIGHT), 0, 2*vga_hres*FONT_HEIGHT);
		cursor_pos = 0;
	}
}

static int escape_mode;
static int highlight;

static void raw_print(char c, unsigned short int fg)
{
	unsigned char c2 = (unsigned char)c;
	unsigned int c3 = c2;
	
	bitblit(fg, cursor_pos*8, vga_vres-FONT_HEIGHT, fontdata_8x16+c3*FONT_HEIGHT);
}

static void write_hook(char c)
{
	unsigned short int color;
	
	if(wait_tmu) {
		q_buf[q_produce] = c;
		q_produce = (q_produce + 1) & Q_RINGBUFFER_MASK;
		return;
	}
	
	if(escape_mode) {
		switch(c) {
			case '1':
				highlight = 1;
				break;
			case '0':
				highlight = 0;
				break;
			case 'm':
			case '\n':
				escape_mode = 0;
				break;
			default:
				break;
		}
	} else {
		if(c == '\n') {
			raw_print(' ', MAKERGB565N(192, 192, 192));
			scroll();
		} else if(c == 0x08) {
			if(cursor_pos > 0) {
				raw_print(' ', MAKERGB565N(192, 192, 192));
				cursor_pos--;
			}
		}
		else if(c == '\e')
			escape_mode = 1;
		else {
			color = highlight ? MAKERGB565N(255, 255, 255) : MAKERGB565N(192, 192, 192);
			raw_print(c, color);
			cursor_pos++;
			if(cursor_pos >= (text_line_len-1))
				scroll();
		}
		if(!wait_tmu)
			raw_print(0xdb, MAKERGB565N(192, 192, 192));
	}
}

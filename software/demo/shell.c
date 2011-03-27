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
#include <stdlib.h>
#include <string.h>
#include <console.h>
#include <uart.h>
#include <blockdev.h>
#include <fatfs.h>
#include <system.h>
#include <math.h>
#include <irq.h>
#include <board.h>
#include <version.h>
#include <hw/pfpu.h>
#include <hw/tmu.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <hw/interrupts.h>
#include <hw/minimac.h>
#include <hw/bt656cap.h>
#include <hw/rc5.h>
#include <hw/midi.h>
#include <hw/memcard.h>
#include <hw/memtest.h>

#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/tmu.h>
#include <hal/time.h>
#include <hal/brd.h>
#include <hal/vin.h>
#include <hal/usb.h>

#include "line.h"
#include "wave.h"
#include "rpipe.h"
#include "cpustats.h"
#include "memstats.h"
#include "shell.h"
#include "renderer.h"

#define NUMBER_OF_BYTES_ON_A_LINE 16
static void dump_bytes(unsigned int *ptr, int count, unsigned addr)
{
	char *data = (char *)ptr;
	int line_bytes = 0, i = 0;

	putsnonl("Memory dump:");
	while(count > 0){
		line_bytes =
			(count > NUMBER_OF_BYTES_ON_A_LINE)?
				NUMBER_OF_BYTES_ON_A_LINE : count;

		printf("\n0x%08x  ", addr);
		for(i=0;i<line_bytes;i++)
			printf("%02x ", *(unsigned char *)(data+i));

		for(;i<NUMBER_OF_BYTES_ON_A_LINE;i++)
			printf("   ");

		printf(" ");

		for(i=0;i<line_bytes;i++) {
			if((*(data+i) < 0x20) || (*(data+i) > 0x7e))
				printf(".");
			else
				printf("%c", *(data+i));
		}

		for(;i<NUMBER_OF_BYTES_ON_A_LINE;i++)
			printf(" ");

		data += (char)line_bytes;
		count -= line_bytes;
		addr += line_bytes;
	}
	printf("\n");
}

static void mr(char *startaddr, char *len)
{
	char *c;
	unsigned *addr;
	unsigned length;

	if(*startaddr == 0) {
		printf("mr <address> [length]\n");
		return;
	}
	addr = (unsigned *)strtoul(startaddr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	if(*len == 0) {
		length = 1;
	} else {
		length = strtoul(len, &c, 0);
		if(*c != 0) {
			printf("incorrect length\n");
			return;
		}
	}

	dump_bytes(addr, length, (unsigned)addr);
}

static void mw(char *addr, char *value, char *count)
{
	char *c;
	unsigned *addr2;
	unsigned value2;
	unsigned count2;
	unsigned i;

	if((*addr == 0) || (*value == 0)) {
		printf("mw <address> <value>\n");
		return;
	}
	addr2 = (unsigned *)strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	value2 = strtoul(value, &c, 0);
	if(*c != 0) {
		printf("incorrect value\n");
		return;
	}
	if(*count == 0) {
		count2 = 1;
	} else {
		count2 = strtoul(count, &c, 0);
		if(*c != 0) {
			printf("incorrect count\n");
			return;
		}
	}
	for(i=0;i<count2;i++) *addr2++ = value2;
}

static int lscb(const char *filename, const char *longname, void *param)
{
	printf("%12s [%s]\n", filename, longname);
	return 1;
}

static void ls(const char *dev)
{
	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	fatfs_list_files(lscb, NULL);
	fatfs_done();
}

static void edid()
{
	char buf[256];

	if(!vga_read_edid(buf)) {
		printf("Failed to read EDID\n");
		return;
	}
	dump_bytes((unsigned int *)buf, 256, 0);
}

static char patch_buf[8192];

static void new()
{
	patch_buf[0] = 0;
}

static void del(const char *eqn)
{
	char *p, *p2;
	char eqn2[256];
	int l;

	strcpy(eqn2, eqn);
	l = strlen(eqn2);
	eqn2[l++] = '=';
	eqn2[l] = 0;

	p = patch_buf;
	while(1) {
		if(strncmp(p, eqn2, l) == 0) {
			p2 = p;
			while((*p2 != '\n') && (*p2 != 0))
				p2++;
			if(*p2 == '\n')
				p2++;
			memmove(p, p2, strlen(patch_buf)-(p2-patch_buf)+2);
			return;
		}
		while(*p != '\n') {
			p++;
			if(*p == 0)
				return;
		}
		p++;
	}
}

static void add(const char *eqn)
{
	int l;
	char *c;

	c = strchr(eqn, '=');
	if(c == NULL) {
		printf("Invalid equation\n");
		return;
	}
	*c = 0;
	del(eqn);
	*c = '=';

	/* FIXME: check for overflows... */
	l = strlen(patch_buf);
	strcpy(&patch_buf[l], eqn);
	l += strlen(eqn);
	patch_buf[l] = '\n';
	patch_buf[l+1] = 0;
}

static void print()
{
	puts(patch_buf);
}

static void renderb()
{
	char patch_buf_copy[8192];

	strcpy(patch_buf_copy, patch_buf);
	renderer_start(patch_buf_copy);
}

static void renderf(const char *filename)
{
	char buffer[8192];
	int size;

	if(*filename == 0) {
		printf("renderf <filename>\n");
		return;
	}

	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	if(!fatfs_load(filename, buffer, sizeof(buffer), &size)) return;
	fatfs_done();
	buffer[size] = 0;

	renderer_start(buffer);
}

static void vmode(const char *mode)
{
	char *c;
	int mode2;

	mode2 = strtoul(mode, &c, 0);
	if(*c != 0) {
		printf("incorrect mode\n");
		return;
	}
	vga_set_mode(mode2);
}

static void stats()
{
	int hours, mins, secs;
	struct timestamp ts;
	unsigned int amat;
	unsigned int netbw;
	unsigned int occupancy;

	time_get(&ts);
	secs = ts.sec;
	mins = secs/60;
	secs -= mins*60;
	hours = mins/60;
	mins -= hours*60;
	printf("Uptime: %02d:%02d:%02d  FPS: %d  CPU:%3d%%\n", hours, mins, secs,
		rpipe_fps(),
		cpustats_load());

	amat = memstat_amat();
	netbw = memstat_net_bandwidth();
	occupancy = memstat_occupancy();
	if(occupancy != 0) {
		printf("Net memory bandwidth : %d Mbps\n", netbw);
		printf("Memory bus occupancy : %d%%\n", occupancy);
		printf("Avg. mem. access time: %d.%02d cycles\n", amat/100, amat%100);
	}
}

static void help()
{
	puts("Milkymist(tm) demonstration program (PROOF OF CONCEPT ONLY!)\n");
	puts("Available commands:");
	puts("cons        - switch console mode");
	puts("ls          - list files on the memory card");
	puts("new         - clear buffer");
	puts("add     [a] - add an equation to buffer");
	puts("del     [d] - delete an equation from buffer");
	puts("print   [p] - print buffer");
	puts("renderb [r] - render buffer");
	puts("renderf     - render file");
	puts("renderi     - render console input");
	puts("stop        - stop renderer");
	puts("stats       - print system stats");
	puts("version     - display version");
	puts("reboot      - system reset");
	puts("reconf      - reload FPGA configuration");
}

static void cpucfg()
{
	unsigned long cpu_cfg;

	__asm__ volatile(
		"rcsr %0, cfg\n\t"
		: "=r"(cpu_cfg)
	);
	printf("CPU config word: 0x%08x\n", cpu_cfg);
	printf("Options: ");
	if(cpu_cfg & 0x001) printf("M ");
	if(cpu_cfg & 0x002) printf("D ");
	if(cpu_cfg & 0x004) printf("S ");
	if(cpu_cfg & 0x008) printf("X ");
	if(cpu_cfg & 0x010) printf("U ");
	if(cpu_cfg & 0x020) printf("CC ");
	if(cpu_cfg & 0x040) printf("DC ");
	if(cpu_cfg & 0x080) printf("IC ");
	if(cpu_cfg & 0x100) printf("G ");
	if(cpu_cfg & 0x200) printf("H ");
	if(cpu_cfg & 0x400) printf("R ");
	if(cpu_cfg & 0x800) printf("J ");
	printf("\n");
	printf("IRQs: %d\n", (cpu_cfg >> 12) & 0x3F);
	printf("Breakpoints: %d\n", (cpu_cfg >> 18) & 0x0F);
	printf("Watchpoints: %d\n", (cpu_cfg >> 22) & 0x0F);
	printf("CPU revision: %d\n", cpu_cfg >> 26);
}

static void loadpic(const char *filename)
{
	int size;

	if(*filename == 0) {
		printf("loadpic <filename>\n");
		return;
	}

	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	if(!fatfs_load(filename, (void *)vga_backbuffer, vga_hres*vga_vres*2, &size)) return;
	fatfs_done();

	vga_swap_buffers();
}

static void checker()
{
	int x, y;

	for(y=0;y<vga_vres;y++)
		for(x=0;x<vga_hres;x++)
			if((x/4+y/4) & 1)
				vga_backbuffer[y*vga_hres+x] = 0x0000;
			else
				vga_backbuffer[y*vga_hres+x] = 0xffff;
	vga_swap_buffers();
}

/*
 * Low-level PFPU test, bypassing driver.
 * This test should only be run when the driver task queue
 * is empty.
 */
static struct tmu_vertex mesh[128][128] __attribute__((aligned(8)));
static void pfputest()
{
	unsigned int *pfpu_regs = (unsigned int *)CSR_PFPU_DREGBASE;
	unsigned int *pfpu_code = (unsigned int *)CSR_PFPU_CODEBASE;
	int x, y;
	int timeout;
	unsigned int oldmask;

	/* Do not let the driver get our interrupt */
	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_PFPU));

	for(y=0;y<128;y++)
		for(x=0;x<128;x++) {
			mesh[y][x].x = 0xdeadbeef;
			mesh[y][x].y = 0xdeadbeef;
		}

	CSR_PFPU_MESHBASE = (unsigned int)&mesh;
	//CSR_PFPU_HMESHLAST = 6;
	//CSR_PFPU_VMESHLAST = 9;

	CSR_PFPU_HMESHLAST = 11;
	CSR_PFPU_VMESHLAST = 9;

	pfpu_regs[3] = 0x41300000;
	pfpu_regs[4] = 0x41100000;

	pfpu_code[ 0] = 0x00000300;
	pfpu_code[ 1] = 0x00040300;
	pfpu_code[ 2] = 0x00000000;
	pfpu_code[ 3] = 0x00000003;
	pfpu_code[ 4] = 0x00000004;
	pfpu_code[ 5] = 0x000c2080;
	pfpu_code[ 6] = 0x00000000;
	pfpu_code[ 7] = 0x00000000;
	pfpu_code[ 8] = 0x00000000;
	pfpu_code[ 9] = 0x00000005;
	pfpu_code[10] = 0x00142b80;

	CSR_PFPU_CTL = PFPU_CTL_START;
	printf("Waiting for PFPU...\n");
	timeout = 30;
	do {
		printf("%08x vertices:%d collisions:%d strays:%d last:%08x pc:%04x\n",
			CSR_PFPU_CTL, CSR_PFPU_VERTICES, CSR_PFPU_COLLISIONS, CSR_PFPU_STRAYWRITES, CSR_PFPU_LASTDMA, 4*CSR_PFPU_PC);
	} while((timeout--) && (CSR_PFPU_CTL & PFPU_CTL_BUSY));
	if(timeout > 0)
		printf("OK\n");
	else
		printf("Timeout\n");

	flush_cpu_dcache();

	printf("Result:\n");
	for(y=0;y<10;y++) {
		for(x=0;x<12;x++)
			printf("%08x ", mesh[y][x].x);
		printf("\n");
	}
	printf("\n");
	for(y=0;y<10;y++) {
		for(x=0;x<12;x++)
			printf("%08x ", mesh[y][x].y);
		printf("\n");
	}

	printf("Program:\n");
	for(x=0;x<11;x++)
		printf("%08x ", pfpu_code[x]);
	printf("\n");

	CSR_PFPU_CTL = 0; /* Ack interrupt */
	irq_ack(IRQ_PFPU);
	irq_setmask(oldmask);
}

static void tmutest_callback(struct tmu_td *td)
{
	int *complete;
	complete = (int *)td->user;
	*complete = 1;
}

static void tmutest()
{
	int x, y;
	static struct tmu_vertex srcmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));
	struct tmu_td td;
	volatile int complete;

	for(y=0;y<=32;y++)
		for(x=0;x<=32;x++) {
			srcmesh[y][x].x = (10*x) << TMU_FIXEDPOINT_SHIFT;
			srcmesh[y][x].y = (7*y) << TMU_FIXEDPOINT_SHIFT;
		}

	td.flags = 0;
	td.hmeshlast = 32;
	td.vmeshlast = 32;
	td.brightness = TMU_BRIGHTNESS_MAX;
	td.chromakey = 0;
	td.vertices = &srcmesh[0][0];
	td.texfbuf = vga_frontbuffer;
	td.texhres = vga_hres;
	td.texvres = vga_vres;
	td.texhmask = TMU_MASK_FULL;
	td.texvmask = TMU_MASK_FULL;
	td.dstfbuf = vga_backbuffer;
	td.dsthres = vga_hres;
	td.dstvres = vga_vres;
	td.dsthoffset = 0;
	td.dstvoffset = 0;
	td.dstsquarew = vga_hres/32;
	td.dstsquareh = vga_vres/32;
	td.alpha = TMU_ALPHA_MAX;

	td.callback = tmutest_callback;
	td.user = (void *)&complete;

	complete = 0;
	flush_bridge_cache();
	tmu_submit_task(&td);
	while(!complete);
	vga_swap_buffers();
}

static void tmubench()
{
	int i;
	int zoom;
	int x, y;
	static struct tmu_vertex srcmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));
	static unsigned short int texture[512*512] __attribute__((aligned(16)));
	struct tmu_td td;
	volatile int complete;
	unsigned int t;
	int hits, reqs;

	uart_force_sync(1);

	for(i=0;i<512*512;i++)
		texture[i] = i;
	flush_bridge_cache();

	for(zoom=0;zoom<16*64*2;zoom++) {
		for(y=0;y<=32;y++)
			for(x=0;x<=32;x++) {
				srcmesh[y][x].x = zoom*x;
				srcmesh[y][x].y = zoom*y;
			}

		td.flags = 0;
		td.hmeshlast = 32;
		td.vmeshlast = 32;
		td.brightness = TMU_BRIGHTNESS_MAX;
		td.chromakey = 0;
		td.vertices = &srcmesh[0][0];
		td.texfbuf = texture;
		td.texhres = 512;
		td.texvres = 512;
		td.texhmask = 0x7FFF;
		td.texvmask = 0x7FFF;
		td.dstfbuf = vga_backbuffer;
		td.dsthres = vga_hres;
		td.dstvres = vga_vres;
		td.dsthoffset = 0;
		td.dstvoffset = 0;
		td.dstsquarew = vga_hres/32;
		td.dstsquareh = vga_vres/32;
		td.alpha = TMU_ALPHA_MAX;

		td.callback = tmutest_callback;
		td.user = (void *)&complete;

		complete = 0;
		CSR_TIMER1_CONTROL = 0;
		CSR_TIMER1_COUNTER = 0;
		CSR_TIMER1_COMPARE = 0xffffffff;
		CSR_TIMER1_CONTROL = TIMER_ENABLE;
		tmu_submit_task(&td);
		while(!complete);
		t = CSR_TIMER1_COUNTER;
		hits = CSR_TMU_HIT_A + CSR_TMU_HIT_B + CSR_TMU_HIT_C + CSR_TMU_HIT_D;
		reqs = CSR_TMU_REQ_A + CSR_TMU_REQ_B + CSR_TMU_REQ_C + CSR_TMU_REQ_D;
		printf("%d,%d,%d\n", t, hits, reqs);
		vga_swap_buffers();
	}

	uart_force_sync(0);
}

static short audio_buffer1[SND_MAX_NSAMPLES*2];
static short audio_buffer2[SND_MAX_NSAMPLES*2];
static short audio_buffer3[SND_MAX_NSAMPLES*2];
static short audio_buffer4[SND_MAX_NSAMPLES*2];

static void record_callback(short *buffer, void *user)
{
	snd_play_refill(buffer);
}

static void play_callback(short *buffer, void *user)
{
	snd_record_refill(buffer);
}

static void echo()
{
	if(snd_play_active()) {
		snd_record_stop();
		snd_play_stop();
		printf("Digital Echo demo stopped\n");
	} else {
		int i;

		snd_play_empty();
		for(i=0;i<AC97_MAX_DMASIZE/2;i++) {
			audio_buffer1[i] = 0;
			audio_buffer2[i] = 0;
		}
		snd_play_refill(audio_buffer1);
		snd_play_refill(audio_buffer2);
		snd_play_start(play_callback, SND_MAX_NSAMPLES, NULL);

		snd_record_empty();
		snd_record_refill(audio_buffer3);
		snd_record_refill(audio_buffer4);
		snd_record_start(record_callback, SND_MAX_NSAMPLES, NULL);
		printf("Digital Echo demo started\n");
	}
}

static void cr(char *addr)
{
	unsigned int a;
	char *c;

	if(*addr == 0) {
		printf("cr <address>\n");
		return;
	}
	a = strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}

	printf("%04x\n", snd_ac97_read(a));
}

static void cw(char *addr, char *value)
{
	unsigned int a, v;
	char *c;

	if((*addr == 0)||(*value == 0)) {
		printf("cw <address> <value>\n");
		return;
	}
	a = strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	v = strtoul(value, &c, 0);
	if(*c != 0) {
		printf("incorrect value\n");
		return;
	}
	snd_ac97_write(a, v);
}

static void readv(char *addr)
{
	unsigned char a;
	char *c;

	if(*addr == 0) {
		printf("readv <address>\n");
		return;
	}
	a = strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}

	printf("%02x\n", vin_read_reg(a));
}

static void writev(char *addr, char *value)
{
	unsigned char a, v;
	char *c;

	if((*addr == 0)||(*value == 0)) {
		printf("writev <address> <value>\n");
		return;
	}
	a = strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	v = strtoul(value, &c, 0);
	if(*c != 0) {
		printf("incorrect value\n");
		return;
	}

	vin_write_reg(a, v);
}

static short vbuffer[720*288] __attribute__((aligned(32)));

static void testv()
{
	int x, y;

	irq_ack(IRQ_VIDEOIN);
	CSR_BT656CAP_BASE = (unsigned int)vbuffer;
	CSR_BT656CAP_FILTERSTATUS = BT656CAP_FILTERSTATUS_FIELD1;
	printf("wait1 %d\n", CSR_TIMER0_COUNTER);
	while(!(irq_pending() & IRQ_VIDEOIN));
	irq_ack(IRQ_VIDEOIN);
	printf("wait2 %d\n", CSR_TIMER0_COUNTER);
	while(!(irq_pending() & IRQ_VIDEOIN));
	irq_ack(IRQ_VIDEOIN);
	CSR_BT656CAP_FILTERSTATUS = 0;
	printf("wait3 %d\n", CSR_TIMER0_COUNTER);
	while(CSR_BT656CAP_FILTERSTATUS & BT656CAP_FILTERSTATUS_INFRAME);
	printf("done %d\n", CSR_TIMER0_COUNTER);
	printf("nbursts=%d/%d\n", CSR_BT656CAP_DONEBURSTS, CSR_BT656CAP_MAXBURSTS);
	flush_bridge_cache();
	for(y=0;y<288;y++)
		for(x=0;x<640;x++)
			vga_frontbuffer[640*y+x] = vbuffer[720*y+x];
	flush_bridge_cache();
}

static void irtest()
{
	unsigned int r;

	irq_ack(IRQ_IR);
	while(!readchar_nonblock()) {
		if(irq_pending() & IRQ_IR) {
			r = CSR_RC5_RX;
			irq_ack(IRQ_IR);
			printf("%04x - fld:%d ctl:%d sys:%d cmd:%d\n", r,
				(r & 0x1000) >> 12,
				(r & 0x0800) >> 11,
				(r & 0x07c0) >> 6,
				r & 0x003f);

		}
	}
}

static void midiprint()
{
	unsigned int r;
	if(irq_pending() & IRQ_MIDIRX) {
		r = CSR_MIDI_RXTX;
		irq_ack(IRQ_MIDIRX);
		printf("RX: %02x\n", r);
	}
}

static void midirx()
{
	irq_ack(IRQ_MIDIRX);
	while(!readchar_nonblock()) midiprint();
}

static void midisend(int c)
{
	printf("TX: %02x\n", c);
	CSR_MIDI_RXTX = c;
	while(!(irq_pending() & IRQ_MIDITX));
	printf("TX done\n");
	irq_ack(IRQ_MIDITX);
	midiprint();
}

static void miditx(char *note)
{
	int note2;
	char *c;

	if(*note == 0) {
		printf("miditx <note>\n");
		return;
	}
	note2 = strtoul(note, &c, 0);
	if(*c != 0) {
		printf("incorrect note\n");
		return;
	}

	midisend(0x90);
	midisend(note2);
	midisend(0x22);
}

static void readblock(char *b)
{
	char *c;
	unsigned int b2;
	unsigned int buf[128];
	if(*b == 0) {
		printf("readblock <block>\n");
		return;
	}
	b2 = strtoul(b, &c, 0);
	if(*c != 0) {
		printf("incorrect block\n");
		return;
	}
	bd_readblock(b2, buf);
}

static int mouse_x, mouse_y;

static void mouse_cb(unsigned char buttons, char dx, char dy, unsigned char wheel)
{
	mouse_x += dx;
	mouse_y += dy;
	if(mouse_x < 0)
		mouse_x = 0;
	else if(mouse_x >= vga_hres)
		mouse_x = vga_hres-1;
	if(mouse_y < 0)
		mouse_y = 0;
	else if(mouse_y >= vga_vres)
		mouse_y = vga_vres-1;
	vga_frontbuffer[vga_hres*mouse_y+mouse_x] = 0xffff;
}

static void keyboard_cb(unsigned char modifiers, unsigned char key)
{
	if(modifiers != 0x00)
		printf("%x (mod:%x)\n", key, modifiers);
	else
		printf("%x\n", key);
}

static void input()
{
	mouse_x = 0;
	mouse_y = 0;
	usb_set_mouse_cb(mouse_cb);
	usb_set_keyboard_cb(keyboard_cb);
	while(!uart_read_nonblock());
	usb_set_mouse_cb(NULL);
	usb_set_keyboard_cb(NULL);
}

#define MEMTEST_LEN (32*1024*1024)
extern void* _memtest_buffer;
static void memtest(char *nb)
{
	char *c;
	unsigned int n;

	if(*nb == 0) {
		printf("memtest <nbursts>\n");
		return;
	}
	n = strtoul(nb, &c, 0);
	if(*c != 0) {
		printf("incorrect count\n");
		return;
	}

	printf("Filling buffer...\n");
	CSR_MEMTEST_ADDRESS = (unsigned int)_memtest_buffer;
	CSR_MEMTEST_ERRORS = 0;
	CSR_MEMTEST_WRITE = 1;
	CSR_MEMTEST_BCOUNT = n; //MEMTEST_LEN/32;
	while(CSR_MEMTEST_BCOUNT > 0);
	printf("Reading buffer...\n");
	CSR_MEMTEST_ADDRESS = (unsigned int)_memtest_buffer;
	CSR_MEMTEST_ERRORS = 0;
	CSR_MEMTEST_WRITE = 0;
	CSR_MEMTEST_BCOUNT = n;
	while(CSR_MEMTEST_BCOUNT > 0);
	printf("Errors: %d\n", CSR_MEMTEST_ERRORS);
}

/* beyond this number, the address LFSR loops */
#define LMEMTEST_BCOUNT 209715LL
#define LMEMTEST_RUNS 200LL
static void lmemtest()
{
	int i;
	unsigned int total_errors;
	struct timestamp t0, t1, t;
	unsigned int length;

	total_errors = 0;

	flush_bridge_cache();
	while(!readchar_nonblock()) {
		time_get(&t0);
		for(i=0;i<LMEMTEST_RUNS;i++) {
			CSR_MEMTEST_ADDRESS = (unsigned int)_memtest_buffer;
			CSR_MEMTEST_ERRORS = 0;
			CSR_MEMTEST_WRITE = 1;
			CSR_MEMTEST_BCOUNT = LMEMTEST_BCOUNT;
			while(CSR_MEMTEST_BCOUNT > 0);
			CSR_MEMTEST_ADDRESS = (unsigned int)_memtest_buffer;
			CSR_MEMTEST_ERRORS = 0;
			CSR_MEMTEST_WRITE = 0;
			CSR_MEMTEST_BCOUNT = LMEMTEST_BCOUNT;
			while(CSR_MEMTEST_BCOUNT > 0);
			total_errors += CSR_MEMTEST_ERRORS;
		}
		time_get(&t1);
		time_diff(&t, &t1, &t0);
		length = 2LL*LMEMTEST_BCOUNT*32LL*LMEMTEST_RUNS/(1024LL*1024LL);
		if(t.sec != 0)
			printf("%d MB in %d s (%d MB/s), cumulative errors: %d\n", length, t.sec, length/t.sec, total_errors);
	}
}

static char *get_token(char **str)
{
	char *c, *d;

	c = (char *)strchr(*str, ' ');
	if(c == NULL) {
		d = *str;
		*str = *str+strlen(*str);
		return d;
	}
	*c = 0;
	d = *str;
	*str = c+1;
	return d;
}

static int irender;

static void do_command(char *c)
{
	if(irender) {
		if(*c == 0) {
			irender = 0;
			renderer_idone();
		} else
			renderer_iinput(c);
	} else {
		char *command, *param1, *param2, *param3;

		command = get_token(&c);
		param1 = get_token(&c);
		param2 = get_token(&c);
		param3 = get_token(&c);

		if(strcmp(command, "cons") == 0) vga_set_console(!vga_get_console());
		else if(strcmp(command, "mr") == 0) mr(param1, param2);
		else if(strcmp(command, "mw") == 0) mw(param1, param2, param3);
		else if(strcmp(command, "ls") == 0) ls(param1);
		else if(strcmp(command, "flush") == 0) flush_bridge_cache();
		else if(strcmp(command, "edid") == 0) edid();
		else if(strcmp(command, "new") == 0) new();
		else if(strcmp(command, "add") == 0) add(param1);
		else if(strcmp(command, "a") == 0) add(param1);
		else if(strcmp(command, "del") == 0) del(param1);
		else if(strcmp(command, "d") == 0) del(param1);
		else if(strcmp(command, "print") == 0) print();
		else if(strcmp(command, "p") == 0) print();
		else if(strcmp(command, "renderb") == 0) renderb();
		else if(strcmp(command, "r") == 0) renderb();
		else if(strcmp(command, "renderf") == 0) renderf(param1);
		else if(strcmp(command, "renderi") == 0) {
			renderer_istart();
			irender = 1;
		} else if(strcmp(command, "stop") == 0) renderer_stop();
		else if(strcmp(command, "vmode") == 0) vmode(param1);
		else if(strcmp(command, "stats") == 0) stats();
		else if(strcmp(command, "version") == 0) puts(VERSION);
		else if(strcmp(command, "reboot") == 0) reboot();
		else if(strcmp(command, "reconf") == 0) reconf();
		else if(strcmp(command, "help") == 0) help();

		/* Test functions and hacks */
		else if(strcmp(command, "cpucfg") == 0) cpucfg();
		else if(strcmp(command, "loadpic") == 0) loadpic(param1);
		else if(strcmp(command, "checker") == 0) checker();
		else if(strcmp(command, "pfputest") == 0) pfputest();
		else if(strcmp(command, "tmutest") == 0) tmutest();
		else if(strcmp(command, "tmubench") == 0) tmubench();
		else if(strcmp(command, "echo") == 0) echo();
		else if(strcmp(command, "cr") == 0) cr(param1);
		else if(strcmp(command, "cw") == 0) cw(param1, param2);
		else if(strcmp(command, "testv") == 0) testv();
		else if(strcmp(command, "readv") == 0) readv(param1);
		else if(strcmp(command, "writev") == 0) writev(param1, param2);
		else if(strcmp(command, "irtest") == 0) irtest();
		else if(strcmp(command, "midirx") == 0) midirx();
		else if(strcmp(command, "miditx") == 0) miditx(param1);
		else if(strcmp(command, "readblock") == 0) readblock(param1);
		else if(strcmp(command, "input") == 0) input();
		else if(strcmp(command, "memtest") == 0) memtest(param1);
		else if(strcmp(command, "lmemtest") == 0) lmemtest();

		else if(strcmp(command, "") != 0) printf("Command not found: '%s'\n", command);
	}
}

static char command_buffer[512];
static unsigned int command_index;

static void prompt()
{
	if(irender)
		putsnonl("\e[1mpatch% \e[0m");
	else
		putsnonl("\e[1m% \e[0m");
}

void shell_init()
{
	prompt();
	command_index = 0;
	irender = 0;
}

void shell_input(char c)
{
	char xc[2];

	cpustats_enter();
	switch(c) {
		case 0x7f:
		case 0x08:
			if(command_index > 0) {
				command_index--;
				putsnonl("\x08 \x08");
			}
			break;
		case '\e':
			vga_set_console(!vga_get_console());
			break;
		case 0x07:
			break;
		case '\r':
		case '\n':
			command_buffer[command_index] = 0x00;
			putsnonl("\n");
			command_index = 0;
			do_command(command_buffer);
			prompt();
			break;
		default:
			if(command_index < (sizeof(command_buffer)-1)) {
				xc[0] = c;
				xc[1] = 0;
				putsnonl(xc);
				command_buffer[command_index] = c;
				command_index++;
			}
			break;
	}
	cpustats_leave();
}

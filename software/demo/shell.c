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
#include <cffat.h>
#include <system.h>
#include <math.h>
#include <irq.h>
#include <board.h>
#include <hw/pfpu.h>
#include <hw/tmu.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <hw/interrupts.h>
#include <hw/minimac.h>

#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/tmu.h>
#include <hal/time.h>
#include <hal/brd.h>

#include "line.h"
#include "wave.h"
#include "rpipe.h"
#include "cpustats.h"
#include "memstats.h"
#include "shell.h"
#include "ui.h"
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
	for (i=0;i<count2;i++) *addr2++ = value2;
}

static int lscb(const char *filename, const char *longname, void *param)
{
	printf("%12s [%s]\n", filename, longname);
	return 1;
}

static void ls()
{
	cffat_init();
	cffat_list_files(lscb, NULL);
	cffat_done();
}

static void render(const char *filename)
{
	if(*filename == 0) {
		printf("render <filename>\n");
		return;
	}

	ui_render_from_file(filename, 0);
}

static void spam()
{
	spam_enabled = !spam_enabled;
	if(spam_enabled)
		printf("Advertising enabled\n");
	else
		printf("Advertising disabled\n");
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
		printf("Net memory bandwidth      : %d Mbps\n", netbw);
		printf("Memory bus occupancy      : %d%%\n", occupancy);
		printf("Avg. mem. access time     : %d.%02d cycles\n", amat/100, amat%100);
	}
}

static void help()
{
	puts("Milkymist demo firmware\n");
	puts("Available commands :");
	puts("mr         - read address space");
	puts("mw         - write address space");
	puts("flush      - flush FML bridge cache");
	puts("ls         - list files on the memory card");
	puts("render     - start rendering a preset");
	puts("irender    - input preset equations interactively");
	puts("stop       - stop renderer");
	puts("spam       - start/stop advertising");
	puts("stats      - print system stats");
	puts("reboot     - system reset");
}

static void loadpic(const char *filename)
{
	int size;
	
	if(*filename == 0) {
		printf("loadpic <filename>\n");
		return;
	}

	if(!cffat_init()) return;
	if(!cffat_load(filename, (void *)vga_backbuffer, vga_hres*vga_vres*2, &size)) return;
	cffat_done();

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

	asm volatile( /* Invalidate Level-1 data cache */
		"wcsr DCC, r0\n"
		"nop\n"
	);

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
	
	td.callback = tmutest_callback;
	td.user = (void *)&complete;

	complete = 0;
	flush_bridge_cache();
	tmu_submit_task(&td);
	while(!complete);
	vga_swap_buffers();
}

static unsigned short original[640*480*2] __attribute__((aligned(2)));

static void tmudemo()
{
	int size;
	unsigned int oldmask;
	static struct tmu_vertex srcmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));
	struct tmu_td td;
	volatile int complete;
	int w, speed;
	int mindelta, xdelta, ydelta;

	if(!cffat_init()) return;
	if(!cffat_load("lena.raw", (void *)original, vga_hres*vga_vres*2, &size)) return;
	cffat_done();

	printf("done\n");
	
	/* Disable UI keys and slowout */
	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_GPIO) & (~IRQ_TIMER1));
	
	speed = 0;
	w = 512 << TMU_FIXEDPOINT_SHIFT;

	xdelta = 0;
	ydelta = 0;
	while(1) {
		srcmesh[0][0].x = xdelta;
		srcmesh[0][0].y = ydelta;
		srcmesh[0][1].x = w+xdelta;
		srcmesh[0][1].y = ydelta;
		srcmesh[1][0].x = xdelta;
		srcmesh[1][0].y = w+ydelta;
		srcmesh[1][1].x = w+xdelta;
		srcmesh[1][1].y = w+ydelta;

		if(CSR_GPIO_IN & GPIO_DIP6) {
			if(CSR_GPIO_IN & GPIO_PBN)
				ydelta += 16;
			if(CSR_GPIO_IN & GPIO_PBS)
				ydelta -= 16;
			if(CSR_GPIO_IN & GPIO_PBE)
				xdelta += 16;
			if(CSR_GPIO_IN & GPIO_PBW)
				xdelta -= 16;
		} else {
			if(CSR_GPIO_IN & GPIO_PBN)
				speed += 2;
			if(CSR_GPIO_IN & GPIO_PBS)
				speed -= 2;
		}
		w += speed;
		if(w < 1) {
			w = 1;
			speed = 0;
		}
		if(xdelta > ydelta)
			mindelta = ydelta;
		else
			mindelta = xdelta;
		if(w > ((TMU_MASK_FULL >> 1)+mindelta)) {
			w = (TMU_MASK_FULL >> 1)+mindelta;
			speed = 0;
		}
		if(speed > 0) speed--;
		if(speed < 0) speed++;
		

		td.flags = 0;
		td.hmeshlast = 1;
		td.vmeshlast = 1;
		td.brightness = TMU_BRIGHTNESS_MAX;
		td.chromakey = 0;
		td.vertices = &srcmesh[0][0];
		td.texfbuf = original;
		td.texhres = vga_hres;
		td.texvres = vga_vres;
		td.texhmask = CSR_GPIO_IN & GPIO_DIP7 ? 0x7FFF : TMU_MASK_FULL;
		td.texvmask = CSR_GPIO_IN & GPIO_DIP8 ? 0x7FFF : TMU_MASK_FULL;
		td.dstfbuf = vga_backbuffer;
		td.dsthres = vga_hres;
		td.dstvres = vga_vres;
		td.dsthoffset = 0;
		td.dstvoffset = 0;
		td.dstsquarew = vga_hres;
		td.dstsquareh = vga_vres;

		td.callback = tmutest_callback;
		td.user = (void *)&complete;

		complete = 0;
		flush_bridge_cache();
		CSR_TIMER1_CONTROL = 0;
		CSR_TIMER1_COUNTER = 0;
		CSR_TIMER1_COMPARE = 0xffffffff;
		CSR_TIMER1_CONTROL = TIMER_ENABLE;
		tmu_submit_task(&td);
		while(!complete);
		CSR_TIMER1_CONTROL = 0;

		if(readchar_nonblock()) {
			char c;
			c = readchar();
			if(c == 'q') break;
			if(c == 's') {
				unsigned int t;
				t = CSR_TIMER1_COUNTER;
				printf("Processing cycles: %d (%d Mpixels/s)\n", t, 640*480*100/t);
			}
		}
		vga_swap_buffers();
	}
	irq_ack(IRQ_GPIO);
	irq_setmask(oldmask);
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

		if(strcmp(command, "mr") == 0) mr(param1, param2);
		else if(strcmp(command, "mw") == 0) mw(param1, param2, param3);
		else if(strcmp(command, "ls") == 0) ls();
		else if(strcmp(command, "flush") == 0) flush_bridge_cache();
		else if(strcmp(command, "render") == 0) render(param1);
		else if(strcmp(command, "irender") == 0) {
			renderer_istart();
			irender = 1;
		} else if(strcmp(command, "stop") == 0) ui_render_stop();
		else if(strcmp(command, "spam") == 0) spam();
		else if(strcmp(command, "stats") == 0) stats();
		else if(strcmp(command, "reboot") == 0) reboot();
		else if(strcmp(command, "help") == 0) help();

		/* Test functions and hacks */
		else if(strcmp(command, "loadpic") == 0) loadpic(param1);
		else if(strcmp(command, "checker") == 0) checker();
		else if(strcmp(command, "pfputest") == 0) pfputest();
		else if(strcmp(command, "tmutest") == 0) tmutest();
		else if(strcmp(command, "tmudemo") == 0) tmudemo();
		else if(strcmp(command, "echo") == 0) echo();

		else if(strcmp(command, "") != 0) printf("Command not found: '%s'\n", command);
	}
}

static char command_buffer[512];
static unsigned int command_index;

static void prompt()
{
	if(irender)
		putsnonl("\e[1mpreset% \e[0m");
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
	cpustats_enter();
	switch(c) {
		case 0x7f:
		case 0x08:
			if(command_index > 0) {
				command_index--;
				putsnonl("\x08 \x08");
			}
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
				writechar(c);
				command_buffer[command_index] = c;
				command_index++;
			}
			break;
	}
	cpustats_leave();
}

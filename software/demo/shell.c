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

#include <libc.h>
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

#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/tmu.h>
#include <hal/time.h>
#include <hal/brd.h>

#include "line.h"
#include "wave.h"
#include "rpipe.h"
#include "cpustats.h"
#include "shell.h"
#include "ui.h"

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

	ui_render_from_file(filename);
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

	time_get(&ts);
	secs = ts.sec;
	mins = secs/60;
	secs -= mins*60;
	hours = mins/60;
	mins -= hours*60;
	printf("Uptime: %02d:%02d:%02d  FPS: %d  CPU:%3d%%\n", hours, mins, secs,
		rpipe_fps(),
		cpustats_load());
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
	puts("stop       - stop renderer");
	puts("spam       - start/stop advertising");
	puts("stats      - print system stats");
}

/*
 * Low-level PFPU test, bypassing driver.
 * This test should only be run when the driver task queue
 * is empty.
 */
static void pfputest()
{
	unsigned int mesh[128][128];
	unsigned int *pfpu_regs = (unsigned int *)CSR_PFPU_DREGBASE;
	unsigned int *pfpu_code = (unsigned int *)CSR_PFPU_CODEBASE;
	int x, y;
	int timeout;
	unsigned int oldmask;

	/* Do not let the driver get our interrupt */
	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_PFPU));

	for(y=0;y<128;y++)
		for(x=0;x<128;x++)
			mesh[y][x] = 0xdeadbeef;

	CSR_PFPU_MESHBASE = (unsigned int)mesh;
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
	pfpu_code[ 9] = 0x0000007f;

	/*printf("Program:\n");
	for(x=0;x<10;x++)
		printf("%08x ", pfpu_code[x]);
	printf("\n");*/

	CSR_PFPU_CTL = PFPU_CTL_START;
	printf("Waiting for PFPU...\n");
	timeout = 30;
	do {
		printf("%08x vertices:%d collisions:%d strays:%d dma:%d pc:%04x\n",
			CSR_PFPU_CTL, CSR_PFPU_VERTICES, CSR_PFPU_COLLISIONS, CSR_PFPU_STRAYWRITES, CSR_PFPU_DMAPENDING, 4*CSR_PFPU_PC);
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
			printf("%08x ", mesh[y][x]);
		printf("\n");
	}

	printf("Program:\n");
	for(x=0;x<10;x++)
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
	struct tmu_vertex srcmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE];
	struct tmu_vertex dstmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE];
	struct tmu_td td;
	volatile int complete;

	for(y=0;y<=24;y++)
		for(x=0;x<=32;x++) {
			srcmesh[y][x].x = 30*x;
			srcmesh[y][x].y = 30*y;
		
			dstmesh[y][x].x = 20*x;
			dstmesh[y][x].y = 20*y;
		}

	td.hmeshlast = 32;
	td.vmeshlast = 24;
	td.brightness = TMU_BRIGHTNESS_MAX;
	td.srcmesh = &srcmesh[0][0];
	td.srcfbuf = vga_frontbuffer;
	td.srchres = vga_hres;
	td.srcvres = vga_vres;
	td.dstmesh = &dstmesh[0][0];
	td.dstfbuf = vga_backbuffer;
	td.dsthres = vga_hres;
	td.dstvres = vga_vres;
	
	td.profile = 1;
	td.callback = tmutest_callback;
	td.user = (void *)&complete;

	complete = 0;
	tmu_submit_task(&td);
	while(!complete);
	vga_swap_buffers();
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

static void do_command(char *c)
{
	char *token;

	token = get_token(&c);

	if(strcmp(token, "mr") == 0) mr(get_token(&c), get_token(&c));
	else if(strcmp(token, "mw") == 0) mw(get_token(&c), get_token(&c), get_token(&c));
	else if(strcmp(token, "ls") == 0) ls();
	else if(strcmp(token, "flush") == 0) flush_bridge_cache();
	else if(strcmp(token, "render") == 0) render(get_token(&c));
	else if(strcmp(token, "stop") == 0) ui_render_stop();
	else if(strcmp(token, "spam") == 0) spam();
	else if(strcmp(token, "stats") == 0) stats();
	else if(strcmp(token, "help") == 0) help();

	/* Test functions and hacks */
	else if(strcmp(token, "pfputest") == 0) pfputest();
	else if(strcmp(token, "tmutest") == 0) tmutest();
	else if(strcmp(token, "echo") == 0) echo();

	else if(strcmp(token, "") != 0) printf("Command not found: '%s'\n", token);
}

static char command_buffer[64];
static unsigned int command_index;

static void prompt()
{
	putsnonl("\e[1m% \e[0m");
}

void shell_init()
{
	prompt();
	command_index = 0;
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

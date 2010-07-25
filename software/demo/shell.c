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

#include <hal/vga.h>
#include <hal/snd.h>
#include <hal/tmu.h>
#include <hal/time.h>
#include <hal/brd.h>
#include <hal/vin.h>

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

static void ls()
{
	if(!fatfs_init(BLOCKDEV_FLASH, 0)) return;
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

static void render(const char *filename)
{
	char buffer[8192];
	int size;

	if(*filename == 0) {
		printf("render <filename>\n");
		return;
	}

	if(!fatfs_init(BLOCKDEV_FLASH, 0)) return;
	if(!fatfs_load(filename, buffer, sizeof(buffer), &size)) return;
	fatfs_done();
	buffer[size] = 0;

	renderer_start(buffer);
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
	puts("Milkymist demo firmware\n");
	puts("Available commands:");
	puts("ls         - list files on the memory card");
	puts("render     - start rendering a patch");
	puts("irender    - input patch equations interactively");
	puts("stop       - stop renderer");
	puts("stats      - print system stats");
	puts("reboot     - system reset");
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

	if(!fatfs_init(BLOCKDEV_FLASH, 0)) return;
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
	unsigned int oldmask;
	int i;
	int zoom;
	int x, y;
	static struct tmu_vertex srcmesh[TMU_MESH_MAXSIZE][TMU_MESH_MAXSIZE] __attribute__((aligned(8)));
	static unsigned short int texture[512*512] __attribute__((aligned(16)));
	struct tmu_td td;
	volatile int complete;
	unsigned int t;
	int hits, reqs;

	/* Disable slowout */
	oldmask = irq_getmask();
	irq_setmask(oldmask & (~IRQ_TIMER1));
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

	irq_ack(IRQ_TIMER1);
	irq_setmask(oldmask);
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

#define MEMCARD_DEBUG

static void memcard_start_cmd_tx()
{
	CSR_MEMCARD_ENABLE = MEMCARD_ENABLE_CMD_TX;
}

static void memcard_start_cmd_rx()
{
	CSR_MEMCARD_PENDING = MEMCARD_PENDING_CMD_RX;
	CSR_MEMCARD_START = MEMCARD_START_CMD_RX;
	CSR_MEMCARD_ENABLE = MEMCARD_ENABLE_CMD_RX;
}

static void memcard_start_cmd_dat_rx()
{
	CSR_MEMCARD_PENDING = MEMCARD_PENDING_CMD_RX|MEMCARD_PENDING_DAT_RX;
	CSR_MEMCARD_START = MEMCARD_START_CMD_RX|MEMCARD_START_DAT_RX;
	CSR_MEMCARD_ENABLE = MEMCARD_ENABLE_CMD_RX|MEMCARD_ENABLE_DAT_RX;
}

static void memcard_send_command(unsigned char cmd, unsigned int arg)
{
	unsigned char packet[6];
	int a;
	int i;
	unsigned char data;
	unsigned char crc;

	packet[0] = cmd | 0x40;
	packet[1] = ((arg >> 24) & 0xff);
	packet[2] = ((arg >> 16) & 0xff);
	packet[3] = ((arg >> 8) & 0xff);
	packet[4] = (arg & 0xff);

	crc = 0;
	for(a=0;a<5;a++) {
		data = packet[a];
		for(i=0;i<8;i++) {
			crc <<= 1;
			if((data & 0x80) ^ (crc & 0x80))
				crc ^= 0x09;
			data <<= 1;
		}
	}
	crc = (crc<<1) | 1;
	
	packet[5] = crc;

#ifdef MEMCARD_DEBUG
	printf(">> %02x %02x %02x %02x %02x %02x\n", packet[0], packet[1], packet[2], packet[3], packet[4], packet[5]);
#endif

	for(i=0;i<6;i++) {
		CSR_MEMCARD_CMD = packet[i];
		while(CSR_MEMCARD_PENDING & MEMCARD_PENDING_CMD_TX);
	}
}

static void memcard_send_dummy()
{
	CSR_MEMCARD_CMD = 0xff;
	while(CSR_MEMCARD_PENDING & MEMCARD_PENDING_CMD_TX);
}

static int memcard_receive_command(unsigned char *buffer)
{
	int i;
	int timeout;

	for(i=0;i<6;i++) {
		timeout = 2000000;
		while(!(CSR_MEMCARD_PENDING & MEMCARD_PENDING_CMD_RX)) {
			timeout--;
			if(timeout == 0) {
				#ifdef MEMCARD_DEBUG
				printf("Command receive timeout\n");
				#endif
				return 0;
			}
		}
		buffer[i] = CSR_MEMCARD_CMD;
		CSR_MEMCARD_PENDING = MEMCARD_PENDING_CMD_RX;
	}

	#ifdef MEMCARD_DEBUG
	printf("<< %02x %02x %02x %02x %02x %02x\n", buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5]);
	#endif

	
	return 1;
}

static int memcard_receive_command_data(unsigned char *command, unsigned int *data)
{
	int i, j;
	int timeout;

	i = 0;
	j = 0;
	while(j < 129) {
		timeout = 2000000;
		while(!(CSR_MEMCARD_PENDING & (MEMCARD_PENDING_CMD_RX|MEMCARD_PENDING_DAT_RX))) {
			timeout--;
			if(timeout == 0) {
				#ifdef MEMCARD_DEBUG
				printf("Command receive timeout\n");
				#endif
				return 0;
			}
		}
		if(CSR_MEMCARD_PENDING & MEMCARD_PENDING_CMD_RX) {
			command[i++] = CSR_MEMCARD_CMD;
			CSR_MEMCARD_PENDING = MEMCARD_PENDING_CMD_RX;
			if(i == 6)
				CSR_MEMCARD_ENABLE = MEMCARD_ENABLE_DAT_RX; /* disable command RX */
		}
		if(CSR_MEMCARD_PENDING & MEMCARD_PENDING_DAT_RX) {
			data[j++] = CSR_MEMCARD_DAT;
			CSR_MEMCARD_PENDING = MEMCARD_PENDING_DAT_RX;
		}
	}

	#ifdef MEMCARD_DEBUG
	printf("<< %02x %02x %02x %02x %02x %02x\n", command[0], command[1], command[2], command[3], command[4], command[5]);
	#endif

	return 1;
}

static void memcard()
{
	int i;
	unsigned char b[6];
	unsigned int rca;
	unsigned int bd[129];
	struct timestamp t0, t1, d;

	CSR_MEMCARD_CLK2XDIV = 250;

	/* CMD0 */
	memcard_start_cmd_tx();
	memcard_send_command(0, 0);

	memcard_send_dummy();

	/* CMD8 */
	memcard_send_command(8, 0x1aa);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;

	/* ACMD41 - initialize */
	while(1) {
		memcard_start_cmd_tx();
		memcard_send_command(55, 0);
		memcard_start_cmd_rx();
		if(!memcard_receive_command(b)) return;
		memcard_start_cmd_tx();
		memcard_send_command(41, 0x00300000);
		memcard_start_cmd_rx();
		if(!memcard_receive_command(b)) return;
		if(b[1] & 0x80) break;
		printf("Card is busy, retrying\n");
	}

	/* CMD2 - get CID */
	memcard_start_cmd_tx();
	memcard_send_command(2, 0);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;

	/* CMD3 - get RCA */
	memcard_start_cmd_tx();
	memcard_send_command(3, 0);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;
	rca = (((unsigned int)b[1]) << 8)|((unsigned int)b[2]);
	printf("RCA: %04x\n", rca);

	/* CMD3 - get RCA. Seems we need to do it twice for some reason. */
	memcard_start_cmd_tx();
	memcard_send_command(3, 0);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;
	rca = (((unsigned int)b[1]) << 8)|((unsigned int)b[2]);
	printf("RCA: %04x\n", rca);

	/* CMD7 - select card */
	memcard_start_cmd_tx();
	memcard_send_command(7, rca << 16);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;
	
	/* ACMD6 - set bus width */
	memcard_start_cmd_tx();
	memcard_send_command(55, rca << 16);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;
	memcard_start_cmd_tx();
	memcard_send_command(6, 2);
	memcard_start_cmd_rx();
	if(!memcard_receive_command(b)) return;

	CSR_MEMCARD_CLK2XDIV = 2;

	/* CMD17 - read block */
	time_get(&t0);
	memcard_start_cmd_tx();
	memcard_send_command(17, 0);
	memcard_start_cmd_dat_rx();
	if(!memcard_receive_command_data(b, bd)) return;
	time_get(&t1);
	for(i=0;i<129;i++)
		printf("%08x ", bd[i]);
	printf("\n");
	time_diff(&d, &t1, &t0);
	printf("Transfer speed: %d KB/s\n", 500000/d.usec);
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
		else if(strcmp(command, "edid") == 0) edid();
		else if(strcmp(command, "render") == 0) render(param1);
		else if(strcmp(command, "irender") == 0) {
			renderer_istart();
			irender = 1;
		} else if(strcmp(command, "stop") == 0) renderer_stop();
		else if(strcmp(command, "stats") == 0) stats();
		else if(strcmp(command, "reboot") == 0) reboot();
		else if(strcmp(command, "help") == 0) help();

		/* Test functions and hacks */
		else if(strcmp(command, "cpucfg") == 0) cpucfg();
		else if(strcmp(command, "loadpic") == 0) loadpic(param1);
		else if(strcmp(command, "checker") == 0) checker();
		else if(strcmp(command, "pfputest") == 0) pfputest();
		else if(strcmp(command, "tmutest") == 0) tmutest();
		else if(strcmp(command, "tmubench") == 0) tmubench();
		else if(strcmp(command, "echo") == 0) echo();
		else if(strcmp(command, "testv") == 0) testv();
		else if(strcmp(command, "readv") == 0) readv(param1);
		else if(strcmp(command, "writev") == 0) writev(param1, param2);
		else if(strcmp(command, "irtest") == 0) irtest();
		else if(strcmp(command, "midirx") == 0) midirx();
		else if(strcmp(command, "miditx") == 0) miditx(param1);
		else if(strcmp(command, "memcard") == 0) memcard();

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

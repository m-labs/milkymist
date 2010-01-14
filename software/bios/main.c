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
#include <console.h>
#include <string.h>
#include <uart.h>
#include <cffat.h>
#include <crc.h>
#include <system.h>
#include <board.h>
#include <version.h>
#include <hw/hpdmc.h>
#include <hw/vga.h>
#include <hw/fmlbrg.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>
#include <hw/uart.h>

#include "boot.h"
#include "splash.h"

const struct board_desc *brd_desc;

/* SDRAM functions */

static int dqs_ps;

static void ddrinit()
{
	volatile unsigned int i;

	putsnonl("I: Initializing SDRAM [DDR200 CL=2 BL=8]...");
	/* Bring CKE high */
	CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_BYPASS|HPDMC_SYSTEM_RESET|HPDMC_SYSTEM_CKE;
	for(i=0;i<2;i++);
	CSR_HPDMC_BYPASS = 0x400B;	/* Precharge All */
	for(i=0;i<2;i++);
	CSR_HPDMC_BYPASS = 0x2000F;	/* Load Extended Mode Register */
	for(i=0;i<2;i++);
	CSR_HPDMC_BYPASS = 0x123F;	/* Load Mode Register */
	for(i=0;i<200;i++);
	CSR_HPDMC_BYPASS = 0x400B;	/* Precharge All */
	for(i=0;i<2;i++);
	CSR_HPDMC_BYPASS = 0xD;		/* Auto Refresh */
	for(i=0;i<8;i++);
	CSR_HPDMC_BYPASS = 0xD;		/* Auto Refresh */
	for(i=0;i<8;i++);
	CSR_HPDMC_BYPASS = 0x23F;	/* Load Mode Register, Enable DLL */
	for(i=0;i<200;i++);
	/* Leave Bypass mode and bring up hardware controller */
	CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_CKE;
	
	/* Set up pre-programmed data bus timings */
	CSR_HPDMC_IODELAY = HPDMC_IDELAY_RST;
	for(i=0;i<brd_desc->ddr_idelay;i++)
		CSR_HPDMC_IODELAY = HPDMC_IDELAY_CE|HPDMC_IDELAY_INC;
	
	dqs_ps = brd_desc->ddr_dqsdelay;
	for(i=0;i<brd_desc->ddr_dqsdelay;i++) {
		CSR_HPDMC_IODELAY = HPDMC_DQSDELAY_CE|HPDMC_DQSDELAY_INC;
		while(!(CSR_HPDMC_IODELAY & HPDMC_DQSDELAY_RDY));
	}
	
	printf("OK\n");
}

static int plltest()
{
	int ok1, ok2;

	printf("I: Checking if SDRAM clocking is functional:\n");
	ok1 = CSR_HPDMC_IODELAY & HPDMC_PLL1_LOCKED;
	ok2 = CSR_HPDMC_IODELAY & HPDMC_PLL2_LOCKED;
	printf("I:   PLL#1: %s\n", ok1 ? "Locked" : "Error");
	printf("I:   PLL#2: %s\n", ok2 ? "Locked" : "Error");
	return(ok1 && ok2);
}

static int memtest(unsigned int div)
{
	unsigned int *testbuf = (unsigned int *)SDRAM_BASE;
	unsigned int expected;
	unsigned int i;
	unsigned int size;

	putsnonl("I: SDRAM test...");

	size = brd_desc->sdram_size*1024*1024/(4*div);
	for(i=0;i<size;i++)
		testbuf[i] = i;

	/* NB. The Mico32 cache (Level-1) is write-through,
	 * therefore there is no order to flush the cache hierarchy.
	 */
	asm volatile( /* Invalidate Level-1 data cache */
		"wcsr DCC, r0\n"
		"nop\n"
	);
	flush_bridge_cache(); /* Invalidate Level-2 cache */

	for(i=0;i<size;i++) {
		expected = i;
		if(testbuf[i] != expected) {
			printf("\nE: Failed offset 0x%08x (got 0x%08x, expected 0x%08x)\n", i, testbuf[i], expected);
			return 0;
		}
	}

	printf("%u/%uMB tested OK\n", brd_desc->sdram_size/div, brd_desc->sdram_size);
	return 1;
}

static void calibrate()
{
	int taps;
	int quit;
	char c;

	printf("================================\n");
	printf("DDR SDRAM calibration tool\n");
	printf("================================\n");
	printf("Memo:\n");
	printf("[> Input Delay\n");
	printf(" r = reset to 0 taps\n");
	printf(" u = add 1 tap\n");
	printf(" d = remove 1 tap\n");
	printf("[> DQS output phase\n");
	printf(" U = increase phase\n");
	printf(" D = decrease phase\n");
	printf("[> Misc\n");
	printf(" t = load image to framebuffer\n");
	printf(" q = quit\n");
	
	CSR_VGA_RESET = 0;
	
	CSR_HPDMC_IODELAY = HPDMC_IDELAY_RST;
	
	taps = 0;
	quit = 0;
	while(!quit) {
		printf("Taps: %02d (78ps each) - DQS phase: %04d/255\r", taps, dqs_ps);
		c = readchar();
		switch(c) {
			case 'q':
				quit = 1;
				break;
			case 'r':
				taps = 0;
				CSR_HPDMC_IODELAY = HPDMC_IDELAY_RST;
				break;
			case 'u':
				if(taps < 63) {
					taps++;
					CSR_HPDMC_IODELAY = HPDMC_IDELAY_CE|HPDMC_IDELAY_INC;
				}
				break;
			case 'd':
				if(taps > 0) {
					taps--;
					CSR_HPDMC_IODELAY = HPDMC_IDELAY_CE;
				}
				break;
			case 'U':
				if(dqs_ps < 255) {
					dqs_ps++;
					CSR_HPDMC_IODELAY = HPDMC_DQSDELAY_CE|HPDMC_DQSDELAY_INC;
					while(!(CSR_HPDMC_IODELAY & HPDMC_DQSDELAY_RDY));
				}
				break;
			case 'D':
				if(dqs_ps > 0) {
					dqs_ps--;
					CSR_HPDMC_IODELAY = HPDMC_DQSDELAY_CE;
					while(!(CSR_HPDMC_IODELAY & HPDMC_DQSDELAY_RDY));
				}
				break;
			case 't':
				splash_display((void *)SDRAM_BASE);
				break;
		}
	}

	CSR_VGA_RESET = VGA_RESET;

	printf("\n");
}

/* General address space functions */

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
	unsigned int *addr;
	unsigned int length;

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
	unsigned int *addr2;
	unsigned int value2;
	unsigned int count2;
	unsigned int i;

	if((*addr == 0) || (*value == 0)) {
		printf("mw <address> <value> [count]\n");
		return;
	}
	addr2 = (unsigned int *)strtoul(addr, &c, 0);
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

static void mc(char *dstaddr, char *srcaddr, char *count)
{
	char *c;
	unsigned int *dstaddr2;
	unsigned int *srcaddr2;
	unsigned int count2;
	unsigned int i;

	if((*dstaddr == 0) || (*srcaddr == 0)) {
		printf("mc <dst> <src> [count]\n");
		return;
	}
	dstaddr2 = (unsigned int *)strtoul(dstaddr, &c, 0);
	if(*c != 0) {
		printf("incorrect destination address\n");
		return;
	}
	srcaddr2 = (unsigned int *)strtoul(srcaddr, &c, 0);
	if(*c != 0) {
		printf("incorrect source address\n");
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
	for (i=0;i<count2;i++) *dstaddr2++ = *srcaddr2++;
}

static void crc(char *startaddr, char *len)
{
	char *c;
	char *addr;
	unsigned int length;

	if((*startaddr == 0)||(*len == 0)) {
		printf("crc <address> <length>\n");
		return;
	}
	addr = (char *)strtoul(startaddr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	length = strtoul(len, &c, 0);
	if(*c != 0) {
		printf("incorrect length\n");
		return;
	}

	printf("CRC32: %08x\n", crc32((unsigned char *)addr, length));
}

/* CF filesystem functions */

static int lscb(const char *filename, const char *longname, void *param)
{
	printf("%12s [%s]\n", filename, longname);
	return 1;
}

static void ls()
{
	if(brd_desc->memory_card == MEMCARD_NONE) {
		printf("E: No memory card on this board\n");
		return;
	}
	cffat_init();
	cffat_list_files(lscb, NULL);
	cffat_done();
}

static void load(char *filename, char *addr)
{
	char *c;
	unsigned int *addr2;

	if(brd_desc->memory_card == MEMCARD_NONE) {
		printf("E: No memory card on this board\n");
		return;
	}

	if((*filename == 0) || (*addr == 0)) {
		printf("load <filename> <address>\n");
		return;
	}
	addr2 = (unsigned *)strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	cffat_init();
	cffat_load(filename, (char *)addr2, 16*1024*1024, NULL);
	cffat_done();
}

/* Init + command line */

static void help()
{
	puts("This is the Milkymist BIOS debug shell.");
	puts("It is used for system development and maintainance, and not");
	puts("for regular operation.\n");
	puts("Available commands:");
	puts("plltest    - print status of the SDRAM clocking PLLs");
	puts("memtest    - extended SDRAM test");
	puts("calibrate  - run DDR SDRAM calibration tool");
	puts("flush      - flush FML bridge cache");
	puts("mr         - read address space");
	puts("mw         - write address space");
	puts("mc         - copy address space");
	puts("crc        - compute CRC32 of a part of the address space");
	puts("ls         - list files on the memory card");
	puts("load       - load a file from the memory card");
	puts("serialboot - attempt SFL boot");
	puts("cardboot   - attempt booting from memory card");
	puts("reboot     - system reset");
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

	if(strcmp(token, "plltest") == 0) plltest();
	else if(strcmp(token, "memtest") == 0) memtest(1);
	else if(strcmp(token, "calibrate") == 0) calibrate();
	else if(strcmp(token, "flush") == 0) flush_bridge_cache();

	else if(strcmp(token, "mr") == 0) mr(get_token(&c), get_token(&c));
	else if(strcmp(token, "mw") == 0) mw(get_token(&c), get_token(&c), get_token(&c));
	else if(strcmp(token, "mc") == 0) mc(get_token(&c), get_token(&c), get_token(&c));
	else if(strcmp(token, "crc") == 0) crc(get_token(&c), get_token(&c));
	
	else if(strcmp(token, "ls") == 0) ls();
	else if(strcmp(token, "load") == 0) load(get_token(&c), get_token(&c));
	
	else if(strcmp(token, "serialboot") == 0) serialboot();
	else if(strcmp(token, "cardboot") == 0) cardboot(0);

	else if(strcmp(token, "reboot") == 0) reboot();
	
	else if(strcmp(token, "help") == 0) help();
	
	else if(strcmp(token, "") != 0)
		printf("Command not found\n");
}

static int test_user_abort()
{
	unsigned int i;
	char c;
	
	puts("I: Press Q to abort boot");
	for(i=0;i<4000000;i++) {
		if(readchar_nonblock()) {
			c = readchar();
			if(c == 'Q') {
				puts("I: Aborted boot on user request");
				return 0;
			}
		}
	}
	return 1;
}

extern unsigned int _edata;

static void crcbios()
{
	unsigned int length;
	unsigned int expected_crc;
	unsigned int actual_crc;
	
	/*
	 * _edata is located right after the end of the flat
	 * binary image. The CRC tool writes the 32-bit CRC here.
	 * We also use the address of _edata to know the length
	 * of our code.
	 */
	expected_crc = _edata;
	length = (unsigned int)&_edata;
	actual_crc = crc32((unsigned char *)0, length);
	if(expected_crc == actual_crc)
		printf("I: BIOS CRC passed (%08x)\n", actual_crc);
	else {
		printf("W: BIOS CRC failed (expected %08x, got %08x)\n", expected_crc, actual_crc);
		printf("W: The system will continue, but expect problems.\n");
	}
}

static void display_board()
{
	if(brd_desc == NULL) {
		printf("E: Running on unknown board (ID=0x%08x), startup aborted.\n", CSR_SYSTEM_ID);
		while(1);
	}
	printf("I: Running on %s\n", brd_desc->name);
}

static const char banner[] =
	"\nMILKYMIST(tm) v"VERSION" BIOS\thttp://www.milkymist.org\n"
	"(c) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq\n\n"
	"This program is free software: you can redistribute it and/or modify\n"
	"it under the terms of the GNU General Public License as published by\n"
	"the Free Software Foundation, version 3 of the License.\n\n";

static void boot_sequence()
{
	splash_display((void *)(SDRAM_BASE+1024*1024*(brd_desc->sdram_size-4)));
	if(test_user_abort()) {
		serialboot(1);
		if(brd_desc->memory_card != MEMCARD_NONE) {
			if(CSR_GPIO_IN & GPIO_DIP1)
				cardboot(1);
			else
				cardboot(0);
		}
		printf("E: No boot medium found\n");
	}
}

int main(int i, char **c)
{
	char buffer[64];

	brd_desc = get_board_desc();

	/* Check for double baud rate */
	if(brd_desc != NULL) {
		if(CSR_GPIO_IN & GPIO_DIP2)
			CSR_UART_DIVISOR = brd_desc->clk_frequency/230400/16;
	}

	/* Display a banner as soon as possible to show that the system is alive */
	putsnonl(banner);
	
	crcbios();
	display_board();
	
	if(plltest()) {
		ddrinit();
		flush_bridge_cache();

		if(memtest(8))
			boot_sequence();
		else
			printf("E: Aborted boot on memory error\n");
	} else
		printf("E: Faulty SDRAM clocking\n");

	splash_showerr();
	while(1) {
		putsnonl("\e[1mBIOS>\e[0m ");
		readstr(buffer, 64);
		do_command(buffer);
	}
	return 0;
}

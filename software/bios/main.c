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
#include <blockdev.h>
#include <fatfs.h>
#include <crc.h>
#include <system.h>
#include <board.h>
#include <version.h>
#include <net/mdio.h>
#include <hw/vga.h>
#include <hw/fmlbrg.h>
#include <hw/sysctl.h>
#include <hw/capabilities.h>
#include <hw/gpio.h>
#include <hw/uart.h>
#include <hw/hpdmc.h>
#include <hw/flash.h>

#include "boot.h"
#include "splash.h"

const struct board_desc *brd_desc;

enum {
	CSR_IE = 1, CSR_IM, CSR_IP, CSR_ICC, CSR_DCC, CSR_CC, CSR_CFG, CSR_EBA,
	CSR_DC, CSR_DEBA, CSR_JTX, CSR_JRX, CSR_BP0, CSR_BP1, CSR_BP2, CSR_BP3,
	CSR_WP0, CSR_WP1, CSR_WP2, CSR_WP3,
};

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

/* processor registers */
static int parse_csr(const char *csr)
{
	if (!strcmp(csr, "ie"))   return CSR_IE;
	if (!strcmp(csr, "im"))   return CSR_IM;
	if (!strcmp(csr, "ip"))   return CSR_IP;
	if (!strcmp(csr, "icc"))  return CSR_ICC;
	if (!strcmp(csr, "dcc"))  return CSR_DCC;
	if (!strcmp(csr, "cc"))   return CSR_CC;
	if (!strcmp(csr, "cfg"))  return CSR_CFG;
	if (!strcmp(csr, "eba"))  return CSR_EBA;
	if (!strcmp(csr, "dc"))   return CSR_DC;
	if (!strcmp(csr, "deba")) return CSR_DEBA;
	if (!strcmp(csr, "jtx"))  return CSR_JTX;
	if (!strcmp(csr, "jrx"))  return CSR_JRX;
	if (!strcmp(csr, "bp0"))  return CSR_BP0;
	if (!strcmp(csr, "bp1"))  return CSR_BP1;
	if (!strcmp(csr, "bp2"))  return CSR_BP2;
	if (!strcmp(csr, "bp3"))  return CSR_BP3;
	if (!strcmp(csr, "wp0"))  return CSR_WP0;
	if (!strcmp(csr, "wp1"))  return CSR_WP1;
	if (!strcmp(csr, "wp2"))  return CSR_WP2;
	if (!strcmp(csr, "wp3"))  return CSR_WP3;

	return 0;
}

static void rcsr(char *csr)
{
	unsigned int csr2;
	register unsigned int value;

	if(*csr == 0) {
		printf("rcsr <csr>\n");
		return;
	}

	csr2 = parse_csr(csr);
	if(csr2 == 0) {
		printf("incorrect csr\n");
		return;
	}

	switch (csr2)
	{
		case CSR_IE:   asm volatile ("rcsr %0,ie":"=r"(value)); break;
		case CSR_IM:   asm volatile ("rcsr %0,im":"=r"(value)); break;
		case CSR_IP:   asm volatile ("rcsr %0,ip":"=r"(value)); break;
		case CSR_CC:   asm volatile ("rcsr %0,cc":"=r"(value)); break;
		case CSR_CFG:  asm volatile ("rcsr %0,cfg":"=r"(value)); break;
		case CSR_EBA:  asm volatile ("rcsr %0,eba":"=r"(value)); break;
		case CSR_DEBA: asm volatile ("rcsr %0,deba":"=r"(value)); break;
		case CSR_JTX:  asm volatile ("rcsr %0,jtx":"=r"(value)); break;
		case CSR_JRX:  asm volatile ("rcsr %0,jrx":"=r"(value)); break;
		default: printf("csr write only\n"); return;
	}

	printf("%08x\n", value);
}

static void wcsr(char *csr, char *value)
{
	char *c;
	unsigned int csr2;
	register unsigned int value2;

	if((*csr == 0) || (*value == 0)) {
		printf("wcsr <csr> <address>\n");
		return;
	}

	csr2 = parse_csr(csr);
	if(csr2 == 0) {
		printf("incorrect csr\n");
		return;
	}
	value2 = strtoul(value, &c, 0);
	if(*c != 0) {
		printf("incorrect value\n");
		return;
	}

	switch (csr2)
	{
		case CSR_IE:   asm volatile ("wcsr ie,%0"::"r"(value2)); break;
		case CSR_IM:   asm volatile ("wcsr im,%0"::"r"(value2)); break;
		case CSR_ICC:  asm volatile ("wcsr icc,%0"::"r"(value2)); break;
		case CSR_DCC:  asm volatile ("wcsr dcc,%0"::"r"(value2)); break;
		case CSR_EBA:  asm volatile ("wcsr eba,%0"::"r"(value2)); break;
		case CSR_DC:   asm volatile ("wcsr dcc,%0"::"r"(value2)); break;
		case CSR_DEBA: asm volatile ("wcsr deba,%0"::"r"(value2)); break;
		case CSR_JTX:  asm volatile ("wcsr jtx,%0"::"r"(value2)); break;
		case CSR_JRX:  asm volatile ("wcsr jrx,%0"::"r"(value2)); break;
		case CSR_BP0:  asm volatile ("wcsr bp0,%0"::"r"(value2)); break;
		case CSR_BP1:  asm volatile ("wcsr bp1,%0"::"r"(value2)); break;
		case CSR_BP2:  asm volatile ("wcsr bp2,%0"::"r"(value2)); break;
		case CSR_BP3:  asm volatile ("wcsr bp3,%0"::"r"(value2)); break;
		case CSR_WP0:  asm volatile ("wcsr wp0,%0"::"r"(value2)); break;
		case CSR_WP1:  asm volatile ("wcsr wp1,%0"::"r"(value2)); break;
		case CSR_WP2:  asm volatile ("wcsr wp2,%0"::"r"(value2)); break;
		case CSR_WP3:  asm volatile ("wcsr wp3,%0"::"r"(value2)); break;
		default: printf("csr read only\n"); return;
	}
}


/* CF filesystem functions */

static int lscb(const char *filename, const char *longname, void *param)
{
	printf("%12s [%s]\n", filename, longname);
	return 1;
}

static void ls(char *dev)
{
	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	fatfs_list_files(lscb, NULL);
	fatfs_done();
}

static void load(char *filename, char *addr, char *dev)
{
	char *c;
	unsigned int *addr2;

	if((*filename == 0) || (*addr == 0)) {
		printf("load <filename> <address>\n");
		return;
	}
	addr2 = (unsigned *)strtoul(addr, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	if(!fatfs_init(BLOCKDEV_MEMORY_CARD)) return;
	fatfs_load(filename, (char *)addr2, 16*1024*1024, NULL);
	fatfs_done();
}

static void mdior(char *reg)
{
	char *c;
	int reg2;

	if(*reg == 0) {
		printf("mdior <register>\n");
		return;
	}
	reg2 = strtoul(reg, &c, 0);
	if(*c != 0) {
		printf("incorrect register\n");
		return;
	}

	printf("%04x\n", mdio_read(brd_desc->ethernet_phyadr, reg2));
}

static void mdiow(char *reg, char *value)
{
	char *c;
	int reg2;
	int value2;

	if((*reg == 0) || (*value == 0)) {
		printf("mdiow <register> <value>\n");
		return;
	}
	reg2 = strtoul(reg, &c, 0);
	if(*c != 0) {
		printf("incorrect address\n");
		return;
	}
	value2 = strtoul(value, &c, 0);
	if(*c != 0) {
		printf("incorrect value\n");
		return;
	}

	mdio_write(brd_desc->ethernet_phyadr, reg2, value2);
}

static void xmt()
{
	unsigned int testbuf[64000];
	int i, j;
	unsigned int r;
	unsigned int got;

	r = 0;
	for(i=0;i<64000;i++) {
		r = r*22695477 + 1;
		testbuf[i] = r;
	}

	for(j=0;j<2000;j++) {
		flush_bridge_cache();
		r = 0;
		for(i=0;i<64000;i++) {
			r = r*22695477 + 1;
			got = testbuf[i];
			if(r != got)
				printf("%08x / %08x [%08x]\n", got, r, got ^ r);
		}
	}
}

/* Init + command line */

static void help()
{
	puts("This is the Milkymist BIOS debug shell.");
	puts("It is used for system development and maintainance, and not");
	puts("for regular operation.\n");
	puts("Available commands:");
	puts("flush      - flush FML bridge cache");
	puts("mr         - read address space");
	puts("mw         - write address space");
	puts("mc         - copy address space");
	puts("crc        - compute CRC32 of a part of the address space");
	puts("rcsr       - read processor CSR");
	puts("wcsr       - write processor CSR");
	puts("ls         - list files on the filesystem");
	puts("load       - load a file from the filesystem");
	puts("netboot    - boot via TFTP");
	puts("serialboot - boot via SFL");
	puts("fsboot     - boot from the filesystem");
	puts("mdior      - read MDIO register");
	puts("mdiow      - write MDIO register");
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

	if(strcmp(token, "flush") == 0) flush_bridge_cache();

	else if(strcmp(token, "mr") == 0) mr(get_token(&c), get_token(&c));
	else if(strcmp(token, "mw") == 0) mw(get_token(&c), get_token(&c), get_token(&c));
	else if(strcmp(token, "mc") == 0) mc(get_token(&c), get_token(&c), get_token(&c));
	else if(strcmp(token, "crc") == 0) crc(get_token(&c), get_token(&c));
	
	else if(strcmp(token, "ls") == 0) ls(get_token(&c));
	else if(strcmp(token, "load") == 0) load(get_token(&c), get_token(&c), get_token(&c));

	else if(strcmp(token, "netboot") == 0) netboot();
	else if(strcmp(token, "serialboot") == 0) serialboot();
	else if(strcmp(token, "fsboot") == 0) fsboot(BLOCKDEV_MEMORY_CARD);
	else if(strcmp(token, "flashboot") == 0) flashboot();

	else if(strcmp(token, "mdior") == 0) mdior(get_token(&c));
	else if(strcmp(token, "mdiow") == 0) mdiow(get_token(&c), get_token(&c));

	else if(strcmp(token, "reboot") == 0) reboot();
	
	else if(strcmp(token, "help") == 0) help();

	else if(strcmp(token, "xmt") == 0) xmt();

	else if(strcmp(token, "rcsr") == 0) rcsr(get_token(&c));
	else if(strcmp(token, "wcsr") == 0) wcsr(get_token(&c), get_token(&c));
	
	else if(strcmp(token, "") != 0)
		printf("Command not found\n");
}

static int test_user_abort()
{
	unsigned int i;
	char c;
	
	puts("I: Press Q to abort boot");
	for(i=0;i<3500000;i++) {
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

int rescue;

extern unsigned int _edata;

static void crcbios()
{
	unsigned int offset_bios;
	unsigned int length;
	unsigned int expected_crc;
	unsigned int actual_crc;
	
	/*
	 * _edata is located right after the end of the flat
	 * binary image. The CRC tool writes the 32-bit CRC here.
	 * We also use the address of _edata to know the length
	 * of our code.
	 */
	offset_bios = rescue ? FLASH_OFFSET_RESCUE_BIOS : FLASH_OFFSET_REGULAR_BIOS;
	expected_crc = _edata;
	length = (unsigned int)&_edata - offset_bios;
	actual_crc = crc32((unsigned char *)offset_bios, length);
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

#define display_capability(cap, val) if(val) printf("I: "cap": Yes\n"); else printf("I: "cap": No\n")

static void display_capabilities()
{
	unsigned int cap;

	cap = CSR_CAPABILITIES;
	display_capability("Mem. card ", cap & CAP_MEMORYCARD);
	display_capability("AC'97     ", cap & CAP_AC97);
	display_capability("PFPU      ", cap & CAP_PFPU);
	display_capability("TMU       ", cap & CAP_TMU);
	display_capability("Ethernet  ", cap & CAP_ETHERNET);
	display_capability("FML meter ", cap & CAP_FMLMETER);
	display_capability("Video in  ", cap & CAP_VIDEOIN);
	display_capability("MIDI      ", cap & CAP_MIDI);
	display_capability("DMX       ", cap & CAP_DMX);
	display_capability("IR        ", cap & CAP_IR);
	display_capability("USB       ", cap & CAP_USB);
	display_capability("Memtester ", cap & CAP_MEMTEST);
}

static const char banner[] =
	"\nMILKYMIST(tm) v"VERSION" BIOS\thttp://www.milkymist.org\n"
	"(c) Copyright 2007, 2008, 2009, 2010 Sebastien Bourdeauducq\n\n"
	"This program is free software: you can redistribute it and/or modify\n"
	"it under the terms of the GNU General Public License as published by\n"
	"the Free Software Foundation, version 3 of the License.\n\n";

static void boot_sequence()
{
	if(test_user_abort()) {
		if(rescue) {
			netboot();
			serialboot();
			fsboot(BLOCKDEV_MEMORY_CARD);
			flashboot();
		} else {
			fsboot(BLOCKDEV_MEMORY_CARD);
			flashboot();
			netboot();
			serialboot();
		}
		printf("E: No boot medium found\n");
	}
}

int main(int i, char **c)
{
	char buffer[64];

	brd_desc = get_board_desc();

	/* Display a banner as soon as possible to show that the system is alive */
	CSR_GPIO_OUT = GPIO_LED1;
	putsnonl(banner);
	rescue = !((unsigned int)main > FLASH_OFFSET_REGULAR_BIOS);
	if(rescue)
		printf("I: Booting in rescue mode\n");
	
	crcbios();
	display_board();
	display_capabilities();
	splash_display();

	boot_sequence();

	splash_showerr();
	while(1) {
		putsnonl("\e[1mBIOS>\e[0m ");
		readstr(buffer, 64);
		do_command(buffer);
	}
	return 0;
}

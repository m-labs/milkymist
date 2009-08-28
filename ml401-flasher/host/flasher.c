/*
 * ML401 Flasher
 * Copyright (C) 2009 Sebastien Bourdeauducq
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

/* DLC9 cable protocol functions inspired by those in UrJTAG */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <libusb.h>

static libusb_device_handle *devhandle;

static int control(uint8_t bmRequestType, 
	uint8_t bRequest,
	uint16_t wValue,
	uint16_t wIndex,
	void *data,
	uint16_t wLength)
{
	 return libusb_control_transfer(devhandle,
		bmRequestType,
		bRequest,
		wValue,
		wIndex,
		(unsigned char *)data,
		wLength,
		500
	);
}

#define PROG  3
#define TCK   2
#define TMS   1
#define TDI   0
#define TDO   0

static void pio(uint8_t value)
{
	control(0x40, 0xB0, 0x0030, value, NULL, 0);
}

static void cycle(uint8_t tms, uint8_t tdi)
{
	if (tms)
		tms = 1 << TMS;
	if (tdi)
		tdi = 1 << TDI;
	
	pio((1<<PROG) | tms | tdi);
	pio((1<<PROG) | (1<<TCK) | tms | tdi);
	pio((1<<PROG) | tms | tdi);
}

static void init_jtag()
{
	unsigned short int b;
	int i;
	
	// xpcu_request_28
	control(0x40, 0xB0, 0x0028, 0x11,  NULL, 0);
	
	// xpcu_output_enable
	control(0x40, 0xB0,  0x18, 0, NULL, 0);
	control(0x40, 0xB0, 0x0028, 0x12, NULL, 0);
	
	control(0xC0, 0xB0, 0x0050, 0x0000, &b, 2);
	printf("Cable Firmware version: 0x%04x (%u)\n", b, b);
	
	control(0xC0, 0xB0, 0x0050, 0x0001, &b, 2);
	printf("Cable CPLD version: 0x%04x (%u)\n", b, b);
	
	// Go to Test-Logic-Reset
	for(i=0;i<5;i++)
		cycle(1, 0);
	// Go to Run-Test-Idle
	cycle(0, 0);
}

static void shift_ir(uint64_t value, int length)
{
	int i;
	
	// Go to capture IR
	cycle(1, 0); // Go to Select-DR
	cycle(1, 0); // Go to Select-IR
	cycle(0, 0); // Go to Capture-IR
	cycle(0, 0); // Go to Shift IR
	
	for(i=0;i<length;i++)
		cycle((i==(length-1)), (value>>i) & 1);
	
	cycle(1, 0); // Update-IR
	cycle(0, 0); // Run-Test-Idle
}

static void load_ir()
{
	/*
	 * Chain is xc95144xl -> xc4vlx25 ->      xcf32p     ->  xccace
	 *           BYPASS   ->   USER1  ->      BYPASS     ->  BYPASS
	 *          11111111    1111000010  1111111111111111    11111111
	 * so we must shift: 111111111111111111111111111100001011111111 (42 bits)
	 */
	shift_ir(0x3FFFFFFC2FFLL, 42);
}

#define BULK_BUFSIZ 256
static int bulk_n;
static short unsigned int bulk_buffer[256];

static void bulk_start()
{
	bulk_n = 0;
	memset(bulk_buffer, 0, sizeof(bulk_buffer));
}

static void bulk_add(int tms, int tdi, int tck)
{
	int offset;
	int shift;
	
	offset = bulk_n/4;
	shift = bulk_n%4;
	assert(offset < BULK_BUFSIZ);
	
	tms = tms ? 1 : 0;
	tdi = tdi ? 1 : 0;
	tck = tck ? 1 : 0;
	
	bulk_buffer[offset] |= (tdi << shift)|(tms << (shift+4))|(tck << (shift+8));
	
	bulk_n++;
}

static void bulk_end()
{
	int transfer_len;
	int transferred;
	
	bulk_add(0, 0, 0);
	/*
	 * According to UrJTAG:
	 * "Care has to be taken that N is NOT a multiple of 4.
	 * The CPLD doesn't seem to handle that well."
	 */
	if((bulk_n % 4) == 0)
		bulk_add(0, 0, 0);
	
	control(0x40, 0xB0, 0xA6, bulk_n, NULL, 0);
	
	transfer_len = 2*((bulk_n+3)/4);
	libusb_bulk_transfer(devhandle, 0x02, (unsigned char *)&bulk_buffer, transfer_len, &transferred, 500);
}

static void bulk_cycle(uint8_t tms, uint8_t tdi)
{
	bulk_add(tms, tdi, 0);
	bulk_add(tms, tdi, 1);
}

static void bulk_shift_dr(uint64_t value, int length)
{
	int i;

	bulk_cycle(1, 0); // Go to Select-DR
	bulk_cycle(0, 0); // Go to Capture-DR
	bulk_cycle(0, 0); // Go to Shift DR
	
	for(i=0;i<length;i++)
		bulk_cycle((i==(length-1)), (value>>i)&1);
	
	bulk_cycle(1, 0); // Update-DR
	bulk_cycle(0, 0); // Run-Test-Idle
}

static void bulk_set_fpga_pins(uint64_t state, int length)
{
	/*
	 * Chain is xc95144xl -> xc4vlx25 ->      xcf32p     ->  xccace
	 *           1 bit        n bits          1 bit           1 bit
	 *          don't care    payload       don't care      don't care (total n+3 bits)
	 */

	bulk_shift_dr(state << 1, length+3);
}

static void bulk_ctl_flash(unsigned int data, unsigned int adr, int we_n, int ce, int reset_n, int oe_n)
{
	we_n = we_n ? 1 : 0;
	ce = ce ? 1 : 0;
	reset_n = reset_n ? 1 : 0;
	oe_n = oe_n ? 1 : 0;
	
	bulk_set_fpga_pins(
		 data
		|((unsigned long long int)adr << 32)
		|((unsigned long long int)we_n << 53)
		|((unsigned long long int)ce << 54)
		|((unsigned long long int)reset_n << 55)
		|((unsigned long long int)oe_n << 56), 57);
}

static void reset_flash()
{
	bulk_start();
	bulk_ctl_flash(0, 0, 1, 0, 0, 1);
	bulk_ctl_flash(0, 0, 1, 0, 1, 1);
	bulk_ctl_flash(0, 0, 1, 1, 1, 1);
	bulk_end();
}

static void write_flash(unsigned int data, unsigned int adr)
{
	bulk_start();
	bulk_ctl_flash(data, adr, 0, 1, 1, 1);
	bulk_ctl_flash(data, adr, 1, 1, 1, 1);
	bulk_end();
}

#define ENDIAN_CONV(x) (((x) & 0x000000ff) << 24)|(((x) & 0x0000ff00) << 8)|(((x) & 0x00ff0000) >> 8)|(((x) & 0xff000000) >> 24)

int main(int argc, char *argv[])
{
	int fd;
	unsigned int *buffer;
	unsigned int length;
	int i;
	int nsectors;
	
	if(argc != 2) {
		fprintf(stderr, "Usage: flasher <filename>\n");
		return 1;
	}
	
	fd = open(argv[1], O_RDONLY);
	if(fd == -1) {
		perror("open");
		return 1;
	}
	
	length = lseek(fd, 0, SEEK_END);
	lseek(fd, 0, SEEK_SET);
	
	buffer = mmap(NULL, length, PROT_READ, MAP_SHARED, fd, 0);
	if(!buffer) {
		perror("mmap");
		close(fd);
		return 1;
	}
	
	if(libusb_init(NULL) != 0) {
		fprintf(stderr, "Unable to intialize libusb\n");
		munmap(buffer, length);
		close(fd);
		return 1;
	}
	
	devhandle = libusb_open_device_with_vid_pid(NULL, 0x03fd, 0x0008);
	if(devhandle == NULL) {
		fprintf(stderr, "Unable to find DLC9 JTAG cable\n");
		libusb_exit(NULL);
		munmap(buffer, length);
		close(fd);
		return 1;
	}
	
	if(libusb_claim_interface(devhandle, 0) != 0) {
		fprintf(stderr, "Unable to claim the USB interface. Check that no other application is using the cable.\n");
		libusb_close(devhandle);
		libusb_exit(NULL);
		munmap(buffer, length);
		close(fd);
		return 1;
	}
	
	init_jtag();
	load_ir();
	
	reset_flash();
	
	usleep(100*1000);
	
	printf("Erasing flash:\n");
	/* Unprotect flash */
	write_flash(0x00600060, 0);
	write_flash(0x00d000d0, 0);
	usleep(1000*1000);
	
	nsectors = (length+256*1024-1)/(256*1024);
	for(i=0;i<nsectors;i++) {
		printf("sector %d/%d\n", i+1, nsectors);
		write_flash(0x00200020, i*64*1024);
		write_flash(0x00d000d0, i*64*1024);
		usleep(2000*1000);
	}
	
	printf("Programming flash - 16KB per '.':\n");
	for(i=0;i<(length+3)/4;i++) {
		write_flash(0x00400040, i);
		write_flash(ENDIAN_CONV(buffer[i]), i);
		if((i % (4*1024)) == 0) {
			printf(".");
			fflush(stdout);
		}
	}
	printf("\nDone.\n");
	
	libusb_release_interface(devhandle, 0);
	libusb_close(devhandle);
	libusb_exit(NULL);
	munmap(buffer, length);
	close(fd);
	return 0;
}

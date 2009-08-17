/*
 * Milkymist VJ SoC (Software support library)
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 3 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 */

#include <libc.h>
#include <uart.h>
#include <console.h>

int puts(const char *s)
{
	while(*s) {
		writechar(*s);
		s++;
	}
	writechar('\n');
	return 1;
}

void putsnonl(const char *s)
{
	while(*s) {
		writechar(*s);
		s++;
	}
}

void readstr(char *s, int size)
{
	char c;
	int ptr;
	
	ptr = 0;
	while(1) {
		c = readchar();
		switch(c) {
			case 0x7f:
			case 0x08:
				if(ptr > 0) {
					ptr--;
					putsnonl("\x08 \x08");
				}
				break;
			case '\r':
			case '\n':
				s[ptr] = 0x00;
				putsnonl("\n");
				return;
			default:
				writechar(c);
				s[ptr] = c;
				ptr++;
				break;
		}
	}
}

int printf(const char *fmt, ...)
{
	va_list args;
	int len;
	char outbuf[256];

	va_start(args, fmt);
	len = vscnprintf(outbuf, sizeof(outbuf), fmt, args);
	va_end(args);
	outbuf[len] = 0;
	putsnonl(outbuf);

	return len;
}

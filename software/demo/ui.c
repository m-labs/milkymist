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
#include <string.h>
#include <cffat.h>
#include <irq.h>
#include <version.h>
#include <hw/interrupts.h>
#include <hw/sysctl.h>
#include <hw/gpio.h>

#include <hal/hdlcd.h>
#include <hal/time.h>

#include "renderer.h"
#include "rpipe.h"
#include "cpustats.h"
#include "ui.h"

enum {
	STATE_MAIN,
	STATE_PATCHLIST,
	STATE_RENDERING
};

static int state;
static int switch_count;
static int display_title;
static char patch_author[128];
static char patch_title[128];
static int patch_lifetime;

#define MAX_PATCHES 64
static char patch_list[MAX_PATCHES][64];
static int patch_list_count;
static int patch_list_index;

static void refresh_screen()
{
	switch(state) {
		case STATE_MAIN:
			hdlcd_clear();
			hdlcd_printf("Milkymist v"VERSION"\n[UP]List [DN]Rnd");
			break;
		case STATE_PATCHLIST:
			hdlcd_printf("%16s\n[UP] [DOWN] [OK]", patch_list[patch_list_index]);
			break;
		case STATE_RENDERING: {
			char *orig;
			char firstline[17];
			int i;

			orig = display_title ? patch_title : patch_author;
			for(i=0;orig[i] && i<16;i++)
				firstline[i] = orig[i];
			for(;i<16;i++)
				firstline[i] = ' ';
			firstline[16] = 0;
			if(display_title || (patch_lifetime == -1))
				hdlcd_printf("%s\nFPS:%02d  CPU:%02d%% ", firstline, rpipe_fps(), cpustats_load());
			else
				hdlcd_printf("%s\nTime rem.: %02d   ", firstline, patch_lifetime);
			break;
		}
	}
}

static int getname_cb(const char *filename, const char *longname, void *param)
{
	if(strcmp(filename, (char *)param) == 0) {
		char *c;
		char *c2;
		int len;

		c = strchr(longname, '-');
		if(c == NULL) return 0;
		len = (c - longname)-1;
		if(len < 1) return 0;
		strncpy(patch_author, longname, len);
		patch_author[len] = 0;

		c++;
		if(*c == 0) return 0;
		c++;
		if(*c == 0) return 0;
		c2 = strrchr(longname, '.');
		len = c2 - c;
		if(len < 1) return 0;
		strncpy(patch_title, c, len);
		patch_title[len] = 0;
		
		return 0;
	}
	return 1;
}

int ui_render_from_file(const char *filename, int random)
{
	char buffer[8192];
	int size;

	if(!cffat_init()) return 0;
	if(!cffat_load(filename, buffer, sizeof(buffer), &size)) return 0;
	strcpy(patch_author, "<unknown author>");
	strcpy(patch_title, "<unknown title>");
	cffat_list_files(getname_cb, (void *)filename);
	cffat_done();
	buffer[size] = 0;

	if(!renderer_start(buffer)) return 0;
	if(random)
		patch_lifetime = (rand() % 70) + 10;
	else
		patch_lifetime = -1;
	state = STATE_RENDERING;
	switch_count = 0;
	display_title = 0;
	refresh_screen();
	return 1;
}

void ui_render_stop()
{
	renderer_stop();
	state = STATE_MAIN;
	refresh_screen();
}

static int listpatches_cb(const char *filename, const char *longname, void *param)
{
	int len;

	len = strlen(filename);
	if((len > 4) && (strcmp(filename+len-4, ".MIL") == 0)) {
		if(patch_list_count < MAX_PATCHES) {
			strcpy(patch_list[patch_list_count], filename);
			patch_list_count++;
		}
	}
	return 1;
}

static void list_patches()
{
	patch_list_index = 0;
	patch_list_count = 0;
	if(!cffat_init()) return;
	cffat_list_files(listpatches_cb, NULL);
	cffat_done();
	if(patch_list_count > 0) {
		state = STATE_PATCHLIST;
		refresh_screen();
	}
}

static void select_patch(int up)
{
	if(up) {
		if(patch_list_index > 0)
			patch_list_index--;
	} else {
		if(patch_list_index < (patch_list_count-1))
			patch_list_index++;
	}
	refresh_screen();
}

static void start_patch()
{
	if(!ui_render_from_file(patch_list[patch_list_index], 0)) {
		state = STATE_MAIN;
		refresh_screen();
	}
}

static void random_mode()
{
	patch_list_count = 0;
	if(!cffat_init()) return;
	cffat_list_files(listpatches_cb, NULL);
	cffat_done();
	if(patch_list_count > 0)
		ui_render_from_file(patch_list[rand() % patch_list_count], 1);
}

enum {
	KEY_N = 0,
	KEY_S,
	KEY_C,

	KEY_COUNT /* must be last */
};

static struct timestamp last_press[KEY_COUNT];

enum {
	CMD_NONE,
	CMD_KEY,
	CMD_TICK
};

/* this may lose some events if two happen at the same time,
 * but this is a rare condition without much consequences.
 */
static int ui_cmd;
static int ui_key;

#define UI_GPIO (GPIO_PBN|GPIO_PBS|GPIO_PBC)

void ui_init()
{
	unsigned int mask;
	int i;

	state = STATE_MAIN;
	ui_cmd = CMD_NONE;

	time_get(&last_press[0]);
	for(i=1;i<KEY_COUNT;i++)
		last_press[i] = last_press[0];

	CSR_GPIO_INTEN |= UI_GPIO;

	mask = irq_getmask();
	mask |= IRQ_GPIO;
	irq_setmask(mask);

	refresh_screen();
}

static void handle_key(unsigned int n)
{
	struct timestamp now;
	struct timestamp diff;
	unsigned int msec;

	/* Debounce */
	time_get(&now);
	time_diff(&diff, &now, &last_press[n]);
	msec = diff.sec*1000+diff.usec/1000;
	if(msec < 100) return;
	last_press[n] = now;

	if(ui_cmd != CMD_NONE) return;
	ui_key = n;
	ui_cmd = CMD_KEY;
}

void ui_isr_key()
{
	unsigned int keys;

	keys = CSR_GPIO_IN;

	if(keys & GPIO_PBN)
		handle_key(KEY_N);
	if(keys & GPIO_PBS)
		handle_key(KEY_S);
	if(keys & GPIO_PBC)
		handle_key(KEY_C);
}

void ui_tick()
{
	if(ui_cmd == CMD_NONE)
		ui_cmd = CMD_TICK;
}

void ui_service()
{
	if(ui_cmd == CMD_NONE) return;
	cpustats_enter();
	if(ui_cmd == CMD_KEY) {
		switch(state) {
			case STATE_MAIN:
				if(ui_key == KEY_N) list_patches();
				else if(ui_key == KEY_S) random_mode();
				break;
			case STATE_PATCHLIST:
				switch(ui_key) {
					case KEY_N:
						select_patch(1);
						break;
					case KEY_S:
						select_patch(0);
						break;
					case KEY_C:
						start_patch();
						break;
				}
				break;
			case STATE_RENDERING:
				if(ui_key == KEY_C) ui_render_stop();
				break;
		}
	}
	if(ui_cmd == CMD_TICK) {
		if(state == STATE_RENDERING) {
			if(patch_lifetime != -1) {
				patch_lifetime--;
				if(patch_lifetime == 0) {
					ui_render_from_file(patch_list[rand() % patch_list_count], 1);
					goto end_service;
				}
			}
			switch_count++;
			if(switch_count > 2) {
				display_title = !display_title;
				switch_count = 0;
			}
			refresh_screen();
		}
	}
end_service:
	ui_cmd = CMD_NONE;
	cpustats_leave();
}

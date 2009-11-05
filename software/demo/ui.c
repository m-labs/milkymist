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

#ifdef EMULATION

#include <cffat.h>

#include "renderer.h"

void ui_init()
{
}

void ui_isr_key()
{
}

void ui_tick()
{
}

int ui_render_from_file(const char *filename)
{
	char buffer[8192];
	int size;

	if(!cffat_init()) return 0;
	if(!cffat_load(filename, buffer, sizeof(buffer), &size)) return 0;
	cffat_done();
	buffer[size] = 0;

	if(!renderer_start(buffer)) return 0;
	return 1;
}

void ui_render_stop()
{
	renderer_stop();
}

#else

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
	STATE_PRESETLIST,
	STATE_RENDERING
};

static int state;
static int switch_count;
static int display_title;
static char preset_author[128];
static char preset_title[128];

#define MAX_PRESETS 64
static char preset_list[MAX_PRESETS][64];
static int preset_list_count;
static int preset_list_index;

static void refresh_screen()
{
	switch(state) {
		case STATE_MAIN:
			hdlcd_clear();
			hdlcd_printf("Milkymist v"VERSION"\n[OK] Preset list");
			break;
		case STATE_PRESETLIST:
			hdlcd_printf("%16s\n[UP] [DOWN] [OK]", preset_list[preset_list_index]);
			break;
		case STATE_RENDERING: {
			char *orig;
			char firstline[17];
			int i;

			orig = display_title ? preset_title : preset_author;
			for(i=0;orig[i] && i<16;i++)
				firstline[i] = orig[i];
			for(;i<16;i++)
				firstline[i] = ' ';
			firstline[16] = 0;
			hdlcd_printf("%s\nFPS:%02d  CPU:%02d%% ", firstline, rpipe_fps(), cpustats_load());
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
		strncpy(preset_author, longname, len);
		preset_author[len] = 0;

		c++;
		if(*c == 0) return 0;
		c++;
		if(*c == 0) return 0;
		c2 = strrchr(longname, '.');
		len = c2 - c;
		if(len < 1) return 0;
		strncpy(preset_title, c, len);
		preset_title[len] = 0;
		
		return 0;
	}
	return 1;
}

int ui_render_from_file(const char *filename)
{
	char buffer[8192];
	int size;

	if(!cffat_init()) return 0;
	if(!cffat_load(filename, buffer, sizeof(buffer), &size)) return 0;
	strcpy(preset_author, "<unknown author>");
	strcpy(preset_title, "<unknown title>");
	cffat_list_files(getname_cb, (void *)filename);
	cffat_done();
	buffer[size] = 0;

	if(!renderer_start(buffer)) return 0;
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

static int listpresets_cb(const char *filename, const char *longname, void *param)
{
	if(preset_list_count < MAX_PRESETS) {
		strcpy(preset_list[preset_list_count], filename);
		preset_list_count++;
	}
	return 1;
}

static void list_presets()
{
	preset_list_index = 0;
	preset_list_count = 0;
	if(!cffat_init()) return;
	cffat_list_files(listpresets_cb, NULL);
	cffat_done();
	if(preset_list_count > 0) {
		state = STATE_PRESETLIST;
		refresh_screen();
	}
}

static void select_preset(int up)
{
	if(up) {
		if(preset_list_index > 0)
			preset_list_index--;
	} else {
		if(preset_list_index < (preset_list_count-1))
			preset_list_index++;
	}
	refresh_screen();
}

static void start_preset()
{
	if(!ui_render_from_file(preset_list[preset_list_index])) {
		state = STATE_MAIN;
		refresh_screen();
	}
}

enum {
	KEY_N = 0,
	KEY_S,
	KEY_C,

	KEY_COUNT /* must be last */
};

static struct timestamp last_press[KEY_COUNT];

#define UI_GPIO (GPIO_PBN|GPIO_PBS|GPIO_PBC)

void ui_init()
{
	unsigned int mask;
	int i;

	state = STATE_MAIN;

	time_get(&last_press[0]);
	for(i=1;i<KEY_COUNT;i++)
		last_press[i] = last_press[0];

	CSR_GPIO_CHANGES = UI_GPIO;
	CSR_GPIO_INT |= UI_GPIO;

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

	switch(state) {
		case STATE_MAIN:
			if(n == KEY_C) list_presets();
			break;
		case STATE_PRESETLIST:
			switch(n) {
				case KEY_N:
					select_preset(1);
					break;
				case KEY_S:
					select_preset(0);
					break;
				case KEY_C:
					start_preset();
					break;
			}
			break;
		case STATE_RENDERING:
			if(n == KEY_C) ui_render_stop();
			break;
	}
}

void ui_isr_key()
{
	unsigned int keys;

	CSR_GPIO_CHANGES = CSR_GPIO_CHANGES & UI_GPIO;

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
	if(state == STATE_RENDERING) {
		switch_count++;
		if(switch_count > 2) {
			display_title = !display_title;
			switch_count = 0;
		}
		refresh_screen();
	}
}

#endif /* EMULATION */

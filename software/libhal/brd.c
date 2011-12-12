/*
 * Milkymist SoC (Software)
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <version.h>
#include <board.h>
#include <hw/sysctl.h>
#include <hw/capabilities.h>

#include <hal/brd.h>

const struct board_desc *brd_desc;

#define display_capability(cap, val) if(val) printf("BRD: "cap": Yes\n"); else printf("BRD: "cap": No\n")

static void display_capabilities(void)
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

void brd_init(void)
{
	int rev;
	char soc_version[13];

	brd_desc = get_board_desc();

	if(brd_desc == NULL) {
		printf("BRD: Running on unknown board (ID=0x%08x), startup aborted.\n", CSR_SYSTEM_ID);
		while(1);
	}
	rev = get_pcb_revision();
	get_soc_version_formatted(soc_version);
	printf("BRD: SoC %s on %s (PCB revision %d)\n", soc_version, brd_desc->name, rev);
	if(strcmp(soc_version, VERSION) != 0)
		printf("BRD: SoC and HAL versions do not match!\n");
	if(rev > 2)
		printf("BRD: Unsupported PCB revision, please upgrade!\n");
	display_capabilities();
}

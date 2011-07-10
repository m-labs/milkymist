/*
 * Milkymist SoC (Software)
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

#include <board.h>

#include <hal/brd.h>

#include <hw/fmlmeter.h>

static unsigned int last_stb_count;
static unsigned int last_ack_count;

void memstats_init()
{
	last_stb_count = 0;
	last_ack_count = 0;
	CSR_FMLMETER_COUNTERS_ENABLE = FMLMETER_COUNTERS_ENABLE;
}

void memstats_tick()
{
	CSR_FMLMETER_COUNTERS_ENABLE = 0;
	last_stb_count = CSR_FMLMETER_STBCOUNT;
	last_ack_count = CSR_FMLMETER_ACKCOUNT;
	CSR_FMLMETER_COUNTERS_ENABLE = FMLMETER_COUNTERS_ENABLE;
}

unsigned int memstat_occupancy()
{
	return last_stb_count/(brd_desc->clk_frequency/100);
}

unsigned int memstat_net_bandwidth()
{
	return last_ack_count/((1000*1000)/(4*64));
}

unsigned int memstat_amat()
{
	unsigned int d;

	d = last_ack_count/100;
	if(d == 0)
		return 0;
	else
		return (last_stb_count-last_ack_count)/d;
}

void memstat_capture_start()
{
	CSR_FMLMETER_CAPTURE_WADR = 0;
}

int memstat_capture_ready()
{
	return CSR_FMLMETER_CAPTURE_WADR > 4095;
}

unsigned int memstat_capture_get(int index)
{
	CSR_FMLMETER_CAPTURE_RADR = index;
	return CSR_FMLMETER_CAPTURE_DATA;
}

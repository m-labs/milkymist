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

#include <hw/systemace.h>
#include <cfcard.h>
#include <console.h>

#define TIMEOUT 10000000

int cf_init()
{
	int timeout;
	
	CSR_ACE_BUSMODE = ACE_BUSMODE_16BIT;
	
	if(!(CSR_ACE_STATUSL & ACE_STATUSL_CFDETECT)) return 0;
	if((CSR_ACE_ERRORL != 0) || (CSR_ACE_ERRORH != 0)) return 0;
	
	CSR_ACE_CTLL |= ACE_CTLL_LOCKREQ;
	timeout = TIMEOUT;
	while((timeout > 0) && (!(CSR_ACE_STATUSL & ACE_STATUSL_MPULOCK))) timeout--;
	if(timeout == 0) return 0;
	
	return 1;
}

int cf_readblock(unsigned int blocknr, unsigned char *buf)
{
	unsigned short int *bufw = (unsigned short int *)buf;
	int buffer_count;
	int i;
	int timeout;
	
	/* See p. 39 */
	timeout = TIMEOUT;
	while((timeout > 0) && (!(CSR_ACE_STATUSL & ACE_STATUSL_CFCMDRDY))) timeout--;
	if(timeout == 0) return 0;
	
	CSR_ACE_MLBAL = blocknr & 0x0000ffff;
	CSR_ACE_MLBAH = (blocknr & 0x0fff0000) >> 16;
	
	CSR_ACE_SECCMD = ACE_SECCMD_READ|0x01;
	
	CSR_ACE_CTLL |= ACE_CTLL_CFGRESET;
	
	buffer_count = 16;
	while(buffer_count > 0) {
		timeout = TIMEOUT;
		while((timeout > 0) && (!(CSR_ACE_STATUSL & ACE_STATUSL_DATARDY))) timeout--;
		if(timeout == 0) return 0;

		for(i=0;i<16;i++) {
			*bufw = CSR_ACE_DATA;
			/* SystemACE data buffer access seems little-endian. */
			*bufw = ((*bufw & 0xff00) >> 8) | ((*bufw & 0x00ff) << 8);
			bufw++;
		}
			
		buffer_count--;
	}
	
	CSR_ACE_CTLL &= ~ACE_CTLL_CFGRESET;
	
	return 1;
}

void cf_done()
{
	CSR_ACE_CTLL &= ~ACE_CTLL_LOCKREQ;
}

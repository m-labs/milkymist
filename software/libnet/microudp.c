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
#include <crc.h>
#include <hw/minimac.h>
#include <hw/sysctl.h>

#include <net/microudp.h>

#define ETHERTYPE_ARP 0x0806
#define ETHERTYPE_IP  0x0800

struct ethernet_header {
	unsigned char preamble[8];
	unsigned char destmac[6];
	unsigned char srcmac[6];
	unsigned short ethertype;
} __attribute__((packed));

static void fill_eth_header(struct ethernet_header *h, unsigned char *destmac, unsigned char *srcmac, unsigned short ethertype)
{
	int i;

	for(i=0;i<7;i++)
		h->preamble[i] = 0x55;
	h->preamble[7] = 0xd5;
	for(i=0;i<6;i++)
		h->destmac[i] = destmac[i];
	for(i=0;i<6;i++)
		h->srcmac[i] = srcmac[i];
	h->ethertype = ethertype;
}

#define ARP_HWTYPE_ETHERNET 0x0001
#define ARP_PROTO_IP        0x0800

#define ARP_OPCODE_REQUEST  0x0001
#define ARP_OPCODE_REPLY    0x0002

struct arp_frame {
	unsigned short hwtype;
	unsigned short proto;
	unsigned char hwsize;
	unsigned char protosize;
	unsigned short opcode;
	unsigned char sender_mac[6];
	unsigned int sender_ip;
	unsigned char target_mac[6];
	unsigned int target_ip;
	unsigned char padding[18];
} __attribute__((packed));

struct ethernet_frame {
	struct ethernet_header eth_header;
	union {
		struct arp_frame arp;
	} contents;
} __attribute__((packed));

typedef union {
	struct ethernet_frame frame;
	unsigned char raw[2000];
} ethernet_buffer;


static int rxlen;
static ethernet_buffer rxbuffer __attribute__((aligned(4)));
static int txlen;
static ethernet_buffer txbuffer __attribute__((aligned(4)));

static void sendpacket()
{
	unsigned int crc;
	
	while(CSR_MINIMAC_TXREMAINING != 0);
	crc = crc32(&txbuffer.raw[8], txlen-8);
	txbuffer.raw[txlen  ] = (crc & 0xff);
	txbuffer.raw[txlen+1] = (crc & 0xff00) >> 8;
	txbuffer.raw[txlen+2] = (crc & 0xff0000) >> 16;
	txbuffer.raw[txlen+3] = (crc & 0xff000000) >> 24;
	txlen += 4;
	CSR_MINIMAC_TXADR = (unsigned int)&txbuffer;
	CSR_MINIMAC_TXREMAINING = txlen;
}

static unsigned char mymac[6];
static unsigned int myip;

/* ARP cache - one entry only */
static char cached_mac[6];
static unsigned int cached_ip;

static void process_arp()
{
	if(rxbuffer.frame.contents.arp.hwtype != ARP_HWTYPE_ETHERNET) return;
	if(rxbuffer.frame.contents.arp.proto != ARP_PROTO_IP) return;
	if(rxbuffer.frame.contents.arp.hwsize != 6) return;
	if(rxbuffer.frame.contents.arp.protosize != 4) return;
	if(rxbuffer.frame.contents.arp.opcode == ARP_OPCODE_REPLY) {
		if(rxbuffer.frame.contents.arp.sender_ip == cached_ip) {
			int i;
			for(i=0;i<6;i++)
				cached_mac[i] = rxbuffer.frame.contents.arp.sender_mac[i];
		}
		return;
	}
	if(rxbuffer.frame.contents.arp.opcode == ARP_OPCODE_REQUEST) {
		if(rxbuffer.frame.contents.arp.target_ip == myip) {
			int i;
			
			fill_eth_header(&txbuffer.frame.eth_header,
				rxbuffer.frame.contents.arp.sender_mac,
				mymac,
				ETHERTYPE_ARP);
			txlen = 68;
			txbuffer.frame.contents.arp.hwtype = ARP_HWTYPE_ETHERNET;
			txbuffer.frame.contents.arp.proto = ARP_PROTO_IP;
			txbuffer.frame.contents.arp.hwsize = 6;
			txbuffer.frame.contents.arp.protosize = 4;
			txbuffer.frame.contents.arp.opcode = ARP_OPCODE_REPLY;
			txbuffer.frame.contents.arp.sender_ip = myip;
			for(i=0;i<6;i++)
				txbuffer.frame.contents.arp.sender_mac[i] = mymac[i];
			txbuffer.frame.contents.arp.target_ip = rxbuffer.frame.contents.arp.sender_ip;
			for(i=0;i<6;i++)
				txbuffer.frame.contents.arp.target_mac[i] = rxbuffer.frame.contents.arp.sender_mac[i];
			sendpacket();
		}
		return;
	}
}

static void process_ip()
{
}

static void process_frame()
{
	int i;
	unsigned int received_crc;
	unsigned int computed_crc;

	for(i=0;i<7;i++)
		if(rxbuffer.frame.eth_header.preamble[i] != 0x55) return;
	if(rxbuffer.frame.eth_header.preamble[7] != 0xd5) return;
	received_crc = ((unsigned int)rxbuffer.raw[rxlen-1] << 24)
		|((unsigned int)rxbuffer.raw[rxlen-2] << 16)
		|((unsigned int)rxbuffer.raw[rxlen-3] <<  8)
		|((unsigned int)rxbuffer.raw[rxlen-4]);
	computed_crc = crc32(&rxbuffer.raw[8], rxlen-12);
	if(received_crc != computed_crc) return;

	if(rxbuffer.frame.eth_header.ethertype == ETHERTYPE_ARP) process_arp();
	else if(rxbuffer.frame.eth_header.ethertype == ETHERTYPE_IP) process_ip();
}

void microudp_start(unsigned char *macaddr, unsigned int ip)
{
	int i;

	for(i=0;i<6;i++)
		mymac[i] = macaddr[i];
	myip = ip;

	cached_ip = 0;
	for(i=0;i<6;i++)
		cached_mac[i] = 0;
	
	CSR_MINIMAC_ADDR0 = (unsigned int)&rxbuffer;
	CSR_MINIMAC_STATE0 = MINIMAC_STATE_LOADED;
	CSR_MINIMAC_SETUP = 0;
}

void microudp_service()
{
	if(CSR_MINIMAC_STATE0 == MINIMAC_STATE_PENDING) {
		asm volatile( /* Invalidate Level-1 data cache */
			"wcsr DCC, r0\n"
			"nop\n"
		);
		rxlen = CSR_MINIMAC_COUNT0;
		process_frame();
		CSR_MINIMAC_STATE0 = MINIMAC_STATE_LOADED;
		CSR_MINIMAC_SETUP = 0;
	}
}

void microudp_shutdown()
{
}

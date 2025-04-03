/*
 * Copyright (C) 2017 Merging Technologies
 * Copyright (C) 2025 Bose Professional
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, see <http://www.gnu.org/licenses/>.
 */

#include "network_utils.h"

#include <linux/string.h> // memcpy
#include <stdlib.h> // malloc

#include <sys/errno.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <ifaddrs.h>
//#include <net/if_dl.h>
#include <net/if.h>
#include <netinet/in.h>
//#include <net/if_types.h>
#include <net/route.h>
#include <netinet/if_ether.h>


/////////////////////////////////////////////////////////////////////////////
// Helper
/////////////////////////////////////////////////////////////////////////////
void dump_mac_addr(uint8_t const MACAddr[6])
{
	printk(KERN_DEBUG "%2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x\n", MACAddr[0], MACAddr[1], MACAddr[2], MACAddr[3], MACAddr[4], MACAddr[5]);
}

/////////////////////////////////////////////////////////////////////////////
void dump_ip_addr(uint32_t ui32IP, char bCarriageReturn)
{
	printk(KERN_DEBUG "%d.%d.%d.%d", (ui32IP >> 24) & 0xFF, (ui32IP >> 16) & 0xFF, (ui32IP >> 8) & 0xFF, ui32IP & 0xFF);
	if(bCarriageReturn)
	{
		printk(KERN_DEBUG "\n");
	}
}

/////////////////////////////////////////////////////////////////////////////
void dump_id(uint64_t ullID)
{
	uint32_t ui32;
	for(ui32 = 0; ui32 < sizeof(ullID); ui32++)
	{
		uint8_t by = (ullID >> (ui32 * 8)) & 0xFF;
		if(ui32 > 0)
		{
			printk(KERN_DEBUG ":%2.2X", by);
		}
		else
		{
			printk(KERN_DEBUG "%2.2X", by);
		}
	}
	printk(KERN_DEBUG "\n");
}

/////////////////////////////////////////////////////////////////////////////
int is_mac_equal(uint8_t Addr1[6], uint8_t Addr2[6])
{
	if(*(uint32_t*)Addr1 == *(uint32_t*)Addr2 && *(short*)&Addr1[4] == *(short*)&Addr2[4])
	{
		return 1;
	}
	return 0;
}

/////////////////////////////////////////////////////////////////////////////
int is_ip_mcast(unsigned int uiIP)
{
	return uiIP >= 0xE0000000 && uiIP <= 0xEFFFFFFF ; // 224.0.0.0 to 239.255.255.255
}

// helpers
//////////////////////////////////////////////////////////////////////////////////////////////
#define ARP_FILE_PATH_NAME "/proc/net/arp"
static int get_mac_from_arp_cache(unsigned int uiIP, uint8_t ui8MAC[6])
{
	int iRet = 0;

	struct in_addr addr;
	addr.s_addr = htonl(uiIP);

	std::string  strIP(inet_ntoa(addr));

	std::ifstream file;
	file.open(ARP_FILE_PATH_NAME);
	if (file.fail())
	{
		printk(KERN_DEBUG "unable to open %s\n", ARP_FILE_PATH_NAME);
		return 0;
	}
	do
	{
		std::string strLine;
		std::getline(file, strLine);

		//printk(KERN_DEBUG "%s\n", strLine.c_str());

		if (strLine.find(strIP + ' ') == 0) // next separator
		{
			std::vector<std::string> vTokens;
			boost::split(vTokens, strLine, boost::is_any_of(" "), boost::token_compress_on);
			if (vTokens .size() >= 4)
			{
				int values[6];
				if (6 == sscanf(vTokens[3].c_str(), "%x:%x:%x:%x:%x:%x%c", &values[0], &values[1], &values[2], &values[3], &values[4], &values[5]))
				{
					iRet = 1;
					/* convert to uint8_t */
					for (int i = 0; i < 6; ++i)
						ui8MAC[i] = (uint8_t)values[i];
				}
			}
			break;
		}
	}
	while(!file.fail());
	file.close();
	return iRet;
}

//////////////////////////////////////////////////////////////////////////////////////////////
#define PCKT_LEN 1024
static int SendICMPEchoRequestPacket(unsigned int uiIP, bool bComputeChecksum)
{

    int send;
    int ttl = 1; // Time to live

    char buffer[PCKT_LEN];
    TICMPEchoRequest* pICMPEchoRequest = (TICMPEchoRequest*)buffer;

    memset(buffer, 0, PCKT_LEN); memset(buffer, 0, sizeof(buffer));

    pICMPEchoRequest->ICMPPacketBase.ui8Type = ICMP_TYPE_ECHO_REQUEST;
    pICMPEchoRequest->ui16Identifier = 0x4242; // arbitrary id
    pICMPEchoRequest->ui16SeqNumber = 0;
    memcpy(buffer + sizeof(TICMPEchoRequest), "Ping", 4); //icmp payload
    if(bComputeChecksum)
    {
        pICMPEchoRequest->ICMPPacketBase.ui16Checksum = ntohs(compute_cksum(buffer, sizeof(TICMPEchoRequest) + 4));
    }

    // Destination address
    struct sockaddr_in dst;

    // Create a raw socket with ICMP protocol
    if ((send = socket(PF_INET, SOCK_DGRAM, IPPROTO_ICMP)) < 0)
    {
        printk(KERN_DEBUG "Could not process socket() [send].\n");
        return EXIT_FAILURE;
    }

    dst.sin_family      = AF_INET;
    dst.sin_addr.s_addr = htonl(uiIP);

    // Define time to life
    if(setsockopt(send, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl)) < 0)
    {
        printk(KERN_DEBUG "Could not process setsockopt().\n");
        return 0;
    }

    if(sendto(send, buffer, sizeof(TICMPEchoRequest) + 4, 0, (struct sockaddr *) &dst, sizeof(dst)) < 0)
    {
        printk(KERN_DEBUG "Could not process sendto().\n", errno);
        return 0;
    }
    return 1;
}

//////////////////////////////////////////////////////////////////////////////////////////////
static uint8_t s_byIPV4mcast[6] = {0x01, 0x00, 0x5e, 0, 0, 0};
/*static*/ int get_mac_from_remote_ip(unsigned int uiIP, uint8_t ui8MAC[6])
{
	if(is_ip_mcast(uiIP))
	{
		memcpy(ui8MAC, s_byIPV4mcast, 6);
		// Copy the 23 LSB IPV4 address to 23 LSB MAC address according to IEEE [RFC1112]
		ui8MAC[3] = (uiIP >> 16) & 0x7F;
		ui8MAC[4] = (uiIP >> 8) & 0xFF;
		ui8MAC[5] = (uiIP) & 0xFF;

		return 1;
	}
	else
	{
		int iRes = get_mac_from_arp_cache(uiIP, ui8MAC);
		if(iRes == 0)
		{ // not found
			// send packet to remote to force address resolution
			if (SendICMPEchoRequestPacket(uiIP, true) != 1)
				return 0;

			
			int iRetryCounter = 100;
			while (iRes == 0 && iRetryCounter-- > 0)
			{
				// need some time until cache is updated
				usleep(10000); // 10ms

				//
				iRes = get_mac_from_arp_cache(uiIP, ui8MAC);
			}
		}
		return iRes;
	}
	return 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////
/*static*/ unsigned short compute_cksum(void *dataptr, unsigned short len)
{
	uint32_t acc;
	unsigned short src;
	uint8_t *octetptr;

	acc = 0;
	// dataptr may be at odd or even addresses
	octetptr = (uint8_t*)dataptr;
	while (len > 1)
	{
		// declare first octet as most significant thus assume network order, ignoring host order
		src = (unsigned short)((*octetptr) << 8);
		octetptr++;
		// declare second octet as least significant
		src |= (*octetptr);
		octetptr++;
		acc += src;
		len -= 2;
	}
	if (len > 0)
	{
		// accumulate remaining octet
		src = (unsigned short)((*octetptr) << 8);
		acc += src;
	}
	// add deferred carry bits
	acc = (acc >> 16) + (acc & 0x0000ffffUL);
	if ((acc & 0xffff0000UL) != 0) {
		acc = (acc >> 16) + (acc & 0x0000ffffUL);
	}

	return ~(unsigned short)acc;
}

//////////////////////////////////////////////////////////////////////////////////////////////
//To calculate UDP checksum a "pseudo header" is added to the UDP header. This includes:
//
//IP Source Address			4 bytes
//IP Destination Address	4 bytes
//Protocol					2 bytes
//UDP Length  				2 bytes
unsigned short compute_udp_cksum(void *dataptr, unsigned short len, unsigned short SrcIP[],unsigned short DestIP[])
{
	unsigned short usDataLen = len;
	uint32_t acc;
	unsigned short src;
	uint8_t *octetptr;

	acc = 0;
	// dataptr may be at odd or even addresses
	octetptr = (uint8_t*)dataptr;
	while (len > 1)
	{
		// declare first octet as most significant thus assume network order, ignoring host order
		src = (unsigned short)((*octetptr) << 8);
		octetptr++;
		// declare second octet as least significant
		src |= (*octetptr);
		octetptr++;
		acc += src;
		len -= 2;
	}
	if (len > 0)
	{
		// accumulate remaining octet
		src = (unsigned short)((*octetptr) << 8);
		acc += src;
	}


	// add the UDP pseudo header which contains the IP source and destinationn addresses
	{
        int i;
        for (i = 0; i < 2; i++)
        {
            acc += MTAL_SWAP16(SrcIP[i]);
        }
        for (i = 0; i < 2; i++)
        {
            acc += MTAL_SWAP16(DestIP[i]);
        }
    }
	// the protocol number and the length of the UDP packet
	acc += MTAL_IP_PROTO_UDP + usDataLen;


	// add deferred carry bits
	acc = (acc >> 16) + (acc & 0x0000ffffUL);
	if ((acc & 0xffff0000UL) != 0) {
		acc = (acc >> 16) + (acc & 0x0000ffffUL);
	}

	return ~(unsigned short)acc;
}

//////////////////////////////////////////////////////////////////////////////////////////////
void dump_eth_header(TEthernetHeader* pEthernetHeader)
{
	printk(KERN_DEBUG "Dump Ethernet Header\n");
	printk(KERN_DEBUG "\tSrc = ");
	dump_mac_addr(pEthernetHeader->bySrc);
	printk(KERN_DEBUG "\tDest = ");
	dump_mac_addr(pEthernetHeader->byDest);
	printk(KERN_DEBUG "\tType = 0x%x\n", MTAL_SWAP16(pEthernetHeader->usType));
}

//////////////////////////////////////////////////////////////////////////////////////////////
void dump_mac_ctrl_frame(TMACControlFrame* pMACControlFrame)
{
	printk(KERN_DEBUG "Dump MAC Control Frame\n");
	printk(KERN_DEBUG "\tSrc = "); dump_mac_addr(pMACControlFrame->EthernetHeader.bySrc);
	printk(KERN_DEBUG "\tOpcode = 0x%x\n", MTAL_SWAP16(pMACControlFrame->usOpcode));
	printk(KERN_DEBUG "\tQuanta = 0x%x\n", MTAL_SWAP16(pMACControlFrame->usQuanta));
}

//////////////////////////////////////////////////////////////////////////////////////////////
void dump_ipv4_header(TIPV4Header* pIPV4Header)
{

	printk(KERN_DEBUG "Dump IP Header\n");

	printk(KERN_DEBUG "\tVersion_HLen = 0x%x\n", pIPV4Header->ucVersion_HeaderLen);
	printk(KERN_DEBUG "\tTOS = 0x%x\n", pIPV4Header->ucTOS);
	printk(KERN_DEBUG "\tLen = %d\n", MTAL_SWAP16(pIPV4Header->usLen));
	printk(KERN_DEBUG "\tIdentification: 0x%4x\n", MTAL_SWAP16(pIPV4Header->usId));
	printk(KERN_DEBUG "\tOffset: 0x%4x\n", MTAL_SWAP16(pIPV4Header->usOffset));
	printk(KERN_DEBUG "\tTTL: 0x%x\n", pIPV4Header->byTTL);
	printk(KERN_DEBUG "\tProtocol: 0x%x\n", pIPV4Header->byProtocol);

	printk(KERN_DEBUG "\tChecksum = 0x%4x\n", MTAL_SWAP16(pIPV4Header->usChecksum));

	// ip addresses in network byte order
	printk(KERN_DEBUG "\tSource IP: %d.%d.%d.%d\n", pIPV4Header->ui32SrcIP & 0xFF, (pIPV4Header->ui32SrcIP >> 8) & 0xFF, (pIPV4Header->ui32SrcIP >> 16) & 0xFF, (pIPV4Header->ui32SrcIP >> 24) & 0xFF);
	printk(KERN_DEBUG "\tDest   IP: %d.%d.%d.%d\n", pIPV4Header->ui32DestIP & 0xFF, (pIPV4Header->ui32DestIP >> 8) & 0xFF, (pIPV4Header->ui32DestIP >> 16) & 0xFF, (pIPV4Header->ui32DestIP >> 24) & 0xFF);
}

//////////////////////////////////////////////////////////////////////////////////////////////
void dump_udp_header(TUDPHeader* pUDPHeader)
{
	printk(KERN_DEBUG "Dump UDP Header\n");

	printk(KERN_DEBUG "\tSource Port = %d\n", MTAL_SWAP16(pUDPHeader->usSrcPort));
	printk(KERN_DEBUG "\tDest   Port = %d\n", MTAL_SWAP16(pUDPHeader->usDestPort));
}


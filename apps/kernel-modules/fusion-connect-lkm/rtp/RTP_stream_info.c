/****************************************************************************
*
*  Module Name    : RTP_stream_info.c(pp)
*  Version        : 
*
*  Abstract       : RAVENNA/AES67
*
*  Written by     : van Kempen Bertrand
*  Date           : 25/07/2010
*  Modified by    : Baume Florian
*  Date           : 16/11/2016
*  Modification   : Ported to C
*  Known problems : None
*
* Copyright(C) 2017 Merging Technologies
*
* RAVENNA/AES67 ALSA LKM is free software; you can redistribute it and / or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* RAVENNA/AES67 ALSA LKM is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with RAVAENNA ALSA LKM ; if not, see <http://www.gnu.org/licenses/>.
*
****************************************************************************/

#include <linux/string.h>

#include "RTP_stream_info.h"
#include "network_utils.h"

////////////////////////////////////////////////////////////////////
int check_struct_version(struct fusion_aes67_rtp_stream_info* rtp_stream_info)
{
    return sizeof(struct fusion_aes67_rtp_stream_info) == rtp_stream_info->m_ui32CRTP_stream_info_sizeof;
}

////////////////////////////////////////////////////////////////////
uint64_t make_key(unsigned char byNICId, uint32_t ui32DestIP, unsigned short usDestPort)
{
	return ((uint64_t)byNICId) << 48 | ((uint64_t)ui32DestIP) << 16 | usDestPort;
}

////////////////////////////////////////////////////////////////////
uint64_t get_key(struct fusion_aes67_rtp_stream_info* rtp_stream_info)
{
	return make_key((unsigned char)rtp_stream_info->m_uiIfPortId, swab32(rtp_stream_info->m_ui32DestIP), swab16(rtp_stream_info->m_usDestPort));
}

////////////////////////////////////////////////////////////////////
void dump(struct fusion_aes67_rtp_stream_info* rtp_stream_info)
{
    unsigned short us;

	printk(KERN_DEBUG "RTP_stream_info %s\n", rtp_stream_info->m_bSource ? "Source" : "Sink");
#ifdef WIN32
	printk(KERN_DEBUG "\tKey: 0x%I64x\n", get_key(rtp_stream_info));
#else
	printk(KERN_DEBUG "\tKey: 0x%llx\n", get_key(rtp_stream_info));
#endif //WIN32
	printk(KERN_DEBUG "\tName: %s\n", rtp_stream_info->m_cName);
	printk(KERN_DEBUG "\tNIC: %u\n", rtp_stream_info->m_uiIfPortId);
	printk(KERN_DEBUG "\tPlay out delay: %u\n", rtp_stream_info->m_ui32PlayOutDelay);
	printk(KERN_DEBUG "\tFrame Size: %u\n", rtp_stream_info->m_ui32FrameSize);

	// IP
	printk(KERN_DEBUG "\n");
	printk(KERN_DEBUG "\tRTCP SrcIP: "); dump_ip_addr(rtp_stream_info->m_ui32RTCPSrcIP, true);		// only for LiveOut
	printk(KERN_DEBUG "\tSrcIP: "); dump_ip_addr(rtp_stream_info->m_ui32SrcIP, true);		// only for LiveOut
	printk(KERN_DEBUG "\tDestIP: "); dump_ip_addr(rtp_stream_info->m_ui32DestIP, true);
	printk(KERN_DEBUG "\tDestMAC: "); dump_mac_addr(rtp_stream_info->m_ui8DestMAC);
	printk(KERN_DEBUG "\tTTL: %d\n", rtp_stream_info->m_byTTL);

	// UDP
	printk(KERN_DEBUG "\n");
	printk(KERN_DEBUG "\tUDP src port: %d\n", rtp_stream_info->m_usSrcPort);
	printk(KERN_DEBUG "\tUDP dest port: %d\n", rtp_stream_info->m_usDestPort);
	printk(KERN_DEBUG "\tUDP RTCP src port: %d\n", rtp_stream_info->m_usRTCPSrcPort);
	printk(KERN_DEBUG "\tUDP RTCP dest port: %d\n", rtp_stream_info->m_usRTCPDestPort);

	// RTP
	printk(KERN_DEBUG "\n");
	printk(KERN_DEBUG "\tPayloadType: %d\n", rtp_stream_info->m_byPayloadType);
	printk(KERN_DEBUG "\tSSRC: %u\n", rtp_stream_info->m_ui32SSRC);

	// framecount
	printk(KERN_DEBUG "\n");
	printk(KERN_DEBUG "\t Max samples per packets: %d\n", rtp_stream_info->m_ui32MaxSamplesPerPacket);

	// Sync-time
/*#ifdef WIN32
	printk(KERN_DEBUG "\tAbsoluteTime: %I64u\n", rtp_stream_info->m_ui64AbsoluteTime);
#else
	printk(KERN_DEBUG "\tAbsoluteTime: %llu\n", rtp_stream_info->m_ui64AbsoluteTime);
#endif // WIN32*/
	printk(KERN_DEBUG "\tRTPTimestamp offset: %d\n\n", rtp_stream_info->m_ui32RTPTimestampOffset);


	printk(KERN_DEBUG "\tsampling Rate: %u\n", rtp_stream_info->m_ui32SamplingRate);
	printk(KERN_DEBUG "\tCodec: %s WordLength: %d\n", rtp_stream_info->m_cCodec, get_codec_word_lenght(rtp_stream_info->m_cCodec));
	printk(KERN_DEBUG "\tChannels: %d\n", rtp_stream_info->m_byNbOfChannels);
	printk(KERN_DEBUG "\tSource: %d\n", rtp_stream_info->m_bSource);

	printk(KERN_DEBUG "\tRouting: ");
	for(us = 0; us < rtp_stream_info->m_byNbOfChannels; us++)
	{
		printk(KERN_DEBUG "%u  ", get_routing(rtp_stream_info, us));
	}
	printk(KERN_DEBUG "\n");
}

////////////////////////////////////////////////////////////////////
int is_valid(struct fusion_aes67_rtp_stream_info* rtp_stream_info)
{
	if (rtp_stream_info->m_cName[0] == 0)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Name = %s\n", rtp_stream_info->m_cName);
		return 0;
	}

	if (rtp_stream_info->m_bSource)
	{
		if(rtp_stream_info->m_ui32MaxSamplesPerPacket == 0 || rtp_stream_info->m_ui32MaxSamplesPerPacket * rtp_stream_info->m_byNbOfChannels * rtp_stream_info->m_byWordLength > RTP_MAX_PAYLOAD_SIZE)
		{
			printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong MaxSamplesPerPacket = %u\n", rtp_stream_info->m_ui32MaxSamplesPerPacket);
			return 0;
		}
	}

	if (!rtp_stream_info->m_bSource && rtp_stream_info->m_ui32PlayOutDelay < rtp_stream_info->m_ui32FrameSize)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: PlayOutDelay (%u) must be greater or equal to frame size = %u\n", rtp_stream_info->m_ui32PlayOutDelay, rtp_stream_info->m_ui32FrameSize);
		return 0;
	}

	if (rtp_stream_info->m_ui32RTCPSrcIP == 0)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong RTCP Src IP = ");
		dump_ip_addr(rtp_stream_info->m_ui32RTCPSrcIP, true);
		return 0;
	}

	if (rtp_stream_info->m_bSource && rtp_stream_info->m_ui32SrcIP == 0)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Src IP = ");
		dump_ip_addr(rtp_stream_info->m_ui32SrcIP, true);
		return 0;
	}

	if (rtp_stream_info->m_ui32DestIP == 0)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Dest IP = ");
		dump_ip_addr(rtp_stream_info->m_ui32DestIP, true);
		return 0;
	}

	#ifdef MT_EMBEDDED
	{
		// rejects 224.x.x.x
		if (rtp_stream_info->m_ui32DestIP >> 24 == 224)
		{
			printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Dest IP = ");
			dump_ip_addr(rtp_stream_info->m_ui32DestIP, false);			
			printk(KERN_DEBUG " 224.x.x.x are not supported\n");
			return 0;
		}
		// rejects when multi-cast and x.x.x.255
		if ((rtp_stream_info->m_ui32DestIP & 0xF00000FF) == 0xE00000FF)
		{
			printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Dest IP = ");
			dump_ip_addr(rtp_stream_info->m_ui32DestIP, false);
			printk(KERN_DEBUG " multi-cast x.x.x.255 are not supported\n");
			return 0;
		}
	}
	#endif

	// UDP

	// UDP port limitation
	if (!is_ip_mcast(rtp_stream_info->m_ui32DestIP)
		&& (rtp_stream_info->m_usDestPort < 1024 || rtp_stream_info->m_usDestPort > 32767) // FPGA: limits UNICAST port in range [1024..32767], so that MIDI pre can be placed on 32768 + ports
		)
	{
		printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong Stream Port = %u\nNote: For transports based on UDP (UNICAST only), the value should be in the range 1024 to 32767 inclusive.\n", rtp_stream_info->m_usDestPort);
		return 0;
	}

    {
        char* cCodec = rtp_stream_info->m_cCodec;
		// Note: only ZMAN is supporting L32
        if (strcmp(cCodec, "L16") && strcmp(cCodec, "L24") && strcmp(cCodec, "L32") && strcmp(cCodec, "L2432")
            && strcmp(cCodec, "DSD64_32") && strcmp(cCodec, "DSD128_32")
            && strcmp(cCodec, "DSD64") && strcmp(cCodec, "DSD128") && strcmp(cCodec, "DSD256"))
        {
            printk(KERN_DEBUG "CRTP_stream_info::IsValid: wrong codec = %s\n", cCodec);
            return 0;
        }
    }

	if (rtp_stream_info->m_ui32SamplingRate == 0)
	{
		printk(KERN_DEBUG "CRavennaSession::IsValid: wrong SamplingRate = %u must be > 0\n", rtp_stream_info->m_ui32SamplingRate);
		return 0;
	}

	if (rtp_stream_info->m_byNbOfChannels == 0)
	{
		printk(KERN_DEBUG "CRavennaSession::IsValid: wrong Number Of Channels = %u must be > 0\n", rtp_stream_info->m_byNbOfChannels);
		return 0;
	}
	if (rtp_stream_info->m_byNbOfChannels > MAX_CHANNELS_BY_RTP_STREAM)
	{
		printk(KERN_DEBUG "CRavennaSession::IsValid: too many channels(%u); max is %d\n", rtp_stream_info->m_byNbOfChannels, MAX_CHANNELS_BY_RTP_STREAM);
		return 0;
	}

	return 1;
}

////////////////////////////////////////////////////////////////////
void set_stream_name(struct fusion_aes67_rtp_stream_info* rtp_stream_info, const char* cName)
{
	strncpy(rtp_stream_info->m_cName, cName, MAX_STREAM_NAME_SIZE - 1);
}

////////////////////////////////////////////////////////////////////
void set_dest_MAC_addr(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint8_t ui8MAC[6])
{
	memcpy(rtp_stream_info->m_ui8DestMAC , ui8MAC, 6);
}

////////////////////////////////////////////////////////////////////
void get_dest_MAC_addr(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint8_t ui8MAC[6])
{
	memcpy(ui8MAC, rtp_stream_info->m_ui8DestMAC, 6);
}

////////////////////////////////////////////////////////////////////
void set_SSRC(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32SSRC)
{
	rtp_stream_info->m_ui32SSRC = ui32SSRC;
	rtp_stream_info->m_bSSRCInitialized = 1;
}

////////////////////////////////////////////////////////////////////
int set_codec(struct fusion_aes67_rtp_stream_info* rtp_stream_info, const char* cCodec)
{
	if (strlen(cCodec) + 1 > MAX_CODEC_NAME_SIZE)
		return 0;

	rtp_stream_info->m_byWordLength = get_codec_word_lenght(cCodec);
	if(rtp_stream_info->m_byWordLength == 0)
	{
		printk(KERN_DEBUG "CRTP_stream_info::SetCodec error Codec = %s\n", cCodec);
		return 0;
	}
	strncpy(rtp_stream_info->m_cCodec, cCodec, MAX_CODEC_NAME_SIZE - 1);
	return 1;
}

////////////////////////////////////////////////////////////////////
unsigned char get_codec_word_lenght(const char* cCodec)
{
	if (strcmp(cCodec, "L16") == 0)
	{
		return 2;
	}
	else if (strcmp(cCodec, "L24") == 0)
	{
		return 3;
	}
	else if (strcmp(cCodec, "L2432") == 0 || strcmp(cCodec, "L32") == 0)
	{
		return 4;
	}
	else if (strcmp(cCodec, "DSD64") == 0)
	{
		return 1;
	}
	else if (strcmp(cCodec, "DSD128") == 0)
	{
		return 2;
	}
	else if (strcmp(cCodec, "DSD64_32") == 0 || strcmp(cCodec, "DSD128_32") == 0 || strcmp(cCodec, "DSD256") == 0)
	{
		return 4;
	}
	else
	{
		return 0;
	}
}

////////////////////////////////////////////////////////////////////
int set_routing(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32StreamChannelId, uint32_t ui32PhysicalChannelId)
{
	if (ui32StreamChannelId >= MAX_CHANNELS_BY_RTP_STREAM)
		return 0;
	rtp_stream_info->m_aui32Routing[ui32StreamChannelId] = ui32PhysicalChannelId;
	return 1;
}

////////////////////////////////////////////////////////////////////
uint32_t get_routing(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32StreamChannelId)
{
	if (ui32StreamChannelId >= MAX_CHANNELS_BY_RTP_STREAM)
		return (uint32_t)(~0);
	return rtp_stream_info->m_aui32Routing[ui32StreamChannelId];
}

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

#pragma once

#include<linux/string.h>
#include "network_utils.h"

#define MAX_STREAM_NAME_SIZE	64
#define MAX_CODEC_NAME_SIZE		10
#define MAX_CHANNELS_BY_RTP_STREAM 64

#pragma pack(push, 1) // to have the same packing under x86 and x64

////////////////////////////////////////////////////////////////////
// init: memset all to zero except m_ui32SamplingRate to 48000 and m_ui32CRTP_stream_info_sizeof = sizeof(struct fusion_aes67_rtp_stream_info);
struct fusion_aes67_rtp_stream_info {
	// must be the first class member
	uint32_t		m_ui32CRTP_stream_info_sizeof; // used to verify that CRTP_stream_info version if the same for Host and Target

	int8_t			m_b802_1Q;
	int16_t			m_ui16VLAN_Id;

	unsigned int	m_uiIfPortId;	// id of the ethernet adapter port to use

	char			m_cName[MAX_STREAM_NAME_SIZE]; // we don't use std:string as this class is send through SendIODeviceIOControl(...)
	uint32_t		m_ui32PlayOutDelay; // Ravenna doc: Playout delay may be separately configured for each receiver, and needs to be set high enough to account for the latencies in the network path.
	uint32_t		m_ui32FrameSize;
	uint32_t		m_ui32MaxSamplesPerPacket;

	// Ethernet
	uint8_t			m_ui8DestMAC[6]; // only for source

	// IP
	unsigned char	m_ucDSCP;
	uint32_t		m_ui32RTCPSrcIP;
	uint32_t		m_ui32SrcIP;		// only for Source
	uint32_t		m_ui32DestIP;
	unsigned char	m_byTTL;

	// UDP
	unsigned short	m_usSrcPort;
	unsigned short	m_usDestPort;

	unsigned short	m_usRTCPSrcPort;
	unsigned short	m_usRTCPDestPort;

	// RTP
	unsigned char	m_byPayloadType;
	uint32_t		m_ui32SSRC;			// Source: put it in outgoing packets. Sink: compare it with incoming packet one
	int8_t			m_bSSRCInitialized;

	// Sync-time
	uint32_t		m_ui32RTPTimestampOffset;

	// Audio
	uint32_t		m_ui32SamplingRate;
	char			m_cCodec[MAX_CODEC_NAME_SIZE]; // we don't use std:string as this class is send through SendIODeviceIOControl(...)
	unsigned char	m_byWordLength;
	unsigned char	m_byNbOfChannels;
	int8_t			m_bSource; // a Source is a LiveOut for CoreAudio

	unsigned int	m_uiId; // it is the standard_session_sink::id()

	uint32_t		m_aui32Routing[MAX_CHANNELS_BY_RTP_STREAM]; //[StreamChannelId] = PhysicalChannelId; ~0 means not used
};

struct fusion_aes67_rtp_stream_status {
	union {
		struct {
			unsigned int sink_RTP_seq_id_error : 1;			// 0x01: wrong RTP sequence id
			unsigned int sink_RTP_SSRC_error : 1;			// 0x02: wrong RTP SSRC
			unsigned int sink_RTP_PayloadType_error : 1;	// 0x04: wrong RTP payload type
			unsigned int sink_RTP_SAC_error : 1;			// 0x08: wrong RTP SAC
			unsigned int sink_receiving_RTP_packet : 1;		// 0x10: receiving RTP packet (some packet RTP arrived)
			unsigned int sink_muted : 1;					// 0x20: live has been muted
			unsigned int sink_some_muted : 1;				// 0x40: used by Horus implementation which is only able to detect that a incomming stream is muted but which doesn't know which one
			unsigned int sink_all_muted : 1;				// 0x80: audio missing from all available streams (i.e. ST2022-7)
		} bit_fields;
		unsigned int flags;
	} u;
	int sink_min_time; //  min packet arrival time
};

#pragma pack(pop)

////////////////////////////////////////////////////////////////////
int check_struct_version(struct fusion_aes67_rtp_stream_info* rtp_stream_info);
uint64_t get_key(struct fusion_aes67_rtp_stream_info* rtp_stream_info);
uint64_t make_key(unsigned char byNICId, uint32_t ui32DestIP, unsigned short usDestPort);
void dump(struct fusion_aes67_rtp_stream_info* rtp_stream_info);
int is_valid(struct fusion_aes67_rtp_stream_info* rtp_stream_info);
void set_stream_name(struct fusion_aes67_rtp_stream_info* rtp_stream_info, const char* cName);
void set_dest_MAC_addr(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint8_t ui8MAC[6]);
void get_dest_MAC_addr(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint8_t ui8MAC[6]);
void set_SSRC(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32SSRC);
int set_codec(struct fusion_aes67_rtp_stream_info* rtp_stream_info, const char* cCodec);
unsigned char get_codec_word_lenght(const char* cCodec);
int set_routing(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32StreamChannelId, uint32_t ui32PhysicalChannelId);
uint32_t get_routing(struct fusion_aes67_rtp_stream_info* rtp_stream_info, uint32_t ui32StreamChannelId);

////////////////////////////////////////////////////////////////////
struct fusion_aes67_rtp_stream_update_name {
	uint64_t m_hRTPStreamHandle;
	char m_cName[MAX_STREAM_NAME_SIZE]; // we don't use std:string as this class is send through SendIODeviceIOControl(...)
};

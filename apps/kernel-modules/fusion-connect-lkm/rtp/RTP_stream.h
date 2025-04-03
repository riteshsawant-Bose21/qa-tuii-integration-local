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

#include "network_utils.h"
#include "../fusion_aes67_manager.h"
#include "RTP_stream_info.h"
#include "RTP_stream_defs.h"

#define DEBUG_CHECK					1

// Init it with memset 0
struct fusion_aes67_rtp_stream {
	struct fusion_aes67_netfilter m_pEth_netfilter;

	struct fusion_aes67_rtp_stream_info m_RTP_stream_info;

	TRTPPacketBase			m_RTPPacketBaseOutgoing;
	TRTCPPacketBase			m_RTCPPacketBase;

	unsigned short				m_usOutgoingSeqNum;

	// RTCP SR (Sender report)
	void*						m_pvRTCP_SourceDescription;
	uint32_t					m_ulRTCP_SourceDescriptionSize;

	uint32_t					m_ulSenderRTPTimestamp;
	uint32_t					m_ulSenderOctetCount;
	uint32_t					m_ulSenderPacketCount;

	// RTCP RR (Receiver report)

	uint64_t					m_ui64LastAudioSampleReceivedSAC;

// Debug
	unsigned short				m_usIncomingSeqNum;
	uint32_t                    m_ui32LastRTPSAC;
	uint32_t                    m_ui32LastRTPLengthInSamples;
};


int rtp_stream_init(struct fusion_aes67_rtp_stream* pRTP_stream, fusion_aes67_netfilter* pEth_netfilter, struct fusion_aes67_rtp_stream_info* pRTP_stream_info);
int rtp_stream_destroy(struct fusion_aes67_rtp_stream* pRTP_stream);

uint64_t rtp_stream_get_key(struct fusion_aes67_rtp_stream* pRTP_stream);
void rtp_stream_set_name(struct fusion_aes67_rtp_stream* pRTP_stream, const char * cName);

// RTCP
int rtp_stream_send_RTCP_SR_Packet(struct fusion_aes67_rtp_stream* pRTP_stream);
int rtp_stream_send_RTCP_RR_Packet(struct fusion_aes67_rtp_stream* pRTP_stream);
int rtp_stream_send_RTCP_BYE_Packet(struct fusion_aes67_rtp_stream* pRTP_stream);

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

#include "MTAL_EthUtils.h"
#include "RTP_stream.h"
#include <linux/string.h>

// Init with memset to 0
struct fusion_aes67_rtp_audio_stream {
	struct fusion_aes67_rtp_stream m_tRTPStream;

	uint32_t m_ulLivesInDMCounter;
	void* m_pvLivesInCircularBuffer[MAX_CHANNELS_BY_RTP_STREAM];
	void* m_pvLivesOutCircularBuffer[MAX_CHANNELS_BY_RTP_STREAM];
	unsigned short m_usAudioEngineSampleWordLength;

	int m_bLivesInitialized;

	// RTP Arrival Jitter
	//f10bCMTAL_PerfMonInterval m_pmiRTPArrivalTime;

	uint32_t m_ui32SinkAheadTimeResetCounter;
	uint32_t m_ui32LastSinkAheadTimeResetCounter;
	uint32_t m_ui32MinSinkAheadTime;

	// Messages Counter
	unsigned short m_usWrongSSRCMessageCounter;

	// Stream  status
	struct fusion_aes67_rtp_stream_status m_StreamStatus; // protected by m_csSinkRTPStreams or m_csSourceRTPStreams spinlock
	uint32_t m_ui32StreamStatusResetCounter;
	uint32_t m_ui32StreamStatusLastResetCounter;
	// used for sink stream status
	uint32_t m_ui32WrongRTPSeqIdCounter;
	uint32_t m_ui32WrongRTPSeqIdLastCounter;
	uint32_t m_ui32WrongRTPSSRCCounter;
	uint32_t m_ui32WrongRTPSSRCLastCounter;
	uint32_t m_ui32WrongRTPPayloadTypeCounter;
	uint32_t m_ui32WrongRTPPayloadTypeLastCounter;
	uint32_t m_ui32WrongRTPSACCounter;
	uint32_t m_ui32WrongRTPSACLastCounter;
	uint32_t m_ui32RTPPacketCounter;
	uint32_t m_ui32RTPPacketLastCounter;

	MTCONVERT_MAPPED_TO_INTERLEAVE_PROTOTYPE m_pfnMTConvertMappedToInterleave;
	MTCONVERT_INTERLEAVE__TO_MAPPED_PROTOTYPE m_pfnMTConvertInterleaveToMapped;

	struct rtp_audio_stream_ops* m_pManager;

};


int Create(struct fusion_aes67_rtp_audio_stream* self, struct fusion_aes67_rtp_stream_info* pRTP_stream_info, struct rtp_audio_stream_ops* pManager, fusion_aes67_netfilter* pEth_netfilter);
int Destroy(struct fusion_aes67_rtp_audio_stream* self);

int get_RTPStream_status(struct fusion_aes67_rtp_audio_stream* self, struct fusion_aes67_rtp_stream_status* pstream_status);

void GetStatsFromTIC(TRTPStreamStatsFromTIC* pRTPStreamStatsFromTIC);
void GetStats_SinkAheadTime(struct fusion_aes67_rtp_audio_stream* self, TSinkAheadTime* pSinkAheadTime);
uint32_t GetStats_SinkJitter(struct fusion_aes67_rtp_audio_stream* self);


int ProcessRTPAudioPacket(struct fusion_aes67_rtp_audio_stream* self, TRTPPacketBase* pRTPPacketBase);
int SendRTPAudioPackets(struct fusion_aes67_rtp_audio_stream* self);

int IsLivesInMustBeMuted(struct fusion_aes67_rtp_audio_stream* self);
void PrepareBufferLives(struct fusion_aes67_rtp_audio_stream* self);

uint32_t GetNbOfLivesIn(struct fusion_aes67_rtp_audio_stream* self);
uint32_t GetNbOfLivesOut(struct fusion_aes67_rtp_audio_stream* self);


struct fusion_aes67_rtp_audio_stream_handler {
	struct fusion_aes67_rtp_audio_stream m_RTPAudioStream;
    volatile int m_bActive;
    volatile int m_nReaderCount;
};


int Init(struct fusion_aes67_rtp_audio_stream_handler* self, struct rtp_audio_stream_ops* m_pManager, fusion_aes67_netfilter* pEth_netfilter);

int IsFree(struct fusion_aes67_rtp_audio_stream_handler* self);
void Acquire(struct fusion_aes67_rtp_audio_stream_handler* self);
void Release(struct fusion_aes67_rtp_audio_stream_handler* self);

void ReaderEnter(struct fusion_aes67_rtp_audio_stream_handler* self);
void ReaderLeave(struct fusion_aes67_rtp_audio_stream_handler* self);

int IsActive(struct fusion_aes67_rtp_audio_stream_handler* self);

void Cleanup(struct fusion_aes67_rtp_audio_stream_handler* self, int bCalledFromRelease);




/****************************************************************************
*
*  Module Name    : RTP_streams_manager.h
*  Version        : 
*
*  Abstract       : RAVENNA/AES67 ALSA LKM
*
*  Written by     : van Kempen Bertrand
*  Date           : 25/07/2010
*  Modified by    : Baume Florian
*  Date           : 13/01/2017
*  Modification   : C port (source: RTP_streams_manager.hpp)
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


#pragma once

#include "../fusion_aes67_netfilter.h"
#include "RTP_audio_stream.h"
#include "RTP_stream_info.h"

struct rtp_audio_stream_ops {
    void* user;

    int (*get_mac_address)(void* self, unsigned char* addr, uint32_t length);
    int (*acquire_transmit_packet)(void* self, void** handle, void** packet, uint32_t* packet_size);
    int (*transmit_acquired_packet)(void* self, void* handle, void* packet, uint32_t packet_size);

    uint64_t (*get_global_sac)(void* self);
    uint64_t (*get_global_time)(void* self); // Return the time when the audio frame TIC occurred
    void (*get_global_times)(void* self, uint64_t* global_sac, uint64_t* global_time, uint64_t* global_perf_counter);
    uint32_t (*get_frame_size)(void* self);

    void (*get_sample_format)(void* self, snd_pcm_format_t* sample_format);
    void* (*get_live_in_jitter_buffer)(void* self, uint32_t channel_id);
    void* (*get_live_out_jitter_buffer)(void* self, uint32_t channel_id);
    uint32_t (*get_live_in_jitter_buffer_length)(void* self);
    uint32_t (*get_live_out_jitter_buffer_length)(void* self);
    uint32_t (*get_live_in_jitter_buffer_offset)(void* self, const uint64_t current_sac);
    uint32_t (*get_live_out_jitter_buffer_offset)(void* self, const uint64_t current_sac);

    int (*update_live_in_audio_data_format)(void* self, uint32_t channel_id, const char* codec);

    unsigned char (*get_live_in_mute_pattern)(void* self, uint32_t channel_id);
    unsigned char (*get_live_out_mute_pattern)(void* self, uint32_t channel_id);
};

//////////////////////////////////////////////////////////////
struct fusion_aes67_rtp_manager {
	// CRTP_audio_streams
	// Sources
    void* m_csSourceRTPStreams;

    volatile unsigned short	m_usNumberOfRTPSourceStreams;
    struct fusion_aes67_rtp_audio_stream_handler m_apRTPSourceStreams[MAX_SOURCE_STREAMS*2]; // double the size because remove/add all stream, we potentially need object that are being use. We then ensure that object are able to be used
    struct fusion_aes67_rtp_audio_stream_handler* m_apRTPSourceOrderedStreams[MAX_SOURCE_STREAMS];

	uint32_t m_ui32RTCPPacketCountdown;	// in [audio frame]

	// Sinks
    void* m_csSinkRTPStreams;

	unsigned short m_usNumberOfRTPSinkStreams;
	struct fusion_aes67_rtp_audio_stream_handler m_apRTPSinkStreams[MAX_SINK_STREAMS*2]; // double the size because remove/add all stream, we potentially need object that are being use. We then ensure that object are able to be used
	struct fusion_aes67_rtp_audio_stream_handler* m_apRTPSinkOrderedStreams[MAX_SINK_STREAMS];


	//f10bCMTAL_PerfMonMinMax<uint32_t> m_pmmmLastProcessedRTPDeltaFromTIC;
	//f10bCMTAL_PerfMonMinMax<uint32_t> m_pmmmLastSentRTPDeltaFromTIC;


	struct rtp_audio_stream_ops* m_pManager;
	struct fusion_aes67_netfilter* m_pEth_netfilter;

};


//////////////////////////////////////////////////////////////
int init_(struct fusion_aes67_rtp_manager* self, rtp_audio_stream_ops* pManager, fusion_aes67_netfilter* pEth_netfilter);
void destroy_(struct fusion_aes67_rtp_manager* self);

int process_UDP_packet(struct fusion_aes67_rtp_manager* self, TUDPPacketBase* pUDPPacketBase, uint32_t packetsize);

int add_RTP_stream_(struct fusion_aes67_rtp_manager* self, struct fusion_aes67_rtp_stream_info* pRTPStreamInfo, uint64_t* phRTPStream);
int remove_RTP_stream_(struct fusion_aes67_rtp_manager* self, uint64_t hRTPStream);
void remove_all_RTP_streams(struct fusion_aes67_rtp_manager* self);
int update_RTP_stream_name(struct fusion_aes67_rtp_manager* self, const struct fusion_aes67_rtp_stream_update_name* pRTP_stream_update_name);
int get_RTPStream_status_(struct fusion_aes67_rtp_manager* self, uint64_t hRTPStream, struct fusion_aes67_rtp_stream_status* pstream_status);

uint8_t GetNumberOfSources(struct fusion_aes67_rtp_manager* self);
uint8_t GetNumberOfSinks(struct fusion_aes67_rtp_manager* self);

//int GetSinkStats(uint8_t ui8StreamIdx, TRTPStreamStats* pRTPStreamStats);
int GetSinkStatsFromTIC(struct fusion_aes67_rtp_manager* self, uint8_t ui8StreamIdx, TRTPStreamStatsFromTIC* pRTPStreamStatsFromTIC);
int GetMinSinkAheadTime(struct fusion_aes67_rtp_manager* self, TSinkAheadTime* pSinkAheadTime);
int GetMinMaxSinksJitter(struct fusion_aes67_rtp_manager* self, TSinksJitter* pSinksJitter);

//f10bint GetLastProcessedSinkFromTIC(struct fusion_aes67_rtp_manager* self, TLastProcessedRTPDeltaFromTIC* pLastProcessedRTPDeltaFromTIC);
//f10bint GetLastSentSourceFromTIC(struct fusion_aes67_rtp_manager* self, TLastSentRTPDeltaFromTIC* pLastSentRTPDeltaFromTIC);

// Process
// following methods must be call by the AudioEngine thread
void prepare_buffer_lives(struct fusion_aes67_rtp_manager* self);
void frame_process_begin(struct fusion_aes67_rtp_manager* self);
void frame_process_end(struct fusion_aes67_rtp_manager* self);
void send_outgoing_packets(struct fusion_aes67_rtp_manager* self);


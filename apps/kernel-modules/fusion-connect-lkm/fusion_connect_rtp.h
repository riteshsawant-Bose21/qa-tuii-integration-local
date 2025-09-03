/*
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

#include <linux/types.h>
#include <linux/hashtable.h>
#include <linux/kref.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <linux/swab.h>
#include <sound/asound.h>
#include "fusion_connect_netfilter.h"

#define FUSION_CN_RTP_MAX_STREAMS 64
#define FUSION_CN_RTP_MAX_CHANNELS 64
#define FUSION_CN_RTP_HASH_BITS 6
#define FUSION_CN_NAME_MAX 32

struct fusion_cn_stream_config {
    uint64_t stream_handle;
    char stream_name[FUSION_CN_NAME_MAX];
    uint32_t sample_rate;
    snd_pcm_format_t format;
    uint8_t channels;
    uint32_t frames_per_packet;
    uint32_t dest_ip;
    uint16_t dest_port;
    uint16_t source_port;
    uint32_t source_ip;
    uint8_t payload_type;
    uint32_t playout_delay;
    uint32_t timestamp_offset;
    uint8_t is_source;
    uint8_t is_fusion_connect;
} __attribute__((packed));

struct fusion_cn_rtp_ops {
    uint64_t (*get_phc_ns)(void);
    void    *(*get_buffer)(void *cn_mgr, void *alsa_stream);
    uint32_t (*get_buffer_size_in_frames)(void *cn_mgr, void *alsa_stream);
    uint32_t (*get_buffer_offset)(void *cn_mgr, void *alsa_stream);
    int      (*set_buffer_pos)(void *cn_mgr, uint32_t write_slot, void *alsa_stream);
};

struct fusion_cn_rtp_header {
    uint8_t  version;      /* Version + padding + CC */
    uint8_t  payload_type;
    uint16_t seq_num;
    uint32_t timestamp;
    uint32_t ssrc;
} __attribute__((packed));

struct fusion_cn_rtp_packet {
    struct ethhdr eth;
    struct iphdr ip;
    struct udphdr udp;
    struct fusion_cn_rtp_header rtp;
} __attribute__((packed));

struct fusion_cn_rtp_stream {
    struct hlist_node hnode;
    struct kref ref;
    spinlock_t lock;
    struct fusion_cn_stream_config info;
    struct fusion_cn_rtp_packet rtp_packet_base __aligned(64);
    uint32_t ip_checksum_base;
    atomic_t is_running;
    uint32_t frames_in_buf;
    uint32_t ssrc;
    uint16_t outgoing_seq_num;
    uint16_t current_seq_num;
    uint64_t next_action_time;
    uint64_t *next_action_times;
    uint32_t playback_index; 
    uint64_t packet_time;
    uint64_t ns_per_sample;
};

// map from dest_ip and dest_port to stream_handle for incoming packets
struct fusion_cn_packet_map {
    struct hlist_node hnode;
    void *alsa_stream;
    uint32_t source_ip;
    uint32_t dest_ip;
    uint16_t source_port;
    uint64_t stream_handle;
};

struct fusion_cn_rtp_manager {
    struct hlist_head streams[1 << FUSION_CN_RTP_HASH_BITS];
    struct hlist_head mc_packet_maps[1 << FUSION_CN_RTP_HASH_BITS]; // multicast packet map, mapped by dest ip
    struct hlist_head uc_packet_maps[1 << FUSION_CN_RTP_HASH_BITS]; // unicast packet map, mapped by source ip and port
    rwlock_t lock;
    struct fusion_cn_netfilter *nf;
    struct fusion_cn_rtp_ops *ops;
    void *cn_mgr;
    bool internal_loopback;
    bool debug;
};

/* Function prototypes */
int fusion_cn_rtp_init(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_netfilter *nf,
                    struct fusion_cn_rtp_ops *ops, void *cn_mgr);
void fusion_cn_rtp_destroy(struct fusion_cn_rtp_manager *rtp_mgr);
int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_stream_config *info,
                             void *alsa_stream, struct fusion_cn_rtp_stream **rtp_stream);
int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_stream *stream);
int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_packet *packet);
void fusion_cn_rtp_send_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_stream *stream, void *alsa_stream);
struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle);
void fusion_cn_rtp_stream_release(struct kref *kref);
int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle, bool running, void *alsa_stream);

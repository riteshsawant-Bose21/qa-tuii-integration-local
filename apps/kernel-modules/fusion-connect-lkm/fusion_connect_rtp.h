/*
 * Copyright (C) 2025 Bose Professional
 */

#pragma once

#include <linux/types.h>
#include <linux/hashtable.h>
#include <linux/kref.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <sound/asound.h>
#include "fusion_connect_netfilter.h"

#define FUSION_CN_RTP_MAX_STREAMS 64
#define FUSION_CN_RTP_MAX_CHANNELS 64
#define FUSION_CN_RTP_HASH_BITS 6
#define FUSION_CN_NAME_MAX 32

struct fusion_cn_stream_config {
    u64 stream_handle;
    char stream_name[FUSION_CN_NAME_MAX];
    u32 sample_rate;
    snd_pcm_format_t format;
    u8 channels;
    u32 frames_per_packet;
    u32 dest_ip;
    u16 dest_port;
    u16 source_port;
    u32 source_ip;
    u8 payload_type;
    u32 playout_delay;
    u32 timestamp_offset;
    u8 is_source;
    u8 is_fusion_connect;
} __attribute__((packed));

struct fusion_cn_rtp_ops {
    u64  (*get_phc_ns)(void);
    void *(*get_buffer)(void *alsa_stream);
    u32  (*get_buffer_size_in_frames)(void *alsa_stream);
    u32  (*get_buffer_offset)(void *alsa_stream);
};

struct fusion_cn_rtp_header {
    u8  version;      /* Version + padding + CC */
    u8  payload_type; /* marker bit and payload type */
    u16 seq_num;
    u32 timestamp;
    u32 ssrc;
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
    u32 ip_checksum_base;
    atomic_t is_running;
    u32 buf_size_in_frames;
    u32 buf_size_in_packets;
    u32 ssrc;
    u16 outgoing_seq_num;
    u16 current_seq_num;
    u64 next_action_time;
    u64 *next_action_times;
    u32 playback_index; 
    u64 packet_time;
    u64 ns_per_sample;
    bool rtp_phc_offset_valid;
    s64 rtp_phc_offset_ns;

    struct fusion_cn_stream_metrics *metrics;
    void *stream_node;
};

// map from dest_ip and dest_port to stream_handle for incoming packets
struct fusion_cn_packet_map {
    struct hlist_node hnode;
    void *alsa_stream;
    u32 source_ip;
    u32 dest_ip;
    u16 source_port;
    u64 stream_handle;
};

struct fusion_cn_rtp_manager {
    struct hlist_head streams[1 << FUSION_CN_RTP_HASH_BITS];
    struct hlist_head mc_packet_maps[1 << FUSION_CN_RTP_HASH_BITS]; // multicast packet map, mapped by dest ip
    struct hlist_head uc_packet_maps[1 << FUSION_CN_RTP_HASH_BITS]; // unicast packet map, mapped by source ip and port
    rwlock_t lock;
    struct fusion_cn_netfilter *nf;
    struct fusion_cn_rtp_ops *ops;
    void *cn_mgr;
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
struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, u64 handle);
void fusion_cn_rtp_stream_release(struct kref *kref);
int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, u64 handle, bool running, void *alsa_stream);

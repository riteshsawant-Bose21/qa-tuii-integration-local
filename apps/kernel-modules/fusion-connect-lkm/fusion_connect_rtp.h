/*
* Copyright (C) 2025 Bose Professional
* ... GPL boilerplate ...
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
#define FUSION_CN_RTP_BUFFER_FRAMES 8

#define MAX_STREAM_NAME_SIZE 64

struct fusion_cn_stream_config {
    uint64_t stream_handle;
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
    uint8_t is_source;
    uint8_t is_fusion_connect;
} __attribute__((packed));

struct fusion_cn_rtp_ops {
    uint64_t (*get_phc_ns)(void);
    void *(*get_buffer)(void *cn_mgr, uint64_t handle);
    uint32_t (*get_buffer_length)(void *cn_mgr, uint64_t handle);
    uint32_t (*get_buffer_offset)(void *cn_mgr, uint64_t handle);
    uint32_t (*get_avail_frames)(void *cn_mgr, uint64_t handle);
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
    struct fusion_cn_rtp_packet rtp_packet_base;
    atomic_t is_running;
    uint32_t ssrc;
    uint16_t outgoing_seq_num;
    uint16_t current_seq_num;
    uint64_t next_action_time;
    uint64_t next_action_times[FUSION_CN_RTP_BUFFER_FRAMES]; /* Playback times per slot */
    uint32_t playback_index;                      /* Current playback position (for scheduling pcm_interrupt) */
    uint64_t packet_time;
    uint64_t ns_per_sample;
};

struct handle_node {
    struct list_head node;
    uint64_t handle;
    int bucket;
};

// map from dest_ip and dest_port to stream_handle for incoming packets
struct fusion_cn_packet_map {
    struct hlist_node hnode;
    uint32_t dest_ip;
    uint16_t dest_port;
    uint64_t stream_handle;
};

struct fusion_cn_rtp_manager {
    struct hlist_head streams[1 << FUSION_CN_RTP_HASH_BITS];
    struct hlist_head packet_maps[1 << FUSION_CN_RTP_HASH_BITS];
    rwlock_t lock;
    struct fusion_cn_netfilter *nf;
    struct fusion_cn_rtp_ops *ops;
    void *cn_mgr;
    struct list_head active_streams;
    bool internal_loopback;
};

/* Function prototypes */
int fusion_cn_rtp_init(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_netfilter *nf,
                    struct fusion_cn_rtp_ops *ops, void *cn_mgr);
void fusion_cn_rtp_destroy(struct fusion_cn_rtp_manager *rtp_mgr);
int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_stream_config *info, uint64_t *handle);
int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle);
int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr,
                                struct fusion_cn_rtp_packet *packet);
void fusion_cn_rtp_send_packet(struct fusion_cn_rtp_manager *rtp_mgr,
                            struct fusion_cn_rtp_stream *stream);
struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle);
void fusion_cn_rtp_stream_release(struct kref *kref);
int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle, bool running);

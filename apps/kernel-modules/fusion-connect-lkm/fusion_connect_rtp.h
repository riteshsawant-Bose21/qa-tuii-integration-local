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
#include "fusion_connect_netfilter.h"

#define FUSION_CN_RTP_MAX_STREAMS 64
#define FUSION_CN_RTP_MAX_CHANNELS 64
#define FUSION_CN_RTP_HASH_BITS 6

#define FUSION_CN_RTP_PAYLOAD_TYPE 127 /* Dynamic payload [96..127] */
#define FUSION_CN_RTP_MAX_PAYLOAD_SIZE (ETH_DATA_LEN - sizeof(struct fusion_cn_rtp_packet))

/* RTCP Packet Types (for future use) */
#define FUSION_CN_RTCP_TYPE_SR    200
#define FUSION_CN_RTCP_TYPE_RR    201
#define FUSION_CN_RTCP_TYPE_SDES  202
#define FUSION_CN_RTCP_TYPE_BYE   203
#define FUSION_CN_RTCP_TYPE_APP   204

#define FUSION_CN_RTCP_SDES_END   0
#define FUSION_CN_RTCP_SDES_CNAME 1
#define FUSION_CN_RTCP_SDES_NAME  2
#define FUSION_CN_RTCP_SDES_EMAIL 3
#define FUSION_CN_RTCP_SDES_PHONE 4
#define FUSION_CN_RTCP_SDES_LOC   5
#define FUSION_CN_RTCP_SDES_TOOL  6
#define FUSION_CN_RTCP_SDES_NOTE  7
#define FUSION_CN_RTCP_SDES_PRIV  8

struct fusion_cn_rtp_stream_info {
    uint64_t stream_handle; /* Added for handle mapping */
    uint32_t sample_rate;
    snd_pcm_format_t format;
    uint8_t channels;
    uint32_t samples_per_packet;
    uint32_t dest_ip; /* swab32'd */
    uint16_t dest_port; /* swab16'd */
    uint16_t rtcp_dest_port; /* swab16'd */
    uint8_t payload_type;
    uint32_t playout_delay;
    bool is_source;
    char name[64];
};

struct fusion_cn_rtp_ops {
    uint64_t (*get_sac)(void *user, uint64_t handle);
    void *(*get_buffer)(void *user, uint64_t handle, uint32_t channel_id, bool is_source);
    uint32_t (*get_buffer_length)(void *user, uint64_t handle, bool is_source);
    uint32_t (*get_buffer_offset)(void *user, uint64_t handle, uint64_t sac, bool is_source);
    uint32_t (*get_frame_size)(void *user, uint64_t handle);
};

struct fusion_cn_rtp_header {
    uint8_t  version;      /* Version + padding + CC */
    uint8_t  payload_type;
    uint16_t seq_num;
    uint32_t timestamp;
    uint32_t ssrc;
};

struct fusion_cn_rtp_packet {
    struct ethhdr eth;
    struct iphdr ip;
    struct udphdr udp;
    struct fusion_cn_rtp_header rtp;
};

struct fusion_cn_rtcp_header {
    uint8_t  version;      /* Version + padding + RC */
    uint8_t  packet_type;
    uint16_t length;
    uint32_t ssrc;
};

struct fusion_cn_rtcp_packet {
    struct ethhdr eth;
    struct iphdr ip;
    struct udphdr udp;
    struct fusion_cn_rtcp_header rtcp;
};

struct fusion_cn_rtcp_sr_packet {
    struct fusion_cn_rtcp_packet pkt;
    uint32_t ntp_timestamp_msw;
    uint32_t ntp_timestamp_lsw;
    uint32_t rtp_timestamp;
    uint32_t sender_packet_count;
    uint32_t sender_octet_count;
};

struct fusion_cn_rtcp_rr_packet {
    struct fusion_cn_rtcp_packet pkt;
    uint32_t ssrc;
    uint8_t  fraction_lost;
    uint8_t  accum_packets_lost[3];
    uint32_t seq_num_cycles_count;
    uint32_t highest_seq_num_received;
    uint32_t interarrival_jitter;
    uint32_t last_sr_timestamp;
    uint32_t delay_since_last_sr;
};

struct fusion_cn_rtp_stream {
    struct hlist_node hnode;
    struct kref ref;
    uint64_t handle;
    struct fusion_cn_rtp_stream_info info;
    void *buffers[FUSION_CN_RTP_MAX_CHANNELS];
    struct fusion_cn_rtp_packet rtp_packet_base;
    uint16_t outgoing_seq_num;
    uint64_t last_sac;
    uint64_t next_action_time;
    bool is_running;
};

struct fusion_cn_rtp_manager {
    struct hlist_head streams[FUSION_CN_RTP_HASH_BITS];
    spinlock_t lock;
    struct fusion_cn_netfilter *nf;
    struct fusion_cn_rtp_ops *ops;
    void *ops_user;
};

/* Function prototypes */
int fusion_cn_rtp_init(struct fusion_cn_rtp_manager *mgr, struct fusion_cn_netfilter *nf,
                        struct fusion_cn_rtp_ops *ops, void *ops_user);
void fusion_cn_rtp_destroy(struct fusion_cn_rtp_manager *mgr);
int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *mgr,
                                struct fusion_cn_rtp_stream_info *info, uint64_t *handle);
int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *mgr, uint64_t handle);
int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *mgr,
                                    struct fusion_cn_rtp_packet *packet, uint32_t size);
void fusion_cn_rtp_prepare_buffers(struct fusion_cn_rtp_manager *mgr);
void fusion_cn_rtp_send_packets(struct fusion_cn_rtp_manager *mgr,
                                struct fusion_cn_rtp_stream *stream, uint64_t current_sac);
struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *mgr, uint64_t handle);

/* Checksum helpers */
uint16_t fusion_cn_rtp_compute_cksum(const void *data, uint16_t len);
bool fusion_cn_rtp_is_ip_mcast(uint32_t ip);
void fusion_cn_rtp_set_multicast_mac(uint32_t ip, uint8_t mac[ETH_ALEN]);

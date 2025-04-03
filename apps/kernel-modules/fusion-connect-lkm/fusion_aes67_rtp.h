#ifndef FUSION_AES67_RTP_H
#define FUSION_AES67_RTP_H

#include <linux/types.h>
#include <linux/hashtable.h>
#include <linux/kref.h>
#include <sound/pcm.h>
#include "fusion_aes67_network.h"
#include "fusion_aes67_netfilter.h"

#define FUSION_AES67_RTP_MAX_STREAMS 64
#define FUSION_AES67_RTP_MAX_CHANNELS 64
#define FUSION_AES67_RTP_HASH_BITS 6

struct fusion_aes67_rtp_stream_info {
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

struct fusion_aes67_rtp_ops {
    uint64_t (*get_sac)(void *user, uint64_t handle);
    void *(*get_buffer)(void *user, uint64_t handle, uint32_t channel_id, bool is_source);
    uint32_t (*get_buffer_length)(void *user, uint64_t handle, bool is_source);
    uint32_t (*get_buffer_offset)(void *user, uint64_t handle, uint64_t sac, bool is_source);
    uint32_t (*get_frame_size)(void *user, uint64_t handle);
};

struct fusion_aes67_rtp_stream {
    struct hlist_node hnode;
    struct kref ref;
    uint64_t handle;
    struct fusion_aes67_rtp_stream_info info;
    snd_pcm_t *pcm;
    void *buffers[FUSION_AES67_RTP_MAX_CHANNELS];
    struct fusion_aes67_rtp_packet rtp_packet_base;
    uint16_t outgoing_seq_num;
    uint64_t last_sac;
    uint32_t packet_interval; /* SAC ticks between packets */
};

struct fusion_aes67_rtp_manager {
    struct hlist_head streams[FUSION_AES67_RTP_HASH_BITS];
    spinlock_t lock;
    struct fusion_aes67_netfilter *nf;
    struct fusion_aes67_rtp_ops *ops;
    void *ops_user;
};

/* Function prototypes */
int fusion_aes67_rtp_init(struct fusion_aes67_rtp_manager *mgr, struct fusion_aes67_netfilter *nf,
                          struct fusion_aes67_rtp_ops *ops, void *ops_user);
void fusion_aes67_rtp_destroy(struct fusion_aes67_rtp_manager *mgr);
int fusion_aes67_rtp_add_stream(struct fusion_aes67_rtp_manager *mgr,
                                struct fusion_aes67_rtp_stream_info *info, uint64_t *handle);
int fusion_aes67_rtp_remove_stream(struct fusion_aes67_rtp_manager *mgr, uint64_t handle);
int fusion_aes67_rtp_process_packet(struct fusion_aes67_rtp_manager *mgr,
                                    struct fusion_aes67_rtp_packet *packet, uint32_t size);
void fusion_aes67_rtp_prepare_buffers(struct fusion_aes67_rtp_manager *mgr);
void fusion_aes67_rtp_send_packets(struct fusion_aes67_rtp_manager *mgr, uint64_t current_sac);

#endif /* FUSION_AES67_RTP_H */
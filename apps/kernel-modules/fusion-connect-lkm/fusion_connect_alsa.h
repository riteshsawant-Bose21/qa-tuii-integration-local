#pragma once

#include <linux/hashtable.h>
#include <linux/version.h>
#include <linux/spinlock.h>
#include <linux/hash.h>
#include <sound/core.h>
#include <sound/asound.h>
#include <sound/pcm-indirect.h>

#define FUSION_CN_NUM_CHANNELS_MAX 120
#define FUSION_CN_DEFAULT_BUFFER_FRAMES 512
#define FUSION_CN_MAX_STREAMS 64
#define FUSION_CN_ALSA_HASH_BITS 4
#define FUSION_CN_NAME_MAX 32

struct fusion_cn_chip {
    void *fusion_cn_mgr;
    const struct fusion_cn_alsa_ops *alsa_ops;
    rwlock_t lock;
    struct hlist_head streams[1 << FUSION_CN_ALSA_HASH_BITS];
    struct snd_card *card;
    bool debug;
    DECLARE_BITMAP(stream_indices, FUSION_CN_MAX_STREAMS);
};

struct fusion_cn_substream {
    struct snd_pcm_substream *substream;
    struct snd_pcm          *pcm;
    u64                stream_handle;
    char                    stream_name[FUSION_CN_NAME_MAX];
    snd_pcm_format_t        format;
    u32                sample_width;
    u32                rate;
    u32                channels;
    u32                buffer_pos;
    u32                rtp_frame_size;
    u32                interrupts_per_period;
    u32                interrupt_idx;
    struct snd_pcm_indirect pcm_indirect;
    atomic_t                dma_offset;
    spinlock_t              lock;
    struct hlist_node       hnode;
    struct kref             ref;
    u16                stream_index;
    atomic_t                open_count;
    bool                    pending_free;
    atomic_t                disconnected;
};

struct fusion_cn_alsa_ops {
    int (*register_alsa_driver)(void *mgr, struct fusion_cn_chip *alsa_chip);
    int (*start_interrupts)(void *mgr, u64 stream_handle, struct fusion_cn_substream *stream);
    int (*stop_interrupts)(void *mgr, u64 stream_handle);
};

inline bool fusion_cn_alsa_stream_disconnected(struct fusion_cn_substream *s);
int fusion_cn_alsa_pcm_interrupt(struct fusion_cn_chip *alsa_chip, struct fusion_cn_substream *alsa_stream);
inline u32 fusion_cn_alsa_get_buffer_depth(struct fusion_cn_substream *stream);
int fusion_cn_alsa_open_substream(struct fusion_cn_chip *alsa_chip, u64 stream_handle, 
                                  const char *stream_name, int direction, unsigned int channels, 
                                  u32 rate, snd_pcm_format_t format, u32 frames_per_packet,
                                  struct fusion_cn_substream **alsa_stream);
int fusion_cn_alsa_remove_substream(struct fusion_cn_substream *stream);
int fusion_cn_alsa_driver_init(void *mgr, const struct fusion_cn_alsa_ops *callbacks);
void fusion_cn_alsa_destroy(void);

struct fusion_cn_substream *fusion_cn_find_substream(const char *stream_name);
void fusion_cn_alsa_substream_release(struct kref *kref);

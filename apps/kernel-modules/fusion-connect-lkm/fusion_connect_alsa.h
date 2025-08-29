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
    uint64_t                stream_handle;
    char                    stream_name[FUSION_CN_NAME_MAX];
    snd_pcm_format_t        format;
    uint32_t                sample_width;
    uint32_t                rate;
    uint32_t                channels;
    uint32_t                buffer_pos;
    uint32_t                rtp_frame_size;
    uint32_t                interrupts_per_period;
    uint32_t                interrupt_idx;
    struct snd_pcm_indirect pcm_indirect;
    atomic_t                dma_offset;
    spinlock_t              lock;
    struct hlist_node       hnode;
    struct kref             ref;
    uint16_t                stream_index;
    atomic_t                open_count;
    bool                    pending_free;
};

struct fusion_cn_alsa_ops {
    int (*register_alsa_driver)(void *mgr, struct fusion_cn_chip *alsa_chip);
    int (*start_interrupts)(void *mgr, uint64_t stream_handle, struct fusion_cn_substream *stream);
    int (*stop_interrupts)(void *mgr, uint64_t stream_handle);
};

int fusion_cn_alsa_pcm_interrupt(struct fusion_cn_chip *alsa_chip, struct fusion_cn_substream *alsa_stream);
int fusion_cn_alsa_open_substream(struct fusion_cn_chip *alsa_chip, uint64_t stream_handle, 
                                  const char *stream_name, int direction, unsigned int channels, 
                                  uint32_t rate, snd_pcm_format_t format, uint32_t frames_per_packet,
                                  struct fusion_cn_substream **alsa_stream);
int fusion_cn_alsa_remove_substream(struct fusion_cn_substream *stream);
int fusion_cn_alsa_driver_init(void *mgr, const struct fusion_cn_alsa_ops *callbacks);
void fusion_cn_alsa_destroy(void);

struct fusion_cn_substream *fusion_cn_find_substream(const char *stream_name);
void fusion_cn_alsa_substream_release(struct kref *kref);

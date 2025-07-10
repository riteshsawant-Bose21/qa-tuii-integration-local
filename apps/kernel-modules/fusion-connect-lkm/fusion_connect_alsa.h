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

struct fusion_cn_alsa_ops {
    int (*register_alsa_driver)(void *mgr, struct fusion_cn_chip *alsa_chip);
    int (*get_rtp_frame_size)(void *mgr, uint64_t stream_handle, uint32_t *framesize);
    int (*start_interrupts)(void *mgr, uint64_t stream_handle);
    int (*stop_interrupts)(void *mgr, uint64_t stream_handle);
};

void *fusion_cn_alsa_get_stream_buffer(struct fusion_cn_chip *alsa_chip, const char *stream_name);
uint32_t fusion_cn_alsa_get_stream_buffer_size_in_frames(struct fusion_cn_chip *alsa_chip, const char *stream_name);
uint32_t fusion_cn_alsa_get_stream_buffer_offset(struct fusion_cn_chip *alsa_chip, const char *stream_name);
int fusion_cn_alsa_pcm_interrupt(struct fusion_cn_chip *alsa_chip, int direction, const char *stream_name);
int fusion_cn_alsa_open_substream(struct fusion_cn_chip *alsa_chip, uint64_t stream_handle, const char *stream_name,
                                    int direction, unsigned int channels, uint32_t rate, snd_pcm_format_t format);
int fusion_cn_alsa_remove_substream(struct fusion_cn_chip *alsa_chip, const char *stream_name);
int fusion_cn_alsa_mute_stream_buffers(struct fusion_cn_chip *alsa_chip, const char *stream_name);
int fusion_cn_alsa_set_buffer_pos(struct fusion_cn_chip *alsa_chip, uint32_t write_slot, const char *stream_name);
int fusion_cn_alsa_driver_init(void *mgr, const struct fusion_cn_alsa_ops *callbacks);
void fusion_cn_alsa_destroy(void);
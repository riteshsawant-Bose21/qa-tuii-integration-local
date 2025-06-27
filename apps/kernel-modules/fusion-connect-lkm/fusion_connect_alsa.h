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

#include <sound/asound.h>

#define FUSION_CN_NUM_CHANNELS_MAX 120
#define FUSION_CN_DEFAULT_BUFFER_FRAMES 512
#define FUSION_CN_MAX_STREAMS 64
#define FUSION_CN_ALSA_HASH_BITS 4
#define FUSION_CN_NAME_MAX 32

struct fusion_cn_mgr_ops {
    void *(*get_stream_buffer)(void *alsa_chip, const char *stream_name);
    uint32_t (*get_stream_buffer_size_in_frames)(void *alsa_chip, const char *stream_name);
    uint32_t (*get_stream_buffer_offset)(void *alsa_chip, const char *stream_name);
    void (*lock_buffer)(void *alsa_chip, const char *stream_name, unsigned long *flags);   // unused
    void (*unlock_buffer)(void *alsa_chip, const char *stream_name, unsigned long *flags); // unused
    int (*pcm_interrupt)(void *alsa_chip, int direction, const char *stream_name);
    int (*open_substream)(void *alsa_chip, uint64_t stream_handle, const char *stream_name, int direction, bool is_fusion_connect, 
                          uint16_t src_port, unsigned int channels, uint32_t rate, snd_pcm_format_t format);
    int (*remove_substream)(void *alsa_chip, const char *stream_name);
    uint32_t (*get_stream_available_frames)(void *alsa_chip, const char *stream_name); // used but not important
    int (*mute_stream_buffers)(void *alsa_chip, const char *stream_name);
};

struct fusion_cn_alsa_ops {
    int (*register_alsa_driver)(void *mgr, const struct fusion_cn_mgr_ops *ops, void *alsa_chip);
    int (*get_rtp_frame_size)(void *mgr, uint64_t stream_handle, uint32_t *framesize);
    int (*start_interrupts)(void *mgr, uint64_t stream_handle);
    int (*stop_interrupts)(void *mgr, uint64_t stream_handle);
};

int fusion_cn_alsa_init_(void *mgr, const struct fusion_cn_alsa_ops *callbacks);
void fusion_cn_alsa_destroy(void);
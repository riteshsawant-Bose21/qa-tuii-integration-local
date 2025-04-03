/*
 * Copyright (C) 2017 Merging Technologies
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

#ifndef FUSION_AES67_H
#define FUSION_AES67_H

#include <sound/asound.h>

// AES67 manager calls into the ALSA driver
struct fusion_aes67_mgr_ops {
    void *(*get_playback_buffer)(void *alsa_chip, uint64_t stream_handle);
    uint32_t (*get_playback_buffer_size_in_frames)(void *alsa_chip, uint64_t stream_handle);
    void *(*get_capture_buffer)(void *alsa_chip, uint64_t stream_handle);
    uint32_t (*get_capture_buffer_size_in_frames)(void *alsa_chip, uint64_t stream_handle);
    void (*lock_playback_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void (*unlock_playback_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void (*lock_capture_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void (*unlock_capture_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    int (*pcm_interrupt)(void *alsa_chip, int direction, uint64_t stream_handle);
    uint32_t (*get_capture_buffer_offset)(void *alsa_chip, uint64_t stream_handle);
    uint32_t (*get_playback_buffer_offset)(void *alsa_chip, uint64_t stream_handle);
    int (*set_stream_params)(void *alsa_chip, uint64_t stream_handle, unsigned int rate, unsigned int channels, snd_pcm_format_t format);
    int (*open_substream)(void *alsa_chip, uint64_t stream_handle, int direction);
    int (*remove_substream)(void *alsa_chip, uint64_t stream_handle); // New callback
};

// ALSA driver calls into the AES67 manager
struct fusion_aes67_alsa_ops {
    int (*register_alsa_driver)(void *mgr, const struct fusion_aes67_mgr_ops *ops, void *alsa_chip);
    int (*get_input_jitter_buffer_offset)(void *mgr, uint64_t stream_handle, uint32_t *offset);
    int (*get_output_jitter_buffer_offset)(void *mgr, uint64_t stream_handle, uint32_t *offset);
    int (*get_rtp_frame_size_per_stream)(void *mgr, uint64_t stream_handle, uint32_t *framesize);
    int (*get_jitter_buffer_sample_size)(void *mgr, uint64_t stream_handle, uint8_t *sample_size);
    int (*get_playout_delay)(void *mgr, snd_pcm_sframes_t *delay_in_sample);
    int (*get_capture_delay)(void *mgr, snd_pcm_sframes_t *delay_in_sample);
    int (*start_interrupts)(void *mgr, uint64_t stream_handle);
    int (*stop_interrupts)(void *mgr, uint64_t stream_handle);
};

int fusion_aes67_card_init(void *mgr, struct fusion_aes67_alsa_ops *callbacks);
void fusion_aes67_card_exit(void);

#endif // FUSION_AES67_H

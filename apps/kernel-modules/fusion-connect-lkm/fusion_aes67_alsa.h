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
struct fusion_aes67_mgr_ops
{
    void    *(*get_playback_buffer)(void *alsa_chip, uint64_t stream_handle); // returns pointer to the playback (output) AES67 Ring Buffer for specific stream
    uint32_t (*get_playback_buffer_size_in_frames)(void *alsa_chip, uint64_t stream_handle); // returns the size of the playback (output) AES67 Ring Buffer in samples (channel independent) for specific stream
    void    *(*get_capture_buffer)(void *alsa_chip, uint64_t stream_handle); // returns pointer to the capture (input) AES67 Ring Buffer for specific stream
    uint32_t (*get_capture_buffer_size_in_frames)(void *alsa_chip, uint64_t stream_handle); // returns the size of the capture (input) AES67 Ring Buffer in samples (channel independent) for specific stream
    void     (*lock_playback_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void     (*unlock_playback_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void     (*lock_capture_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    void     (*unlock_capture_buffer)(void *alsa_chip, uint64_t stream_handle, unsigned long *flags);
    int      (*pcm_interrupt)(void *alsa_chip, int direction, uint64_t stream_handle); // direction: 0 for playback, 1 for capture. One interrupt per AES67 TIC for specific stream
    uint32_t (*get_capture_buffer_offset)(void *alsa_chip, uint64_t stream_handle); // returns current offset in samples (channel independent) for AES67 Ring Buffer for specific stream
    uint32_t (*get_playback_buffer_offset)(void *alsa_chip, uint64_t stream_handle); // returns current offset (channel independent) in samples for AES67 Ring Buffer for specific stream
};

// ALSA driver calls into the AES67 manager (unchanged for now)
struct fusion_aes67_alsa_ops
{
    int (*register_alsa_driver)(void *mgr, const struct fusion_aes67_mgr_ops *ops, void *alsa_chip);
    int (*get_input_jitter_buffer_offset)(void *mgr, uint32_t *offset);
    int (*get_output_jitter_buffer_offset)(void *mgr, uint32_t *offset);
    int (*get_min_interrupts_frame_size)(void *mgr, uint32_t *framesize);
    int (*get_max_interrupts_frame_size)(void *mgr, uint32_t *framesize);
    int (*get_rtp_frame_size)(void *mgr, uint32_t *framesize); // General frame size
    int (*get_rtp_frame_size_per_stream)(void *mgr, uint64_t stream_handle, uint32_t *framesize); // Stream-specific
    int (*set_sample_rate)(void *mgr, uint32_t rate);
    int (*get_sample_rate)(void *mgr, uint32_t *rate);
    int (*get_jitter_buffer_sample_size)(void *mgr, uint8_t *sample_size);
    int (*get_num_inputs)(void *mgr, uint32_t *num_channels);
    int (*get_num_outputs)(void *mgr, uint32_t *num_channels);
    int (*get_playout_delay)(void *mgr, snd_pcm_sframes_t *delay_in_sample);
    int (*get_capture_delay)(void *mgr, snd_pcm_sframes_t *delay_in_sample);
    int (*start_interrupts)(void *mgr);
    int (*stop_interrupts)(void *mgr);
    int (*assign_stream_handle)(void *mgr, int direction, uint64_t *stream_handle);
    int (*set_stream_params)(void *mgr, uint64_t stream_handle, unsigned int rate, unsigned int channels, snd_pcm_format_t format);
    void (*pcm_interrupt)(void *alsa_chip, int direction); // Called by manager to advance substreams
};

// called by manager init
int fusion_aes67_card_init(void *mgr, struct fusion_aes67_alsa_ops *callbacks);
void fusion_aes67_card_exit(void);

#endif // FUSION_AES67_H

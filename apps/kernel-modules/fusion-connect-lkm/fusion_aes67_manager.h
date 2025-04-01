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

#pragma once

#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/netfilter_ipv4.h>
#include <linux/netdevice.h>
#include <linux/if_ether.h>
#include <asm/div64.h>

#include <net/ip.h>
#include <net/udp.h>
#include <net/route.h>
#include <net/checksum.h>

#include <linux/hrtimer.h>
#include <time.h>
#include <linux/ptp_clock.h>
#include <linux/netlink.h>
#include <net/netlink.h>

#include "fusion_aes67_alsa.h"
#include "RTP_streams_manager.h"
#include "fusion_aes67_netfilter.h"

#define DEFAULT_SAMPLERATE 48000
#define DEFAULT_TICFRAMESIZE 16
#define MAX_FRAME_SIZE 1024
#define RINGBUFFERSIZE 1024
#define DEFAULT_NUM_INPUTS 32
#define DEFAULT_NUM_OUTPUTS 32

#define FUSION_AES67_CTRL_MSG_MAX_PAYLOAD 1024

enum timing_mode {
    TIMING_HRTIMER,
    TIMING_GPIO_INTERRUPT
};

enum fusion_aes67_ctrl_cmd {
    FUSION_AES67_CTRL_CMD_Start,
    FUSION_AES67_CTRL_CMD_Stop,
    FUSION_AES67_CTRL_CMD_Reset,
    FUSION_AES67_CTRL_CMD_StartIO,
    FUSION_AES67_CTRL_CMD_StopIO,
    FUSION_AES67_CTRL_CMD_SetSampleRate,
    FUSION_AES67_CTRL_CMD_GetSampleRate,
    FUSION_AES67_CTRL_CMD_GetAudioMode,
    FUSION_AES67_CTRL_CMD_SetTICFrameSizeAt1FS,
    FUSION_AES67_CTRL_CMD_SetMaxTICFrameSize,
    FUSION_AES67_CTRL_CMD_SetNumberOfInputs,
    FUSION_AES67_CTRL_CMD_SetNumberOfOutputs,
    FUSION_AES67_CTRL_CMD_GetNumberOfInputs,
    FUSION_AES67_CTRL_CMD_GetNumberOfOutputs,
    FUSION_AES67_CTRL_CMD_Add_RTPStream,
    FUSION_AES67_CTRL_CMD_Remove_RTPStream,
    FUSION_AES67_CTRL_CMD_Update_RTPStream_Name,
    FUSION_AES67_CTRL_CMD_SetPlayoutDelay,
    FUSION_AES67_CTRL_CMD_SetCaptureDelay,
    FUSION_AES67_CTRL_CMD_GetRTPStreamStatus,
};

struct fusion_aes67_ctrl_msg {
    enum fusion_aes67_ctrl_cmd cmd;
    int err;
    int data_size;
    void *data;
    pid_t pid;
};

// Original manager.h structs
struct fusion_aes67_config {
    uint32_t sample_rate;
    uint64_t tic_frame_size_at_1fs;
    uint64_t max_frame_size;
    uint64_t frame_size;
    uint32_t ring_buffer_frame_size;
    uint32_t number_of_inputs;
    uint32_t number_of_outputs;
};

struct fusion_aes67_state {
    bool is_started;
    bool is_source;
    bool is_sink;
    bool alsa_running;
    bool ptp_synchronized; // Set by userspace
    uint64_t playout_delay;
    uint64_t capture_delay;
};

struct fusion_aes67_alsa {
    struct fusion_aes67_chip *alsa_chip;
    const struct fusion_aes67_mgr_ops *mgr_callbacks;
    const struct fusion_aes67_alsa_ops *alsa_callbacks;
};

struct fusion_aes67_rtp {
    struct RTPStreamsManager rtp_streams_manager;
    struct rtp_audio_stream_ops rtp_callbacks;
};

struct fusion_aes67_netfilter {
    volatile bool is_enabled;
    spinlock_t lock;

    struct nf_hook_ops nf_hook_struct;

    char iface_name[16];
};

struct fusion_aes67_manager {
    struct fusion_aes67_config config;
    struct fusion_aes67_state state;
    struct fusion_aes67_alsa alsa;
    struct fusion_aes67_rtp rtp;
    struct fusion_aes67_netfilter netfilter;

    // hrtimer
    enum timing_mode timing_mode;
    struct hrtimer audio_timer;
    clockid_t phc_clockid;

    // PTP gpio
    int gpio_irq;
    int gpio_pin;

    // netlink
    struct sock *nl_sock;
    int nl_family;        
};

// Function declarations
int fusion_aes67_mgr_init(struct fusion_aes67_manager *mgr);
void fusion_aes67_mgr_destroy(struct fusion_aes67_manager *mgr);
bool fusion_aes67_mgr_start(struct fusion_aes67_manager *mgr);
bool fusion_aes67_mgr_stop(struct fusion_aes67_manager *mgr);
bool fusion_aes67_mgr_start_alsa(struct fusion_aes67_manager *mgr);
bool fusion_aes67_mgr_stop_alsa(struct fusion_aes67_manager *mgr);
int fusion_aes67_mgr_set_sample_rate(struct fusion_aes67_manager *mgr, uint32_t rate);
int fusion_aes67_mgr_set_tic_frame_size(struct fusion_aes67_manager *mgr, uint64_t size);
int fusion_aes67_mgr_set_max_frame_size(struct fusion_aes67_manager *mgr, uint64_t size);
int fusion_aes67_mgr_set_num_inputs(struct fusion_aes67_manager *mgr, uint32_t num);
int fusion_aes67_mgr_set_num_outputs(struct fusion_aes67_manager *mgr, uint32_t num);

extern const struct fusion_aes67_alsa_ops fusion_aes67_alsa_callbacks;
extern const struct rtp_audio_stream_ops fusion_aes67_rtp_callbacks;

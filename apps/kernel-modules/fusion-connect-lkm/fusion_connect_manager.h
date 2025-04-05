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

#ifndef FUSION_CN_MANAGER_H
#define FUSION_CN_MANAGER_H

#include <linux/kernel.h>
#include <linux/hrtimer.h>
#include <linux/list.h>
#include <sound/pcm.h>
#include "fusion_connect_alsa.h"
#include "fusion_connect_rtp.h"

enum ptp_timing_mode {
    TIMING_HRTIMER,
    TIMING_GPIO_INTERRUPT
};

enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_start,
    FUSION_CN_CTRL_CMD_stop,
    FUSION_CN_CTRL_CMD_start_io,
    FUSION_CN_CTRL_CMD_stop_io,
    FUSION_CN_CTRL_CMD_add_rtp_stream,
    FUSION_CN_CTRL_CMD_remove_rtp_stream,
    FUSION_CN_CTRL_CMD_update_rtp_stream,
    FUSION_CN_CTRL_CMD_get_rtp_stream_status,
    FUSION_CN_CTRL_CMD_set_playout_delay,
    FUSION_CN_CTRL_CMD_set_capture_delay,
};

#define MAX_STREAM_NAME_SIZE 64

// data struct for add rtp stream API call
struct fusion_cn_stream_config {
    uint64_t stream_handle;
    uint32_t sample_rate;
    snd_pcm_format_t format;
    uint32_t channels;
    uint32_t samples_per_packet;
    uint32_t dest_ip; /* swab32'd */
uint16_t dest_port; /* swab16'd */
uint16_t rtcp_dest_port; /* swab16'd */
    uint8_t payload_type;
    uint32_t playout_delay;
    int8_t is_source;
    char name[MAX_STREAM_NAME_SIZE];
};

struct fusion_cn_state {
    bool is_started;
    bool ptp_synchronized; // Set by userspace
    int32_t playout_delay; // Added missing field
    int32_t capture_delay; // Added missing field
};

struct fusion_cn_alsa {
    struct fusion_cn_chip *alsa_chip;
    const struct fusion_cn_mgr_ops *mgr_callbacks;
    const struct fusion_cn_alsa_ops *alsa_callbacks;
};

struct fusion_cn_ptp {
    enum ptp_timing_mode ptp_timing_mode;
    struct hrtimer audio_timer;
    clockid_t phc_clockid;
    int gpio_irq;
    int gpio_pin;
};

struct fusion_cn_netfilter {
    volatile bool is_enabled;
    spinlock_t lock;
    struct nf_hook_ops nf_hook_struct;
    char iface_name[16];
};

struct fusion_cn_netlink {
    struct sock *nl_sock;
    int nl_family;
};

struct fusion_cn_manager {
    struct fusion_cn_state state;
    struct fusion_cn_alsa alsa;
    struct fusion_cn_rtp_manager rtp;
    struct fusion_cn_ptp ptp;
    struct fusion_cn_netfilter netfilter;
    struct fusion_cn_netlink netlink;
};

struct fusion_cn_ctrl_msg {
    enum fusion_cn_ctrl_cmd cmd;
    int err;
    int data_size;
    void *data;
    pid_t pid;
};

struct message_handler_entry {
    enum fusion_cn_ctrl_cmd cmd;
    int (*handler)(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg, struct fusion_cn_ctrl_msg *reply);
};

int fusion_cn_mgr_init(struct fusion_cn_manager *mgr);
void fusion_cn_mgr_destroy(struct fusion_cn_manager *mgr);
bool fusion_cn_mgr_start(struct fusion_cn_manager *mgr);
bool fusion_cn_mgr_stop(struct fusion_cn_manager *mgr);

extern const struct fusion_cn_alsa_ops fusion_cn_alsa_callbacks;

#endif // FUSION_CN_MANAGER_H

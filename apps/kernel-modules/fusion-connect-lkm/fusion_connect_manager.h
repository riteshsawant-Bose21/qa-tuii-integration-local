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
#include <linux/ptp_clock_kernel.h>
#include <linux/ptp_clock.h>
#include <linux/list.h>
#include <sound/pcm.h>
#include "fusion_connect_alsa.h"
#include "fusion_connect_rtp.h"
#include "fusion_connect_netfilter.h"

enum ptp_timing_mode {
    TIMING_HRTIMER,
    TIMING_GPIO_INTERRUPT
};

enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_NONE = 0,
    FUSION_CN_CTRL_CMD_START_MANAGER,
    FUSION_CN_CTRL_CMD_STOP_MANAGER,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM
};

struct fusion_cn_state {
    bool is_started;
    bool ptp_synchronized;
};

struct fusion_cn_alsa {
    struct fusion_cn_chip *alsa_chip;
    const struct fusion_cn_mgr_ops *mgr_callbacks;
    const struct fusion_cn_alsa_ops *alsa_callbacks;
};

struct fusion_cn_ptp {
    enum ptp_timing_mode ptp_timing_mode;
    struct hrtimer audio_timer;
    uint64_t hrtimer_last_tick_ns;
    uint64_t hrtimer_next_tick_ns;
    uint8_t tick_count;
    int gpio_irq;
    int gpio_pin;
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
    struct platform_device *pdev;
    bool debug;
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

extern const struct fusion_cn_alsa_ops fusion_cn_alsa_ops;

#endif // FUSION_CN_MANAGER_H

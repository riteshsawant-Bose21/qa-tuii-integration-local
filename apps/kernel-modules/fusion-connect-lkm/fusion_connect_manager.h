#pragma once

#include <linux/kernel.h>
#include <linux/hrtimer.h>
#include <linux/list.h>
#include <sound/pcm.h>
#include "fusion_connect_alsa.h"
#include "fusion_connect_rtp.h"
#include "fusion_connect_netfilter.h"


enum fusion_cn_ctrl_cmd {
    FUSION_CN_CTRL_CMD_NONE = 0,
    FUSION_CN_CTRL_CMD_START_MANAGER,
    FUSION_CN_CTRL_CMD_STOP_MANAGER,
    FUSION_CN_CTRL_CMD_ADD_STREAM,
    FUSION_CN_CTRL_CMD_REMOVE_STREAM,
    FUSION_CN_CTRL_CMD_GET_METRICS,
    FUSION_CN_CTRL_CMD_SET_PHC_ANCHOR,
    FUSION_CN_CTRL_CMD_GET_PHC_STATUS,
    FUSION_CN_CTRL_CMD_SET_DEBUG,
    FUSION_CN_CTRL_CMD_SET_ETH_IFACE
};

struct fusion_cn_state {
    atomic_t is_started;
};

struct fusion_cn_alsa {
    struct fusion_cn_chip *alsa_chip;
    const struct fusion_cn_mgr_ops *mgr_callbacks;
    const struct fusion_cn_alsa_ops *alsa_callbacks;
};

struct fusion_cn_timer {
    u64 last_tick_ns;
    u64 next_tick_ns;
    u8 tick_count;
};

struct fusion_cn_netlink {
    struct sock *nl_sock;
    int nl_family;

    atomic_t ready;
};

struct stream_node {
    struct list_head node;
    struct fusion_cn_rtp_stream *rtp_stream;
    struct fusion_cn_substream *alsa_stream;
    atomic_t metrics_pending;
};

struct active_streams {
    struct list_head fn_sink;
    struct list_head fn_source;
    struct list_head aes67_sink;
    struct list_head aes67_source;
};

struct fusion_cn_manager {
    struct fusion_cn_state state;
    struct fusion_cn_alsa alsa;
    struct fusion_cn_rtp_manager rtp;
    struct fusion_cn_timer timer;
    struct fusion_cn_netfilter netfilter;
    struct fusion_cn_netlink netlink;
    struct platform_device *pdev;
    struct active_streams active_streams;
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
u64 fusion_cn_get_phc_ns(void);

extern const struct fusion_cn_alsa_ops fusion_cn_alsa_ops;

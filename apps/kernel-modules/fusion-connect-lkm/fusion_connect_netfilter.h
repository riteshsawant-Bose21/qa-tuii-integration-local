#pragma once

#include <linux/netfilter.h>

struct fusion_cn_netfilter {
    atomic_t is_enabled;
    spinlock_t lock;
    struct nf_hook_ops nf_hook_struct;
    char iface_name[16];
};

/* Init/Destroy */
int fusion_cn_nf_init(void *rtp_mgr);
void fusion_cn_nf_destroy(struct fusion_cn_netfilter *nf);

/* Packet Ops */
int fusion_cn_nf_create_packet(struct fusion_cn_netfilter *nf, struct sk_buff **skb, void **data, u32 *data_size);
int fusion_cn_nf_tx_packet(void *rtp_mgr, struct sk_buff *skb, u32 data_size);

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

#include <linux/netfilter.h>

struct fusion_cn_netfilter {
    volatile bool is_enabled;
    spinlock_t lock;
    struct nf_hook_ops nf_hook_struct;
    char iface_name[16];
};

/* Init/Destroy */
int fusion_cn_nf_init(void *rtp_mgr);
void fusion_cn_nf_destroy(struct fusion_cn_netfilter *nf);

/* Packet Ops */
int fusion_cn_nf_create_packet(struct fusion_cn_netfilter *nf, struct sk_buff **skb, void **data, uint32_t *data_size);
int fusion_cn_nf_tx_packet(void *rtp_mgr, struct sk_buff *skb, uint32_t data_size);

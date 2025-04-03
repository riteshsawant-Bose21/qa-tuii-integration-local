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

 #include "fusion_aes67_manager.h"
 
 int fusion_aes67_nf_init(struct fusion_aes67_manager* mgr);
 int fusion_aes67_nf_destroy(struct fusion_aes67_netfilter* nf);
 
 int fusion_aes67_nf_start(struct fusion_aes67_netfilter* nf, const char *ifname);
 int fusion_aes67_nf_stop(struct fusion_aes67_netfilter* nf);
 
 int fusion_aes67_nf_get_mac_addr(unsigned char *addr, const char *iface);
 
 struct sk_buff *fusion_aes67_nf_get_new_skb(unsigned int data_size);
 int fusion_aes67_nf_free_skb(struct sk_buff *skb);
 void *fusion_aes67_nf_get_skb_data(struct sk_buff *skb, unsigned int data_size);
 
 int fusion_aes67_nf_create_packet(struct fusion_aes67_netfilter *nf, struct sk_buff **skb, void **data, uint32_t *data_size);
 int fusion_aes67_nf_tx_packet(struct sk_buff *skb, unsigned int data_size, const char *iface);
 
 int fusion_aes67_nf_rx_packet(struct fusion_aes67_netfilter* nf, void *packet, int packet_size, const char *ifname);

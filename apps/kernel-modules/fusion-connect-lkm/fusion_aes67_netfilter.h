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

int fusion_aes67_nf_init(struct fusion_aes67_netfilter* self, struct TManager* pManager);
int fusion_aes67_nf_start(struct fusion_aes67_netfilter* self, const char *ifname);
int fusion_aes67_nf_stop(struct fusion_aes67_netfilter* self);
int fusion_aes67_nf_destroy(struct fusion_aes67_netfilter* self);

int fusion_aes67_nf_get_mac_addr(unsigned char *addr, const char *iface_name);
int fusion_aes67_nf_get_new_skb(void **skb, unsigned int data_len);
int fusion_aes67_nf_free_skb(void* skb);
int fusion_aes67_nf_get_skb_data(void **data, void *skb, unsigned int data_len);

int fusion_aes67_nf_socket_tx_packet(void* skb, unsigned int data_len, const char* iface);
int fusion_aes67_nf_socket_tx_buffer(void* user_data, unsigned int data_len, const char* iface);

int fusion_aes67_nf_running(struct fusion_aes67_netfilter* self);

int fusion_aes67_nf_send_raw_packet(struct fusion_aes67_netfilter* self, void* pBuffer, uint32_t ui32Length);

int fusion_aes67_nf_create_tx_packet(struct fusion_aes67_netfilter* self, void** pHandle, void** ppvPacket, uint32_t* pPacketSize);
int fusion_aes67_nf_tx_packet(struct fusion_aes67_netfilter* self, void* pHandle, void* pPacket, uint32_t PacketSize);

int fusion_aes67_nf_rx_packet(struct fusion_aes67_netfilter* self, void* packet, int packet_size, const char* ifname);


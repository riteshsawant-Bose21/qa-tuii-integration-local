/*
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

 #ifndef FUSION_AES67_NETWORK_H
 #define FUSION_AES67_NETWORK_H
 
 #include <linux/if_ether.h>
 #include <linux/ip.h>
 #include <linux/udp.h>
 #include <linux/types.h>
 #include <linux/swab.h>
 
 #pragma pack(push, 1)
 
 /* RTP/RTCP-specific constants */
 #define FUSION_AES67_RTP_PAYLOAD_TYPE 127 /* Dynamic payload [96..127] */
 #define FUSION_AES67_RTP_MAX_PAYLOAD_SIZE (ETH_DATA_LEN - sizeof(struct fusion_aes67_rtp_packet))
 
 #define FUSION_AES67_RTCP_TYPE_SR    200
 #define FUSION_AES67_RTCP_TYPE_RR    201
 #define FUSION_AES67_RTCP_TYPE_SDES  202
 #define FUSION_AES67_RTCP_TYPE_BYE   203
 #define FUSION_AES67_RTCP_TYPE_APP   204
 
 #define FUSION_AES67_RTCP_SDES_END   0
 #define FUSION_AES67_RTCP_SDES_CNAME 1
 #define FUSION_AES67_RTCP_SDES_NAME  2
 #define FUSION_AES67_RTCP_SDES_EMAIL 3
 #define FUSION_AES67_RTCP_SDES_PHONE 4
 #define FUSION_AES67_RTCP_SDES_LOC   5
 #define FUSION_AES67_RTCP_SDES_TOOL  6
 #define FUSION_AES67_RTCP_SDES_NOTE  7
 #define FUSION_AES67_RTCP_SDES_PRIV  8
 
 /* Packet structs */
 struct fusion_aes67_rtp_header {
	 uint8_t  version;      /* Version + padding + CC */
	 uint8_t  payload_type;
	 uint16_t seq_num;
	 uint32_t timestamp;
	 uint32_t ssrc;
 };
 
 struct fusion_aes67_rtp_packet {
	 struct ethhdr eth;     /* Ethernet header */
	 struct iphdr ip;       /* IPv4 header */
	 struct udphdr udp;     /* UDP header */
	 struct fusion_aes67_rtp_header rtp; /* RTP header */
 };
 
 struct fusion_aes67_rtcp_header {
	 uint8_t  version;      /* Version + padding + RC */
	 uint8_t  packet_type;
	 uint16_t length;
	 uint32_t ssrc;
 };
 
 struct fusion_aes67_rtcp_packet {
	 struct ethhdr eth;     /* Ethernet header */
	 struct iphdr ip;       /* IPv4 header */
	 struct udphdr udp;     /* UDP header */
	 struct fusion_aes67_rtcp_header rtcp; /* RTCP header */
 };
 
 struct fusion_aes67_rtcp_sr_packet {
	 struct fusion_aes67_rtcp_packet pkt;
	 uint32_t ntp_timestamp_msw;
	 uint32_t ntp_timestamp_lsw;
	 uint32_t rtp_timestamp;
	 uint32_t sender_packet_count;
	 uint32_t sender_octet_count;
 };
 
 struct fusion_aes67_rtcp_rr_packet {
	 struct fusion_aes67_rtcp_packet pkt;
	 uint32_t ssrc;
	 uint8_t  fraction_lost;
	 uint8_t  accum_packets_lost[3];
	 uint32_t seq_num_cycles_count;
	 uint32_t highest_seq_num_received;
	 uint32_t interarrival_jitter;
	 uint32_t last_sr_timestamp;
	 uint32_t delay_since_last_sr;
 };
 
 /* Helper functions */
 void dump_mac_addr(const uint8_t addr[ETH_ALEN]);
 void dump_ip_addr(uint32_t ip, bool carriage_return);
 void dump_eth_header(const struct ethhdr *eth);
 void dump_ip_header(const struct iphdr *ip);
 void dump_udp_header(const struct udphdr *udp);
 
 bool is_mac_equal(const uint8_t addr1[ETH_ALEN], const uint8_t addr2[ETH_ALEN]);
 bool is_ip_mcast(uint32_t ip);
 int get_mac_from_remote_ip(uint32_t ip, uint8_t mac[ETH_ALEN]);
 
 uint16_t compute_cksum(const void *data, uint16_t len);
 uint16_t compute_udp_cksum(const void *data, uint16_t len, const uint16_t *src_ip, const uint16_t *dest_ip);
 
 #pragma pack(pop)
 
 #endif /* FUSION_AES67_NETWORK_H */

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

#include <linux/slab.h>
#include <linux/random.h>
#include "fusion_connect_rtp.h"

#define HASH_KEY(handle) hash_64(handle, FUSION_CN_RTP_HASH_BITS)

uint16_t fusion_cn_rtp_compute_cksum(const void *data, uint16_t len)
{
    uint32_t acc = 0;
    const uint8_t *ptr = data;

    while (len > 1) {
        acc += (uint16_t)(*ptr << 8) | *(ptr + 1);
        ptr += 2;
        len -= 2;
    }
    if (len) acc += (uint16_t)(*ptr << 8);
    acc = (acc >> 16) + (acc & 0xFFFF);
    if (acc & 0xFFFF0000) acc = (acc >> 16) + (acc & 0xFFFF);
    return ~(uint16_t)acc;
}

static void fusion_cn_rtp_stream_release(struct kref *ref)
{
	struct fusion_cn_rtp_stream *stream = container_of(ref, struct fusion_cn_rtp_stream, ref);
	kfree(stream);
}

int fusion_cn_rtp_init(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_netfilter *nf,
						struct fusion_cn_rtp_ops *ops, void *cn_mgr)
{
	int i;
	rtp_mgr->nf = nf;
	rtp_mgr->ops = ops;
	rtp_mgr->cn_mgr = cn_mgr;
	spin_lock_init(&rtp_mgr->lock);
	for (i = 0; i < FUSION_CN_RTP_HASH_BITS; i++) {
		INIT_HLIST_HEAD(&rtp_mgr->streams[i]);
	}
	return 0;
}

void fusion_cn_rtp_destroy(struct fusion_cn_rtp_manager *rtp_mgr)
{
	int i;
	unsigned long flags;
	spin_lock_irqsave(&rtp_mgr->lock, flags);
	for (i = 0; i < FUSION_CN_RTP_HASH_BITS; i++) {
		struct fusion_cn_rtp_stream *stream;
		struct hlist_node *tmp;
		hlist_for_each_entry_safe(stream, tmp, &rtp_mgr->streams[i], hnode) {
			hlist_del(&stream->hnode);
			kref_put(&stream->ref, fusion_cn_rtp_stream_release);
		}
	}
	spin_unlock_irqrestore(&rtp_mgr->lock, flags);
}

bool fusion_cn_rtp_is_ip_mcast(uint32_t ip)
{
    uint32_t ip_host = be32_to_cpu(ip);
    return (ip_host >= 0xE0000000 && ip_host <= 0xEFFFFFFF); /* 224.0.0.0 - 239.255.255.255 */
}

void fusion_cn_rtp_set_multicast_mac(uint32_t ip, uint8_t mac[ETH_ALEN])
{
    uint32_t ip_host = be32_to_cpu(ip);
    mac[0] = 0x01;
    mac[1] = 0x00;
    mac[2] = 0x5E;
    mac[3] = (ip_host >> 16) & 0x7F; /* Lower 23 bits of IP */
    mac[4] = (ip_host >> 8) & 0xFF;
    mac[5] = ip_host & 0xFF;
}

int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *rtp_mgr,
								struct fusion_cn_rtp_stream_info *info, uint64_t *handle)
{
	struct fusion_cn_rtp_stream *stream;
	unsigned long flags;

	if (!info->sample_rate || !info->channels || !info->dest_ip || !info->dest_port) {
		printk(KERN_ERR "fusion_cn_rtp: Invalid stream info\n");
		return -EINVAL;
	}

	stream = kzalloc(sizeof(*stream), GFP_KERNEL);
	if (!stream) return -ENOMEM;

	get_random_bytes(&stream->handle, sizeof(stream->handle));
	memcpy(&stream->info, info, sizeof(*info));
	kref_init(&stream->ref);
	stream->rtp_packet_base.eth.h_proto = swab16(ETH_P_IP);
	stream->rtp_packet_base.ip.version = 4;
	stream->rtp_packet_base.ip.ihl = 5;
	stream->rtp_packet_base.ip.protocol = IPPROTO_UDP;
	stream->rtp_packet_base.ip.saddr = 0; /* TODO: Set source IP */
	stream->rtp_packet_base.ip.daddr = info->dest_ip;
	if (fusion_cn_rtp_is_ip_mcast(info->dest_ip)) {
        fusion_cn_rtp_set_multicast_mac(info->dest_ip, stream->rtp_packet_base.eth.h_dest);
    } else {
        /* TODO: Set unicast MAC - currently unset, kernel might resolve */
    }
	stream->rtp_packet_base.udp.dest = info->dest_port;
	stream->rtp_packet_base.rtp.version = 0x80; /* Version 2, no padding/extension */
	stream->rtp_packet_base.rtp.payload_type = info->payload_type;

	spin_lock_irqsave(&rtp_mgr->lock, flags);
	hlist_add_head(&stream->hnode, &rtp_mgr->streams[HASH_KEY(stream->handle)]);
	spin_unlock_irqrestore(&rtp_mgr->lock, flags);

	*handle = stream->handle;
	return 0;
}

int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle)
{
	struct fusion_cn_rtp_stream *stream;
	unsigned long flags;
	bool found = false;

	spin_lock_irqsave(&rtp_mgr->lock, flags);
	hlist_for_each_entry(stream, &rtp_mgr->streams[HASH_KEY(handle)], hnode) {
		if (stream->handle == handle) {
			hlist_del(&stream->hnode);
			found = true;
			break;
		}
	}
	spin_unlock_irqrestore(&rtp_mgr->lock, flags);

	if (!found) return -ENOENT;
	kref_put(&stream->ref, fusion_cn_rtp_stream_release);
	return 0;
}

struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket = hash_64(handle, FUSION_CN_RTP_HASH_BITS);

    spin_lock_irqsave(&rtp_mgr->lock, flags);
    hlist_for_each_entry(stream, &rtp_mgr->streams[bucket], hnode) {
        if (stream->handle == handle) {
            kref_get(&stream->ref); /* Increment refcount */
            spin_unlock_irqrestore(&rtp_mgr->lock, flags);
            return stream;
        }
    }
    spin_unlock_irqrestore(&rtp_mgr->lock, flags);
    return NULL;
}

int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr,
									struct fusion_cn_rtp_packet *packet, uint32_t size)
{
	struct fusion_cn_rtp_stream *stream;
	uint64_t key = ((uint64_t)packet->ip.daddr << 16) | packet->udp.dest;
	uint32_t payload_len, offset, len1, len2, samples;
	uint8_t *payload;
	unsigned long flags;

	if (size < sizeof(*packet) || swab16(packet->ip.frag_off) & 0x1FFF) {
		return NF_ACCEPT; /* Too small or fragmented */
	}

	spin_lock_irqsave(&rtp_mgr->lock, flags);
	hlist_for_each_entry(stream, &rtp_mgr->streams[HASH_KEY(key)], hnode) {
		if (!stream->info.is_source && stream->info.dest_ip == packet->ip.daddr &&
			stream->info.dest_port == packet->udp.dest) {
			if (packet->rtp.payload_type != stream->info.payload_type ||
				packet->rtp.ssrc != swab32(0x12345678) /* TODO: SSRC */) {
				continue; /* Wrong payload or SSRC */
			}

			payload_len = swab16(packet->udp.len) - sizeof(struct udphdr) - sizeof(struct fusion_cn_rtp_header);
			payload = (uint8_t *)packet + sizeof(*packet);
			samples = payload_len / (stream->info.channels * snd_pcm_format_width(stream->info.format) / 8);
			if (!samples) continue;

			offset = rtp_mgr->ops->get_buffer_offset(rtp_mgr->cn_mgr, stream->handle,
												swab32(packet->rtp.timestamp) + stream->info.playout_delay, false);
			len1 = min(rtp_mgr->ops->get_buffer_length(rtp_mgr->cn_mgr, stream->handle, false) - offset, samples);
			len2 = samples - len1;

			for (int i = 0; i < stream->info.channels; i++) {
				void *buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->handle, i, false);
				if (len1) memcpy(buf + offset * stream->info.format_width / 8, payload + i * len1, len1);
				if (len2) memcpy(buf, payload + i * len2, len2);
			}

			stream->last_sac = swab32(packet->rtp.timestamp); /* Update on receive */

			spin_unlock_irqrestore(&rtp_mgr->lock, flags);
			return NF_DROP;
		}
	}
	spin_unlock_irqrestore(&rtp_mgr->lock, flags);
	return NF_ACCEPT;
}

void fusion_cn_rtp_prepare_buffers(struct fusion_cn_rtp_manager *rtp_mgr)
{
	struct fusion_cn_rtp_stream *stream;
	unsigned long flags;
	int i;

	spin_lock_irqsave(&rtp_mgr->lock, flags);
	for (i = 0; i < FUSION_CN_RTP_HASH_BITS; i++) {
		hlist_for_each_entry(stream, &rtp_mgr->streams[i], hnode) {
			kref_get(&stream->ref);
			if (!stream->info.is_source) {
				uint64_t sac = rtp_mgr->ops->get_sac(rtp_mgr->cn_mgr, stream->handle);
				if (stream->last_sac + rtp_mgr->ops->get_frame_size(rtp_mgr->cn_mgr, stream->handle) > sac) {
					uint32_t offset = rtp_mgr->ops->get_buffer_offset(rtp_mgr->cn_mgr, stream->handle, sac, false);
					for (int j = 0; j < stream->info.channels; j++) {
						void *buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->handle, j, false);
						memset(buf + offset * stream->info.format_width / 8, 0,
							rtp_mgr->ops->get_frame_size(rtp_mgr->cn_mgr, stream->handle) * stream->info.format_width / 8);
					}
				}
			}
			kref_put(&stream->ref, fusion_cn_rtp_stream_release);
		}
	}
	spin_unlock_irqrestore(&rtp_mgr->lock, flags);
}

void fusion_cn_rtp_send_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_stream *stream, uint64_t current_sac)
{
    if (!stream->info.is_source) return; /* Only sources send */

    struct sk_buff *skb;
    void *packet;
    uint32_t size = sizeof(struct fusion_cn_rtp_packet) +
                    stream->info.samples_per_packet * stream->info.channels *
                    snd_pcm_format_width(stream->info.format) / 8;

    if (fusion_cn_nf_create_packet(rtp_mgr->nf, &skb, &packet, &size) &&
        size >= sizeof(struct fusion_cn_rtp_packet)) {
        struct fusion_cn_rtp_packet *rtp = packet;
        memcpy(rtp, &stream->rtp_packet_base, sizeof(*rtp));
		rtp->ip.daddr = stream->info.dest_ip;
		if (fusion_cn_rtp_is_ip_mcast(stream->info.dest_ip)) {
			fusion_cn_rtp_set_multicast_mac(stream->info.dest_ip, rtp->eth.h_dest);
		}
        rtp->ip.tot_len = swab16(size - ETH_HLEN);
		rtp->ip.tos = 0xB8; /* DSCP 46 (EF) */
        rtp->ip.check = fusion_cn_rtp_compute_cksum(&rtp->ip, sizeof(rtp->ip));
        rtp->udp.len = swab16(size - ETH_HLEN - sizeof(rtp->ip));
        rtp->rtp.seq_num = swab16(stream->outgoing_seq_num++);
        rtp->rtp.timestamp = swab32(current_sac);

        uint8_t *payload = (uint8_t *)packet + sizeof(*rtp);
        uint32_t offset = rtp_mgr->ops->get_buffer_offset(rtp_mgr->cn_mgr, stream->handle, current_sac, true);
        for (int j = 0; j < stream->info.channels; j++) {
            void *buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->handle, j, true);
            memcpy(payload + j * stream->info.samples_per_packet * stream->info.format_width / 8,
                   buf + offset * stream->info.format_width / 8,
                   stream->info.samples_per_packet * stream->info.format_width / 8);
        }

        int ret = fusion_cn_nf_tx_packet(rtp_mgr->nf, skb, packet, size);
        if (ret < 0) printk(KERN_ERR "fusion_cn_rtp: TX failed: %d\n", ret);
        stream->last_sac = current_sac;
    } else {
        printk(KERN_ERR "fusion_cn_rtp: Failed to create packet\n");
    }
}

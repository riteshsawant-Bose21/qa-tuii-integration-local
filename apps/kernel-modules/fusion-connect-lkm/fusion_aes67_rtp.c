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
 #include "fusion_aes67_rtp.h"
 
 #define HASH_KEY(handle) hash_64(handle, FUSION_AES67_RTP_HASH_BITS)
 
 static void fusion_aes67_rtp_stream_release(struct kref *ref)
 {
	 struct fusion_aes67_rtp_stream *stream = container_of(ref, struct fusion_aes67_rtp_stream, ref);
	 kfree(stream);
 }
 
 int fusion_aes67_rtp_init(struct fusion_aes67_rtp_manager *mgr, struct fusion_aes67_netfilter *nf,
						   struct fusion_aes67_rtp_ops *ops, void *ops_user)
 {
	 int i;
	 mgr->nf = nf;
	 mgr->ops = ops;
	 mgr->ops_user = ops_user;
	 spin_lock_init(&mgr->lock);
	 for (i = 0; i < FUSION_AES67_RTP_HASH_BITS; i++) {
		 INIT_HLIST_HEAD(&mgr->streams[i]);
	 }
	 return 0;
 }
 
 void fusion_aes67_rtp_destroy(struct fusion_aes67_rtp_manager *mgr)
 {
	 int i;
	 unsigned long flags;
	 spin_lock_irqsave(&mgr->lock, flags);
	 for (i = 0; i < FUSION_AES67_RTP_HASH_BITS; i++) {
		 struct fusion_aes67_rtp_stream *stream;
		 struct hlist_node *tmp;
		 hlist_for_each_entry_safe(stream, tmp, &mgr->streams[i], hnode) {
			 hlist_del(&stream->hnode);
			 kref_put(&stream->ref, fusion_aes67_rtp_stream_release);
		 }
	 }
	 spin_unlock_irqrestore(&mgr->lock, flags);
 }
 
 int fusion_aes67_rtp_add_stream(struct fusion_aes67_rtp_manager *mgr,
								 struct fusion_aes67_rtp_stream_info *info, uint64_t *handle)
 {
	 struct fusion_aes67_rtp_stream *stream;
	 unsigned long flags;
 
	 if (!info->sample_rate || !info->channels || !info->dest_ip || !info->dest_port) {
		 printk(KERN_ERR "fusion_aes67_rtp: Invalid stream info\n");
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
	 stream->rtp_packet_base.udp.dest = info->dest_port;
	 stream->rtp_packet_base.rtp.version = 0x80; /* Version 2, no padding/extension */
	 stream->rtp_packet_base.rtp.payload_type = info->payload_type;
	 stream->packet_interval = (info->samples_per_packet * 1000000ULL) / info->sample_rate; /* µs */
 
	 spin_lock_irqsave(&mgr->lock, flags);
	 hlist_add_head(&stream->hnode, &mgr->streams[HASH_KEY(stream->handle)]);
	 spin_unlock_irqrestore(&mgr->lock, flags);
 
	 *handle = stream->handle;
	 return 0;
 }
 
 int fusion_aes67_rtp_remove_stream(struct fusion_aes67_rtp_manager *mgr, uint64_t handle)
 {
	 struct fusion_aes67_rtp_stream *stream;
	 unsigned long flags;
	 bool found = false;
 
	 spin_lock_irqsave(&mgr->lock, flags);
	 hlist_for_each_entry(stream, &mgr->streams[HASH_KEY(handle)], hnode) {
		 if (stream->handle == handle) {
			 hlist_del(&stream->hnode);
			 found = true;
			 break;
		 }
	 }
	 spin_unlock_irqrestore(&mgr->lock, flags);
 
	 if (!found) return -ENOENT;
	 kref_put(&stream->ref, fusion_aes67_rtp_stream_release);
	 return 0;
 }
 
 int fusion_aes67_rtp_process_packet(struct fusion_aes67_rtp_manager *mgr,
									 struct fusion_aes67_rtp_packet *packet, uint32_t size)
 {
	 struct fusion_aes67_rtp_stream *stream;
	 uint64_t key = ((uint64_t)packet->ip.daddr << 16) | packet->udp.dest;
	 uint32_t payload_len, offset, len1, len2, samples;
	 uint8_t *payload;
	 unsigned long flags;
 
	 if (size < sizeof(*packet) || swab16(packet->ip.frag_off) & 0x1FFF) {
		 return NF_ACCEPT; /* Too small or fragmented */
	 }
 
	 spin_lock_irqsave(&mgr->lock, flags);
	 hlist_for_each_entry(stream, &mgr->streams[HASH_KEY(key)], hnode) {
		 if (!stream->info.is_source && stream->info.dest_ip == packet->ip.daddr &&
			 stream->info.dest_port == packet->udp.dest) {
			 if (packet->rtp.payload_type != stream->info.payload_type ||
				 packet->rtp.ssrc != swab32(0x12345678) /* TODO: SSRC */) {
				 continue; /* Wrong payload or SSRC */
			 }
 
			 payload_len = swab16(packet->udp.len) - sizeof(struct udphdr) - sizeof(struct fusion_aes67_rtp_header);
			 payload = (uint8_t *)packet + sizeof(*packet);
			 samples = payload_len / (stream->info.channels * snd_pcm_format_width(stream->info.format) / 8);
			 if (!samples) continue;
 
			 offset = mgr->ops->get_buffer_offset(mgr->ops_user, stream->handle,
												  swab32(packet->rtp.timestamp) + stream->info.playout_delay, false);
			 len1 = min(mgr->ops->get_buffer_length(mgr->ops_user, stream->handle, false) - offset, samples);
			 len2 = samples - len1;
 
			 for (int i = 0; i < stream->info.channels; i++) {
				 void *buf = mgr->ops->get_buffer(mgr->ops_user, stream->handle, i, false);
				 if (len1) memcpy(buf + offset * stream->info.format_width / 8, payload + i * len1, len1);
				 if (len2) memcpy(buf, payload + i * len2, len2);
			 }
 
			 spin_unlock_irqrestore(&mgr->lock, flags);
			 return NF_DROP;
		 }
	 }
	 spin_unlock_irqrestore(&mgr->lock, flags);
	 return NF_ACCEPT;
 }
 
 void fusion_aes67_rtp_prepare_buffers(struct fusion_aes67_rtp_manager *mgr)
 {
	 struct fusion_aes67_rtp_stream *stream;
	 unsigned long flags;
	 int i;
 
	 spin_lock_irqsave(&mgr->lock, flags);
	 for (i = 0; i < FUSION_AES67_RTP_HASH_BITS; i++) {
		 hlist_for_each_entry(stream, &mgr->streams[i], hnode) {
			 kref_get(&stream->ref);
			 if (!stream->info.is_source) {
				 uint64_t sac = mgr->ops->get_sac(mgr->ops_user, stream->handle);
				 if (stream->last_sac + mgr->ops->get_frame_size(mgr->ops_user, stream->handle) > sac) {
					 uint32_t offset = mgr->ops->get_buffer_offset(mgr->ops_user, stream->handle, sac, false);
					 for (int j = 0; j < stream->info.channels; j++) {
						 void *buf = mgr->ops->get_buffer(mgr->ops_user, stream->handle, j, false);
						 memset(buf + offset * stream->info.format_width / 8, 0,
								mgr->ops->get_frame_size(mgr->ops_user, stream->handle) * stream->info.format_width / 8);
					 }
				 }
			 }
			 kref_put(&stream->ref, fusion_aes67_rtp_stream_release);
		 }
	 }
	 spin_unlock_irqrestore(&mgr->lock, flags);
 }
 
 void fusion_aes67_rtp_send_packets(struct fusion_aes67_rtp_manager *mgr, uint64_t current_sac)
 {
	 struct fusion_aes67_rtp_stream *stream;
	 unsigned long flags;
	 int i;
 
	 spin_lock_irqsave(&mgr->lock, flags);
	 for (i = 0; i < FUSION_AES67_RTP_HASH_BITS; i++) {
		 hlist_for_each_entry(stream, &mgr->streams[i], hnode) {
			 if (!stream->info.is_source || current_sac < stream->last_sac + stream->packet_interval) continue;
 
			 kref_get(&stream->ref);
			 struct sk_buff *skb;
			 void *packet;
			 uint32_t size = sizeof(struct fusion_aes67_rtp_packet) +
							 stream->info.samples_per_packet * stream->info.channels *
							 snd_pcm_format_width(stream->info.format) / 8;
 
			 if (fusion_aes67_nf_create_packet(mgr->nf, &skb, &packet, &size) &&
				 size >= sizeof(struct fusion_aes67_rtp_packet)) {
				 struct fusion_aes67_rtp_packet *rtp = packet;
				 memcpy(rtp, &stream->rtp_packet_base, sizeof(*rtp));
				 rtp->ip.tot_len = swab16(size - ETH_HLEN);
				 rtp->ip.check = fusion_aes67_compute_cksum(&rtp->ip, sizeof(rtp->ip));
				 rtp->udp.len = swab16(size - ETH_HLEN - sizeof(rtp->ip));
				 rtp->rtp.seq_num = swab16(stream->outgoing_seq_num++);
				 rtp->rtp.timestamp = swab32(current_sac);
 
				 uint8_t *payload = (uint8_t *)packet + sizeof(*rtp);
				 uint32_t offset = mgr->ops->get_buffer_offset(mgr->ops_user, stream->handle, current_sac, true);
				 for (int j = 0; j < stream->info.channels; j++) {
					 void *buf = mgr->ops->get_buffer(mgr->ops_user, stream->handle, j, true);
					 memcpy(payload + j * stream->info.samples_per_packet * stream->info.format_width / 8,
							buf + offset * stream->info.format_width / 8,
							stream->info.samples_per_packet * stream->info.format_width / 8);
				 }
 
				 int ret = fusion_aes67_nf_tx_packet(mgr->nf, skb, packet, size);
				 if (ret < 0) printk(KERN_ERR "fusion_aes67_rtp: TX failed: %d\n", ret);
				 stream->last_sac = current_sac;
			 }
			 kref_put(&stream->ref, fusion_aes67_rtp_stream_release);
		 }
	 }
	 spin_unlock_irqrestore(&mgr->lock, flags);
 }
 
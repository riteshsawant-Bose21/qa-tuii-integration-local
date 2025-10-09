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
#include <linux/types.h>
#include <sound/pcm.h>
#include <linux/delay.h>
#include <linux/byteorder/generic.h>
#include <net/neighbour.h>
#include <net/arp.h>
#include <linux/etherdevice.h>
#include "fusion_connect_rtp.h"

#define TIMER_BASE_INTERVAL_NS 333333

#define HASH_KEY(handle) hash_64(handle, FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_UC(ip, port) hash_64(((uint64_t)(ip) << 16) | (port), FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_MC(ip) hash_64((uint64_t)(ip), FUSION_CN_RTP_HASH_BITS)

static uint16_t fusion_cn_rtp_compute_cksum(const void *data, uint16_t len)
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

void fusion_cn_rtp_stream_release(struct kref *ref)
{
    struct fusion_cn_rtp_stream *stream = container_of(ref, struct fusion_cn_rtp_stream, ref);
    if (stream->next_action_times) {
        kfree(stream->next_action_times);
    }
    printk(KERN_INFO "fusion_cn_rtp: stream_release: release stream %s\n", stream->info.stream_name);
    kfree(stream);
}

int fusion_cn_rtp_init(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_netfilter *nf,
                       struct fusion_cn_rtp_ops *ops, void *cn_mgr)
{
    int i;

    if (!rtp_mgr || !cn_mgr) {
        printk(KERN_ERR "fusion_cn_rtp: manager_init: Invalid arguments\n");
        return -EINVAL;
    }

    rtp_mgr->nf = nf;
    rtp_mgr->ops = ops;
    rtp_mgr->cn_mgr = cn_mgr;
    rwlock_init(&rtp_mgr->lock);
    for (i = 0; i < (1 << FUSION_CN_RTP_HASH_BITS); i++) {
        INIT_HLIST_HEAD(&rtp_mgr->streams[i]);
        INIT_HLIST_HEAD(&rtp_mgr->mc_packet_maps[i]);
        INIT_HLIST_HEAD(&rtp_mgr->uc_packet_maps[i]);
    }
    return 0;
}

void fusion_cn_rtp_destroy(struct fusion_cn_rtp_manager *rtp_mgr)
{
    int i;
    unsigned long flags;
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    struct hlist_node *tmp_map, *tmp_stream;

    write_lock_irqsave(&rtp_mgr->lock, flags);
    for (i = 0; i < (1 << FUSION_CN_RTP_HASH_BITS); i++) {
        hlist_for_each_entry_safe(map, tmp_map, &rtp_mgr->mc_packet_maps[i], hnode) {
            hlist_del(&map->hnode);
            kfree(map);
        }
        hlist_for_each_entry_safe(map, tmp_map, &rtp_mgr->uc_packet_maps[i], hnode) {
            hlist_del(&map->hnode);
            kfree(map);
        }
        hlist_for_each_entry_safe(stream, tmp_stream, &rtp_mgr->streams[i], hnode) {
            fusion_cn_rtp_remove_stream(rtp_mgr, stream);
            hlist_del(&stream->hnode);
            kref_put(&stream->ref, fusion_cn_rtp_stream_release);
        }
    }
    write_unlock_irqrestore(&rtp_mgr->lock, flags);
}

static bool fusion_cn_rtp_is_ip_mcast(uint32_t ip)
{
    uint32_t ip_host = be32_to_cpu(ip);
    return (ip_host >= 0xE0000000 && ip_host <= 0xEFFFFFFF); /* 224.0.0.0 - 239.255.255.255 */
}

static void fusion_cn_rtp_set_multicast_mac(uint32_t ip, uint8_t mac[ETH_ALEN])
{
    uint32_t ip_host = be32_to_cpu(ip);
    mac[0] = 0x01;
    mac[1] = 0x00;
    mac[2] = 0x5E;
    mac[3] = (ip_host >> 16) & 0x7F; /* Lower 23 bits of IP */
    mac[4] = (ip_host >> 8) & 0xFF;
    mac[5] = ip_host & 0xFF;
}

/* Resolve the unicast MAC address for a given IP address */
static int fusion_cn_rtp_resolve_unicast_mac(struct fusion_cn_rtp_manager *rtp_mgr,
                                             __be32 dest_ip_be, u8 mac[ETH_ALEN])
{
    struct net_device *dev;
    struct neighbour *n;
    int i, err = -EAGAIN;

    /* iface_name must be the egress iface; you already have it */
    dev = dev_get_by_name(&init_net, rtp_mgr->nf->iface_name);
    if (!dev) {
        pr_err("fusion_cn_rtp: no dev '%s'\n", rtp_mgr->nf->iface_name);
        return -ENODEV;
    }

    /* If the dest is off-subnet you should resolve the gateway instead.
     * If you only ever send to same-subnet peers, this is fine.
     * (If you later need off-subnet, do a route lookup to get nexthop.) */
    for (i = 0; i < 5; i++) {
        n = neigh_lookup(&arp_tbl, &dest_ip_be, dev);
        if (n) {
            if (READ_ONCE(n->nud_state) & NUD_VALID) {
                ether_addr_copy(mac, n->ha);
                neigh_release(n);
                err = 0;
                break;
            }

            /* Not valid yet; kick resolution and wait */
            neigh_event_send(n, NULL);
            neigh_release(n);
        } else {
            /* No entry yet; send an ARP request and wait */
            arp_send(ARPOP_REQUEST, ETH_P_ARP, dest_ip_be, dev, 0,
                     NULL, dev->dev_addr, NULL);
        }

        /* Give the stack time to process ARP (ms, not us/ns). */
        msleep(40);
    }

    if (err)
        pr_err("fusion_cn_rtp: ARP resolve %pI4 failed (%d)\n", &dest_ip_be, err);

    dev_put(dev);
    return err;
}


int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *rtp_mgr,
                             struct fusion_cn_stream_config *info,
                             void *alsa_stream,
                             struct fusion_cn_rtp_stream **rtp_stream)
{
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map = NULL;
    unsigned long flags;
    int err;
    struct net_device *dev;
    int sample_physical_width_bits;
    uint32_t payload_bytes;
    uint32_t pkt_bytes;

    *rtp_stream = NULL;

    /* Verify interface exists and grab its MAC for eth.h_source */
    dev = dev_get_by_name(&init_net, rtp_mgr->nf->iface_name);
    if (!dev) {
        printk(KERN_ERR "fusion_cn_rtp: add_stream: Interface %s not found\n",
               rtp_mgr->nf->iface_name);
        return -ENODEV;
    }

    printk(KERN_INFO
           "fusion_cn_rtp: add_stream %s: sample_rate=%u, channels=%u, "
           "dest_ip=0x%08x, source_ip=0x%08x, dest_port=%u, source_port=%u, "
           "is_source=%d, is_fusion_connect=%d\n",
           info->stream_name, info->sample_rate, info->channels,
           info->dest_ip, info->source_ip, info->dest_port, info->source_port,
           info->is_source, info->is_fusion_connect);

    if (!info->stream_handle || !info->sample_rate || !info->channels ||
        !info->dest_ip || !info->source_ip || !info->dest_port || !info->source_port) {
        dev_put(dev);
        printk(KERN_ERR "fusion_cn_rtp: add_stream: Invalid stream parameters\n");
        return -EINVAL;
    }

    stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) {
        dev_put(dev);
        return -ENOMEM;
    }

    /* Only allocate packet_map for sink streams (RX) */
    if (!info->is_source) {
        map = kzalloc(sizeof(*map), GFP_KERNEL);
        if (!map) {
            kfree(stream);
            dev_put(dev);
            return -ENOMEM;
        }
    }

    memcpy(&stream->info, info, sizeof(*info));
    kref_init(&stream->ref);
    spin_lock_init(&stream->lock);
    atomic_set(&stream->is_running, 0);

    sample_physical_width_bits = snd_pcm_format_physical_width(info->format);
    if (sample_physical_width_bits <= 0) {
        if (map) kfree(map);
        kfree(stream);
        dev_put(dev);
        printk(KERN_ERR "fusion_cn_rtp: Invalid sample format %d\n", info->format);
        return -EINVAL;
    }

    /* Fixed payload size per packet for this stream */
    payload_bytes = info->frames_per_packet * info->channels * (sample_physical_width_bits / 8);

    /* Prepare invariant headers template */
    stream->rtp_packet_base.eth.h_proto = swab16(ETH_P_IP);
    /* Set source MAC from device */
    ether_addr_copy(stream->rtp_packet_base.eth.h_source, dev->dev_addr);

    stream->rtp_packet_base.ip.version  = 4;
    stream->rtp_packet_base.ip.ihl      = 5;
    stream->rtp_packet_base.ip.protocol = IPPROTO_UDP;
    stream->rtp_packet_base.ip.saddr    = info->source_ip;
    stream->rtp_packet_base.ip.daddr    = info->dest_ip;
    stream->rtp_packet_base.ip.tos      = 0xB8; /* EF; adjust per stream if needed */
    stream->rtp_packet_base.ip.ttl      = 64;

    stream->rtp_packet_base.udp.source  = htons(info->source_port);
    stream->rtp_packet_base.udp.dest    = htons(info->dest_port);

    stream->rtp_packet_base.rtp.version      = 0x80;
    stream->rtp_packet_base.rtp.payload_type = info->payload_type;

    /*
     * Fill dest MAC for TX only (sources). Sinks do not transmit, so no need
     * to resolve anything; their eth header is unused.
     */
    if (info->is_source) {
        if (info->source_ip == info->dest_ip) {
            /* Loopback: set a dummy dest MAC; not used */
            memset(stream->rtp_packet_base.eth.h_dest, 0, ETH_ALEN);
        } else if (fusion_cn_rtp_is_ip_mcast(info->dest_ip)) {
            fusion_cn_rtp_set_multicast_mac(info->dest_ip,
                                            stream->rtp_packet_base.eth.h_dest);
        } else {
            err = fusion_cn_rtp_resolve_unicast_mac(rtp_mgr, info->dest_ip,
                                                    stream->rtp_packet_base.eth.h_dest);
            if (err < 0) {
                printk(KERN_ERR
                       "fusion_cn_rtp: Failed to resolve unicast MAC for IP 0x%08x: %d\n",
                       info->dest_ip, err);
                if (map) kfree(map);
                kfree(stream);
                dev_put(dev);
                return err;
            }
        }
    }

    /*
     * IP/UDP lengths are constant for this stream; compute once and
     * stamp them into the template. (These include RTP header + payload.)
     * packet_bytes = ETH + IP + UDP + RTP + payload
     */
    pkt_bytes = sizeof(struct fusion_cn_rtp_packet) + payload_bytes;
    stream->rtp_packet_base.ip.tot_len = swab16(pkt_bytes - ETH_HLEN);
    stream->rtp_packet_base.udp.len    = swab16(pkt_bytes - ETH_HLEN - sizeof(struct iphdr));

    if (info->is_source) {
        get_random_bytes(&stream->ssrc, sizeof(stream->ssrc));
        stream->rtp_packet_base.rtp.ssrc = swab32(stream->ssrc);
        get_random_bytes(&stream->outgoing_seq_num, sizeof(stream->outgoing_seq_num));
        stream->rtp_packet_base.rtp.seq_num = swab16(stream->outgoing_seq_num);
    } else {
        stream->ssrc = 0;
    }

    stream->next_action_time = 0;
    stream->packet_time = (info->frames_per_packet * NSEC_PER_SEC) / info->sample_rate;

    /* Precompute checksum base over invariant IP fields (excluding tot_len) */
    stream->ip_checksum_base =
        fusion_cn_rtp_compute_cksum(&stream->rtp_packet_base.ip,
                                    sizeof(stream->rtp_packet_base.ip) -
                                    sizeof(stream->rtp_packet_base.ip.tot_len));

    /* No cached skb allocated here anymore */

    write_lock_irqsave(&rtp_mgr->lock, flags);
    hlist_add_head(&stream->hnode,
        &rtp_mgr->streams[hash_64(info->stream_handle, FUSION_CN_RTP_HASH_BITS)]);

    /* Packet maps only needed for sinks (RX path) */
    if (!info->is_source) {
        map->source_ip   = info->source_ip;
        map->dest_ip     = info->dest_ip;
        map->source_port = info->source_port;
        map->stream_handle = info->stream_handle;
        map->alsa_stream = alsa_stream;
        if (fusion_cn_rtp_is_ip_mcast(map->dest_ip)) {
            hlist_add_head(&map->hnode,
                &rtp_mgr->mc_packet_maps[PACKET_MAP_KEY_MC(map->dest_ip)]);
        } else {
            hlist_add_head(&map->hnode,
                &rtp_mgr->uc_packet_maps[PACKET_MAP_KEY_UC(map->source_ip, map->source_port)]);
        }
    }
    write_unlock_irqrestore(&rtp_mgr->lock, flags);

    dev_put(dev);

    *rtp_stream = stream;
    return 0;
}

int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_stream *stream)
{
    struct fusion_cn_packet_map *map;
    struct hlist_node *map_tmp;

    hlist_del(&stream->hnode);
    // Only remove from packet_maps for sink streams
    if (!stream->info.is_source) {
        if (fusion_cn_rtp_is_ip_mcast(stream->info.dest_ip)) {
            hlist_for_each_entry_safe(map, map_tmp, &rtp_mgr->mc_packet_maps[PACKET_MAP_KEY_MC(stream->info.dest_ip)], hnode) {
                if (map->stream_handle == stream->info.stream_handle) {
                    hlist_del(&map->hnode);
                    kfree(map);
                    break;
                }
            }
        } else {
            hlist_for_each_entry_safe(map, map_tmp, &rtp_mgr->uc_packet_maps[PACKET_MAP_KEY_UC(stream->info.source_ip, stream->info.source_port)], hnode) {
                if (map->stream_handle == stream->info.stream_handle) {
                    hlist_del(&map->hnode);
                    kfree(map);
                    break;
                }
            }
        }
    }
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);

    return 0;
}

struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket;

    if (!rtp_mgr || !rtp_mgr->cn_mgr) {
        printk(KERN_ERR "fusion_cn_rtp: get_stream: Null or uninitialized rtp_mgr for handle %llu\n", handle);
        return NULL;
    }

    bucket = hash_64(handle, FUSION_CN_RTP_HASH_BITS);
    read_lock_irqsave(&rtp_mgr->lock, flags);
    hlist_for_each_entry(stream, &rtp_mgr->streams[bucket], hnode) {
        if (stream->info.stream_handle == handle) {
            kref_get(&stream->ref);
            read_unlock_irqrestore(&rtp_mgr->lock, flags);
            return stream;
        }
    }
    read_unlock_irqrestore(&rtp_mgr->lock, flags);
    printk(KERN_WARNING "fusion_cn_rtp: get_stream: Stream %llu not found\n", handle);
    return NULL;
}

__always_inline int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_packet *packet)
{
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    uint32_t payload_len, len1, len2, frames_in_payload;
    uint8_t *payload;
    void *buf;
    unsigned long flags;
    uint32_t packet_ssrc;
    uint64_t handle = 0;
    uint16_t seq_num;
    uint32_t write_slot;
    uint32_t buf_offset;
    uint64_t current_phc_ns, current_sac, global_sac, ns_from_ms_boundary, reconstructed_phc_ns;
    uint32_t rtp_timestamp;
    int sample_physical_width_bits;

    if (!packet) {
        printk(KERN_ERR "fusion_cn_rtp: process_packet: Invalid packet pointer\n");
        return NF_ACCEPT;
    }

    read_lock_irqsave(&rtp_mgr->lock, flags);
    if (fusion_cn_rtp_is_ip_mcast(packet->ip.daddr)) {
        hlist_for_each_entry(map, &rtp_mgr->mc_packet_maps[PACKET_MAP_KEY_MC(packet->ip.daddr)], hnode) {
            if (map->dest_ip == packet->ip.daddr) {
                handle = map->stream_handle;
                break;
            }
        }
    } else {
        int source_port = ntohs(packet->udp.source);
        hlist_for_each_entry(map, &rtp_mgr->uc_packet_maps[PACKET_MAP_KEY_UC(packet->ip.saddr, source_port)], hnode) {
            if (map->source_ip == packet->ip.saddr && map->source_port == source_port) {
                handle = map->stream_handle;
                break;
            }
        }
    }
    if (!handle) {
        read_unlock_irqrestore(&rtp_mgr->lock, flags);
        return NF_ACCEPT;
    }

    hlist_for_each_entry(stream, &rtp_mgr->streams[hash_64(handle, FUSION_CN_RTP_HASH_BITS)], hnode) {
        if (stream->info.stream_handle == handle && !stream->info.is_source) {
            spin_lock(&stream->lock);

            if (!atomic_read(&stream->is_running)) {
                spin_unlock(&stream->lock);
                read_unlock_irqrestore(&rtp_mgr->lock, flags);
                return NF_DROP;
            }
            
            sample_physical_width_bits = snd_pcm_format_physical_width(stream->info.format);

            packet_ssrc = swab32(packet->rtp.ssrc);
            if (stream->ssrc == 0 || packet_ssrc != stream->ssrc) {
                stream->ssrc = packet_ssrc;
                stream->current_seq_num = 0;
                printk(KERN_INFO "fusion_cn_rtp: process_packet: Stashed SSRC 0x%08x for stream %s\n",
                       stream->ssrc, stream->info.stream_name);
            }

            payload_len = swab16(packet->udp.len) - sizeof(struct udphdr) - sizeof(struct fusion_cn_rtp_header);
            payload = (uint8_t *)packet + sizeof(*packet);

            // TODO: Assume full payload... prevent packets without right?
            frames_in_payload = payload_len / (stream->info.channels * sample_physical_width_bits / 8);
            if (!frames_in_payload) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Zero length frame detected!");
                spin_unlock(&stream->lock);
                continue;
            }

            seq_num = swab16(packet->rtp.seq_num);
            write_slot = seq_num % (stream->frames_in_buf / stream->info.frames_per_packet);
            buf_offset = write_slot * stream->info.frames_per_packet;

            if (stream->playback_index >= (stream->frames_in_buf / stream->info.frames_per_packet)) {
                stream->playback_index = 0;
            }

            buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, map->alsa_stream);
            if (!buf) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Invalid Buffer!");
                spin_unlock(&stream->lock);
                read_unlock_irqrestore(&rtp_mgr->lock, flags);
                return NF_DROP;
            }

            len1 = min(stream->frames_in_buf - buf_offset, frames_in_payload);
            len2 = frames_in_payload - len1;

            if (len1) {
                memcpy(buf + buf_offset * stream->info.channels * sample_physical_width_bits / 8, 
                       payload, len1 * stream->info.channels * sample_physical_width_bits / 8);
            }
            if (len2) { // TODO unsure of why this copies to the beginning of the buffer
                memcpy(buf + buf_offset, payload + len1 * stream->info.channels * sample_physical_width_bits / 8,
                       len2 * stream->info.channels * sample_physical_width_bits / 8);
            }

            rtp_timestamp = swab32(packet->rtp.timestamp);
            current_phc_ns = rtp_mgr->ops->get_phc_ns();
            // TODO: review for 96k
            // sac = (phc * sample_rate) / NSEC_PER_SEC 
            current_sac = (((current_phc_ns >> (stream->info.sample_rate == 48000 ? 2 : 1)) * 3) / 15625);

            global_sac = ((current_sac & 0xFFFFFFFF00000000ULL) | rtp_timestamp) - stream->info.timestamp_offset;
            
            if (rtp_timestamp < 0x3FFFFFFFU && (uint32_t)current_sac >= 0xC0000000U) {
                global_sac += (1ULL << 32);
            } else if ((uint32_t)current_sac < 0x3FFFFFFFU && rtp_timestamp >= 0xC0000000U) {
                global_sac -= (1ULL << 32);
            }
            
            // Avoid overflow in reconstructed_phc_ns calculation
            // TODO: review for 96k
            // phc = (sac * NSEC_PER_SEC) / sample_rate
            reconstructed_phc_ns = (global_sac * 62500) / (stream->info.sample_rate == 48000 ? 3 : 6);
            ns_from_ms_boundary = reconstructed_phc_ns % NSEC_PER_MSEC;
            reconstructed_phc_ns -= ns_from_ms_boundary;

            if (ns_from_ms_boundary <= TIMER_BASE_INTERVAL_NS) {
                reconstructed_phc_ns += TIMER_BASE_INTERVAL_NS;
            } else if (ns_from_ms_boundary <= 2 * TIMER_BASE_INTERVAL_NS) {
                reconstructed_phc_ns += 2 * TIMER_BASE_INTERVAL_NS;
            } else {
                reconstructed_phc_ns += NSEC_PER_MSEC;
            }

            if (stream->current_seq_num != 0 && seq_num > stream->current_seq_num && seq_num != stream->current_seq_num + 1) {
                for (int i = stream->current_seq_num + 1; i < seq_num; i++) {
                    uint32_t gap_slot = i % (stream->frames_in_buf / stream->info.frames_per_packet);
                    uint32_t gap_offset = gap_slot * stream->info.frames_per_packet;
                    printk(KERN_WARNING "fusion_cn_rtp: process_packet: Gap detected in stream %s, seq_num=%u, gap_slot=%u\n",
                            stream->info.stream_name, i, gap_slot);
                    memset(buf + gap_offset * stream->info.channels * sample_physical_width_bits / 8,
                            0, stream->info.frames_per_packet * stream->info.channels * sample_physical_width_bits / 8);
                    stream->next_action_times[gap_slot] = (reconstructed_phc_ns - ((seq_num - i) * stream->packet_time)) + stream->info.playout_delay;
                }
            } else if (seq_num < stream->current_seq_num && stream->current_seq_num != 65535) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Got older packet for stream %s, seq_num=%u\n",
                            stream->info.stream_name, seq_num);
            }

            stream->next_action_times[write_slot] = reconstructed_phc_ns + stream->info.playout_delay;
            stream->current_seq_num = seq_num;

            if (rtp_mgr->debug) printk(KERN_DEBUG "fusion_cn_rtp: process_packet: Stream %s, slot=%u, seq_num=%u, current_phc_ns=%llu, reconstructed_phc=%llu, next_action_time=%llu\n",
                stream->info.stream_name, write_slot, seq_num, current_phc_ns, reconstructed_phc_ns, stream->next_action_times[write_slot]);

            spin_unlock(&stream->lock);
            read_unlock_irqrestore(&rtp_mgr->lock, flags);
            return NF_DROP;
        }
    }

    read_unlock_irqrestore(&rtp_mgr->lock, flags);
    return NF_ACCEPT;
}


__always_inline void fusion_cn_rtp_send_packet(struct fusion_cn_rtp_manager *rtp_mgr,
                                               struct fusion_cn_rtp_stream  *stream,
                                               void *alsa_stream)
{
    struct sk_buff *skb;
    const u32 phys_bits = snd_pcm_format_physical_width(stream->info.format);

    if (!stream->info.is_source)
        return;

    if ((int)phys_bits <= 0) {
        printk(KERN_ERR "fusion_cn_rtp: send_packet: Invalid sample format %d\n",
               stream->info.format);
        return;
    }

    /* sizes */
    const u32 sample_bytes = phys_bits / 8;
    const u32 ch           = stream->info.channels;
    const u32 frames       = stream->info.frames_per_packet;
    const u32 payload_len  = sample_bytes * ch * frames;
    const u32 hdr_len      = sizeof(stream->rtp_packet_base);           /* ETH+IP+UDP+RTP template */
    const u32 total_len    = hdr_len + payload_len;                      /* matches on-wire size */

    spin_lock(&stream->lock);

    /* Timestamp / seq */
    {
        u64 global_sac = (((stream->next_action_time >>
                           (stream->info.sample_rate == 48000 ? 2 : 1)) * 3) / 15625);
        stream->rtp_packet_base.rtp.timestamp = swab32((u32)(global_sac + stream->info.timestamp_offset));
        stream->rtp_packet_base.rtp.seq_num   = swab16(stream->outgoing_seq_num++);
    }

    /* IP/UDP lengths and incremental IP checksum */
    {
        const u32 ip_tot_len = total_len - ETH_HLEN;
        const u32 udp_len    = total_len - ETH_HLEN - sizeof(struct iphdr);
        u32 sum;

        stream->rtp_packet_base.ip.tot_len = swab16(ip_tot_len);
        stream->rtp_packet_base.udp.len    = swab16(udp_len);

        sum = stream->ip_checksum_base + swab16(ip_tot_len);
        sum = (sum >> 16) + (sum & 0xFFFF);
        stream->rtp_packet_base.ip.check = swab16((u16)~sum);
    }

    /* fresh skb per packet */
    skb = alloc_skb(total_len, GFP_ATOMIC);
    if (unlikely(!skb)) {
        printk(KERN_ERR "fusion_cn_rtp: alloc_skb(%u) failed for %s\n",
               total_len, stream->info.stream_name);
        spin_unlock(&stream->lock);
        return;
    }

    /* grow and fill */
    {
        u8 *base = skb_put(skb, total_len);
        if (unlikely(!base)) {
            kfree_skb(skb);
            spin_unlock(&stream->lock);
            return;
        }

        /* headers */
        memcpy(base, &stream->rtp_packet_base, hdr_len);

        /* payload */
        {
            const u32 off_frames = rtp_mgr->ops->get_buffer_offset(rtp_mgr->cn_mgr, alsa_stream);
            const u8 *src = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, alsa_stream)
                           + (u64)off_frames * ch * sample_bytes;
            memcpy(base + hdr_len, src, payload_len);
        }
    }

    /* metadata for stack */
    skb_set_network_header(skb, ETH_HLEN);
    skb->protocol = htons(ETH_P_IP);

    if (rtp_mgr->debug) {
        printk(KERN_DEBUG "fusion_cn_rtp: send_packet %s seq=%u len=%u\n",
               stream->info.stream_name, stream->outgoing_seq_num, total_len);
    }

    spin_unlock(&stream->lock);

    /* TX hands off ownership; do NOT touch skb afterwards */
    if (fusion_cn_nf_tx_packet(rtp_mgr, skb, total_len) < 0) {
        /* if your TX path doesn’t free on failure, free here */
        kfree_skb(skb);
    }
}

int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle, bool running, void *alsa_stream)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket;
    bool found = false;

    if (!rtp_mgr || !rtp_mgr->cn_mgr) {
        printk(KERN_ERR "fusion_cn_rtp: set_rtp_stream_running: Null or uninitialized rtp_mgr for handle %llu\n", handle);
        return -EINVAL;
    }

    bucket = hash_64(handle, FUSION_CN_RTP_HASH_BITS);
    read_lock_irqsave(&rtp_mgr->lock, flags);
    hlist_for_each_entry(stream, &rtp_mgr->streams[bucket], hnode) {
        if (stream->info.stream_handle == handle) {
            kref_get(&stream->ref);
            found = true;
            break;
        }
    }
    read_unlock_irqrestore(&rtp_mgr->lock, flags);

    if (!found) {
        printk(KERN_ERR "fusion_cn_rtp: set_rtp_stream_running: Stream %llu not found\n", handle);
        return -ENOENT;
    }

    if (running) {
        stream->frames_in_buf = rtp_mgr->ops->get_buffer_size_in_frames(rtp_mgr->cn_mgr, alsa_stream);
        // for sinks only. allocate this before we set the stream running
        // but it needs to happen after alsa device is opened and has set the buffer frames
        if (!stream->info.is_source) {
            if (stream->next_action_times) {
                kfree(stream->next_action_times);
            } 
            
            stream->next_action_times = kzalloc(sizeof(uint64_t) * (stream->frames_in_buf / stream->info.frames_per_packet), GFP_KERNEL);
            memset(stream->next_action_times, 0, sizeof(uint64_t) * (stream->frames_in_buf / stream->info.frames_per_packet));
            printk(KERN_DEBUG "fusion_cn_rtp: alloc %u slots in next_action_times", stream->frames_in_buf / stream->info.frames_per_packet);
        }
        stream->playback_index = (stream->frames_in_buf / stream->info.frames_per_packet); // set to a invalid value i can check for on first process_packet
        stream->next_action_time = 0;
        stream->current_seq_num = 0;
    }

    atomic_set(&stream->is_running, running);

    kref_put(&stream->ref, fusion_cn_rtp_stream_release);

    printk(KERN_INFO "fusion_cn_rtp: set_rtp_stream_running: Stream %s is_running=%d\n", stream->info.stream_name, running);
    return 0;
}

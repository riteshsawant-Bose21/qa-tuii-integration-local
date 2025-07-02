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
#include <net/arp.h>
#include "fusion_connect_rtp.h"

#define TIMER_BASE_INTERVAL_NS 333333

#define HASH_KEY(handle) hash_64(handle, FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_UC(ip, port) hash_64(((uint64_t)(ip) << 16) | (port), FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_MC(ip) hash_64((uint64_t)(ip), FUSION_CN_RTP_HASH_BITS)

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

// static __sum16 fusion_cn_rtp_compute_udp_cksum(struct iphdr *ip, struct udphdr *udp, void *data, uint32_t data_len)
// {
//     struct {
//         __be32 src;
//         __be32 dst;
//         __u8 zero;
//         __u8 proto;
//         __be16 len;
//     } __attribute__((packed)) pseudo_hdr;
//     unsigned long sum = 0;
//     int i;

//     /* Pseudo-header for UDP checksum */
//     pseudo_hdr.src = ip->saddr;
//     pseudo_hdr.dst = ip->daddr;
//     pseudo_hdr.zero = 0;
//     pseudo_hdr.proto = IPPROTO_UDP;
//     pseudo_hdr.len = udp->len;

//     /* Sum the pseudo-header */
//     for (i = 0; i < sizeof(pseudo_hdr) / 2; i++) {
//         sum += ((uint16_t *)&pseudo_hdr)[i];
//     }

//     /* Sum the UDP header */
//     for (i = 0; i < sizeof(*udp) / 2; i++) {
//         sum += ((uint16_t *)udp)[i];
//     }

//     /* Sum the data */
//     for (i = 0; i < data_len / 2; i++) {
//         sum += ((uint16_t *)data)[i];
//     }
//     if (data_len % 2) {
//         sum += ((uint8_t *)data)[data_len - 1];
//     }

//     /* Fold the sum */
//     while (sum >> 16) {
//         sum = (sum & 0xFFFF) + (sum >> 16);
//     }

//     return (__sum16)~sum;
// }

void fusion_cn_rtp_stream_release(struct kref *ref)
{
    struct fusion_cn_rtp_stream *stream = container_of(ref, struct fusion_cn_rtp_stream, ref);
    if (stream->next_action_times) {
        kfree(stream->next_action_times);
    }
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
    INIT_LIST_HEAD(&rtp_mgr->active_stream_handles.fn_sink);
    INIT_LIST_HEAD(&rtp_mgr->active_stream_handles.fn_source);
    INIT_LIST_HEAD(&rtp_mgr->active_stream_handles.aes67_sink);
    INIT_LIST_HEAD(&rtp_mgr->active_stream_handles.aes67_source);
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
    struct handle_node *handle_node, *tmp;
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    struct hlist_node *tmp_map, *tmp_stream;

    write_lock_irqsave(&rtp_mgr->lock, flags);
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.fn_sink, node) {
        list_del(&handle_node->node);
        kfree(handle_node);
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.fn_source, node) {
        list_del(&handle_node->node);
        kfree(handle_node);
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.aes67_sink, node) {
        list_del(&handle_node->node);
        kfree(handle_node);
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.aes67_source, node) {
        list_del(&handle_node->node);
        kfree(handle_node);
    }
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
            fusion_cn_rtp_remove_stream(rtp_mgr, stream->info.stream_handle);
            hlist_del(&stream->hnode);
            kref_put(&stream->ref, fusion_cn_rtp_stream_release);
        }
    }
    write_unlock_irqrestore(&rtp_mgr->lock, flags);
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

/* Resolve the unicast MAC address for a given IP address */
static int fusion_cn_rtp_resolve_unicast_mac(struct fusion_cn_rtp_manager *rtp_mgr,
                                            uint32_t dest_ip, unsigned char *mac_addr)
{
    struct net_device *dev;
    struct neighbour *neigh;
    int err = -ENETUNREACH;

    /* Find the output device */
    dev = dev_get_by_name(&init_net, rtp_mgr->nf->iface_name);
    if (!dev) {
        printk(KERN_ERR "fusion_cn_rtp: Failed to find device %s for ARP resolution\n", rtp_mgr->nf->iface_name);
        return -ENODEV;
    }

    /* Look up the MAC address in the ARP cache */
    neigh = neigh_lookup(&arp_tbl, &dest_ip, dev);
    if (neigh) {
        if (neigh->nud_state & NUD_VALID) {
            memcpy(mac_addr, neigh->ha, ETH_ALEN);
            err = 0;
        } else {
            /* ARP entry is not valid, send an ARP request */
            arp_send(ARPOP_REQUEST, ETH_P_ARP, dest_ip, dev, 0, NULL, dev->dev_addr, NULL);
            err = -EAGAIN;
        }
        neigh_release(neigh);
    } else {
        /* No ARP entry, send an ARP request */
        arp_send(ARPOP_REQUEST, ETH_P_ARP, dest_ip, dev, 0, NULL, dev->dev_addr, NULL);
        err = -EAGAIN;
    }

    dev_put(dev);
    return err;
}

int fusion_cn_rtp_add_stream(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_stream_config *info, uint64_t *handle)
{
    struct fusion_cn_rtp_stream *stream;
    struct handle_node *handle_node;
    struct fusion_cn_packet_map *map = NULL;  // Only allocate for sink streams
    unsigned long flags;
    int err;
    struct net_device *dev;

    dev = dev_get_by_name(&init_net, rtp_mgr->nf->iface_name);
    if (!dev) {
        printk(KERN_ERR"fusion_cn: Interface %s not found\n", rtp_mgr->nf->iface_name);
        return -ENODEV;
    }
    dev_put(dev);

    printk(KERN_INFO "fusion_cn_rtp: add_stream %s: sample_rate=%u, channels=%u, dest_ip=0x%08x, source_ip=0x%08x, dest_port=%u, source_port=%u, is_source=%d, is_fusion_connect=%d\n",
           info->stream_name, info->sample_rate, info->channels, info->dest_ip, info->source_ip, info->dest_port, info->source_port, info->is_source, info->is_fusion_connect);

    if (!info->stream_handle || !info->sample_rate || !info->channels ||
        !info->dest_ip || !info->source_ip || !info->dest_port || !info->source_port) {
        printk(KERN_ERR "fusion_cn_rtp: Invalid stream parameters\n");
        return -EINVAL;
    }

    stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) return -ENOMEM;

    handle_node = kzalloc(sizeof(*handle_node), GFP_KERNEL);
    if (!handle_node) {
        kfree(stream);
        return -ENOMEM;
    }

    // Only allocate packet_map for sink streams
    if (!info->is_source) {
        map = kzalloc(sizeof(*map), GFP_KERNEL);
        if (!map) {
            kfree(stream);
            kfree(handle_node);
            return -ENOMEM;
        }
    }

    memcpy(&stream->info, info, sizeof(*info));
    kref_init(&stream->ref);
    spin_lock_init(&stream->lock);
    atomic_set(&stream->is_running, 0);
    stream->rtp_packet_base.eth.h_proto = swab16(ETH_P_IP);
    stream->rtp_packet_base.ip.version = 4;
    stream->rtp_packet_base.ip.ihl = 5;
    stream->rtp_packet_base.ip.protocol = IPPROTO_UDP;
    stream->rtp_packet_base.ip.saddr = info->source_ip;
    stream->rtp_packet_base.ip.daddr = info->dest_ip;

    // Check if this is a loopback packet (source IP == dest IP)
    if (info->source_ip == info->dest_ip) {
        // For loopback, set a dummy MAC address (not used in loopback)
        memset(stream->rtp_packet_base.eth.h_dest, 0, ETH_ALEN);
    } else if (fusion_cn_rtp_is_ip_mcast(info->dest_ip)) {
        fusion_cn_rtp_set_multicast_mac(info->dest_ip, stream->rtp_packet_base.eth.h_dest);
    } else {
        if (info->is_source) {
            err = fusion_cn_rtp_resolve_unicast_mac(rtp_mgr, info->dest_ip, stream->rtp_packet_base.eth.h_dest);
        } else {
            err = fusion_cn_rtp_resolve_unicast_mac(rtp_mgr, info->source_ip, stream->rtp_packet_base.eth.h_source);
        }

        if (err < 0) {
            printk(KERN_ERR "fusion_cn_rtp: Failed to resolve unicast MAC for IP 0x%08x: %d\n", 
                   info->is_source ? info->dest_ip : info->source_ip, err);
            kfree(handle_node);
            if (map) kfree(map);
            kfree(stream);
            return err;
        }
    }

    stream->rtp_packet_base.udp.source = htons(info->source_port);
    stream->rtp_packet_base.udp.dest = htons(info->dest_port);
    stream->rtp_packet_base.rtp.version = 0x80;
    stream->rtp_packet_base.rtp.payload_type = info->payload_type;

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
    stream->ns_per_sample = NSEC_PER_SEC / (uint64_t)info->sample_rate;

    write_lock_irqsave(&rtp_mgr->lock, flags);
    handle_node->handle = info->stream_handle;
    handle_node->bucket = hash_64(info->stream_handle, FUSION_CN_RTP_HASH_BITS);
    hlist_add_head(&stream->hnode, &rtp_mgr->streams[handle_node->bucket]);

    // Only add to packet_maps for sink streams
    if (!info->is_source) {
        map->source_ip = info->source_ip;
        map->dest_ip = info->dest_ip;
        map->source_port = info->source_port;
        map->stream_handle = info->stream_handle;
        if (fusion_cn_rtp_is_ip_mcast(map->dest_ip)) {
            hlist_add_head(&map->hnode, &rtp_mgr->mc_packet_maps[PACKET_MAP_KEY_MC(map->dest_ip)]);
        } else {
            printk(KERN_INFO "Adding stream %llu with sip %u sport %u", map->stream_handle, map->source_ip, map->source_port);
            hlist_add_head(&map->hnode, &rtp_mgr->uc_packet_maps[PACKET_MAP_KEY_UC(map->source_ip, map->source_port)]);
        }
        if (info->is_fusion_connect) {
            list_add_tail(&handle_node->node, &rtp_mgr->active_stream_handles.fn_sink);
        } else {
            list_add_tail(&handle_node->node, &rtp_mgr->active_stream_handles.aes67_sink);
        }
    } else {
        if (info->is_fusion_connect) {
            list_add_tail(&handle_node->node, &rtp_mgr->active_stream_handles.fn_source);
        } else {
            list_add_tail(&handle_node->node, &rtp_mgr->active_stream_handles.aes67_source);
        }
    }

    write_unlock_irqrestore(&rtp_mgr->lock, flags);

    *handle = stream->info.stream_handle;
    return 0;
}

int fusion_cn_rtp_clear_active_stream_handle(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle) 
{
    struct handle_node *handle_node, *tmp;

    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.fn_sink, node) {
        if (handle_node->handle == handle) {
            list_del(&handle_node->node);
            kfree(handle_node);
            return 0;
        }
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.fn_source, node) {
        if (handle_node->handle == handle) {
            list_del(&handle_node->node);
            kfree(handle_node);
            return 0;
        }
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.aes67_sink, node) {
        if (handle_node->handle == handle) {
            list_del(&handle_node->node);
            kfree(handle_node);
            return 0;
        }
    }
    list_for_each_entry_safe(handle_node, tmp, &rtp_mgr->active_stream_handles.aes67_source, node) {
        if (handle_node->handle == handle) {
            list_del(&handle_node->node);
            kfree(handle_node);
            return 0;
        }
    }

    return -1;
}

int fusion_cn_rtp_remove_stream(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle)
{
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    struct hlist_node *map_tmp;
    bool err;

    if ((err = fusion_cn_rtp_clear_active_stream_handle(rtp_mgr, handle)) == 0) {
        hlist_for_each_entry(stream, &rtp_mgr->streams[hash_64(handle, FUSION_CN_RTP_HASH_BITS)], hnode) {
            if (stream->info.stream_handle == handle) {
                hlist_del(&stream->hnode);
                // Only remove from packet_maps for sink streams
                if (!stream->info.is_source) {
                    if (fusion_cn_rtp_is_ip_mcast(stream->info.dest_ip)) {
                        hlist_for_each_entry_safe(map, map_tmp, &rtp_mgr->mc_packet_maps[PACKET_MAP_KEY_MC(stream->info.dest_ip)], hnode) {
                            if (map->stream_handle == handle) {
                                hlist_del(&map->hnode);
                                kfree(map);
                                break;
                            }
                        }
                    } else {
                        hlist_for_each_entry_safe(map, map_tmp, &rtp_mgr->uc_packet_maps[PACKET_MAP_KEY_UC(stream->info.source_ip, stream->info.source_port)], hnode) {
                            if (map->stream_handle == handle) {
                                hlist_del(&map->hnode);
                                kfree(map);
                                break;
                            }
                        }
                    }
                }
                kref_put(&stream->ref, fusion_cn_rtp_stream_release);
                break;
            }
        }
    }

    return err ? -ENOENT : 0;
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

int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr,
                                struct fusion_cn_rtp_packet *packet)
{
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    uint32_t payload_len, len1, len2, frames;

    uint8_t *payload;
    void *buf;
    unsigned long flags;
    uint32_t packet_ssrc;
    uint64_t handle = 0;
    uint16_t seq_num;
    uint32_t write_slot;
    uint32_t buf_offset, frames_in_buf;
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
                printk(KERN_INFO "fusion_cn_rtp: process_packet: Stashed SSRC 0x%08x for stream %llu\n",
                       stream->ssrc, stream->info.stream_handle);
            }

            payload_len = swab16(packet->udp.len) - sizeof(struct udphdr) - sizeof(struct fusion_cn_rtp_header);
            payload = (uint8_t *)packet + sizeof(*packet);
            frames = payload_len / (stream->info.channels * sample_physical_width_bits / 8);
            if (!frames) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Zero length frame detected !");
                spin_unlock(&stream->lock);
                continue;
            }

            seq_num = swab16(packet->rtp.seq_num);
            frames_in_buf = rtp_mgr->ops->get_buffer_size_in_frames(rtp_mgr->cn_mgr, stream->info.stream_name);
            write_slot = seq_num % (frames_in_buf / stream->info.frames_per_packet);
            buf_offset = write_slot * stream->info.frames_per_packet;

            if (stream->playback_index == (frames_in_buf / stream->info.frames_per_packet)) {
                stream->playback_index = write_slot;
                if (rtp_mgr->ops->set_buffer_pos(rtp_mgr->cn_mgr, write_slot, stream->info.stream_name)) {
                    printk(KERN_WARNING "fusion_cn_rtp: process_packet: set_buffer_pos failed!");
                }
            }

            if (stream->current_seq_num != 0 && seq_num != stream->current_seq_num + 1) {
                for (int i = stream->current_seq_num + 1; i < seq_num; i++) {
                    uint32_t gap_slot = i % (frames_in_buf / stream->info.frames_per_packet);
                    uint32_t gap_offset = gap_slot * stream->info.frames_per_packet;
                    void *gap_buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->info.stream_name);
                    if (gap_buf) {
                        printk(KERN_WARNING "fusion_cn_rtp: process_packet: Gap detected in stream %llu, seq_num=%u, gap_slot=%u\n",
                               stream->info.stream_handle, i, gap_slot);
                        memset(gap_buf + gap_offset * stream->info.channels * sample_physical_width_bits / 8,
                               0, stream->info.frames_per_packet * stream->info.channels * sample_physical_width_bits / 8);
                        stream->next_action_times[gap_slot] = 0;
                    }
                }
            }

            buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->info.stream_name);
            if (!buf) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Invalid Buffer !");
                spin_unlock(&stream->lock);
                read_unlock_irqrestore(&rtp_mgr->lock, flags);
                return NF_DROP;
            }

            len1 = min(frames_in_buf - buf_offset, frames);
            len2 = frames - len1;

            if (len1) {
                memcpy(buf + buf_offset * stream->info.channels * sample_physical_width_bits / 8, 
                       payload, len1 * stream->info.channels * sample_physical_width_bits / 8);
            }
            if (len2) { // TODO unsure of why this copies to the beginning of the buffer
                memcpy(buf, payload + len1 * stream->info.channels * sample_physical_width_bits / 8,
                       len2 * stream->info.channels * sample_physical_width_bits / 8);
            }

            rtp_timestamp = swab32(packet->rtp.timestamp);
            current_phc_ns = rtp_mgr->ops->get_phc_ns();
            current_sac = current_phc_ns / stream->ns_per_sample;

            global_sac = ((current_sac & 0xFFFFFFFF00000000ULL) | rtp_timestamp) - stream->info.timestamp_offset;
            
            if (rtp_timestamp < 0x3FFFFFFFU && (uint32_t)current_sac >= 0xC0000000U) {
                global_sac += (1ULL << 32);
            } else if ((uint32_t)current_sac < 0x3FFFFFFFU && rtp_timestamp >= 0xC0000000U) {
                global_sac -= (1ULL << 32);
            }
            
            // Avoid overflow in reconstructed_phc_ns calculation
            reconstructed_phc_ns = global_sac * stream->ns_per_sample;
            ns_from_ms_boundary = reconstructed_phc_ns % NSEC_PER_MSEC;
            reconstructed_phc_ns -= ns_from_ms_boundary;

            if (ns_from_ms_boundary <= TIMER_BASE_INTERVAL_NS) {
                reconstructed_phc_ns += TIMER_BASE_INTERVAL_NS;
            } else if (ns_from_ms_boundary <= 2 * TIMER_BASE_INTERVAL_NS) {
                reconstructed_phc_ns += 2 * TIMER_BASE_INTERVAL_NS;
            } else  {
                reconstructed_phc_ns += NSEC_PER_MSEC;
            }

            stream->next_action_times[write_slot] = reconstructed_phc_ns + stream->info.playout_delay;
            stream->current_seq_num = seq_num;

            if (rtp_mgr->debug) printk(KERN_DEBUG "fusion_cn_rtp: process_packet: Stream %llu, slot=%u, current_phc_ns=%llu, reconstructed_phc=%llu, next_action_time=%llu\n",
                stream->info.stream_handle, write_slot, current_phc_ns, reconstructed_phc_ns, stream->next_action_times[write_slot]);

            spin_unlock(&stream->lock);
            read_unlock_irqrestore(&rtp_mgr->lock, flags);
            return NF_DROP;
        }
    }

    read_unlock_irqrestore(&rtp_mgr->lock, flags);
    return NF_ACCEPT;
}


__always_inline void fusion_cn_rtp_send_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_stream *stream)
{
    struct sk_buff *skb = NULL;
    void *packet;
    uint32_t size;
    struct fusion_cn_rtp_packet *rtp;
    uint32_t offset;
    int ret;
    int sample_physical_width_bits;
    uint64_t global_sac;

    if (!stream->info.is_source) return;

    sample_physical_width_bits = snd_pcm_format_physical_width(stream->info.format);
    if (sample_physical_width_bits <= 0) {
        printk(KERN_ERR "fusion_cn_rtp: Invalid sample format %d\n", stream->info.format);
        return;
    }

    size = sizeof(struct fusion_cn_rtp_packet) +
           stream->info.frames_per_packet * stream->info.channels * sample_physical_width_bits / 8;

    offset = rtp_mgr->ops->get_buffer_offset(rtp_mgr->cn_mgr, stream->info.stream_name);

    if (!fusion_cn_nf_create_packet(rtp_mgr->nf, &skb, &packet, &size) && size >= sizeof(struct fusion_cn_rtp_packet)) {
        rtp = packet;
        memcpy(rtp, &stream->rtp_packet_base, sizeof(*rtp));
        rtp->ip.daddr = stream->info.dest_ip;
        if (fusion_cn_rtp_is_ip_mcast(stream->info.dest_ip)) {
            fusion_cn_rtp_set_multicast_mac(stream->info.dest_ip, rtp->eth.h_dest);
        }
        rtp->ip.tot_len = swab16(size - ETH_HLEN);
        rtp->ip.tos = 0xB8;
        rtp->ip.ttl = 64;
        rtp->ip.check = swab16(fusion_cn_rtp_compute_cksum(&rtp->ip, sizeof(rtp->ip)));
        rtp->udp.len = swab16(size - ETH_HLEN - sizeof(rtp->ip));
        rtp->udp.check = 0; /* No checksum */

        // Set the network header to point to the IP header (after Ethernet header)
        skb_set_network_header(skb, ETH_HLEN);
        skb->protocol = htons(ETH_P_IP);

        // Calculate RTP timestamp using absolute next_action_time (in sample units)
        global_sac = stream->next_action_time / stream->ns_per_sample;
        rtp->rtp.timestamp = swab32((uint32_t)(global_sac + stream->info.timestamp_offset));
        rtp->rtp.seq_num = swab16(stream->outgoing_seq_num++);

        if (rtp_mgr->debug) printk(KERN_DEBUG "fusion_cn_rtp: send_packet: Sending packet, stream %llu, next_action_time=%llu\n",
               stream->info.stream_handle, stream->next_action_time);

        {
            uint8_t *payload = (uint8_t *)packet + sizeof(*rtp);
            void *buf = rtp_mgr->ops->get_buffer(rtp_mgr->cn_mgr, stream->info.stream_name);

            memcpy(payload, buf + offset * stream->info.channels * sample_physical_width_bits / 8,
                    stream->info.frames_per_packet * stream->info.channels * sample_physical_width_bits / 8);
        }

        ret = fusion_cn_nf_tx_packet(rtp_mgr, skb, size);
        if (ret < 0) printk(KERN_DEBUG "fusion_cn_rtp: TX failed: %d\n", ret);
    } else {
        printk(KERN_ERR "fusion_cn_rtp: Failed to create packet; size %u/%lu\n", size, sizeof(struct fusion_cn_rtp_packet));
    }
}

int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, uint64_t handle, bool running)
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
        uint32_t frames_in_buf = rtp_mgr->ops->get_buffer_size_in_frames(rtp_mgr->cn_mgr, stream->info.stream_name);
        // for sinks only. allocate this before we set the stream running
        // but it needs to happen after alsa device is opened and has set the buffer frames
        if (!stream->info.is_source) {
            if (stream->next_action_times) {
                kfree(stream->next_action_times);
            } 
            
            stream->next_action_times = kzalloc(sizeof(uint64_t) * (frames_in_buf / stream->info.frames_per_packet), GFP_KERNEL);
            memset(stream->next_action_times, 0, sizeof(uint64_t) * (frames_in_buf / stream->info.frames_per_packet));
            printk(KERN_INFO "fusion_cn_rtp: alloc %u slots in next_action_times", frames_in_buf / stream->info.frames_per_packet);
        }
        stream->playback_index = (frames_in_buf / stream->info.frames_per_packet); // set to a invalid value i can check for on first process_packet
        stream->next_action_time = 0;
        stream->current_seq_num = 0;
    }

    atomic_set(&stream->is_running, running);

    kref_put(&stream->ref, fusion_cn_rtp_stream_release);

    printk(KERN_INFO "fusion_cn_rtp: set_rtp_stream_running: Stream %llu is_running=%d\n", handle, running);
    return 0;
}

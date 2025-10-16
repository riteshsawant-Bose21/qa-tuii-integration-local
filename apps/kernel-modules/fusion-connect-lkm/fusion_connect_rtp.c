#include <linux/slab.h>
#include <linux/random.h>
#include <linux/types.h>
#include <sound/pcm.h>
#include <linux/delay.h>
#include <linux/byteorder/generic.h>
#include <net/route.h>
#include <net/ip.h>
#include <linux/inetdevice.h>
#include <net/neighbour.h>
#include <net/arp.h>
#include <linux/etherdevice.h>
#include "fusion_connect_rtp.h"
#include "fusion_connect_metrics.h"

#define TIMER_BASE_INTERVAL_NS 333333

#define HASH_KEY(handle) hash_64(handle, FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_UC(ip, port) hash_64(((u64)(ip) << 16) | (port), FUSION_CN_RTP_HASH_BITS)
#define PACKET_MAP_KEY_MC(ip) hash_64((u64)(ip), FUSION_CN_RTP_HASH_BITS)

static u16 fusion_cn_rtp_compute_cksum(const void *data, u16 len)
{
    u32 acc = 0;
    const u8 *ptr = data;

    while (len > 1) {
        acc += (u16)(*ptr << 8) | *(ptr + 1);
        ptr += 2;
        len -= 2;
    }
    if (len) acc += (u16)(*ptr << 8);
    acc = (acc >> 16) + (acc & 0xFFFF);
    if (acc & 0xFFFF0000) acc = (acc >> 16) + (acc & 0xFFFF);
    return ~(u16)acc;
}

void fusion_cn_rtp_stream_release(struct kref *ref)
{
    struct fusion_cn_rtp_stream *stream = container_of(ref, struct fusion_cn_rtp_stream, ref);
    if (stream->next_action_times) {
        kfree(stream->next_action_times);
    }
    printk(KERN_DEBUG "fusion_cn_rtp: stream_release: release stream %s\n", stream->info.stream_name);
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

static bool fusion_cn_rtp_is_ip_mcast(u32 ip)
{
    u32 ip_host = be32_to_cpu(ip);
    return (ip_host >= 0xE0000000 && ip_host <= 0xEFFFFFFF); /* 224.0.0.0 - 239.255.255.255 */
}

static void fusion_cn_rtp_set_multicast_mac(u32 ip, u8 mac[ETH_ALEN])
{
    u32 ip_host = be32_to_cpu(ip);
    mac[0] = 0x01;
    mac[1] = 0x00;
    mac[2] = 0x5E;
    mac[3] = (ip_host >> 16) & 0x7F; /* Lower 23 bits of IP */
    mac[4] = (ip_host >> 8) & 0xFF;
    mac[5] = ip_host & 0xFF;
}

static int fusion_cn_rtp_resolve_unicast_mac(struct fusion_cn_rtp_manager *rtp_mgr,
                                       __be32 daddr_be, u8 mac[ETH_ALEN])
{
    struct net *netns = &init_net;
    struct rtable *rt;
    struct neighbour *n = NULL;
    int err = -EAGAIN;

    struct flowi4 fl4 = {
        .saddr       = htonl(INADDR_ANY),
        .daddr       = daddr_be,
        .flowi4_oif  = 0,   /* set to ifindex if you want to force iface */
        .flowi4_mark = 0,
        .flowi4_tos  = 0,
    };

    rt = ip_route_output_key(netns, &fl4);
    if (IS_ERR(rt)) {
        pr_err("fusion_cn_rtp: route %pI4 failed (%ld)\n",
               &daddr_be, PTR_ERR(rt));
        return PTR_ERR(rt);
    }

    /*
     * dst_neigh_lookup() knows the proper neigh key for this dst (gateway vs on-link),
     * so we don’t need to read any rt_gateway/rt_gw4 private fields (which vary by kernel).
     */
    n = dst_neigh_lookup(&rt->dst, &daddr_be);
    if (!n) {
        /* Create an ARP neighbour on this dev for daddr; ARP machinery will steer to gw if needed */
        n = neigh_lookup(&arp_tbl, &daddr_be, rt->dst.dev);
        if (!n) {
            n = neigh_create(&arp_tbl, &daddr_be, rt->dst.dev);
            if (IS_ERR(n)) {
                pr_err("fusion_cn_rtp: neigh_create failed (%ld)\n", PTR_ERR(n));
                ip_rt_put(rt);
                return PTR_ERR(n);
            }
        }
    }

    if (READ_ONCE(n->nud_state) & NUD_VALID) {
        ether_addr_copy(mac, n->ha);
        err = 0;
    } else {
        neigh_event_send(n, NULL);  /* trigger resolution asynchronously */
        err = -EAGAIN;
    }

    neigh_release(n);
    ip_rt_put(rt);
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
    u32 payload_bytes;
    u32 pkt_bytes;

    *rtp_stream = NULL;

    /* Verify interface exists and grab its MAC for eth.h_source */
    dev = dev_get_by_name(&init_net, rtp_mgr->nf->iface_name);
    if (!dev) {
        printk(KERN_ERR "fusion_cn_rtp: add_stream: Interface %s not found\n",
               rtp_mgr->nf->iface_name);
        return -ENODEV;
    }

    printk(KERN_DEBUG
           "fusion_cn_rtp: add_stream %s: sample_rate=%u, channels=%u, "
           "dest_ip=0x%08x, source_ip=0x%08x, dest_port=%u, source_port=%u, "
           "is_source=%d, is_fusion_connect=%d\n",
           info->stream_name, info->sample_rate, info->channels,
           info->dest_ip, info->source_ip, info->dest_port, info->source_port,
           info->is_source, info->is_fusion_connect);

    if (!info->stream_handle || !info->sample_rate || !info->channels ||
        !info->dest_ip || !info->dest_port || !info->source_port) {
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
        if (!info->source_ip) {
            printk(KERN_ERR "fusion_cn_rtp: add_stream: missing source_ip for source stream\n");
            return -EINVAL;
        }
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

    write_lock_irqsave(&rtp_mgr->lock, flags);
    hlist_add_head(&stream->hnode,
        &rtp_mgr->streams[HASH_KEY(info->stream_handle)]);

    stream->rtp_phc_offset_valid = false;

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
            if (!info->source_ip) {
                printk(KERN_ERR "fusion_cn_rtp: add_stream: missing source_ip for unicast stream--required for 1-to-1 mapping\n");
                write_unlock_irqrestore(&rtp_mgr->lock, flags);
                return -EINVAL;
            }
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

    // TODO: Cleanup profiling and stats gathering

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

struct fusion_cn_rtp_stream *fusion_cn_rtp_get_stream(struct fusion_cn_rtp_manager *rtp_mgr, u64 handle)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket;

    if (!rtp_mgr || !rtp_mgr->cn_mgr) {
        printk(KERN_ERR "fusion_cn_rtp: get_stream: Null or uninitialized rtp_mgr for handle %llu\n", handle);
        return NULL;
    }

    bucket = HASH_KEY(handle);
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

static inline void fc_rx_metrics_note(struct fusion_cn_rtp_stream *rtp,
                                      u32 rtp_ts, u16 payload_len, 
                                      u16 flags, u64 arrival_phc_ns)
{
    fusion_cn_metrics_rx_stash(rtp->metrics,
                                rtp->current_seq_num, rtp_ts, arrival_phc_ns,
                                payload_len, flags);
}

__always_inline int fusion_cn_rtp_process_packet(struct fusion_cn_rtp_manager *rtp_mgr, struct fusion_cn_rtp_packet *packet)
{
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_packet_map *map;
    u32 payload_len, len1, len2, frames_in_payload;
    u8 *payload;
    void *buf;
    unsigned long flags;
    u32 packet_ssrc;
    u64 handle = 0;
    u16 seq_num;
    u32 write_slot;
    u32 buf_offset;
    u64 current_phc_ns, current_sac, global_sac, ns_from_ms_boundary, reconstructed_phc_ns;
    u32 rtp_timestamp;
    int sample_physical_width_bits;

    u64 sched_ns, thresh;
    s64 delta;
    bool marker, malformed, duplicate, reorder = false, late, early;
    u16 metrics_flags = 0;

    if (!packet) {
        printk(KERN_ERR "fusion_cn_rtp: process_packet: Invalid packet pointer\n");
        return NF_ACCEPT;
    }

    // TODO: start profiling
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

    hlist_for_each_entry(stream, &rtp_mgr->streams[HASH_KEY(handle)], hnode) {
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
                printk(KERN_DEBUG "fusion_cn_rtp: process_packet: Stashed SSRC 0x%08x for stream %s\n",
                       stream->ssrc, stream->info.stream_name);
            }

            payload_len = swab16(packet->udp.len) - sizeof(struct udphdr) - sizeof(struct fusion_cn_rtp_header);
            payload = (u8 *)packet + sizeof(*packet);

            frames_in_payload = payload_len / (stream->info.channels * sample_physical_width_bits / 8);
            malformed = frames_in_payload != stream->info.frames_per_packet;
            marker = !!(packet->rtp.payload_type & 0x80);

            seq_num = swab16(packet->rtp.seq_num);
            duplicate = (stream->current_seq_num && seq_num == stream->current_seq_num);
            write_slot = seq_num % stream->buf_size_in_packets;
            buf_offset = write_slot * stream->info.frames_per_packet;

            if (stream->playback_index >= stream->buf_size_in_packets) {
                stream->playback_index = write_slot;
            }

            buf = rtp_mgr->ops->get_buffer(map->alsa_stream);
            if (!buf) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Invalid Buffer!\n");
                spin_unlock(&stream->lock);
                read_unlock_irqrestore(&rtp_mgr->lock, flags);
                return NF_DROP;
            }

            len1 = min(stream->buf_size_in_frames - buf_offset, frames_in_payload);
            len2 = frames_in_payload - len1;

            if (len1) {
                memcpy(buf + buf_offset * stream->info.channels * sample_physical_width_bits / 8, 
                    payload, len1 * stream->info.channels * sample_physical_width_bits / 8);
            }
            if (len2) {
                memcpy(buf, payload + len1 * stream->info.channels * sample_physical_width_bits / 8,
                    len2 * stream->info.channels * sample_physical_width_bits / 8);
            }

            rtp_timestamp = swab32(packet->rtp.timestamp);
            current_phc_ns = rtp_mgr->ops->get_phc_ns();
            // TODO: review for 96k
            // sac = (phc * sample_rate) / NSEC_PER_SEC 
            current_sac = (((current_phc_ns >> (stream->info.sample_rate == 48000 ? 2 : 1)) * 3) / 15625);

            global_sac = ((current_sac & 0xFFFFFFFF00000000ULL) | rtp_timestamp) - stream->info.timestamp_offset;
            
            if (rtp_timestamp < 0x3FFFFFFFU && (u32)current_sac >= 0xC0000000U) {
                global_sac += (1ULL << 32);
            } else if ((u32)current_sac < 0x3FFFFFFFU && rtp_timestamp >= 0xC0000000U) {
                global_sac -= (1ULL << 32);
            }
            
            // Avoid overflow in reconstructed_phc_ns calculation
            // TODO: review for 96k
            // phc = (sac * NSEC_PER_SEC) / sample_rate
            reconstructed_phc_ns = (global_sac * 62500) / (stream->info.sample_rate == 48000 ? 3 : 6);

            

            // for fusion-connect streams only, reconstruct exact phc time from rtp timestamp
            if (stream->info.is_fusion_connect) {
                ns_from_ms_boundary = reconstructed_phc_ns % NSEC_PER_MSEC;
                reconstructed_phc_ns -= ns_from_ms_boundary;

                if (ns_from_ms_boundary <= TIMER_BASE_INTERVAL_NS) {
                    reconstructed_phc_ns += TIMER_BASE_INTERVAL_NS;
                } else if (ns_from_ms_boundary <= 2 * TIMER_BASE_INTERVAL_NS) {
                    reconstructed_phc_ns += 2 * TIMER_BASE_INTERVAL_NS;
                } else {
                    reconstructed_phc_ns += NSEC_PER_MSEC;
                }
            // for aes67 streams only, stash a bias offset to compensate for phase/network
            } else {
                if (!stream->rtp_phc_offset_valid) {
                    stream->rtp_phc_offset_ns = current_phc_ns - reconstructed_phc_ns;
                    stream->rtp_phc_offset_valid = true;

                    printk(KERN_DEBUG "fusion_cn_rtp: process_packet: RTP timestamp anchor = %lld\n", stream->rtp_phc_offset_ns);
                }

                reconstructed_phc_ns += stream->rtp_phc_offset_ns;
            }

            sched_ns = reconstructed_phc_ns + stream->info.playout_delay;
            delta = (s64)current_phc_ns - (s64)sched_ns;   /* >0 means we’re past the target (late) */
            thresh = stream->packet_time / 4;              /* threshold to avoid noise; tune as needed */

            late  = (delta > (s64)thresh);
            early = (delta < -(s64)thresh);

            if (stream->current_seq_num != 0 && seq_num > stream->current_seq_num && seq_num != stream->current_seq_num + 1) {
                for (int i = stream->current_seq_num + 1; i < seq_num; i++) {
                    u32 gap_slot = i % stream->buf_size_in_packets;
                    u32 gap_offset = gap_slot * stream->info.frames_per_packet;
                    printk(KERN_WARNING "fusion_cn_rtp: process_packet: Gap detected in stream %s, seq_num=%u, gap_slot=%u\n",
                            stream->info.stream_name, i, gap_slot);

                    memset(buf + gap_offset * stream->info.channels * sample_physical_width_bits / 8,
                            0, stream->info.frames_per_packet * stream->info.channels * sample_physical_width_bits / 8);
                    stream->next_action_times[gap_slot] = (reconstructed_phc_ns - ((seq_num - i) * stream->packet_time)) + stream->info.playout_delay;
                }
            } else if (seq_num < stream->current_seq_num && stream->current_seq_num != 65535) {
                printk(KERN_WARNING "fusion_cn_rtp: process_packet: Got older packet for stream %s, seq_num=%u\n",
                            stream->info.stream_name, seq_num);
                reorder = true;
            }

            stream->next_action_times[write_slot] = reconstructed_phc_ns + stream->info.playout_delay;
            stream->current_seq_num = seq_num;

            // end profile

            if (rtp_mgr->debug) printk(KERN_DEBUG "fusion_cn_rtp: process_packet: Stream %s, slot=%u, seq_num=%u, current_phc_ns=%llu, reconstructed_phc=%llu, next_action_time=%llu\n",
                stream->info.stream_name, write_slot, seq_num, current_phc_ns, reconstructed_phc_ns, stream->next_action_times[write_slot]);

            if (marker)        metrics_flags |= FUSION_CN_PKTF_MARKER;
            if (malformed)     metrics_flags |= FUSION_CN_PKTF_MALFORMED;
            if (duplicate)     metrics_flags |= FUSION_CN_PKTF_DUP;
            if (reorder)       metrics_flags |= FUSION_CN_PKTF_REORDERHINT;
            if (late)          metrics_flags |= FUSION_CN_PKTF_LATE;
            if (early)         metrics_flags |= FUSION_CN_PKTF_EARLY;

            fc_rx_metrics_note(stream, rtp_timestamp, payload_len, metrics_flags, current_phc_ns);

            spin_unlock(&stream->lock);
            read_unlock_irqrestore(&rtp_mgr->lock, flags);
            return NF_DROP;
        }
    }

    read_unlock_irqrestore(&rtp_mgr->lock, flags);
    return NF_ACCEPT;
}

static inline void fc_tx_metrics_note(struct fusion_cn_rtp_manager *rtp_mgr,
                                      struct fusion_cn_rtp_stream *rtp,
                                      u16 payload_len, u64 scheduled_send_ns)
{
    u64 now_ns = rtp_mgr->ops->get_phc_ns();
    fusion_cn_metrics_tx_stash(rtp->metrics, now_ns, payload_len, scheduled_send_ns);
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

    /* ETH+IP+UDP+RTP template size you prebuilt into stream->rtp_packet_base */
    const u32 hdr_len      = sizeof(stream->rtp_packet_base);
    const u32 total_len    = hdr_len + payload_len;

    spin_lock(&stream->lock);

    /* ---------- Per-packet RTP fields ---------- */
    {
        /* sac = phc*Fs/1e9, using your integer trick */
        u64 sac = (((stream->next_action_time >>
                    (stream->info.sample_rate == 48000 ? 2 : 1)) * 3) / 15625);

        /* NOTE: make sure the RTP header’s first byte (vpxcc) is exactly 0x80 in your template */
        stream->rtp_packet_base.rtp.timestamp = htonl((u32)(sac + stream->info.timestamp_offset));
        stream->rtp_packet_base.rtp.seq_num   = htons(stream->outgoing_seq_num++);
    }

    /* ---------- Per-packet IP/UDP finalize ---------- */
    {
        struct iphdr  *iph = &stream->rtp_packet_base.ip;
        struct udphdr *udph = &stream->rtp_packet_base.udp;

        const u16 ip_tot_len = (u16)(total_len - ETH_HLEN);
        const u16 udp_len    = (u16)(total_len - ETH_HLEN - sizeof(struct iphdr)); /* = sizeof(udp)+RTP+payload */

        /* lengths (network order) */
        iph->tot_len = htons(ip_tot_len);
        udph->len    = htons(udp_len);

        /* recompute IPv4 header checksum from scratch */
        iph->check   = 0;
        iph->check   = ip_fast_csum((u8 *)iph, iph->ihl);

        /* disable UDP checksum for IPv4 (0 means “no checksum”) */
        udph->check  = 0;
    }

    /* ---------- fresh skb ---------- */
    skb = alloc_skb(total_len, GFP_ATOMIC);
    if (unlikely(!skb)) {
        printk(KERN_ERR "fusion_cn_rtp: alloc_skb(%u) failed for %s\n",
               total_len, stream->info.stream_name);
        spin_unlock(&stream->lock);
        return;
    }

    {
        u8 *base = skb_put(skb, total_len);
        if (unlikely(!base)) {
            kfree_skb(skb);
            spin_unlock(&stream->lock);
            return;
        }

        /* copy headers (ETH+IP+UDP+RTP) */
        memcpy(base, &stream->rtp_packet_base, hdr_len);

        /* copy payload */
        {
            const u32 off_frames = rtp_mgr->ops->get_buffer_offset(alsa_stream);
            const u8 *src = rtp_mgr->ops->get_buffer(alsa_stream)
                          + (u64)off_frames * ch * sample_bytes;
            memcpy(base + hdr_len, src, payload_len);
        }
    }

    /* annotate for the stack */
    skb_set_network_header(skb, ETH_HLEN);   /* keep network header at IP */
    skb_reset_mac_header(skb);               /* L2 starts at skb->data */
    skb->protocol   = htons(ETH_P_IP);
    skb->ip_summed  = CHECKSUM_NONE;         /* we provided full checksums */

    if (rtp_mgr->debug) {
        printk(KERN_DEBUG "fusion_cn_rtp: send_packet %s seq=%u len=%u\n",
               stream->info.stream_name, (u32)(ntohs(stream->rtp_packet_base.rtp.seq_num)),
               total_len);
    }

    spin_unlock(&stream->lock);

    fc_tx_metrics_note(rtp_mgr, stream, payload_len, stream->next_action_time);

    if (fusion_cn_nf_tx_packet(rtp_mgr, skb, total_len) < 0) {
        kfree_skb(skb);
    }
}

int fusion_cn_rtp_set_stream_running(struct fusion_cn_rtp_manager *rtp_mgr, u64 handle, bool running, void *alsa_stream)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket;
    bool found = false;

    if (!rtp_mgr || !rtp_mgr->cn_mgr) {
        printk(KERN_ERR "fusion_cn_rtp: set_rtp_stream_running: Null or uninitialized rtp_mgr for handle %llu\n", handle);
        return -EINVAL;
    }

    bucket = HASH_KEY(handle);
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
        stream->buf_size_in_frames = rtp_mgr->ops->get_buffer_size_in_frames(alsa_stream);
        stream->buf_size_in_packets = stream->buf_size_in_frames / stream->info.frames_per_packet;
        // for sinks only. allocate this before we set the stream running
        // but it needs to happen after alsa device is opened and has set the buffer frames
        if (!stream->info.is_source) {
            if (stream->next_action_times) {
                kfree(stream->next_action_times);
            } 
            
            stream->next_action_times = kcalloc(stream->buf_size_in_packets, sizeof(u64), GFP_KERNEL);
            if (!stream->next_action_times) {
                kref_put(&stream->ref, fusion_cn_rtp_stream_release);
                return -ENOMEM;
            }
            memset(stream->next_action_times, 0, sizeof(u64) * (stream->buf_size_in_packets));
            printk(KERN_DEBUG "fusion_cn_rtp: alloc %u slots in next_action_times", stream->buf_size_in_packets);
        }
        stream->playback_index = (stream->buf_size_in_packets); // set to a invalid value i can check for on first process_packet
        stream->next_action_time = 0;
        stream->current_seq_num = 0;
    }

    atomic_set(&stream->is_running, running);

    kref_put(&stream->ref, fusion_cn_rtp_stream_release);

    printk(KERN_DEBUG "fusion_cn_rtp: set_rtp_stream_running: Stream %s is_running=%d\n", stream->info.stream_name, running);
    return 0;
}

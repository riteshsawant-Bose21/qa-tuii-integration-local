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

#include <linux/skbuff.h>
#include <linux/netfilter_ipv4.h>
#include <linux/netdevice.h>
#include <linux/ip.h>
#include "fusion_connect_netfilter.h"
#include "fusion_connect_rtp.h"

static unsigned int nf_hook_func(void *priv, struct sk_buff *skb, const struct nf_hook_state *state)
{
    struct fusion_cn_rtp_manager *rtp_mgr = priv;
    struct iphdr *ip_header;
    uint8_t *rtp_header;
    struct fusion_cn_rtp_packet *packet;

    ip_header = ip_hdr(skb);
    if (!skb || !ip_header) {
        return NF_ACCEPT;
    }

    if (ip_header->ihl != 5) {
        return NF_ACCEPT;
    }

    // Filter by UDP protocol
    if (ip_header->protocol != IPPROTO_UDP) {
        return NF_ACCEPT;
    }

    if (skb_is_nonlinear(skb) && skb_linearize(skb) < 0) {
        return NF_ACCEPT;
    }

    if (skb->len + ETH_HLEN < sizeof(struct fusion_cn_rtp_packet)) {
        return NF_ACCEPT;
    }

    packet = (void *)skb_mac_header(skb);

    // Check RTP header: Version (first byte) should be 0x80 (Version 2)
    rtp_header = (uint8_t *)packet + ETH_HLEN + (ip_header->ihl * 4) + sizeof(struct udphdr);
    if (*rtp_header != 0x80) {
        return NF_ACCEPT;
    } else {
        if (ip_header->saddr == ip_header->daddr) {
            printk(KERN_INFO "fusion_cn: nf_hook_func: Loopback packet detected: src_ip=0x%08x, dst_ip=0x%08x\n",
                    ip_header->saddr, ip_header->daddr);
        }
    }

    return fusion_cn_rtp_process_packet(rtp_mgr, packet);
}

int fusion_cn_nf_init(void *rtp_mgr)
{
    struct fusion_cn_rtp_manager *rtp = rtp_mgr;
    struct fusion_cn_netfilter *nf = rtp->nf;
    struct net_device *dev;
    int err;

    dev = dev_get_by_name(&init_net, nf->iface_name);
    if (!dev) {
        printk(KERN_ERR"fusion_cn: Interface %s not found\n", nf->iface_name);
        return -ENODEV;
    }
    dev_put(dev);

    spin_lock_init(&nf->lock);

    nf->nf_hook_struct.hook = nf_hook_func;
    nf->nf_hook_struct.hooknum = NF_INET_PRE_ROUTING;
    nf->nf_hook_struct.pf = NFPROTO_IPV4;
    nf->nf_hook_struct.priority = NF_IP_PRI_FIRST;
    nf->nf_hook_struct.priv = rtp_mgr;

    err = nf_register_net_hook(&init_net, &nf->nf_hook_struct);
    if (err) {
        printk(KERN_ERR"fusion_cn: nf_register_net_hook failed: %d\n", err);
    }
    return err;
}

void fusion_cn_nf_destroy(struct fusion_cn_netfilter *nf)
{
    nf_unregister_net_hook(&init_net, &nf->nf_hook_struct);
}

int fusion_cn_nf_create_packet(struct fusion_cn_netfilter *nf, struct sk_buff **skb,
                            void **data, uint32_t *data_size)
{
    *skb = alloc_skb(*data_size, GFP_ATOMIC);
    if (!*skb) {
        printk(KERN_ERR"fusion_cn: alloc_skb failed\n");
        return -ENOMEM;
    }

    *data = skb_put(*skb, *data_size);
    if (!*data) {
        printk(KERN_ERR"fusion_cn: skb_put failed\n");
        kfree_skb(*skb);
        *skb = NULL;
        return -ENOMEM;
    }

    return 0;
}

int fusion_cn_nf_tx_packet(void *rtp_mgr, struct sk_buff *skb, uint32_t data_size)
{
    struct net_device *dev;
    int ret;
    struct fusion_cn_rtp_manager *mgr = rtp_mgr;
    struct fusion_cn_netfilter *nf = mgr->nf;
    struct iphdr *ip_header;
    struct udphdr *udp_header;
    struct fusion_cn_rtp_packet *packet;

    ip_header = ip_hdr(skb);
    if (!ip_header) {
        printk(KERN_ERR "fusion_cn: tx_packet: Invalid IP header\n");
        kfree_skb(skb);
        return -EINVAL;
    }

    if (mgr->internal_loopback) {
        // For loopback packets, process directly
        if (ip_header->daddr == ip_header->saddr) {
            // Ensure skb is linear
            if (skb_is_nonlinear(skb) && skb_linearize(skb) < 0) {
                printk(KERN_ERR "fusion_cn: tx_packet: Failed to linearize skb\n");
                kfree_skb(skb);
                return -ENOMEM;
            }

            // Access UDP header directly
            udp_header = (struct udphdr *)((char *)ip_header + (ip_header->ihl * 4));

            // Use the original packet pointer (starting at Ethernet header) for process_packet
            packet = (struct fusion_cn_rtp_packet *)skb->data;

            // Process directly
            ret = fusion_cn_rtp_process_packet(mgr, packet);
            kfree_skb(skb);  // Free the skb since we're done
            return ret == NF_DROP ? 0 : -1;
        }
    }

    // Non-loopback: Send via network
    dev = dev_get_by_name(&init_net, nf->iface_name);
    if (!dev) {
        printk(KERN_ERR "fusion_cn: tx_packet: Interface %s not found\n", nf->iface_name);
        kfree_skb(skb);
        return -ENODEV;
    }

    if (data_size == 0) {
        printk(KERN_ERR "fusion_cn: tx_packet: Empty data\n");
        dev_put(dev);
        kfree_skb(skb);
        return -EINVAL;
    }

    skb->pkt_type = PACKET_OUTGOING;
    skb->dev = dev;
    skb_reset_network_header(skb);
    skb_trim(skb, data_size);

    ret = dev_queue_xmit(skb);
    if (ret < 0) {
        printk(KERN_ERR "fusion_cn: dev_queue_xmit failed: %d\n", ret);
    }

    dev_put(dev);
    return ret;
}

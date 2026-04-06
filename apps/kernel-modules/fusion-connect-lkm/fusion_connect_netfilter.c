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
    u64 stream_handle;

    ip_header = ip_hdr(skb);
    if (!skb || !ip_header) {
        return NF_ACCEPT;
    }

    if (ip_header->ihl != 5) {
        return NF_ACCEPT;
    }

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

    rtp_header = (uint8_t *)packet + ETH_HLEN + (ip_header->ihl * 4) + sizeof(struct udphdr);
    if (!(*rtp_header & 0x80)) {
        return NF_ACCEPT;
    }

    if (!fusion_cn_rtp_lookup_packet_handle(rtp_mgr, packet, &stream_handle)) {
        return NF_ACCEPT;
    }

    if (!rtp_mgr->ops->get_timing_ready(rtp_mgr->cn_mgr)) {
        return NF_DROP;
    }

    if (fusion_cn_rtp_enqueue_packet(rtp_mgr, stream_handle, skb, skb->len + ETH_HLEN) < 0) {
        printk(KERN_DEBUG "fusion_cn: nf_hook: drop queued RX packet\n");
    }

    return NF_DROP;
}


int fusion_cn_nf_init(void *rtp_mgr)
{
    struct fusion_cn_rtp_manager *rtp = rtp_mgr;
    struct fusion_cn_netfilter *nf = rtp->nf;
    int err;

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
                               void **data, u32 *data_size)
{
    if (*skb && (*skb)->truesize >= *data_size) {
        *data = skb_put(*skb, *data_size);
        if (!*data) {
            printk(KERN_ERR "fusion_cn: skb_put failed\n");
            kfree_skb(*skb);
            *skb = NULL;
            return -ENOMEM;
        }
        return 0;
    }

    if (*skb) kfree_skb(*skb);
    *skb = alloc_skb(*data_size, GFP_ATOMIC);
    if (!*skb) {
        printk(KERN_ERR "fusion_cn: alloc_skb failed\n");
        return -ENOMEM;
    }

    *data = skb_put(*skb, *data_size);
    if (!*data) {
        printk(KERN_ERR "fusion_cn: skb_put failed\n");
        kfree_skb(*skb);
        *skb = NULL;
        return -ENOMEM;
    }

    return 0;
}

int fusion_cn_nf_tx_packet(void *rtp_mgr, struct sk_buff *skb, u32 data_size)
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
        return -EINVAL;
    }

    // internally loopback
    if (ip_header->daddr == ip_header->saddr) {
        u64 stream_handle;

        if (skb_is_nonlinear(skb) && skb_linearize(skb) < 0) {
            printk(KERN_ERR "fusion_cn: tx_packet: Failed to linearize skb\n");
            return -ENOMEM;
        }

        udp_header = (struct udphdr *)((char *)ip_header + (ip_header->ihl * 4));
        packet = (struct fusion_cn_rtp_packet *)skb->data;

        if (!fusion_cn_rtp_lookup_packet_handle(mgr, packet, &stream_handle))
            return -ENOENT;

        ret = fusion_cn_rtp_enqueue_packet(mgr, stream_handle, skb, skb->len);
        kfree_skb(skb);
        return ret < 0 ? ret : 0;
    }

    dev = dev_get_by_name(&init_net, nf->iface_name);
    if (!dev) {
        printk(KERN_ERR "fusion_cn: tx_packet: Interface %s not found\n", nf->iface_name);
        return -ENODEV;
    }

    if (data_size == 0) {
        printk(KERN_ERR "fusion_cn: tx_packet: Empty data\n");
        dev_put(dev);
        return -EINVAL;
    }

    skb->pkt_type = PACKET_OUTGOING;
    skb->dev = dev;
    skb_trim(skb, data_size);

    ret = dev_queue_xmit(skb);
    if (ret < 0) {
        printk(KERN_ERR "fusion_cn: dev_queue_xmit failed: %d\n", ret);
    }

    dev_put(dev);
    return 0;
}

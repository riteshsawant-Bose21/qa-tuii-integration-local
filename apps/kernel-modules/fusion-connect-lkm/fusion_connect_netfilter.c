#include <linux/skbuff.h>
#include <linux/netfilter_ipv4.h>
#include <linux/netdevice.h>
#include <linux/ip.h>
#include "fusion_connect_netfilter.h"
#include "fusion_connect_rtp.h"

static unsigned int nf_hook_func(void *priv, struct sk_buff *skb, const struct nf_hook_state *state)
{
    struct fusion_cn_rtp_manager *rtp_mgr = priv;
    struct iphdr *iph;
    struct udphdr *udph;
    u8 *rtph;
    u16 ip_tot_len;
    int iphl;

    if (!atomic_read(&rtp_mgr->nf->is_enabled))
        return NF_ACCEPT;

    if (!skb)
        return NF_ACCEPT;

    /* Ensure we can read a minimal IP header */
    if (!pskb_may_pull(skb, sizeof(struct iphdr)))
        return NF_ACCEPT;

    iph = ip_hdr(skb);
    if (!iph || iph->version != 4)
        return NF_ACCEPT;

    /* Only IPv4/UDP */
    if (iph->protocol != IPPROTO_UDP)
        return NF_ACCEPT;

    iphl = iph->ihl * 4;
    ip_tot_len = be16_to_cpu(iph->tot_len);
    if (ip_tot_len < iphl + sizeof(struct udphdr) + 12) /* need UDP + RTP hdr */
        return NF_ACCEPT;

    /* Make sure UDP header & a byte of RTP are available */
    if (!pskb_may_pull(skb, iphl + sizeof(struct udphdr) + 1))
        return NF_ACCEPT;

    /* Point transport header to UDP */
    skb_set_transport_header(skb, iphl);
    udph = udp_hdr(skb);
    if (!udph)
        return NF_ACCEPT;

    /* RTP header begins after UDP */
    rtph = (u8 *)udph + sizeof(struct udphdr);

    /* RTP v2 check (don’t assume Ethernet present; don’t add ETH_HLEN) */
    if ( (rtph[0] & 0xC0) != 0x80 )
        return NF_ACCEPT;

    /* Build a contiguous “packet” buffer with a synthetic Ethernet header */
    {
        const int copy_len = ip_tot_len;                /* IP header + UDP + RTP + payload */
        const int pkt_len  = ETH_HLEN + copy_len;       /* what process_packet expects */
        struct fusion_cn_rtp_packet *pkt;
        u8 *buf;

        buf = kmalloc(pkt_len, GFP_ATOMIC);
        if (!buf)
            return NF_ACCEPT;

        /* Fake Ethernet header: just EtherType IPv4; MACs unused by your parser */
        memset(buf, 0, ETH_HLEN - 2);
        buf[12] = 0x08; buf[13] = 0x00;                 /* ETH_P_IP */

        /* Copy IP..payload from the skb */
        if (skb_copy_bits(skb, skb_network_offset(skb), buf + ETH_HLEN, copy_len)) {
            kfree(buf);
            return NF_ACCEPT;
        }

        pkt = (struct fusion_cn_rtp_packet *)buf;

        /* Hand to your existing parser */
        fusion_cn_rtp_process_packet(rtp_mgr, pkt);

        kfree(buf);
        return NF_DROP; /* we consumed it */
    }
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
        kfree_skb(skb);
        return -EINVAL;
    }

    // internally loopback
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

#include "fusion_aes67_netfilter.h"
#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/version.h>
#include <linux/skbuff.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/netdevice.h>
#include <linux/inetdevice.h>
#include <linux/if.h>
#include <linux/irqflags.h>
#include <linux/inet.h>
#include <linux/delay.h>
#include <asm/div64.h>

int fusion_aes67_nf_rx_packet(struct fusion_aes67_netfilter *nf, void *packet, int packet_size, const char *ifname)
{
    unsigned long flags;
    struct fusion_aes67_manager *mgr = container_of(nf, struct fusion_aes67_manager, netfilter);
    TUDPPacketBase *pUDPPacketBase = (TUDPPacketBase*)packet;

    spin_lock_irqsave(&nf->lock, flags);
    if (!nf->is_enabled) {
        spin_unlock_irqrestore(&nf->lock, flags);
        return NF_ACCEPT;
    }
    spin_unlock_irqrestore(&nf->lock, flags);

    if (!packet || packet_size <= 0) {
        printk(KERN_INFO "rx_packet: null or invalid size\n");
        return NF_ACCEPT;
    }

    if (packet_size < sizeof(TUDPPacketBase) || pUDPPacketBase->EthernetHeader.usType != swab16(ETH_P_IP) ||
        pUDPPacketBase->IPV4Header.byProtocol != IPPROTO_UDP) {
        return NF_ACCEPT;
    }

    return process_UDP_packet(&mgr->rtp.rtp_streams_manager, pUDPPacketBase, packet_size);
}

static unsigned int nf_hook_func(void *priv, struct sk_buff *skb, const struct nf_hook_state *state)
{
    struct fusion_aes67_netfilter *nf = (struct fusion_aes67_netfilter *)priv;
    struct iphdr *ip_header = (struct iphdr *)skb_network_header(skb);

    if (!skb || !ip_header) {
        return NF_ACCEPT;
    }

    if (ip_header->saddr == htonl(INADDR_LOOPBACK)) {
        return NF_ACCEPT;
    }

    if (skb_is_nonlinear(skb)) {
        if (skb_linearize(skb) < 0) {
            printk(KERN_WARNING "skb_linearize failed\n");
            return NF_ACCEPT;
        }
    }

    switch (fusion_aes67_nf_rx_packet(nf, skb_mac_header(skb), skb->len + ETH_HLEN, state->in->name)) {
        case 0: return NF_DROP;
        case 1: return NF_ACCEPT;
        default: printk(KERN_ALERT "rx_packet unknown return\n"); return NF_ACCEPT;
    }
}

int fusion_aes67_nf_init(struct fusion_aes67_manager *mgr)
{
    int err;
    mgr->netfilter.is_enabled = false;
    spin_lock_init(&mgr->netfilter.lock);

    mgr->netfilter.nf_hook_struct.hook = nf_hook_func;
    mgr->netfilter.nf_hook_struct.hooknum = NF_INET_PRE_ROUTING;
    mgr->netfilter.nf_hook_struct.pf = NFPROTO_IPV4;
    mgr->netfilter.nf_hook_struct.priority = NF_IP_PRI_FIRST;
    mgr->netfilter.nf_hook_struct.priv = &mgr->netfilter;
    err = nf_register_net_hook(&init_net, &mgr->netfilter.nf_hook_struct);
    if (err) {
        printk(KERN_ERR "nf_register_net_hook failed: %d\n", err);
        return err;
    }
    return 0;
}

int fusion_aes67_nf_destroy(struct fusion_aes67_netfilter *nf)
{
    nf_unregister_net_hook(&init_net, &nf->nf_hook_struct);
    return 0;
}

int fusion_aes67_nf_start(struct fusion_aes67_netfilter *nf, const char *ifname)
{
    unsigned long flags;
    if (ifname) {
        strlcpy(nf->iface_name, ifname, sizeof(nf->iface_name));
    }
    spin_lock_irqsave(&nf->lock, flags);
    nf->is_enabled = true;
    spin_unlock_irqrestore(&nf->lock, flags);
    return 0;
}

int fusion_aes67_nf_stop(struct fusion_aes67_netfilter *nf)
{
    unsigned long flags;
    spin_lock_irqsave(&nf->lock, flags);
    nf->is_enabled = false;
    spin_unlock_irqrestore(&nf->lock, flags);
    return 0;
}

int fusion_aes67_nf_get_mac_addr(unsigned char *addr, const char *iface)
{
    struct net_device *dev = dev_get_by_name(&init_net, iface);
    if (!dev) return -ENODEV;
    memcpy(addr, dev->dev_addr, ETH_ALEN);
    dev_put(dev);
    return 0;
}

struct sk_buff *fusion_aes67_nf_get_new_skb(unsigned int data_size)
{
    struct sk_buff *skb = dev_alloc_skb(data_size, GFP_ATOMIC);
    if (!skb) {
        printk(KERN_ALERT "dev_alloc_skb failed\n");
    }
    return skb;
}

int fusion_aes67_nf_free_skb(struct sk_buff *skb)
{
    dev_kfree_skb(skb);
    return 0;
}

void *fusion_aes67_nf_get_skb_data(struct sk_buff *skb, unsigned int data_size)
{
    void *data = skb_put(skb, data_size);
    if (!data) {
        printk(KERN_ALERT "skb_put failed\n");
    }
    return data;
}

int fusion_aes67_nf_create_packet(struct fusion_aes67_netfilter *nf, struct sk_buff **skb, void **data, uint32_t *data_size)
{
    *skb = dev_alloc_skb(*data_size, GFP_ATOMIC);
    if (!*skb) {
        printk(KERN_ALERT "dev_alloc_skb failed\n");
        *data_size = 0;
        return 0;
    }

    *data = skb_put(*skb, *data_size);
    if (!*data) {
        printk(KERN_ALERT "skb_put failed\n");
        fusion_aes67_nf_free_skb(*skb);
        *skb = NULL;
        *data_size = 0;
        return 0;
    }

    return 1;
}

int fusion_aes67_nf_tx_packet(struct sk_buff *skb, unsigned int data_size, const char *iface)
{
    struct net_device *dev = dev_get_by_name(&init_net, iface);
    int ret;

    if (!dev) {
        printk(KERN_ERR "tx_packet: dev not found for %s\n", iface);
        fusion_aes67_nf_free_skb(skb);
        return -ENODEV;
    }

    if (data_size == 0) {
        dev_put(dev);
        fusion_aes67_nf_free_skb(skb);
        return -EINVAL;
    }

    skb->pkt_type = PACKET_OUTGOING;
    skb->dev = dev;
    skb_reset_network_header(skb);
    fusion_aes67_nf_skb_trim(skb, data_size);

    ret = dev_queue_xmit(skb);
    dev_put(dev);
    if (ret < 0) {
        printk(KERN_ALERT "dev_queue_xmit failed: %d\n", ret);
        fusion_aes67_nf_free_skb(skb);
    }
    return ret;
}

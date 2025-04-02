/*
 * Copyright (C) 2017 Merging Technologies
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

#include "fusion_aes67_netfilter.h"
#include "fusion_aes67_manager.h"
#include "MTAL_EthUtils.h"

#include <linux/spinlock.h>
#include <linux/slab.h>

#include <linux/version.h>

#include <linux/skbuff.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h> /*NF_IP_PRE_FIRST*/

#include <linux/netdevice.h>
#include <linux/inetdevice.h>
#include <linux/if.h>

#include <linux/irqflags.h>

#include <linux/inet.h> /*in_aton()*/

#include <linux/delay.h>

//#include <asm-generic/div64.h>
#include <asm/div64.h>


// We return NF_ACCEPT for packets we DO NOT process, and NF_DROP for packets we DO process
int fusion_aes67_nf_rx_packet(struct fusion_aes67_netfilter *nf, void *packet, int packet_size, const char *ifname)
{
    int ret = 0;
    unsigned long flags;
    struct fusion_aes67_manager *mgr = container_of(nf, struct fusion_aes67_manager, netfilter);
    TUDPPacketBase *pUDPPacketBase = (TUDPPacketBase*)pBuffer;

    spin_lock_irqsave(&nf->lock, flags);
    if (!nf->is_enabled) {
        ret = 1;
    }
    spin_unlock_irqrestore(&nf->lock, flags);

    if (ret == 1) {
        return NF_ACCEPT;
    }

    if (packet == NULL) {
        printk(KERN_INFO "rx_packet null\n");
        return NF_ACCEPT;
    }
    if (packet_size <= 0) {
        printk(KERN_INFO "rx_packet size <= 0\n");
        return NF_ACCEPT;
    }

    if(packet_size < sizeof(TUDPPacketBase) || pUDPPacketBase->EthernetHeader.usType != MTAL_SWAP16(MTAL_ETH_PROTO_IPV4) || pUDPPacketBase->IPV4Header.byProtocol != IP_PROTO_UDP)
    { // cannot be for us
        if(pUDPPacketBase->EthernetHeader.usType == MTAL_SWAP16(MTAL_ETH_MAC_CONTROL) && packet_size >= sizeof(TMACControlFrame))
        {
            TMACControlFrame *pMACControlFrame = (TMACControlFrame*)pBuffer;
            printk(KERN_DEBUG "receive a MAC CONTROL: could be a PAUSE packet which could mean there is a too slow device (10/100Mb) on the network\n");
            dump_mac_ctrl_frame(pMACControlFrame);
        }
        return NF_ACCEPT;
    }

    // OK, it's an UDP packet

    //dump_ipv4_header(&pUDPPacketBase->IPV4Header);
    //dump_udp_header(&pUDPPacketBase->UDPHeader);
    //printk(KERN_DEBUG "packet_size %u\n", packet_size);

    return process_UDP_packet(&mgr->m_RTP_streams_manager, pUDPPacketBase, packet_size);
}

unsigned int nf_hook_func(void *priv, struct sk_buff *skb, const struct nf_hook_state *state)
{
    int err = 0;
    struct iphdr *ip_header = NULL;
    struct fusion_aes67_netfilter *nf = (struct fusion_aes67_netfilter *)priv;

    if (!skb) {
        printk(KERN_ALERT "sock buffer null\n");
        return NF_ACCEPT;
    }

    printk(KERN_INFO "nf_hook_func: first message received\n");

    ip_header = (struct iphdr *)skb_network_header(skb); // Grab network header using accessor
    if (!ip_header) {
        printk(KERN_ALERT "sock header null\n");
        return NF_ACCEPT;
    }

    if (ip_header->saddr == htonl(INADDR_LOOPBACK)) { // 127.0.0.1
        return NF_ACCEPT;
    }

    if (skb_is_nonlinear(skb)) {
        err = skb_linearize(skb);
        if (err < 0) {
            printk(KERN_WARNING "skb_linearize error %d\n", err);
            return NF_ACCEPT;
        }
    }

    // Call your packet processing function
    switch(fusion_aes67_nf_rx_packet(nf, skb_mac_header(skb), skb->len + ETH_HLEN, state->in->name)) {
        case 0:
            return NF_DROP;
        case 1:
            return NF_ACCEPT;
        default:
            printk(KERN_ALERT "nf_rx_packet unknown return code\n");
    }

    return NF_ACCEPT;
}

int fusion_aes67_nf_init(struct fusion_aes67_manager *mgr)
{
    int err;

    mgr->netfilter.is_enabled = false;

    spin_lock_init(&mgr->netfilter.lock);

    strcpy(mgr->netfilter.ifname_used, "eth0"); // ?

    mgr->netfilter.nf_hook_struct.user = (void *)&mgr->netfilter;
    mgr->netfilter.nf_hook_struct.hook = nf_hook_func;                 //function to call when conditions below met
    mgr->netfilter.nf_hook_struct.hooknum = NF_INET_PRE_ROUTING;    //called right after packet recieved, first hook in Netfilter
    mgr->netfilter.nf_hook_struct.pf = NFPROTO_IPV4;                //IPV4 packets
    mgr->netfilter.nf_hook_struct.priority = NF_IP_PRI_FIRST;       //set to highest priority over all other hook functions
    err = nf_register_net_hook(&init_net, &mgr->netfilter.nf_hook_struct); //register hook
    if (err) {
        printk(KERN_ERR "nf_register_net_hook return err code %d \n", err);
        return err;
    }

    return 0;
}

int fusion_aes67_nf_get_mac_addr(unsigned char *addr, const char *iface)
{
    struct net_device *dev = dev_get_by_name(&init_net, iface);
    if (!dev)
        return -1;
    memcpy(addr, dev->dev_addr, ETH_ALEN);
    return 0;
}

int fusion_aes67_nf_get_new_skb(void **skb, unsigned int data_len)
{
    *skb = dev_alloc_skb(data_len/*, GFP_ATOMIC*/);
    if (*skb) {
        return 0;
    }
    else {
        printk(KERN_ALERT "dev_alloc_skb out of memory\n");
        return -1;
    }
}

int fusion_aes67_nf_free_skb(void *skb)
{
    dev_kfree_skb(skb);
    return 0;
}

int fusion_aes67_nf_get_skb_data(void **data, void *skb, unsigned int data_len)
{
    struct sk_buff *skb_ptr = (struct sk_buff*)skb;
    *data = skb_put(skb_ptr, data_len);
    if (*data) {
        return 0;
    }
    else {
        return -1;
        printk(KERN_ALERT "skb_put pulData out of memory\n");
    }
}

int irqCheckOnce = 0;
int fusion_aes67_nf_tx_packet(void *skb, unsigned int data_len, const char *iface)
{
    struct sk_buff *skb_ptr = (struct sk_buff*)skb;
    struct net_device *dev = dev_get_by_name(&init_net, iface);
    int ret = 0;

    if (data_len == 0)
    {
        return -10;
    }

    skb_ptr->pkt_type = PACKET_OUTGOING;
    //skb->ip_summed = CHECKSUM_NONE; // do not change anything ?
    skb_ptr->dev = dev;

    fusion_aes67_nf_skb_trim(skb, data_len);
    //return 0;
    if (irqCheckOnce == 0)
    {
        if (irqs_disabled() != 0)
        {
            printk(KERN_ALERT "IRQ disabled !!!\n");
            irqCheckOnce = 1;
        }
    }
    skb_reset_network_header(skb_ptr);

    ret = dev_queue_xmit(skb_ptr);
    if (ret < 0)
    {
        printk(KERN_ALERT "dev_queue_xmit return err code %d \n", ret);
        dev_kfree_skb(skb_ptr);
    }

    return ret;
}

int fusion_aes67_nf_create_packet(struct fusion_aes67_netfilter *nf, struct sk_buff **skb, void **ppvPacket, uint32_t *pPacketSize)
{
#ifdef FAKE_AQUIRE_PACKET
    *ppvPacket = shortCutPacket;
    *pPacketSize = ETHERNET_STANDARD_FRAME_SIZE;
    return 1;
#else
    if (fusion_aes67_nf_get_new_skb(skb, ETHERNET_STANDARD_FRAME_SIZE) < 0) {
        return 0;
    }
    if (fusion_aes67_nf_get_skb_data(ppvPacket, *skb, ETHERNET_STANDARD_FRAME_SIZE) < 0) {
        free_skb(*skb);
        *skb = NULL;
        *pPacketSize = 0;
        return 0;
    }
    *pPacketSize = ETHERNET_STANDARD_FRAME_SIZE;
    return 1;
#endif
}

////////////////////////////////////////////////////////////////////////
int fusion_aes67_nf_destroy(struct fusion_aes67_netfilter *nf)
{
    if (nf->nf_hook_struct) {
        nf_unregister_net_hook(&init_net, &nf->nf_hook_struct);
    }

    return 0;
}

////////////////////////////////////////////////////////////////////////
int fusion_aes67_nf_start(struct fusion_aes67_netfilter *nf)
{
    int ret = 1;
    unsigned long flags;

    spin_lock_irqsave(&nf->lock, flags);
    nf->is_enabled = true;
    spin_unlock_irqrestore(&nf->lock, flags);

    return ret;
}

////////////////////////////////////////////////////////////////////////
int fusion_aes67_nf_stop(struct fusion_aes67_netfilter *nf)
{
    unsigned long flags;

    spin_lock_irqsave(&nf->lock, flags);
    nf->is_enabled = false;
    spin_unlock_irqrestore(&nf->lock, flags);

    return 1;
}


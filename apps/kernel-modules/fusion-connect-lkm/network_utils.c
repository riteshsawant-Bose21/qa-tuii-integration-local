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

#include "network_utils.h"
#include <linux/string.h>
#include <linux/errno.h>
#include <linux/icmp.h>
#include <netinet/in.h>

void dump_mac_addr(const uint8_t addr[ETH_ALEN])
{
    printk(KERN_DEBUG "%02x:%02x:%02x:%02x:%02x:%02x\n",
           addr[0], addr[1], addr[2], addr[3], addr[4], addr[5]);
}

void dump_ip_addr(__be32 ip, char carriage_return)
{
    uint32_t ip_host = __be32_to_cpu(ip);
    printk(KERN_DEBUG "%d.%d.%d.%d", (ip_host >> 24) & 0xFF, (ip_host >> 16) & 0xFF,
           (ip_host >> 8) & 0xFF, ip_host & 0xFF);
    if (carriage_return) printk(KERN_DEBUG "\n");
}

int is_mac_equal(const uint8_t addr1[ETH_ALEN], const uint8_t addr2[ETH_ALEN])
{
    return memcmp(addr1, addr2, ETH_ALEN) == 0;
}

int is_ip_mcast(__be32 ip)
{
    uint32_t ip_host = __be32_to_cpu(ip);
    return (ip_host >= 0xE0000000 && ip_host <= 0xEFFFFFFF); // 224.0.0.0 - 239.255.255.255
}

uint16_t compute_cksum(const void *data, uint16_t len)
{
    uint32_t acc = 0;
    const uint8_t *octetptr = (const uint8_t *)data;

    while (len > 1) {
        uint16_t src = ((uint16_t)*octetptr << 8) | *(octetptr + 1);
        acc += src;
        octetptr += 2;
        len -= 2;
    }
    if (len > 0) {
        acc += (uint16_t)*octetptr << 8;
    }
    acc = (acc >> 16) + (acc & 0xFFFF);
    if (acc & 0xFFFF0000) {
        acc = (acc >> 16) + (acc & 0xFFFF);
    }
    return ~(uint16_t)acc;
}

uint16_t compute_udp_cksum(const void *data, uint16_t len, const uint16_t *src_ip, const uint16_t *dest_ip)
{
    uint32_t acc = 0;
    const uint8_t *octetptr = (const uint8_t *)data;

    while (len > 1) {
        uint16_t src = ((uint16_t)*octetptr << 8) | *(octetptr + 1);
        acc += src;
        octetptr += 2;
        len -= 2;
    }
    if (len > 0) {
        acc += (uint16_t)*octetptr << 8;
    }

    acc += uint16_t_to_cpu(src_ip[0]) + uint16_t_to_cpu(src_ip[1]);
    acc += uint16_t_to_cpu(dest_ip[0]) + uint16_t_to_cpu(dest_ip[1]);
    acc += IPPROTO_UDP + len;

    acc = (acc >> 16) + (acc & 0xFFFF);
    if (acc & 0xFFFF0000) {
        acc = (acc >> 16) + (acc & 0xFFFF);
    }
    return ~(uint16_t)acc;
}

void dump_eth_header(const struct ethhdr *eth)
{
    printk(KERN_DEBUG "Dump Ethernet Header\n");
    printk(KERN_DEBUG "\tSrc = ");
    dump_mac_addr(eth->h_source);
    printk(KERN_DEBUG "\tDest = ");
    dump_mac_addr(eth->h_dest);
    printk(KERN_DEBUG "\tType = 0x%04x\n", uint16_t_to_cpu(eth->h_proto));
}

void dump_ipv4_header(const struct iphdr *ip)
{
    printk(KERN_DEBUG "Dump IP Header\n");
    printk(KERN_DEBUG "\tVersion_HLen = 0x%x\n", ip->version << 4 | ip->ihl);
    printk(KERN_DEBUG "\tTOS = 0x%x\n", ip->tos);
    printk(KERN_DEBUG "\tLen = %d\n", uint16_t_to_cpu(ip->tot_len));
    printk(KERN_DEBUG "\tIdentification: 0x%04x\n", uint16_t_to_cpu(ip->id));
    printk(KERN_DEBUG "\tOffset: 0x%04x\n", uint16_t_to_cpu(ip->frag_off));
    printk(KERN_DEBUG "\tTTL: 0x%x\n", ip->ttl);
    printk(KERN_DEBUG "\tProtocol: 0x%x\n", ip->protocol);
    printk(KERN_DEBUG "\tChecksum = 0x%04x\n", uint16_t_to_cpu(ip->check));
    printk(KERN_DEBUG "\tSource IP: ");
    dump_ip_addr(ip->saddr, 0);
    printk(KERN_DEBUG "\n\tDest IP: ");
    dump_ip_addr(ip->daddr, 1);
}

void dump_udp_header(const struct udphdr *udp)
{
    printk(KERN_DEBUG "Dump UDP Header\n");
    printk(KERN_DEBUG "\tSource Port = %d\n", uint16_t_to_cpu(udp->source));
    printk(KERN_DEBUG "\tDest Port = %d\n", uint16_t_to_cpu(udp->dest));
}

// Placeholder for ARP/ICMP - kernel replacements need socket API adjustments
int get_mac_from_remote_ip(__be32 ip, uint8_t mac[ETH_ALEN])
{
    // TODO: Replace with kernel ARP lookup (e.g., arp_lookup) or keep custom
    return 0;
}

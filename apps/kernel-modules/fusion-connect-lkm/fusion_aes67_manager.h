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

 #ifndef FUSION_AES67_MANAGER_H
 #define FUSION_AES67_MANAGER_H
 
 #include <linux/kernel.h>
 #include <linux/netfilter_ipv4.h>
 #include <linux/netdevice.h>
 #include <linux/if_ether.h>
 #include <linux/types.h>
 #include <asm/div64.h>
 #include <net/ip.h>
 #include <net/udp.h>
 #include <net/route.h>
 #include <net/checksum.h>
 #include <linux/hrtimer.h>
 #include <time.h>
 #include <linux/ptp_clock.h>
 #include "fusion_aes67_alsa.h"
 #include "RTP_streams_manager.h"
 
 enum ptp_timing_mode {
     TIMING_HRTIMER,
     TIMING_GPIO_INTERRUPT
 };
 
 enum fusion_aes67_ctrl_cmd {
     FUSION_AES67_CTRL_CMD_start,
     FUSION_AES67_CTRL_CMD_stop,
     FUSION_AES67_CTRL_CMD_start_io,
     FUSION_AES67_CTRL_CMD_stop_io,
     FUSION_AES67_CTRL_CMD_add_rtp_stream,
     FUSION_AES67_CTRL_CMD_remove_rtp_stream,
     FUSION_AES67_CTRL_CMD_update_rtp_stream,
     FUSION_AES67_CTRL_CMD_get_rtp_stream_status,
     FUSION_AES67_CTRL_CMD_set_playout_delay,
     FUSION_AES67_CTRL_CMD_set_capture_delay,
 };
 
 #define MAX_STREAM_NAME_SIZE 64
 
 // data struct for add rtp stream API call
 struct aes67_stream_config {
     uint64_t stream_handle;
     uint32_t sample_rate;
     snd_pcm_format_t format;
     uint32_t channels;
     uint32_t samples_per_packet;
     uint32_t dest_ip;
     uint16_t dest_port;
     uint16_t rtcp_dest_port;
     uint8_t payload_type;
     uint32_t playout_delay;
     int8_t is_source;
     char name[MAX_STREAM_NAME_SIZE];
 };
 
 struct fusion_aes67_state {
     bool is_started;
     bool ptp_synchronized; // Set by userspace
     int32_t playout_delay; // Added missing field
     int32_t capture_delay; // Added missing field
 };
 
 struct fusion_aes67_alsa {
     struct fusion_aes67_chip *alsa_chip;
     const struct fusion_aes67_mgr_ops *mgr_callbacks;
     const struct fusion_aes67_alsa_ops *alsa_callbacks;
     // Removed is_running - per-stream now
 };
 
 struct fusion_aes67_rtp {
     struct fusion_aes67_rtp_manager rtp_streams_manager;
     struct rtp_audio_stream_ops rtp_callbacks;
 };
 
 // populates stream_timings list in fusion_aes67_ptp
 struct fusion_aes67_stream_timing {
     uint64_t next_action_time;
     uint64_t last_rtp_timestamp;
     uint32_t sample_rate;
     uint32_t samples_per_packet;
     uint32_t playout_delay;
     int8_t is_source;
     int8_t is_running;
     struct list_head list;
 };
 
 struct fusion_aes67_ptp {
     enum ptp_timing_mode ptp_timing_mode;
     struct hrtimer audio_timer;
     clockid_t phc_clockid;
     int gpio_irq;
     int gpio_pin;
     struct list_head stream_timings;
 };
 
 struct fusion_aes67_netfilter {
     volatile bool is_enabled;
     spinlock_t lock;
     struct nf_hook_ops nf_hook_struct;
     char iface_name[16];
 };
 
 struct fusion_aes67_netlink {
     struct sock *nl_sock;
     int nl_family;
 };
 
 struct fusion_aes67_manager {
     struct fusion_aes67_state state;
     struct fusion_aes67_alsa alsa;
     struct fusion_aes67_rtp rtp;
     struct fusion_aes67_ptp ptp;
     struct fusion_aes67_netfilter netfilter;
     struct fusion_aes67_netlink netlink;
 };
 
 struct fusion_aes67_ctrl_msg {
     enum fusion_aes67_ctrl_cmd cmd;
     int err;
     int data_size;
     void *data;
     pid_t pid;
 };
 
 struct message_handler_entry {
     enum fusion_aes67_ctrl_cmd cmd;
     int (*handler)(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply);
 };
 
 int fusion_aes67_mgr_init(struct fusion_aes67_manager *mgr);
 void fusion_aes67_mgr_destroy(struct fusion_aes67_manager *mgr);
 bool fusion_aes67_mgr_start(struct fusion_aes67_manager *mgr);
 bool fusion_aes67_mgr_stop(struct fusion_aes67_manager *mgr);
 
 extern const struct fusion_aes67_alsa_ops fusion_aes67_alsa_callbacks;
 extern const struct rtp_audio_stream_ops fusion_aes67_rtp_callbacks;
 
 #endif // FUSION_AES67_MANAGER_H

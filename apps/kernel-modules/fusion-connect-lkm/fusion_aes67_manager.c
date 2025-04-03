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

#include <linux/errno.h>
#include <linux/delay.h>
#include <linux/slab.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/netlink.h>
#include <net/netlink.h>
#include <linux/skbuff.h>
#include "fusion_aes67_manager.h"
#include "fusion_aes67_netfilter.h"

static void fusion_aes67_mute_buffers(struct fusion_aes67_manager *mgr)
{
    struct fusion_aes67_stream_timing *timing;
    unsigned long flags;

    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->is_source) {
            uint32_t buffer_length = mgr->alsa.mgr_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip, timing->stream_handle);
            int32_t *buffer = mgr->alsa.mgr_callbacks->get_capture_buffer(mgr->alsa.alsa_chip, timing->stream_handle);
            if (buffer && buffer_length) {
                mgr->alsa.mgr_callbacks->lock_capture_buffer(mgr->alsa.alsa_chip, timing->stream_handle, &flags);
                memset(buffer, 0, buffer_length * timing->channels * 4);
                mgr->alsa.mgr_callbacks->unlock_capture_buffer(mgr->alsa.alsa_chip, timing->stream_handle, &flags);
            }
        } else {
            uint32_t buffer_length = mgr->alsa.mgr_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip, timing->stream_handle);
            int32_t *buffer = mgr->alsa.mgr_callbacks->get_playback_buffer(mgr->alsa.alsa_chip, timing->stream_handle);
            if (buffer && buffer_length) {
                mgr->alsa.mgr_callbacks->lock_playback_buffer(mgr->alsa.alsa_chip, timing->stream_handle, &flags);
                memset(buffer, 0, buffer_length * timing->channels * 4);
                mgr->alsa.mgr_callbacks->unlock_playback_buffer(mgr->alsa.alsa_chip, timing->stream_handle, &flags);
            }
        }
    }
}

/* ALSA Callbacks */
static int alsa_ops_attach_alsa_driver(void *mgr, const struct fusion_aes67_mgr_ops *ops, void *alsa_chip_pointer) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!ops || !alsa_chip_pointer) return -EINVAL;
    mgr->alsa.alsa_chip = alsa_chip_pointer;
    mgr->alsa.mgr_callbacks = ops;
    return 0;
}

static int alsa_ops_get_input_jitter_buffer_offset(void *mgr, uint64_t stream_handle, uint32_t *offset) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!offset) return -EINVAL;
    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == stream_handle && timing->is_source) {
            *offset = mgr->alsa.mgr_callbacks->get_capture_buffer_offset(mgr->alsa.alsa_chip, stream_handle);
            return 0;
        }
    }
    return -ENOENT;
}

static int alsa_ops_get_output_jitter_buffer_offset(void *mgr, uint64_t stream_handle, uint32_t *offset) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!offset) return -EINVAL;
    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == stream_handle && !timing->is_source) {
            *offset = mgr->alsa.mgr_callbacks->get_playback_buffer_offset(mgr->alsa.alsa_chip, stream_handle);
            return 0;
        }
    }
    return -ENOENT;
}

static int alsa_ops_get_rtp_frame_size_per_stream(void *mgr, uint64_t stream_handle, uint32_t *framesize) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!framesize) return -EINVAL;
    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == stream_handle) {
            *framesize = timing->samples_per_packet;
            return 0;
        }
    }
    return -ENOENT;
}

static int alsa_ops_get_jitter_buffer_sample_size(void *mgr, uint64_t stream_handle, uint8_t *sample_size) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!sample_size) return -EINVAL;
    *sample_size = 4; // Hardcoded 32-bit PCM for now
    return 0;
}

static int alsa_ops_get_playout_delay(void *mgr, snd_pcm_sframes_t *delay_in_sample) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr->state.playout_delay;
    return 0;
}

static int alsa_ops_get_capture_delay(void *mgr, snd_pcm_sframes_t *delay_in_sample) 
{
    struct fusion_aes67_manager *mgr = mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr->state.capture_delay;
    return 0;
}

static int alsa_ops_start_interrupts(void *aes67_mgr, uint64_t stream_handle)
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == stream_handle) {
            timing->is_running = 1;
            return 0;
        }
    }
    return -ENOENT;
}

static int alsa_ops_stop_interrupts(void *aes67_mgr, uint64_t stream_handle)
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == stream_handle) {
            timing->is_running = 0;
            return 0;
        }
    }
    return -ENOENT;
}

const struct fusion_aes67_alsa_ops fusion_aes67_alsa_callbacks = {
    .register_alsa_driver = alsa_ops_attach_alsa_driver,
    .get_input_jitter_buffer_offset = alsa_ops_get_input_jitter_buffer_offset,
    .get_output_jitter_buffer_offset = alsa_ops_get_output_jitter_buffer_offset,
    .get_rtp_frame_size_per_stream = alsa_ops_get_rtp_frame_size_per_stream,
    .get_jitter_buffer_sample_size = alsa_ops_get_jitter_buffer_sample_size,
    .get_playout_delay = alsa_ops_get_playout_delay,
    .get_capture_delay = alsa_ops_get_capture_delay,
    .start_interrupts = alsa_ops_start_interrupts,
    .stop_interrupts = alsa_ops_stop_interrupts
};

/* RTP Callbacks (Broken, to be fixed in RTP refactor) */
static uint64_t get_global_sac_new(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    struct timespec ts;
    clock_gettime(mgr->ptp.phc_clockid, &ts);
    uint64_t ns = ts.tv_sec * 1000000000ULL + ts.tv_nsec;
    return ns; // TODO: Per-stream sample rate needed
}

static uint64_t get_global_time_new(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    struct timespec ts;
    clock_gettime(mgr->ptp.phc_clockid, &ts);
    return ts.tv_sec * 10000000ULL + ts.tv_nsec / 100;
}

static void get_global_times_new(void *user, uint64_t *global_sac, uint64_t *global_time, uint64_t *global_performance_counter) 
{
    struct fusion_aes67_manager *mgr = user;
    struct timespec ts;
    clock_gettime(mgr->ptp.phc_clockid, &ts);
    uint64_t ns = ts.tv_sec * 1000000000ULL + ts.tv_nsec;
    *global_time = ts.tv_sec * 10000000ULL + ts.tv_nsec / 100;
    *global_sac = ns; // TODO: Per-stream sample rate needed
    *global_performance_counter = ktime_to_ns(ktime_get());
}

const struct rtp_audio_stream_ops fusion_aes67_rtp_callbacks = {
    .get_global_SAC = get_global_sac_new,
    .get_global_time = get_global_time_new,
    .get_global_times = get_global_times_new,
    // Remaining callbacks omitted for brevity, flagged for RTP refactor
};

/* Timing Functions */
static clockid_t get_phc_clockid(void) {
    int fd = open("/dev/ptp0", O_RDONLY);
    if (fd < 0) return -1;
    clockid_t clkid = ((~(clockid_t)(fd) << 3) | 3);
    close(fd);
    return clkid;
}

static enum hrtimer_restart audio_frame_process(struct hrtimer *timer)
{
    struct fusion_aes67_manager *mgr = container_of(timer, struct fusion_aes67_manager, ptp.audio_timer);
    struct timespec phc_ts;
    uint64_t current_phc_ns;

    clock_gettime(mgr->ptp.phc_clockid, &phc_ts);
    current_phc_ns = phc_ts.tv_sec * 1000000000ULL + phc_ts.tv_nsec;

    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (!timing->is_running || !mgr->state.ptp_synchronized) continue;

        uint64_t current_samples = (current_phc_ns * timing->sample_rate) / 1000000000ULL;
        if (timing->is_source) {
            if (current_phc_ns >= timing->next_action_time) {
                mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 0, timing->stream_handle);
                prepare_buffer_lives(&mgr->rtp.rtp_streams_manager);
                frame_process_begin(&mgr->rtp.rtp_streams_manager);
                frame_process_end(&mgr->rtp.rtp_streams_manager);
                timing->last_rtp_timestamp += timing->samples_per_packet;
                timing->next_action_time = (timing->last_rtp_timestamp * 1000000000ULL) / timing->sample_rate;
            }
        } else {
            uint32_t next_rtp_ts = get_next_rtp_timestamp(&mgr->rtp.rtp_streams_manager);
            uint64_t playout_ts = next_rtp_ts + (mgr->state.playout_delay ? mgr->state.playout_delay : timing->playout_delay);
            if (current_samples >= playout_ts) {
                prepare_buffer_lives(&mgr->rtp.rtp_streams_manager);
                frame_process_begin(&mgr->rtp.rtp_streams_manager);
                mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 1, timing->stream_handle);
                frame_process_end(&mgr->rtp.rtp_streams_manager);
                timing->last_rtp_timestamp = next_rtp_ts;
                timing->next_action_time = ((next_rtp_ts + timing->samples_per_packet) * 1000000000ULL) / timing->sample_rate;
            }
        }
    }

    hrtimer_forward_now(timer, ns_to_ktime(100000));
    return HRTIMER_RESTART;
}

/* Manager Functions */
static int fusion_aes67_state_init(struct fusion_aes67_manager *mgr) 
{
    mgr->state.is_started = false;
    mgr->state.ptp_synchronized = false;
    mgr->state.playout_delay = 0; // Initialize added fields
    mgr->state.capture_delay = 0;
    INIT_LIST_HEAD(&mgr->ptp.stream_timings);
    return 0;
}

static int fusion_aes67_rtp_init(struct fusion_aes67_manager *mgr) 
{
    mgr->rtp.rtp_callbacks = fusion_aes67_rtp_callbacks;
    mgr->rtp.rtp_callbacks.user = mgr;
    return init_rtp_streams(&mgr->rtp.rtp_streams_manager, &mgr->rtp.rtp_callbacks, &mgr->netfilter);
}

static int fusion_aes67_alsa_init(struct fusion_aes67_manager *mgr) 
{
    mgr->alsa.alsa_chip = NULL;
    mgr->alsa.mgr_callbacks = NULL;
    mgr->alsa.alsa_callbacks = &fusion_aes67_alsa_callbacks;
    return fusion_aes67_card_init(mgr, &fusion_aes67_alsa_callbacks);
}

static int fusion_aes67_ptp_init(struct fusion_aes67_manager *mgr) 
{
    int err = 0;
    if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT) {
        if (mgr->ptp.gpio_pin < 0) {
            printk(KERN_ERR "fusion_aes67: Invalid GPIO pin number: %d\n", mgr->ptp.gpio_pin);
            return -EINVAL;
        }
        if ((err = init_gpio_interrupt(mgr)) < 0) { // Assuming this exists from context
            printk(KERN_ERR "fusion_aes67: Failed to initialize GPIO interrupt: %d\n", err);
            return err;
        }
    } else {
        mgr->ptp.ptp_timing_mode = TIMING_HRTIMER;
        mgr->ptp.phc_clockid = get_phc_clockid();
        if (mgr->ptp.phc_clockid < 0) return -EINVAL;
        hrtimer_init(&mgr->ptp.audio_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
        mgr->ptp.audio_timer.function = audio_frame_process;
        mgr->ptp.gpio_irq = -1;
        mgr->ptp.gpio_pin = -1;
    }
    printk(KERN_INFO "fusion_aes67: Manager initialized with %s timing\n",
           mgr->ptp.ptp_timing_mode == TIMING_HRTIMER ? "hrtimer" : "GPIO interrupt");
    return 0;
}

static int fusion_aes67_nl_init(struct fusion_aes67_manager *mgr)
{
    static struct netlink_kernel_cfg cfg = {
        .input = fusion_aes67_nl_recv_msg,
    };
    mgr->netlink.nl_family = NETLINK_USERSOCK;
    mgr->netlink.nl_sock = netlink_kernel_create(&init_net, mgr->netlink.nl_family, &cfg);
    if (!mgr->netlink.nl_sock) {
        printk(KERN_ERR "fusion_aes67: Failed to create netlink socket\n");
        return -ENOMEM;
    }
    mgr->netlink.nl_sock->sk_private_data = mgr;
    return 0;
}

void fusion_aes67_nl_destroy(struct fusion_aes67_manager *mgr) 
{
    if (mgr->netlink.nl_sock) {
        netlink_kernel_release(mgr->netlink.nl_sock);
        mgr->netlink.nl_sock = NULL;
    }
}

int fusion_aes67_mgr_init(struct fusion_aes67_manager *mgr) 
{
    int err;
    if (!mgr) {
        printk(KERN_ERR "fusion_aes67: Null manager pointer\n");
        return -EINVAL;
    }
    if ((err = fusion_aes67_state_init(mgr)) < 0) return err;
    if ((err = fusion_aes67_nf_init(mgr)) < 0) return err;
    if ((err = fusion_aes67_rtp_init(mgr)) < 0) {
        fusion_aes67_nf_destroy(&mgr->netfilter);
        return err;
    }
    if ((err = fusion_aes67_alsa_init(mgr)) < 0) {
        destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
        fusion_aes67_nf_destroy(&mgr->netfilter);
        return err;
    }
    if ((err = fusion_aes67_nl_init(mgr)) < 0) {
        fusion_aes67_card_exit();
        destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
        fusion_aes67_nf_destroy(&mgr->netfilter);
        return err;
    }
    if ((err = fusion_aes67_ptp_init(mgr)) < 0) {
        fusion_aes67_nl_destroy(mgr);
        fusion_aes67_card_exit();
        destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
        fusion_aes67_nf_destroy(&mgr->netfilter);
        return err;
    }
    return 0;
}

void fusion_aes67_mgr_destroy(struct fusion_aes67_manager *mgr) 
{
    if (!mgr) return;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        free_irq(mgr->ptp.gpio_irq, mgr);
        if (gpio_is_valid(mgr->ptp.gpio_pin)) gpio_free(mgr->ptp.gpio_pin);
    }
    fusion_aes67_nl_destroy(mgr);
    fusion_aes67_card_exit();
    destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
    fusion_aes67_nf_destroy(&mgr->netfilter);
    printk(KERN_INFO "fusion_aes67: Manager destroyed\n");
}

bool fusion_aes67_mgr_start(struct fusion_aes67_manager *mgr) 
{
    if (!mgr || mgr->state.is_started) return false;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_start(&mgr->ptp.audio_timer, ns_to_ktime(100000), HRTIMER_MODE_REL);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        enable_irq(mgr->ptp.gpio_irq);
    } else {
        printk(KERN_ERR "fusion_aes67: Invalid timing mode or GPIO not configured\n");
        return false;
    }
    mgr->netfilter.is_enabled = true;
    mgr->state.is_started = true;
    return true;
}

bool fusion_aes67_mgr_stop(struct fusion_aes67_manager *mgr) 
{
    if (!mgr || !mgr->state.is_started) return false;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        disable_irq(mgr->ptp.gpio_irq);
    }
    mgr->netfilter.is_enabled = false;
    mgr->state.is_started = false;
    return true;
}

/* Message Handlers */
static int handle_start(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    printk(KERN_INFO "fusion_aes67: Starting manager\n");
    return reply->err = fusion_aes67_mgr_start(mgr) ? 0 : -EIO;
}

static int handle_stop(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    printk(KERN_INFO "fusion_aes67: Stopping manager\n");
    return reply->err = fusion_aes67_mgr_stop(mgr) ? 0 : -EIO;
}

static int handle_start_io(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    uint64_t *stream_handle = (uint64_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Starting IO for stream %llu\n", *stream_handle);
    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->start_interrupts) {
        int ret = mgr->alsa.mgr_callbacks->start_interrupts(mgr->alsa.alsa_chip, *stream_handle);
        if (ret < 0) return reply->err = ret;
    } else {
        return reply->err = -ENOSYS;
    }
    return reply->err = 0;
}

static int handle_stop_io(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    uint64_t *stream_handle = (uint64_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Stopping IO for stream %llu\n", *stream_handle);
    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->stop_interrupts) {
        int ret = mgr->alsa.mgr_callbacks->stop_interrupts(mgr->alsa.alsa_chip, *stream_handle);
        if (ret < 0) return reply->err = ret;
    } else {
        return reply->err = -ENOSYS;
    }
    return reply->err = 0;
}

static int handle_add_rtp_stream(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(struct aes67_stream_config)) return reply->err = -EINVAL;

    struct aes67_stream_config *config = (struct aes67_stream_config *)msg->data;
    bool restart_required = mgr->state.is_started;

    if (config->sample_rate == 0 || config->channels == 0 || config->samples_per_packet == 0 || config->stream_handle == 0) {
        return reply->err = -EINVAL;
    }

    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == config->stream_handle) {
            return reply->err = -EEXIST;
        }
    }

    if (mgr->state.is_started) fusion_aes67_mgr_stop(mgr);

    struct fusion_aes67_rtp_stream_info rtp_info = {
        .m_ui32SamplingRate = config->sample_rate,
        .m_byWordLength = snd_pcm_format_physical_width(config->format),
        .m_byNbOfChannels = config->channels,
        .m_ui32MaxSamplesPerPacket = config->samples_per_packet,
        .m_ui32DestIP = config->dest_ip,
        .m_usDestPort = config->dest_port,
        .m_usRTCPDestPort = config->rtcp_dest_port,
        .m_byPayloadType = config->payload_type,
        .m_ui32PlayOutDelay = config->playout_delay,
        .m_bSource = config->is_source,
        .m_ui32SSRC = (uint32_t)config->stream_handle,
        .m_bSSRCInitialized = 1,
        .m_byTTL = 255,
        .m_ucDSCP = 46,
    };
    strlcpy(rtp_info.m_cName, config->name, MAX_STREAM_NAME_SIZE);

    if (!add_rtp_stream(&mgr->rtp.rtp_streams_manager, &rtp_info, &config->stream_handle)) {
        if (restart_required) fusion_aes67_mgr_start(mgr);
        return reply->err = -EIO;
    }

    // Create ALSA PCM device with correct buffer size
    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->open_substream) {
        int ret = mgr->alsa.mgr_callbacks->open_substream(mgr->alsa.alsa_chip, config->stream_handle,
                                                          config->is_source ? SNDRV_PCM_STREAM_CAPTURE : SNDRV_PCM_STREAM_PLAYBACK,
                                                          config->channels, config->format);
        if (ret < 0) {
            remove_rtp_stream(&mgr->rtp.rtp_streams_manager, config->stream_handle);
            if (restart_required) fusion_aes67_mgr_start(mgr);
            return reply->err = ret;
        }
    }

    // Set stream parameters (rate only, buffer already sized)
    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->set_stream_params) {
        int ret = mgr->alsa.mgr_callbacks->set_stream_params(mgr->alsa.alsa_chip, config->stream_handle,
                                                             config->sample_rate, config->channels, config->format);
        if (ret < 0) {
            remove_rtp_stream(&mgr->rtp.rtp_streams_manager, config->stream_handle);
            if (restart_required) fusion_aes67_mgr_start(mgr);
            return reply->err = ret;
        }
    }

    timing = kzalloc(sizeof(*timing), GFP_KERNEL);
    if (!timing) {
        remove_rtp_stream(&mgr->rtp.rtp_streams_manager, config->stream_handle);
        if (restart_required) fusion_aes67_mgr_start(mgr);
        return reply->err = -ENOMEM;
    }
    timing->stream_handle = config->stream_handle;
    timing->sample_rate = config->sample_rate;
    timing->samples_per_packet = config->samples_per_packet;
    timing->playout_delay = config->playout_delay;
    timing->is_source = config->is_source;
    timing->is_running = 0;
    timing->next_action_time = 0;
    list_add(&timing->list, &mgr->ptp.stream_timings);

    if (restart_required) {
        if (!fusion_aes67_mgr_start(mgr)) {
            list_del(&timing->list);
            kfree(timing);
            remove_rtp_stream(&mgr->rtp.rtp_streams_manager, config->stream_handle);
            return reply->err = -EIO;
        }
    }

    reply->err = 0;
    reply->data_size = sizeof(uint64_t);
    reply->data = &config->stream_handle;
    return 0;
}

static int handle_remove_rtp_stream(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    uint64_t *handle = (uint64_t *)msg->data;
    bool restart_required = mgr->state.is_started;

    struct fusion_aes67_stream_timing *timing, *tmp;
    LIST_FOR_EACH_ENTRY_SAFE(timing, tmp, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == *handle) {
            if (restart_required) fusion_aes67_mgr_stop(mgr);
            list_del(&timing->list);
            kfree(timing);
            if (!remove_rtp_stream(&mgr->rtp.rtp_streams_manager, *handle)) {
                if (restart_required) fusion_aes67_mgr_start(mgr);
                return reply->err = -EIO;
            }
            if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->remove_substream) {
                int ret = mgr->alsa.mgr_callbacks->remove_substream(mgr->alsa.alsa_chip, *handle);
                if (ret < 0) {
                    printk(KERN_ERR "fusion_aes67: Failed to remove substream %llu: %d\n", *handle, ret);
                    if (restart_required) fusion_aes67_mgr_start(mgr);
                    return reply->err = ret;
                }
            }
            if (restart_required) fusion_aes67_mgr_start(mgr);
            return reply->err = 0;
        }
    }
    return reply->err = -ENOENT;
}

static int handle_update_rtp_stream(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(struct aes67_stream_config)) return reply->err = -EINVAL;
    struct aes67_stream_config *config = (struct aes67_stream_config *)msg->data;
    bool restart_required = mgr->state.is_started;

    struct fusion_aes67_stream_timing *timing;
    LIST_FOR_EACH_ENTRY(timing, &mgr->ptp.stream_timings, list) {
        if (timing->stream_handle == config->stream_handle) {
            if (restart_required) fusion_aes67_mgr_stop(mgr);
            timing->sample_rate = config->sample_rate;
            timing->samples_per_packet = config->samples_per_packet;
            timing->playout_delay = config->playout_delay;
            timing->is_source = config->is_source;

            struct fusion_aes67_rtp_stream_info rtp_info = {
                .m_ui32SamplingRate = config->sample_rate,
                .m_byWordLength = snd_pcm_format_physical_width(config->format),
                .m_byNbOfChannels = config->channels,
                .m_ui32MaxSamplesPerPacket = config->samples_per_packet,
                .m_ui32DestIP = config->dest_ip,
                .m_usDestPort = config->dest_port,
                .m_usRTCPDestPort = config->rtcp_dest_port,
                .m_byPayloadType = config->payload_type,
                .m_ui32PlayOutDelay = config->playout_delay,
                .m_bSource = config->is_source,
                .m_ui32SSRC = (uint32_t)config->stream_handle,
                .m_bSSRCInitialized = 1,
                .m_byTTL = 255,
                .m_ucDSCP = 46,
            };
            strlcpy(rtp_info.m_cName, config->name, MAX_STREAM_NAME_SIZE);

            if (!update_rtp_stream(&mgr->rtp.rtp_streams_manager, &rtp_info, config->stream_handle)) {
                if (restart_required) fusion_aes67_mgr_start(mgr);
                return reply->err = -EIO;
            }

            if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->set_stream_params) {
                int ret = mgr->alsa.mgr_callbacks->set_stream_params(mgr->alsa.alsa_chip, config->stream_handle,
                                                                     config->sample_rate, config->channels, config->format);
                if (ret < 0) {
                    if (restart_required) fusion_aes67_mgr_start(mgr);
                    return reply->err = ret;
                }
            }

            if (restart_required) fusion_aes67_mgr_start(mgr);
            reply->err = 0;
            reply->data_size = sizeof(uint64_t);
            reply->data = &config->stream_handle;
            return 0;
        }
    }
    return reply->err = -ENOENT;
}

static int handle_get_rtp_stream_status(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    static struct fusion_aes67_rtp_stream_status stream_status;
    uint64_t *handle = (uint64_t *)msg->data;
    if (!get_rtp_stream_status(&mgr->rtp.rtp_streams_manager, *handle, &stream_status)) {
        return reply->err = -EIO;
    }
    reply->err = 0;
    reply->data_size = sizeof(struct fusion_aes67_rtp_stream_status);
    reply->data = &stream_status;
    return 0;
}

static int handle_set_playout_delay(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(int32_t)) return reply->err = -EINVAL;
    int32_t *delay = (int32_t *)msg->data;
    mgr->state.playout_delay = *delay;
    return reply->err = 0;
}

static int handle_set_capture_delay(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(int32_t)) return reply->err = -EINVAL;
    int32_t *delay = (int32_t *)msg->data;
    mgr->state.capture_delay = *delay;
    return reply->err = 0;
}

/* Message Handling */
static const struct message_handler_entry message_handlers[] = {
    { FUSION_AES67_CTRL_CMD_start, handle_start },
    { FUSION_AES67_CTRL_CMD_stop, handle_stop },
    { FUSION_AES67_CTRL_CMD_start_io, handle_start_io },
    { FUSION_AES67_CTRL_CMD_stop_io, handle_stop_io },
    { FUSION_AES67_CTRL_CMD_add_rtp_stream, handle_add_rtp_stream },
    { FUSION_AES67_CTRL_CMD_remove_rtp_stream, handle_remove_rtp_stream },
    { FUSION_AES67_CTRL_CMD_update_rtp_stream, handle_update_rtp_stream },
    { FUSION_AES67_CTRL_CMD_get_rtp_stream_status, handle_get_rtp_stream_status },
    { FUSION_AES67_CTRL_CMD_set_playout_delay, handle_set_playout_delay },
    { FUSION_AES67_CTRL_CMD_set_capture_delay, handle_set_capture_delay },
    { 0, NULL }
};

/* Netlink Functions */
static void fusion_aes67_nl_recv_msg(struct sk_buff *skb)
{
    struct fusion_aes67_manager *mgr = nl_sk(skb->sk)->sk_private_data;
    struct nlmsghdr *nlh = nlmsg_hdr(skb);
    struct fusion_aes67_ctrl_msg msg_rcv;

    if (nlh->nlmsg_len < NLMSG_HDRLEN + sizeof(struct fusion_aes67_ctrl_msg)) {
        printk(KERN_ERR "fusion_aes67: Netlink message too short\n");
        return;
    }

    memcpy(&msg_rcv, nlmsg_data(nlh), sizeof(msg_rcv));
    msg_rcv.pid = nlh->nlmsg_pid;
    fusion_aes67_process_nl_msg(mgr, &msg_rcv);
}

static void fusion_aes67_nl_send_msg(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *reply)
{
    struct sk_buff *skb;
    struct nlmsghdr *nlh;
    int msg_size = sizeof(*reply) + reply->data_size;

    if (!mgr || !mgr->netlink.nl_sock) {
        printk(KERN_ERR "fusion_aes67: No manager or netlink socket for reply\n");
        return;
    }

    skb = nlmsg_new(msg_size, GFP_KERNEL);
    if (!skb) {
        printk(KERN_ERR "fusion_aes67: Failed to allocate netlink skb\n");
        return;
    }

    nlh = nlmsg_put(skb, 0, 0, NLMSG_DONE, msg_size, 0);
    if (!nlh) {
        kfree_skb(skb);
        return;
    }

    memcpy(nlmsg_data(nlh), reply, sizeof(*reply));
    if (reply->data_size && reply->data) {
        memcpy(nlmsg_data(nlh) + sizeof(*reply), reply->data, reply->data_size);
    }

    if (netlink_unicast(mgr->netlink.nl_sock, skb, reply->pid, MSG_DONTWAIT) < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to send netlink reply\n");
        kfree_skb(skb);
    }
}

void fusion_aes67_process_nl_msg(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg_rcv) 
{
    struct fusion_aes67_ctrl_msg msg_reply = {
        .cmd = msg_rcv ? msg_rcv->cmd : 0,
        .err = -ENOENT,
        .data_size = 0,
        .data = NULL,
        .pid = msg_rcv ? msg_rcv->pid : 0
    };
    if (!mgr || !msg_rcv) {
        printk(KERN_ERR "fusion_aes67: process_nl_msg received NULL mgr or msg\n");
        return;
    }
    const struct message_handler_entry *entry = message_handlers;
    while (entry->cmd != 0) {
        if (entry->cmd == msg_rcv->cmd) {
            if (entry->handler) {
                int ret = entry->handler(mgr, msg_rcv, &msg_reply);
                if (ret < 0) {
                    printk(KERN_ERR "fusion_aes67: Handler for cmd %d failed: %d\n", msg_rcv->cmd, ret);
                }
            } else {
                msg_reply.err = -ENOSYS;
            }
            break;
        }
        entry++;
    }
    if (entry->cmd == 0) {
        printk(KERN_WARNING "fusion_aes67: Unknown command: %d\n", msg_rcv->cmd);
        msg_reply.err = -EINVAL;
    }
    fusion_aes67_nl_send_msg(mgr, &msg_reply);
}

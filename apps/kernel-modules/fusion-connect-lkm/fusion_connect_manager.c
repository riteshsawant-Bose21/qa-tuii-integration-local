/*
* Copyright (C) 2025 Bose Professional
* ... GPL boilerplate ...
*/

#include <linux/fcntl.h>
#include <linux/unistd.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/time.h>
#include <linux/ktime.h>
#include <linux/math64.h>
#include <linux/netlink.h>
#include <net/netlink.h>
#include "fusion_connect_manager.h"

#ifndef abs64
#define abs64(x) ((x) >= 0 ? (x) : -(x))
#endif

static void fusion_cn_mute_buffers(struct fusion_cn_manager *mgr)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int i;

    /* Optimize: Single lock/unlock, mute all streams */
    spin_lock_irqsave(&mgr->rtp.lock, flags);
    for (i = 0; i < FUSION_CN_RTP_HASH_BITS; i++) {
        hlist_for_each_entry(stream, &mgr->rtp.streams[i], hnode) {
            uint32_t buffer_length = stream->info.is_source ?
                mgr->alsa.mgr_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip, stream->handle) :
                mgr->alsa.mgr_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip, stream->handle);
            int32_t *buffer = stream->info.is_source ?
                mgr->alsa.mgr_callbacks->get_capture_buffer(mgr->alsa.alsa_chip, stream->handle) :
                mgr->alsa.mgr_callbacks->get_playback_buffer(mgr->alsa.alsa_chip, stream->handle);

            if (buffer && buffer_length) {
                unsigned long sub_flags;
                void (*lock)(void *, uint64_t, unsigned long *) =
                    stream->info.is_source ? mgr->alsa.mgr_callbacks->lock_capture_buffer :
                                            mgr->alsa.mgr_callbacks->lock_playback_buffer;
                void (*unlock)(void *, uint64_t, unsigned long *) =
                    stream->info.is_source ? mgr->alsa.mgr_callbacks->unlock_capture_buffer :
                                            mgr->alsa.mgr_callbacks->unlock_playback_buffer;

                lock(mgr->alsa.alsa_chip, stream->handle, &sub_flags);
                memset(buffer, 0, buffer_length * stream->info.channels * 4);
                unlock(mgr->alsa.alsa_chip, stream->handle, &sub_flags);
            }
        }
    }
    spin_unlock_irqrestore(&mgr->rtp.lock, flags);
}

static int fusion_cn_mute_stream_buffer(struct fusion_cn_manager *mgr, uint64_t stream_handle)
{
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int bucket;

    /* Compute the bucket using the same hash function as fusion_cn_rtp_get_stream */
    bucket = hash_64(stream_handle, FUSION_CN_RTP_HASH_BITS);

    /* Lock the RTP manager to safely access the stream list */
    spin_lock_irqsave(&mgr->rtp.lock, flags);

    /* Search for the stream in the computed bucket */
    hlist_for_each_entry(stream, &mgr->rtp.streams[bucket], hnode) {
        if (stream->handle == stream_handle) {
            /* Found the stream, proceed with muting */
            uint32_t buffer_length = stream->info.is_source ?
                mgr->alsa.mgr_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip, stream->handle) :
                mgr->alsa.mgr_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip, stream->handle);
            int32_t *buffer = stream->info.is_source ?
                mgr->alsa.mgr_callbacks->get_capture_buffer(mgr->alsa.alsa_chip, stream->handle) :
                mgr->alsa.mgr_callbacks->get_playback_buffer(mgr->alsa.alsa_chip, stream->handle);

            if (buffer && buffer_length) {
                unsigned long sub_flags;
                void (*lock)(void *, uint64_t, unsigned long *) =
                    stream->info.is_source ? mgr->alsa.mgr_callbacks->lock_capture_buffer :
                                            mgr->alsa.mgr_callbacks->lock_playback_buffer;
                void (*unlock)(void *, uint64_t, unsigned long *) =
                    stream->info.is_source ? mgr->alsa.mgr_callbacks->unlock_capture_buffer :
                                            mgr->alsa.mgr_callbacks->unlock_playback_buffer;

                lock(mgr->alsa.alsa_chip, stream->handle, &sub_flags);
                memset(buffer, 0, buffer_length * stream->info.channels * 4);
                unlock(mgr->alsa.alsa_chip, stream->handle, &sub_flags);
            }

            spin_unlock_irqrestore(&mgr->rtp.lock, flags);

            if (!buffer || !buffer_length) {
                printk(KERN_WARNING "fusion_cn: No buffer to mute for stream %llu\n", stream_handle);
                return -EINVAL;
            }

            return 0;
        }
    }

    /* Stream not found */
    spin_unlock_irqrestore(&mgr->rtp.lock, flags);
    printk(KERN_ERR "fusion_cn: Stream %llu not found for muting\n", stream_handle);
    return -ENOENT;
}

/* ALSA Callbacks */
static int alsa_ops_attach_alsa_driver(void *mgr, const struct fusion_cn_mgr_ops *ops, void *alsa_chip_pointer)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!ops || !alsa_chip_pointer) return -EINVAL;
    mgr_ptr->alsa.alsa_chip = alsa_chip_pointer;
    mgr_ptr->alsa.mgr_callbacks = ops;
    return 0;
}

static int alsa_ops_get_input_jitter_buffer_offset(void *mgr, uint64_t stream_handle, uint32_t *offset)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!offset) return -EINVAL;
    *offset = mgr_ptr->alsa.mgr_callbacks->get_capture_buffer_offset(mgr_ptr->alsa.alsa_chip, stream_handle);
    return 0;
}

static int alsa_ops_get_output_jitter_buffer_offset(void *mgr, uint64_t stream_handle, uint32_t *offset)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!offset) return -EINVAL;
    *offset = mgr_ptr->alsa.mgr_callbacks->get_playback_buffer_offset(mgr_ptr->alsa.alsa_chip, stream_handle);
    return 0;
}

static int alsa_ops_get_rtp_frame_size(void *mgr, uint64_t stream_handle, uint32_t *framesize)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    struct fusion_cn_rtp_stream *stream;

    if (!framesize) return -EINVAL;
    stream = fusion_cn_rtp_get_stream(&mgr_ptr->rtp, stream_handle);
    if (!stream) return -ENOENT;
    *framesize = stream->info.samples_per_packet;
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int alsa_ops_get_jitter_buffer_sample_size(void *mgr, uint64_t stream_handle, uint8_t *sample_size)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    struct fusion_cn_rtp_stream *stream;

    if (!sample_size) return -EINVAL;
    stream = fusion_cn_rtp_get_stream(&mgr_ptr->rtp, stream_handle);
    if (!stream) return -ENOENT;
    *sample_size = snd_pcm_format_width(stream->info.format) / 8; /* Dynamic from SDP */
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int alsa_ops_get_playout_delay(void *mgr, snd_pcm_sframes_t *delay_in_sample)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr_ptr->state.playout_delay;
    return 0;
}

static int alsa_ops_get_capture_delay(void *mgr, snd_pcm_sframes_t *delay_in_sample)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr_ptr->state.capture_delay;
    return 0;
}

static int alsa_ops_start_interrupts(void *mgr, uint64_t stream_handle)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;

    stream = fusion_cn_rtp_get_stream(&mgr_ptr->rtp, stream_handle);
    if (!stream) return -ENOENT;
    spin_lock_irqsave(&mgr_ptr->rtp.lock, flags);
    stream->is_running = true;
    spin_unlock_irqrestore(&mgr_ptr->rtp.lock, flags);
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int alsa_ops_stop_interrupts(void *mgr, uint64_t stream_handle)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;

    stream = fusion_cn_rtp_get_stream(&mgr_ptr->rtp, stream_handle);
    if (!stream) return -ENOENT;
    spin_lock_irqsave(&mgr_ptr->rtp.lock, flags);
    stream->is_running = false;
    spin_unlock_irqrestore(&mgr_ptr->rtp.lock, flags);
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int alsa_ops_set_stream_params(void *mgr, uint64_t stream_handle, unsigned int rate,
                                      unsigned int channels, snd_pcm_format_t format)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!mgr_ptr->alsa.mgr_callbacks || !mgr_ptr->alsa.mgr_callbacks->set_stream_params) {
        return -ENOTSUPP;
    }
    return mgr_ptr->alsa.mgr_callbacks->set_stream_params(mgr_ptr->alsa.alsa_chip, stream_handle,
                                                          rate, channels, format);
}

const struct fusion_cn_alsa_ops fusion_cn_alsa_ops = {
    .register_alsa_driver = alsa_ops_attach_alsa_driver,
    .get_input_jitter_buffer_offset = alsa_ops_get_input_jitter_buffer_offset,
    .get_output_jitter_buffer_offset = alsa_ops_get_output_jitter_buffer_offset,
    .get_rtp_frame_size = alsa_ops_get_rtp_frame_size,
    .get_jitter_buffer_sample_size = alsa_ops_get_jitter_buffer_sample_size,
    .get_playout_delay = alsa_ops_get_playout_delay,
    .get_capture_delay = alsa_ops_get_capture_delay,
    .start_interrupts = alsa_ops_start_interrupts,
    .stop_interrupts = alsa_ops_stop_interrupts,
    .set_stream_params = alsa_ops_set_stream_params,
};

/* RTP Callbacks */
static uint64_t fusion_cn_rtp_get_sac(void *cn_mgr, uint64_t handle)
{
    struct timespec64 ts;
    ktime_get_ts64(&ts);
    return (uint64_t)(ts.tv_sec * 1000000000ULL + ts.tv_nsec); /* PHC ns */
}

static void *fusion_cn_rtp_get_buffer(void *cn_mgr, uint64_t handle, uint32_t channel_id, bool is_source)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    int32_t *buffer = is_source ? mgr->alsa.mgr_callbacks->get_capture_buffer(mgr->alsa.alsa_chip, handle) :
                                mgr->alsa.mgr_callbacks->get_playback_buffer(mgr->alsa.alsa_chip, handle);
    if (!buffer) return NULL;
    return buffer + channel_id * snd_pcm_format_width(SNDRV_PCM_FORMAT_S32_LE) / 8; /* Adjust if format varies */
}

static uint32_t fusion_cn_rtp_get_buffer_length(void *cn_mgr, uint64_t handle, bool is_source)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    return is_source ? mgr->alsa.mgr_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip, handle) :
                    mgr->alsa.mgr_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip, handle);
}

static uint32_t fusion_cn_rtp_get_buffer_offset(void *cn_mgr, uint64_t handle, uint64_t sac, bool is_source)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    return is_source ? mgr->alsa.mgr_callbacks->get_capture_buffer_offset(mgr->alsa.alsa_chip, handle) :
                    mgr->alsa.mgr_callbacks->get_playback_buffer_offset(mgr->alsa.alsa_chip, handle);
}

static uint32_t fusion_cn_rtp_get_frame_size(void *cn_mgr, uint64_t handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    struct fusion_cn_rtp_stream *stream;
    uint32_t size;

    stream = fusion_cn_rtp_get_stream(&mgr->rtp, handle);
    if (!stream) return 0;
    size = stream->info.samples_per_packet;
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return size;
}


/* Timing Functions */
static clockid_t get_phc_clockid(void)
{
    struct file *file;
    clockid_t clkid;

    file = filp_open("/dev/ptp0", O_RDONLY, 0);
    if (IS_ERR(file)) return -1; /* Invalid clock ID */
    clkid = ((~(clockid_t)(PTR_ERR(file)) << 3) | 3);
    filp_close(file, NULL);
    return clkid;
}

static void audio_frame_process(struct fusion_cn_manager *mgr)
{
    struct timespec64 phc_ts;
    uint64_t current_phc_ns;
    struct fusion_cn_rtp_stream *stream;
    unsigned long flags;
    int i;

    ktime_get_ts64(&phc_ts);
    current_phc_ns = phc_ts.tv_sec * 1000000000ULL + phc_ts.tv_nsec;

    fusion_cn_rtp_prepare_buffers(&mgr->rtp);

    spin_lock_irqsave(&mgr->rtp.lock, flags);
    for (i = 0; i < FUSION_CN_RTP_HASH_BITS; i++) {
        hlist_for_each_entry(stream, &mgr->rtp.streams[i], hnode) {
            if (!stream->is_running || !mgr->state.ptp_synchronized) continue;

            if (current_phc_ns >= stream->next_action_time) {
                if (stream->info.is_source) {
                    mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, SNDRV_PCM_STREAM_CAPTURE, stream->handle);
                    fusion_cn_rtp_send_packets(&mgr->rtp, stream, current_phc_ns);
                    stream->next_action_time = stream->last_sac + (stream->info.samples_per_packet * 1000000000ULL / stream->info.sample_rate);
                } else {
                    uint64_t playout_ts = stream->last_sac + (stream->info.playout_delay ? stream->info.playout_delay : mgr->state.playout_delay);
                    uint64_t current_samples = (current_phc_ns * stream->info.sample_rate) / 1000000000ULL;
                    if (current_samples >= playout_ts) {
                        mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, SNDRV_PCM_STREAM_PLAYBACK, stream->handle);
                        stream->next_action_time += stream->info.samples_per_packet * 1000000000ULL / stream->info.sample_rate;
                    }
                }
            }
        }
    }
    spin_unlock_irqrestore(&mgr->rtp.lock, flags);
}

static enum hrtimer_restart audio_frame_tic_hrtimer(struct hrtimer *timer)
{
    struct fusion_cn_manager *mgr = container_of(timer, struct fusion_cn_manager, ptp.audio_timer);
    static uint64_t last_check;
    static int64_t baseline_drift_ns;
    static bool first_check = true;
    ktime_t base_interval;
    uint64_t now_ns;
    struct timespec64 phc_ts, mono_ts;
    int64_t drift_ns;
    int64_t relative_drift_ns;
    int64_t adjustment_per_tick;

    audio_frame_process(mgr);

    base_interval = ns_to_ktime(100000); /* 100µs */
    now_ns = ktime_to_ns(ktime_get());
    if (now_ns - last_check > NSEC_PER_SEC) { /* 1s check */
        ktime_get_ts64(&phc_ts);
        ktime_get_raw_ts64(&mono_ts);
        drift_ns = (phc_ts.tv_sec * NSEC_PER_SEC + phc_ts.tv_nsec) -
                   (mono_ts.tv_sec * NSEC_PER_SEC + mono_ts.tv_nsec);

        if (first_check || abs64(drift_ns - baseline_drift_ns) > NSEC_PER_SEC) {
            baseline_drift_ns = drift_ns;
            first_check = false;
        } else {
            relative_drift_ns = drift_ns - baseline_drift_ns;
            if (abs64(relative_drift_ns) > 5000) { /* 5µs */
                adjustment_per_tick = relative_drift_ns / 10000;
                base_interval = ktime_add_ns(base_interval, adjustment_per_tick);
            }
        }
        last_check = now_ns;
    }

    hrtimer_forward_now(timer, base_interval);
    return HRTIMER_RESTART;
}

static irqreturn_t audio_frame_tic_gpio(int irq, void *dev_id)
{
    struct fusion_cn_manager *mgr = dev_id;
    audio_frame_process(mgr);
    return IRQ_HANDLED;
}

/* Manager Functions */
static int fusion_cn_state_init(struct fusion_cn_manager *mgr)
{
    mgr->state.is_started = false;
    mgr->state.ptp_synchronized = false;
    mgr->state.playout_delay = 0;
    mgr->state.capture_delay = 0;
    return 0;
}

static struct fusion_cn_rtp_ops rtp_ops = {
    .get_sac = fusion_cn_rtp_get_sac,
    .get_buffer = fusion_cn_rtp_get_buffer,
    .get_buffer_length = fusion_cn_rtp_get_buffer_length,
    .get_buffer_offset = fusion_cn_rtp_get_buffer_offset,
    .get_frame_size = fusion_cn_rtp_get_frame_size,
};

static int fusion_cn_alsa_init(struct fusion_cn_manager *mgr)
{
    mgr->alsa.alsa_chip = NULL;
    mgr->alsa.mgr_callbacks = NULL;
    mgr->alsa.alsa_callbacks = &fusion_cn_alsa_ops;
    return fusion_cn_alsa_init_(mgr, &fusion_cn_alsa_ops);
}

static int fusion_cn_ptp_init(struct fusion_cn_manager *mgr)
{
    mgr->ptp.phc_clockid = get_phc_clockid();
    if (mgr->ptp.phc_clockid == -1) {
        printk(KERN_ERR "fusion_cn: Failed to get PHC clock ID\n");
        return -EINVAL;
    }

    if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT) {
        int err;
        if (mgr->ptp.gpio_pin < 0 || !gpio_is_valid(mgr->ptp.gpio_pin)) {
            printk(KERN_ERR "fusion_cn: Invalid GPIO pin %d\n", mgr->ptp.gpio_pin);
            return -EINVAL;
        }
        err = gpio_request(mgr->ptp.gpio_pin, "fusion_cn_ptp_interrupt");
        if (err < 0) return err;
        err = gpio_direction_input(mgr->ptp.gpio_pin);
        if (err < 0) {
            gpio_free(mgr->ptp.gpio_pin);
            return err;
        }
        mgr->ptp.gpio_irq = gpio_to_irq(mgr->ptp.gpio_pin);
        if (mgr->ptp.gpio_irq < 0) {
            gpio_free(mgr->ptp.gpio_pin);
            return mgr->ptp.gpio_irq;
        }
        err = request_irq(mgr->ptp.gpio_irq, audio_frame_tic_gpio, IRQF_TRIGGER_RISING,
                        "fusion_cn_ptp_interrupt", mgr);
        if (err < 0) {
            gpio_free(mgr->ptp.gpio_pin);
            return err;
        }
        disable_irq(mgr->ptp.gpio_irq);
    } else {
        mgr->ptp.ptp_timing_mode = TIMING_HRTIMER;
        hrtimer_init(&mgr->ptp.audio_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
        mgr->ptp.audio_timer.function = audio_frame_tic_hrtimer;
        mgr->ptp.gpio_irq = -1;
        mgr->ptp.gpio_pin = -1;
    }
    printk(KERN_INFO "fusion_cn: Initialized with %s timing\n",
        mgr->ptp.ptp_timing_mode == TIMING_HRTIMER ? "hrtimer" : "GPIO interrupt");
    return 0;
}

// proto for nl_init
static void fusion_cn_nl_recv_msg(struct sk_buff *);

static int fusion_cn_nl_init(struct fusion_cn_manager *mgr)
{
    struct netlink_kernel_cfg cfg = { .input = fusion_cn_nl_recv_msg };
    mgr->netlink.nl_family = NETLINK_USERSOCK;
    mgr->netlink.nl_sock = netlink_kernel_create(&init_net, mgr->netlink.nl_family, &cfg);
    if (!mgr->netlink.nl_sock) {
        printk(KERN_ERR "fusion_cn: Failed to create netlink socket\n");
        return -ENOMEM;
    }
    mgr->netlink.nl_sock->sk_user_data = mgr;
    return 0;
}

void fusion_cn_nl_destroy(struct fusion_cn_manager *mgr)
{
    if (mgr->netlink.nl_sock) {
        netlink_kernel_release(mgr->netlink.nl_sock);
    }
}

int fusion_cn_mgr_init(struct fusion_cn_manager *mgr)
{
    int err;
    if (!mgr) return -EINVAL;

    if ((err = fusion_cn_state_init(mgr)) < 0) return err;
    if ((err = fusion_cn_nf_init(&mgr->rtp)) < 0) return err;
    if ((err = fusion_cn_rtp_init(&mgr->rtp, &mgr->netfilter, &rtp_ops, mgr)) < 0) goto err_nf;    
    if ((err = fusion_cn_alsa_init(mgr)) < 0) goto err_rtp;
    if ((err = fusion_cn_nl_init(mgr)) < 0) goto err_alsa;
    if ((err = fusion_cn_ptp_init(mgr)) < 0) goto err_nl;

    return 0;

err_nl:
    fusion_cn_nl_destroy(mgr);
err_alsa:
    fusion_cn_card_exit();
err_rtp:
    fusion_cn_rtp_destroy(&mgr->rtp);
err_nf:
    fusion_cn_nf_destroy(&mgr->netfilter);
    return err;
}

void fusion_cn_mgr_destroy(struct fusion_cn_manager *mgr)
{
    if (!mgr) return;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        free_irq(mgr->ptp.gpio_irq, mgr);
        if (gpio_is_valid(mgr->ptp.gpio_pin)) gpio_free(mgr->ptp.gpio_pin);
    }
    fusion_cn_nl_destroy(mgr);
    fusion_cn_card_exit();
    fusion_cn_rtp_destroy(&mgr->rtp);
    fusion_cn_nf_destroy(&mgr->netfilter);
}

bool fusion_cn_mgr_start(struct fusion_cn_manager *mgr)
{
    if (!mgr || mgr->state.is_started) return false;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_start(&mgr->ptp.audio_timer, ns_to_ktime(100000), HRTIMER_MODE_REL);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        enable_irq(mgr->ptp.gpio_irq);
    } else {
        printk(KERN_ERR "fusion_cn: Invalid timing mode or GPIO not configured\n");
        return false;
    }

    mgr->netfilter.is_enabled = true;
    mgr->state.is_started = true;
    
    return true;
}

bool fusion_cn_mgr_stop(struct fusion_cn_manager *mgr)
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
static int handle_start(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                        struct fusion_cn_ctrl_msg *reply)
{
    printk(KERN_INFO "fusion_cn: Starting manager\n");
    reply->err = fusion_cn_mgr_start(mgr) ? 0 : -EIO;
    return 0;
}

static int handle_stop(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                    struct fusion_cn_ctrl_msg *reply)
{
    printk(KERN_INFO "fusion_cn: Stopping manager\n");
    reply->err = fusion_cn_mgr_stop(mgr) ? 0 : -EIO;
    return 0;
}

static int handle_start_io(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                           struct fusion_cn_ctrl_msg *reply)
{
    uint64_t stream_handle;

    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    stream_handle = *(uint64_t *)msg->data;
    printk(KERN_INFO "fusion_cn: Starting IO for stream %llu\n", stream_handle);

    /* Mute all buffers before starting I/O to prevent pops */
    fusion_cn_mute_buffers(mgr);

    reply->err = alsa_ops_start_interrupts(mgr, stream_handle);
    return 0;
}

static int handle_stop_io(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                          struct fusion_cn_ctrl_msg *reply)
{
    uint64_t stream_handle;

    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    stream_handle = *(uint64_t *)msg->data;
    printk(KERN_INFO "fusion_cn: Stopping IO for stream %llu\n", stream_handle);

    /* Mute all buffers before stopping I/O to prevent pops */
    fusion_cn_mute_buffers(mgr);

    reply->err = alsa_ops_stop_interrupts(mgr, stream_handle);
    return 0;
}

static int handle_add_rtp_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                 struct fusion_cn_ctrl_msg *reply)
{
    struct fusion_cn_stream_config *config;
    bool restart_required;
    struct fusion_cn_rtp_stream_info rtp_info;
    uint64_t handle;
    int ret;

    if (msg->data_size != sizeof(struct fusion_cn_stream_config)) return reply->err = -EINVAL;

    config = (struct fusion_cn_stream_config *)msg->data;
    restart_required = mgr->state.is_started;

    if (config->sample_rate == 0 || config->channels == 0 || config->samples_per_packet == 0 ||
        config->stream_handle == 0) {
        return reply->err = -EINVAL;
    }

    if (restart_required) fusion_cn_mgr_stop(mgr);

    rtp_info.sample_rate = config->sample_rate;
    rtp_info.format = config->format;
    rtp_info.channels = config->channels;
    rtp_info.samples_per_packet = config->samples_per_packet;
    rtp_info.dest_ip = config->dest_ip;
    rtp_info.dest_port = config->dest_port;
    rtp_info.rtcp_dest_port = config->rtcp_dest_port;
    rtp_info.payload_type = config->payload_type;
    rtp_info.playout_delay = config->playout_delay;
    rtp_info.is_source = config->is_source;
    strscpy(rtp_info.name, config->name, MAX_STREAM_NAME_SIZE); /* Safer than strlcpy */

    ret = fusion_cn_rtp_add_stream(&mgr->rtp, &rtp_info, &handle);
    if (ret < 0) {
        if (restart_required) fusion_cn_mgr_start(mgr);
        return reply->err = ret;
    }

    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->open_substream) {
        ret = mgr->alsa.mgr_callbacks->open_substream(mgr->alsa.alsa_chip, handle,
                                                    config->is_source ? SNDRV_PCM_STREAM_CAPTURE : SNDRV_PCM_STREAM_PLAYBACK,
                                                    config->channels, config->format);
        if (ret < 0) {
            fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
            if (restart_required) fusion_cn_mgr_start(mgr);
            return reply->err = ret;
        }
    }

    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->set_stream_params) {
        ret = mgr->alsa.mgr_callbacks->set_stream_params(mgr->alsa.alsa_chip, handle,
                                                        config->sample_rate, config->channels, config->format);
        if (ret < 0) {
            fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
            if (restart_required) fusion_cn_mgr_start(mgr);
            return reply->err = ret;
        }
    }

    if (restart_required && !fusion_cn_mgr_start(mgr)) {
        fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
        return reply->err = -EIO;
    }

    reply->err = 0;
    reply->data_size = sizeof(uint64_t);
    reply->data = kmemdup(&handle, sizeof(handle), GFP_KERNEL);
    if (!reply->data) reply->err = -ENOMEM;
    return 0;
}

static int handle_remove_rtp_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                    struct fusion_cn_ctrl_msg *reply)
{
    uint64_t handle;
    bool restart_required;
    int ret;

    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    handle = *(uint64_t *)msg->data;
    restart_required = mgr->state.is_started;

    if (restart_required) fusion_cn_mgr_stop(mgr);
    ret = fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
    if (ret < 0) {
        if (restart_required) fusion_cn_mgr_start(mgr);
        return reply->err = ret;
    }

    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->remove_substream) {
        ret = mgr->alsa.mgr_callbacks->remove_substream(mgr->alsa.alsa_chip, handle);
        if (ret < 0) {
            if (restart_required) fusion_cn_mgr_start(mgr);
            return reply->err = ret;
        }
    }

    if (restart_required) fusion_cn_mgr_start(mgr);
    return reply->err = 0;
}

static int handle_update_rtp_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                    struct fusion_cn_ctrl_msg *reply)
{
    struct fusion_cn_stream_config *config;
    bool restart_required;
    struct fusion_cn_rtp_stream *stream;
    struct fusion_cn_rtp_stream_info rtp_info;
    unsigned long flags;
    int ret;

    if (msg->data_size != sizeof(struct fusion_cn_stream_config)) return reply->err = -EINVAL;
    config = (struct fusion_cn_stream_config *)msg->data;
    restart_required = mgr->state.is_started;

    stream = fusion_cn_rtp_get_stream(&mgr->rtp, config->stream_handle);
    if (!stream) return reply->err = -ENOENT;

    if (restart_required) fusion_cn_mgr_stop(mgr);

    /* Mute the specific stream’s buffer before updating to prevent audio artifacts */
    ret = fusion_cn_mute_stream_buffer(mgr, config->stream_handle);
    if (ret < 0) {
        printk(KERN_WARNING "fusion_cn: Failed to mute stream %llu during update: %d\n",
               config->stream_handle, ret);
        /* Proceed with the update despite the failure to mute */
    }

    rtp_info.sample_rate = config->sample_rate;
    rtp_info.format = config->format;
    rtp_info.channels = config->channels;
    rtp_info.samples_per_packet = config->samples_per_packet;
    rtp_info.dest_ip = config->dest_ip;
    rtp_info.dest_port = config->dest_port;
    rtp_info.rtcp_dest_port = config->rtcp_dest_port;
    rtp_info.payload_type = config->payload_type;
    rtp_info.playout_delay = config->playout_delay;
    rtp_info.is_source = config->is_source;
    strscpy(rtp_info.name, config->name, MAX_STREAM_NAME_SIZE);

    spin_lock_irqsave(&mgr->rtp.lock, flags);
    stream->info = rtp_info; /* Update in-place */
    spin_unlock_irqrestore(&mgr->rtp.lock, flags);

    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->set_stream_params) {
        ret = mgr->alsa.mgr_callbacks->set_stream_params(mgr->alsa.alsa_chip, config->stream_handle,
                                                        config->sample_rate, config->channels, config->format);
        if (ret < 0) {
            if (restart_required) fusion_cn_mgr_start(mgr);
            kref_put(&stream->ref, fusion_cn_rtp_stream_release);
            return reply->err = ret;
        }
    }

    if (restart_required) fusion_cn_mgr_start(mgr);
    reply->err = 0;
    reply->data_size = sizeof(uint64_t);
    reply->data = kmemdup(&config->stream_handle, sizeof(config->stream_handle), GFP_KERNEL);
    if (!reply->data) reply->err = -ENOMEM;
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int handle_set_playout_delay(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                    struct fusion_cn_ctrl_msg *reply)
{
    int32_t delay;

    if (msg->data_size != sizeof(int32_t)) return reply->err = -EINVAL;
    delay = *(int32_t *)msg->data;
    mgr->state.playout_delay = delay;
    return reply->err = 0;
}

static int handle_set_capture_delay(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                    struct fusion_cn_ctrl_msg *reply)
{
    int32_t delay;

    if (msg->data_size != sizeof(int32_t)) return reply->err = -EINVAL;
    delay = *(int32_t *)msg->data;
    mgr->state.capture_delay = delay;
    return reply->err = 0;
}

static const struct message_handler_entry message_handlers[] = {
    { FUSION_CN_CTRL_CMD_START, handle_start },
    { FUSION_CN_CTRL_CMD_STOP, handle_stop },
    { FUSION_CN_CTRL_CMD_START_IO, handle_start_io },
    { FUSION_CN_CTRL_CMD_STOP_IO, handle_stop_io },
    { FUSION_CN_CTRL_CMD_ADD_RTP_STREAM, handle_add_rtp_stream },
    { FUSION_CN_CTRL_CMD_REMOVE_RTP_STREAM, handle_remove_rtp_stream },
    { FUSION_CN_CTRL_CMD_UPDATE_RTP_STREAM, handle_update_rtp_stream },
    { FUSION_CN_CTRL_CMD_SET_PLAYOUT_DELAY, handle_set_playout_delay },
    { FUSION_CN_CTRL_CMD_SET_CAPTURE_DELAY, handle_set_capture_delay },
    { 0, NULL }
};

/* Netlink Functions */
static void fusion_cn_nl_send_msg(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *reply)
{
    struct sk_buff *skb;
    struct nlmsghdr *nlh;
    int msg_size = sizeof(*reply) + reply->data_size;

    if (!mgr || !mgr->netlink.nl_sock) return;

    skb = nlmsg_new(msg_size, GFP_KERNEL);
    if (!skb) {
        printk(KERN_ERR "fusion_cn: Failed to allocate netlink skb\n");
        goto out_free_data;
    }

    nlh = nlmsg_put(skb, 0, 0, NLMSG_DONE, msg_size, 0);
    if (!nlh) {
        kfree_skb(skb);
        goto out_free_data;
    }

    memcpy(nlmsg_data(nlh), reply, sizeof(*reply));
    if (reply->data_size && reply->data) {
        memcpy(nlmsg_data(nlh) + sizeof(*reply), reply->data, reply->data_size);
    }

    if (netlink_unicast(mgr->netlink.nl_sock, skb, reply->pid, MSG_DONTWAIT) < 0) {
        printk(KERN_ERR "fusion_cn: Failed to send netlink reply\n");
        kfree_skb(skb);
    }

out_free_data:
    if (reply->data) kfree(reply->data); /* Caller must set to NULL if not owned */
}

static void fusion_cn_process_nl_msg(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg_rcv)
{
    struct fusion_cn_ctrl_msg msg_reply = {
        .cmd = msg_rcv ? msg_rcv->cmd : 0,
        .err = -ENOENT,
        .data_size = 0,
        .data = NULL,
        .pid = msg_rcv ? msg_rcv->pid : 0
    };
    const struct message_handler_entry *entry;

    if (!mgr || !msg_rcv) return;

    entry = message_handlers;
    while (entry->cmd) {
        if (entry->cmd == msg_rcv->cmd) {
            entry->handler(mgr, msg_rcv, &msg_reply);
            break;
        }
        entry++;
    }
    fusion_cn_nl_send_msg(mgr, &msg_reply);
}

static void fusion_cn_nl_recv_msg(struct sk_buff *skb)
{
    struct fusion_cn_manager *mgr = skb->sk->sk_user_data;
    struct nlmsghdr *nlh;
    struct fusion_cn_ctrl_msg msg_rcv;

    if (!mgr) return;

    nlh = nlmsg_hdr(skb);
    if (nlh->nlmsg_len < NLMSG_HDRLEN + sizeof(msg_rcv)) {
        printk(KERN_ERR "fusion_cn: Netlink message too short\n");
        return;
    }

    memcpy(&msg_rcv, nlmsg_data(nlh), sizeof(msg_rcv));
    msg_rcv.pid = nlh->nlmsg_pid;
    fusion_cn_process_nl_msg(mgr, &msg_rcv);
}

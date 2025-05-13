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

#define TIMER_BASE_INTERVAL_NS 333333
#define BOUNDARY_INTERVAL_NS   1000000

/* ALSA Callbacks */
static int alsa_ops_attach_alsa_driver(void *mgr, const struct fusion_cn_mgr_ops *ops, void *alsa_chip)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    if (!ops || !alsa_chip) return -EINVAL;
    mgr_ptr->alsa.alsa_chip = alsa_chip;
    mgr_ptr->alsa.mgr_callbacks = ops;
    return 0;
}

static int alsa_ops_get_rtp_frame_size(void *mgr, uint64_t stream_handle, uint32_t *framesize)
{
    struct fusion_cn_manager *mgr_ptr = mgr;
    struct fusion_cn_rtp_stream *stream;

    if (!framesize) {
        printk(KERN_ERR "fusion_cn: get_rtp_frame_size: NULL framesize pointer\n");
        return -EINVAL;
    }
    stream = fusion_cn_rtp_get_stream(&mgr_ptr->rtp, stream_handle);
    if (!stream) {
        printk(KERN_ERR "fusion_cn: get_rtp_frame_size: Stream %llu not found in RTP manager\n", stream_handle);
        return -ENOENT;
    }
    *framesize = stream->info.frames_per_packet;
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return 0;
}

static int alsa_ops_start_interrupts(void *mgr, uint64_t stream_handle)
{
    struct fusion_cn_manager *mgr_ptr = mgr;

    if (!mgr_ptr || !mgr_ptr->rtp.cn_mgr) {
        printk(KERN_ERR "fusion_cn: start_interrupts: Invalid manager or uninitialized RTP for stream %llu\n", stream_handle);
        return -EINVAL;
    }

    printk(KERN_DEBUG "fusion_cn: start_interrupts: Starting stream %llu, rtp_mgr=%p\n", stream_handle, &mgr_ptr->rtp);
    return fusion_cn_rtp_set_stream_running(&mgr_ptr->rtp, stream_handle, true);
}

static int alsa_ops_stop_interrupts(void *mgr, uint64_t stream_handle)
{
    struct fusion_cn_manager *mgr_ptr = mgr;

    if (!mgr_ptr || !mgr_ptr->rtp.cn_mgr) {
        printk(KERN_ERR "fusion_cn: stop_interrupts: Invalid manager or uninitialized RTP for stream %llu\n", stream_handle);
        return -EINVAL;
    }

    printk(KERN_DEBUG "fusion_cn: stop_interrupts: Stopping stream %llu, rtp_mgr=%p\n", stream_handle, &mgr_ptr->rtp);
    return fusion_cn_rtp_set_stream_running(&mgr_ptr->rtp, stream_handle, false);
}

const struct fusion_cn_alsa_ops fusion_cn_alsa_ops = {
    .register_alsa_driver = alsa_ops_attach_alsa_driver,
    .get_rtp_frame_size = alsa_ops_get_rtp_frame_size,
    .start_interrupts = alsa_ops_start_interrupts,
    .stop_interrupts = alsa_ops_stop_interrupts
};

/* RTP Callbacks */
static uint64_t fusion_cn_rtp_get_phc_ns(void)
{
    struct timespec64 ts;

    // Use system clock disciplined by phc2sys
    ktime_get_real_ts64(&ts);
    return (uint64_t)(ts.tv_sec * NSEC_PER_SEC + ts.tv_nsec);
}

static void *fusion_cn_rtp_get_buffer(void *cn_mgr, uint64_t handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    int32_t *buffer = mgr->alsa.mgr_callbacks->get_stream_buffer(mgr->alsa.alsa_chip, handle);
    if (!buffer) return NULL;
    return buffer;
}

static uint32_t fusion_cn_rtp_get_buffer_length(void *cn_mgr, uint64_t handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    return mgr->alsa.mgr_callbacks->get_stream_buffer_size_in_frames(mgr->alsa.alsa_chip, handle);
}

static uint32_t fusion_cn_rtp_get_buffer_offset(void *cn_mgr, uint64_t handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    return mgr->alsa.mgr_callbacks->get_stream_buffer_offset(mgr->alsa.alsa_chip, handle);
}

static uint32_t fusion_cn_rtp_get_avail_frames(void *cn_mgr, uint64_t handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    struct fusion_cn_rtp_stream *stream;
    uint32_t size;

    stream = fusion_cn_rtp_get_stream(&mgr->rtp, handle);
    if (!stream) return 0;
    size = mgr->alsa.mgr_callbacks->get_stream_available_frames(mgr->alsa.alsa_chip, handle);
    kref_put(&stream->ref, fusion_cn_rtp_stream_release);
    return size;
}

static void audio_frame_process(struct fusion_cn_manager *mgr)
{
    uint64_t current_phc_ns;
    struct fusion_cn_rtp_stream *stream;
    struct handle_node *handle_node, *tmp;
    uint64_t handle;
    unsigned long flags;
    uint32_t current_slot;

    current_phc_ns = fusion_cn_rtp_get_phc_ns();
    if (current_phc_ns == 0) {
        printk(KERN_ERR "fusion_cn: audio_frame_process: Failed to get PHC time\n");
        return;
    }

    printk(KERN_DEBUG "fusion_cn: audio_frame_process: current_phc_ns=%llu\n", current_phc_ns);

    read_lock_irqsave(&mgr->rtp.lock, flags);
    list_for_each_entry_safe(handle_node, tmp, &mgr->rtp.active_streams, node) {
        handle = handle_node->handle;
        hlist_for_each_entry(stream, &mgr->rtp.streams[hash_64(handle, FUSION_CN_RTP_HASH_BITS)], hnode) {
            spin_lock(&stream->lock);
            if (!atomic_read(&stream->is_running) || !mgr->state.ptp_synchronized) {
                spin_unlock(&stream->lock);
                continue;
            }

            if (stream->info.is_source) {
                if (current_phc_ns >= stream->next_action_time) {
                    fusion_cn_rtp_send_packet(&mgr->rtp, stream);
                    mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, SNDRV_PCM_STREAM_PLAYBACK, stream->info.stream_handle);

                    printk(KERN_DEBUG "fusion_cn: audio_frame_process: Source stream %llu, next_action_time=%llu\n",
                        stream->info.stream_handle, stream->next_action_time);
            
                    // Increment next_action_time by packet duration (e.g., 1 ms for 48 samples at 48 kHz)
                    if (stream->next_action_time == 0) {
                        // Align to the next 1 ms boundary
                        uint64_t interval = (stream->info.frames_per_packet * NSEC_PER_SEC) / stream->info.sample_rate;
                        stream->next_action_time = current_phc_ns - (current_phc_ns % interval) + interval;
                    }
                    stream->next_action_time += (stream->info.frames_per_packet * NSEC_PER_SEC) / stream->info.sample_rate;
                }
            } else {
                current_slot = stream->playback_index % FUSION_CN_RTP_BUFFER_FRAMES;
                if (stream->next_action_times[current_slot] != 0 && current_phc_ns >= stream->next_action_times[current_slot]) {
                    printk(KERN_DEBUG "fusion_cn: audio_frame_process: Sink stream %llu, next_action_time=%llu\n",
                        stream->info.stream_handle, stream->next_action_times[current_slot]);
                    // Trigger pcm_interrupt to advance hw_ptr and signal user-space
                    mgr->alsa.mgr_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, SNDRV_PCM_STREAM_CAPTURE, stream->info.stream_handle);
                    stream->playback_index++;
                }
            }
            spin_unlock(&stream->lock);
        }
    }
    read_unlock_irqrestore(&mgr->rtp.lock, flags);
}

static enum hrtimer_restart audio_frame_tick_hrtimer(struct hrtimer *timer)
{
    struct fusion_cn_manager *mgr = container_of(timer, struct fusion_cn_manager, ptp.audio_timer);
    static uint64_t last_check;
    static int64_t baseline_drift_ns;
    static bool first_check = true;
    static uint64_t tick_count = 0;
    ktime_t base_interval;
    uint64_t now_ns;
    uint64_t phc_ns;
    struct timespec64 mono_ts;
    int64_t drift_ns;
    int64_t relative_drift_ns;
    int64_t adjustment_per_tick = 0;

    audio_frame_process(mgr);

    base_interval = ns_to_ktime(TIMER_BASE_INTERVAL_NS);
    now_ns = ktime_to_ns(ktime_get());

    // Align every third tick to 1 ms boundary
    if (tick_count % 3 == 0) {
        phc_ns = fusion_cn_rtp_get_phc_ns();
        if (phc_ns != 0) {
            uint64_t boundary = phc_ns - (phc_ns % BOUNDARY_INTERVAL_NS) + BOUNDARY_INTERVAL_NS;
            int64_t adjust = boundary - (now_ns + 3 * TIMER_BASE_INTERVAL_NS);
            if (adjust > -10000 && adjust < 10000) { // Limit to ±10 µs
                adjustment_per_tick += adjust / 3; // Spread over 3 ticks
                printk(KERN_DEBUG "fusion_cn: audio_frame_tick_hrtimer: Boundary adjustment=%lld ns\n", adjust);
            }
        }
    }

    // Drift correction every 100 ms
    if (now_ns - last_check > 100000000ULL) {
        phc_ns = fusion_cn_rtp_get_phc_ns();
        if (phc_ns == 0) {
            printk(KERN_ERR "fusion_cn: audio_frame_tick_hrtimer: Failed to get PHC time\n");
            last_check = now_ns;
            hrtimer_forward_now(timer, base_interval);
            return HRTIMER_RESTART;
        }

        ktime_get_raw_ts64(&mono_ts);
        drift_ns = phc_ns - (mono_ts.tv_sec * NSEC_PER_SEC + mono_ts.tv_nsec);

        if (first_check || abs64(drift_ns - baseline_drift_ns) > NSEC_PER_SEC) {
            baseline_drift_ns = drift_ns;
            first_check = false;
        } else {
            relative_drift_ns = drift_ns - baseline_drift_ns;
            if (abs64(relative_drift_ns) > 1000) {
                adjustment_per_tick += relative_drift_ns / 1000;
                printk(KERN_DEBUG "fusion_cn: audio_frame_tick_hrtimer: Drift correction=%lld ns\n", relative_drift_ns);
            }
        }
        last_check = now_ns;
    }

    // Apply combined adjustment
    if (adjustment_per_tick != 0) {
        base_interval = ktime_add_ns(base_interval, adjustment_per_tick);
    }

    hrtimer_forward_now(timer, base_interval);
    tick_count++;
    return HRTIMER_RESTART;
}

static irqreturn_t audio_frame_tick_gpio(int irq, void *dev_id)
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
    return 0;
}

static struct fusion_cn_rtp_ops rtp_ops = {
    .get_phc_ns = fusion_cn_rtp_get_phc_ns,
    .get_buffer = fusion_cn_rtp_get_buffer,
    .get_buffer_length = fusion_cn_rtp_get_buffer_length,
    .get_buffer_offset = fusion_cn_rtp_get_buffer_offset,
    .get_avail_frames = fusion_cn_rtp_get_avail_frames
};

static int fusion_cn_alsa_init(struct fusion_cn_manager *mgr)
{
    mgr->alsa.alsa_callbacks = &fusion_cn_alsa_ops;
    return fusion_cn_alsa_init_(mgr, &fusion_cn_alsa_ops);
}


static int fusion_cn_ptp_init(struct fusion_cn_manager *mgr)
{
    if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT) {
        int err;
        if (mgr->ptp.gpio_pin < 0 || !gpio_is_valid(mgr->ptp.gpio_pin)) {
            printk(KERN_ERR "fusion_cn: Invalid GPIO pin %d\n", mgr->ptp.gpio_pin);
            return -EINVAL;
        }
        err = gpio_request(mgr->ptp.gpio_pin, "fusion_cn_ptp_interrupt");
        if (err < 0) {
            return err;
        }
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
        err = request_irq(mgr->ptp.gpio_irq, audio_frame_tick_gpio, IRQF_TRIGGER_RISING,
                          "fusion_cn_ptp_interrupt", mgr);
        if (err < 0) {
            gpio_free(mgr->ptp.gpio_pin);
            return err;
        }
        disable_irq(mgr->ptp.gpio_irq);
    } else {
        mgr->ptp.ptp_timing_mode = TIMING_HRTIMER;
        hrtimer_init(&mgr->ptp.audio_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
        mgr->ptp.audio_timer.function = audio_frame_tick_hrtimer;
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

    if ((err = fusion_cn_state_init(mgr)) < 0) return err;
    if ((err = fusion_cn_alsa_init(mgr)) < 0) return err;
    if ((err = fusion_cn_rtp_init(&mgr->rtp, &mgr->netfilter, &rtp_ops, mgr)) < 0) goto err_rtp;
    if ((err = fusion_cn_nf_init(&mgr->rtp)) < 0) goto err_nf;
    if ((err = fusion_cn_nl_init(mgr)) < 0) goto err_nl;
    if ((err = fusion_cn_ptp_init(mgr)) < 0) goto err_init;

    return 0;

err_init:
    fusion_cn_nl_destroy(mgr);
err_nl:
    fusion_cn_nf_destroy(&mgr->netfilter);
err_nf:
    fusion_cn_rtp_destroy(&mgr->rtp);
err_rtp:
    return err;
}

void fusion_cn_mgr_destroy(struct fusion_cn_manager *mgr)
{
    if (!mgr) return;

    /* Stop netlink communication first to prevent new commands */
    fusion_cn_nl_destroy(mgr);

    /* Stop RTP streams, which might be using ALSA buffers */
    fusion_cn_rtp_destroy(&mgr->rtp);

    /* Stop PTP timing to prevent further audio frame processing */
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        free_irq(mgr->ptp.gpio_irq, mgr);
        if (gpio_is_valid(mgr->ptp.gpio_pin)) gpio_free(mgr->ptp.gpio_pin);
    }

    /* Unregister netfilter hook to stop packet processing */
    fusion_cn_nf_destroy(&mgr->netfilter);

    /* Finally, clean up the ALSA card */
    fusion_cn_alsa_destroy();

    /* Clear the RTP manager to prevent use-after-free */
    memset(&mgr->rtp, 0, sizeof(mgr->rtp));
}

bool fusion_cn_mgr_start(struct fusion_cn_manager *mgr)
{
    if (!mgr || mgr->state.is_started) {
        printk(KERN_ERR "fusion_cn: bad mgr ptr or mgr already started\n");
        return false;
    }

    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        uint64_t current_phc_ns;
        uint64_t offset_to_next_boundary;
        ktime_t initial_delay;

        // Get current PHC time
        current_phc_ns = fusion_cn_rtp_get_phc_ns();
        if (current_phc_ns == 0) {
            printk(KERN_ERR "fusion_cn: mgr_start: Failed to get PHC time\n");
            return false;
        }

        // Compute offset to the next tick boundary (333,333 ns)
        offset_to_next_boundary = TIMER_BASE_INTERVAL_NS - (current_phc_ns % TIMER_BASE_INTERVAL_NS);
        initial_delay = ns_to_ktime(offset_to_next_boundary);

        // Start hrtimer with initial delay to align with boundary
        hrtimer_start(&mgr->ptp.audio_timer, initial_delay, HRTIMER_MODE_REL);
        printk(KERN_INFO "fusion_cn: mgr_start: Aligned hrtimer to PHC boundary, initial delay=%llu ns\n",
               offset_to_next_boundary);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPIO_INTERRUPT && mgr->ptp.gpio_irq >= 0) {
        enable_irq(mgr->ptp.gpio_irq);
    } else {
        printk(KERN_ERR "fusion_cn: Invalid timing mode or GPIO not configured\n");
        return false;
    }

    mgr->netfilter.is_enabled = true;
    mgr->state.is_started = true;
    mgr->state.ptp_synchronized = true; /* Enable audio_frame_process */
    printk(KERN_INFO "fusion_cn: mgr_start: Started manager, ptp_synchronized=%d\n",
           mgr->state.ptp_synchronized);
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

static int handle_add_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                 struct fusion_cn_ctrl_msg *reply)
{
    struct fusion_cn_stream_config *config;
    struct fusion_cn_rtp_stream *stream;
    uint64_t handle;
    int ret;
    int direction;
    int bucket;
    unsigned long flags;

    if (msg->data_size != sizeof(struct fusion_cn_stream_config)) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: Invalid data size: %u, expected %zu\n",
               msg->data_size, sizeof(struct fusion_cn_stream_config));
        return reply->err = -EINVAL;
    }
    config = (struct fusion_cn_stream_config *)msg->data;

    if (!mgr->alsa.alsa_chip) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: ALSA chip is NULL\n");
        return reply->err = -EINVAL;
    }

    /* Generate a handle if the user passed 0 */
    if (config->stream_handle == 0) {
        do {
            get_random_bytes(&config->stream_handle, sizeof(config->stream_handle));
            if (config->stream_handle == 0) continue;
            bucket = hash_64(config->stream_handle, FUSION_CN_RTP_HASH_BITS);
            read_lock_irqsave(&mgr->rtp.lock, flags);
            hlist_for_each_entry(stream, &mgr->rtp.streams[bucket], hnode) {
                if (stream->info.stream_handle == config->stream_handle) {
                    config->stream_handle = 0;
                    break;
                }
            }
            read_unlock_irqrestore(&mgr->rtp.lock, flags);
        } while (config->stream_handle == 0);
    } else {
        bucket = hash_64(config->stream_handle, FUSION_CN_RTP_HASH_BITS);
        read_lock_irqsave(&mgr->rtp.lock, flags);
        hlist_for_each_entry(stream, &mgr->rtp.streams[bucket], hnode) {
            if (stream->info.stream_handle == config->stream_handle) {
                read_unlock_irqrestore(&mgr->rtp.lock, flags);
                printk(KERN_ERR "fusion_cn: handle_add_stream: Stream handle %llu already exists\n", config->stream_handle);
                return reply->err = -EEXIST;
            }
        }
        read_unlock_irqrestore(&mgr->rtp.lock, flags);
    }

    printk(KERN_INFO "fusion_cn: handle_add_stream: Calling fusion_cn_rtp_add_stream with handle %llu\n", config->stream_handle);
    ret = fusion_cn_rtp_add_stream(&mgr->rtp, config, &handle);
    if (ret < 0) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: fusion_cn_rtp_add_stream failed: %d\n", ret);
        return reply->err = ret;
    }

    if (handle != config->stream_handle) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: Handle mismatch: expected %llu, got %llu\n",
               config->stream_handle, handle);
        fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
        return reply->err = -EINVAL;
    }

    /* for rtp source we have alsa playback and vice versa */
    direction = config->is_source ? SNDRV_PCM_STREAM_PLAYBACK : SNDRV_PCM_STREAM_CAPTURE;
    printk(KERN_INFO "fusion_cn: handle_add_stream: Calling open_substream\n");
    ret = mgr->alsa.mgr_callbacks->open_substream(mgr->alsa.alsa_chip, handle, direction,
                                                  config->channels, config->sample_rate, config->format);
    if (ret < 0) {
        fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
        printk(KERN_ERR "fusion_cn: handle_add_stream: open_substream failed: %d\n", ret);
        return reply->err = ret;
    }

    reply->err = 0;
    reply->data_size = sizeof(uint64_t);
    reply->data = kmemdup(&handle, sizeof(handle), GFP_KERNEL);
    if (!reply->data) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: kmemdup failed\n");
        reply->err = -ENOMEM;
    }

    printk(KERN_INFO "fusion_cn: handle_add_stream: Success, handle=%llu\n", handle);
    return 0;
}

static int handle_remove_rtp_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                                    struct fusion_cn_ctrl_msg *reply)
{
    uint64_t handle;
    int ret;

    if (msg->data_size != sizeof(uint64_t)) return reply->err = -EINVAL;
    handle = *(uint64_t *)msg->data;

    ret = fusion_cn_rtp_remove_stream(&mgr->rtp, handle);
    if (ret < 0) {
        return reply->err = ret;
    }

    if (mgr->alsa.mgr_callbacks && mgr->alsa.mgr_callbacks->remove_substream) {
        ret = mgr->alsa.mgr_callbacks->remove_substream(mgr->alsa.alsa_chip, handle);
        if (ret < 0) {
            return reply->err = ret;
        }
    }

    return reply->err = 0;
}

static const struct message_handler_entry message_handlers[] = {
    { FUSION_CN_CTRL_CMD_START_MANAGER, handle_start },
    { FUSION_CN_CTRL_CMD_STOP_MANAGER, handle_stop },
    { FUSION_CN_CTRL_CMD_ADD_STREAM, handle_add_stream },
    { FUSION_CN_CTRL_CMD_REMOVE_STREAM, handle_remove_rtp_stream },
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

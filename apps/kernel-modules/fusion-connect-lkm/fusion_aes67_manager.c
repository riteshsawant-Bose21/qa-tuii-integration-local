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

#include "fusion_aes67_manager.h"
#include "fusion_aes67_netfilter.h"

/* Helper Functions */
static inline uint32_t min(uint32_t a, uint32_t b) {
    return (a < b) ? a : b;
}

static uint8_t get_alsa_sample_size(struct fusion_aes67_manager *mgr) 
{
    return 4; /* 32-bit PCM */
}

void update_frame_size(struct fusion_aes67_manager *mgr) 
{
    mgr->config.frame_size = min((uint32_t)mgr->config.tic_frame_size_at_1fs, mgr->config.max_frame_size);
}

/* ALSA Callbacks */
static int attach_alsa_driver(void *aes67_mgr, const struct fusion_aes67_mgr_ops *ops, void *alsa_chip_pointer) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!ops || !alsa_chip_pointer) return -EINVAL;
    mgr->alsa.alsa_chip = alsa_chip_pointer;
    mgr->alsa.mgr_callbacks = ops;
    return 0;
}

static int get_input_jitter_buffer_offset(void *aes67_mgr, uint32_t *offset) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!offset) return -EINVAL;
    *offset = get_live_in_jitter_buffer_offset(mgr, get_global_sac_new(mgr));
    return 0;
}

static int get_output_jitter_buffer_offset(void *aes67_mgr, uint32_t *offset) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!offset) return -EINVAL;
    *offset = get_live_out_jitter_buffer_offset(mgr, get_global_sac_new(mgr));
    return 0;
}

static int get_min_interrupts_frame_size(void *aes67_mgr, uint32_t *framesize) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!framesize) return -EINVAL;
    *framesize = (uint32_t)mgr->config.tic_frame_size_at_1fs;
    return 0;
}

static int get_max_interrupts_frame_size(void *aes67_mgr, uint32_t *framesize) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!framesize) return -EINVAL;
    *framesize = min(mgr->config.max_frame_size, (uint32_t)mgr->config.tic_frame_size_at_1fs * 8);
    return 0;
}

static int get_interrupts_frame_size(void *aes67_mgr, uint32_t *framesize) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!framesize) return -EINVAL;
    *framesize = mgr->config.frame_size;
    return 0;
}

static int set_sample_rate(void *aes67_mgr, uint32_t rate) 
{
    return fusion_aes67_mgr_set_sample_rate(aes67_mgr, rate);
}

static int get_sample_rate(void *aes67_mgr, uint32_t *rate) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!rate) return -EINVAL;
    *rate = mgr->config.sample_rate;
    return 0;
}

static int get_jitter_buffer_sample_size(void *aes67_mgr, uint8_t *sample_size) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!sample_size) return -EINVAL;
    *sample_size = get_alsa_sample_size(mgr);
    return 0;
}

static int get_num_inputs(void *aes67_mgr, uint32_t *num_channels) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!num_channels) return -EINVAL;
    *num_channels = mgr->config.number_of_inputs;
    return 0;
}

static int get_num_outputs(void *aes67_mgr, uint32_t *num_channels) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!num_channels) return -EINVAL;
    *num_channels = mgr->config.number_of_outputs;
    return 0;
}

static int get_playout_delay(void *aes67_mgr, snd_pcm_sframes_t *delay_in_sample) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr->state.playout_delay;
    return 0;
}

static int get_capture_delay(void *aes67_mgr, snd_pcm_sframes_t *delay_in_sample) 
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!delay_in_sample) return -EINVAL;
    *delay_in_sample = mgr->state.capture_delay;
    return 0;
}

static int start_interrupts(void *aes67_mgr) 
{
    return fusion_aes67_mgr_start_alsa(aes67_mgr) ? 0 : -EIO;
}

static int stop_interrupts(void *aes67_mgr) 
{
    return fusion_aes67_mgr_stop_alsa(aes67_mgr) ? 0 : -EIO;
}

static int assign_stream_handle(void *aes67_mgr, int direction, uint64_t *stream_handle)
{
    // Stub for now—will be fleshed out with netlink
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!stream_handle) return -EINVAL;
    // Placeholder: manager will assign this from userspace via netlink
    *stream_handle = (direction == SNDRV_PCM_STREAM_PLAYBACK) ? 1 : 1000;
    printk(KERN_INFO "fusion_aes67: Assigned stream handle %llu (stub)\n", *stream_handle);
    return 0;
}

static int get_rtp_frame_size_per_stream(void *aes67_mgr, uint64_t stream_handle, uint32_t *framesize)
{
    struct fusion_aes67_manager *mgr = aes67_mgr;
    if (!framesize) return -EINVAL;
    // Stub: use general frame size until stream-specific logic is added
    *framesize = mgr->config.frame_size;
    return 0;
}

static int set_stream_params(void *mgr, uint64_t stream_handle, unsigned int rate,
                             unsigned int channels, snd_pcm_format_t format)
{
    // Stub for now—will configure RTP stream via RTPStreamsManager
    printk(KERN_INFO "fusion_aes67: Set stream %llu: rate=%u, channels=%u, format=%d (stub)\n",
           stream_handle, rate, channels, format);
    return 0;
}

static void pcm_interrupt(void *alsa_chip, int direction)
{
    // Already called by manager, but not in ops—stubbed here for completeness
    struct fusion_aes67_chip *chip = alsa_chip;
    if (chip && chip->alsa_ops && chip->alsa_ops->pcm_interrupt) {
        chip->alsa_ops->pcm_interrupt(chip, direction);
    }
}

const struct fusion_aes67_alsa_ops fusion_aes67_alsa_callbacks = {
    .register_alsa_driver = attach_alsa_driver,
    .get_input_jitter_buffer_offset = get_input_jitter_buffer_offset,
    .get_output_jitter_buffer_offset = get_output_jitter_buffer_offset,
    .get_min_interrupts_frame_size = get_min_interrupts_frame_size,
    .get_max_interrupts_frame_size = get_max_interrupts_frame_size,
    .get_rtp_frame_size = get_interrupts_frame_size,
    .get_rtp_frame_size_per_stream = get_rtp_frame_size_per_stream,
    .set_sample_rate = set_sample_rate,
    .get_sample_rate = get_sample_rate,
    .get_jitter_buffer_sample_size = get_jitter_buffer_sample_size,
    .get_num_inputs = get_num_inputs,
    .get_num_outputs = get_num_outputs,
    .get_playout_delay = get_playout_delay,
    .get_capture_delay = get_capture_delay,
    .start_interrupts = start_interrupts,
    .stop_interrupts = stop_interrupts,
    .assign_stream_handle = assign_stream_handle,
    .set_stream_params = set_stream_params,
    .pcm_interrupt = pcm_interrupt,
};

/* RTP Callbacks */
static uint64_t get_frame_size(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    return mgr->config.frame_size;
}

static void get_audio_engine_sample_format(void *user, uint32_t *sample_format) 
{
    *sample_format = 4; /* 32-bit PCM */
}

static void update_live_in_audio_data_format(void *user, uint32_t sample_format) 
{
    printk(KERN_INFO "fusion_aes67: update_live_in_audio_data_format to %u (no-op)\n", sample_format);
}

static void *get_live_in_jitter_buffer(void *user, uint32_t channel_id) 
{
    struct fusion_aes67_manager *mgr = user;
    unsigned char *input_buffer = (unsigned char *)mgr->alsa.alsa_callbacks->get_capture_buffer(mgr->alsa.alsa_chip);
    if (!input_buffer || channel_id >= mgr->config.number_of_inputs) {
        printk(KERN_ERR "fusion_aes67: get_live_in_jitter_buffer failed: channel %u invalid\n", channel_id + 1);
        return NULL;
    }
    return input_buffer + channel_id * mgr->config.ring_buffer_frame_size * get_alsa_sample_size(mgr);
}

static void *get_live_out_jitter_buffer(void *user, uint32_t channel_id) 
{
    struct fusion_aes67_manager *mgr = user;
    unsigned char *output_buffer = (unsigned char *)mgr->alsa.alsa_callbacks->get_playback_buffer(mgr->alsa.alsa_chip);
    if (!output_buffer || channel_id >= mgr->config.number_of_outputs) {
        printk(KERN_ERR "fusion_aes67: get_live_out_jitter_buffer failed: channel %u invalid\n", channel_id + 1);
        return NULL;
    }
    return output_buffer + channel_id * mgr->config.ring_buffer_frame_size * get_alsa_sample_size(mgr);
}

static uint32_t get_live_in_jitter_buffer_length(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    return mgr->alsa.alsa_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip);
}

static uint32_t get_live_out_jitter_buffer_length(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    return mgr->alsa.alsa_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip);
}

static uint32_t get_live_in_jitter_buffer_offset(void *user, const uint64_t current_sac) 
{
    struct fusion_aes67_manager *mgr = user;
    uint32_t length = mgr->alsa.alsa_callbacks->get_capture_buffer_size_in_frames(mgr->alsa.alsa_chip);
    return (uint32_t)(current_sac % length);
}

static uint32_t get_live_out_jitter_buffer_offset(void *user, const uint64_t current_sac) 
{
    struct fusion_aes67_manager *mgr = user;
    uint32_t length = mgr->alsa.alsa_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip);
    return (uint32_t)(current_sac % length);
}

static uint64_t get_global_sac_new(void *user) 
{
    struct fusion_aes67_manager *mgr = user;
    struct timespec ts;
    clock_gettime(mgr->phc_clockid, &ts);
    uint64_t ns = ts.tv_sec * 1000000000ULL + ts.tv_nsec;
    return (ns * mgr->config.sample_rate) / 1000000000ULL;
}

static uint64_t get_global_time_new(void *user) 
{
    struct timespec ts;
    clock_gettime(mgr->phc_clockid, &ts);
    return ts.tv_sec * 10000000ULL + ts.tv_nsec / 100; // [100ns]
}

static void get_global_times_new(void *user, uint64_t *global_sac, uint64_t *global_time, uint64_t *global_performance_counter) 
{
    struct fusion_aes67_manager *mgr = user;
    struct timespec ts;
    clock_gettime(mgr->phc_clockid, &ts);
    uint64_t ns = ts.tv_sec * 1000000000ULL + ts.tv_nsec;
    *global_time = ts.tv_sec * 10000000ULL + ts.tv_nsec / 100;
    *global_sac = (ns * mgr->config.sample_rate) / 1000000000ULL;
    *global_performance_counter = ktime_to_ns(ktime_get());
}

const struct rtp_audio_stream_ops fusion_aes67_rtp_callbacks = {
    .get_global_SAC = get_global_sac_new,
    .get_global_time = get_global_time_new,
    .get_global_times = get_global_times_new,
    .get_frame_size = get_frame_size,
    .get_audio_engine_sample_format = get_audio_engine_sample_format,
    .update_live_in_audio_data_format = update_live_in_audio_data_format,
    .get_live_in_jitter_buffer = get_live_in_jitter_buffer,
    .get_live_out_jitter_buffer = get_live_out_jitter_buffer,
    .get_live_in_jitter_buffer_length = get_live_in_jitter_buffer_length,
    .get_live_out_jitter_buffer_length = get_live_out_jitter_buffer_length,
    .get_live_out_jitter_buffer_offset = get_live_out_jitter_buffer_offset,
    .get_live_in_jitter_buffer_offset = get_live_in_jitter_buffer_offset,
};

/* Timing Functions */
static void audio_frame_tic(struct fusion_aes67_manager *mgr) 
{
    prepare_buffer_lives(&mgr->rtp.rtp_streams_manager);
    if (mgr->state.alsa_running && mgr->state.ptp_synchronized) {
        frame_process_begin(&mgr->rtp.rtp_streams_manager);
        if (mgr->alsa.alsa_chip && mgr->alsa.alsa_callbacks) {
            mgr->alsa.alsa_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 1); /* Playback */
            mgr->alsa.alsa_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 0); /* Capture */
        }
        frame_process_end(&mgr->rtp.rtp_streams_manager);
    }
}

static clockid_t get_phc_clockid(void) {
    int fd = open("/dev/ptp0", O_RDONLY);
    if (fd < 0) return -1;
    clockid_t clkid = ((~(clockid_t)(fd) << 3) | 3);  // Dynamic clock ID
    close(fd);
    return clkid;
}

static enum hrtimer_restart audio_timer_process(struct hrtimer *timer)
{
    struct fusion_aes67_manager *mgr = container_of(timer, struct fusion_aes67_manager, audio_timer);
    struct timespec phc_ts;
    uint64_t current_phc_ns, current_samples, next_tick_ns;

    // Get current PHC time
    clock_gettime(mgr->phc_clockid, &phc_ts);
    current_phc_ns = phc_ts.tv_sec * 1000000000ULL + phc_ts.tv_nsec;
    current_samples = (current_phc_ns * mgr->config.sample_rate) / 1000000000ULL;

    // Source role: Capture and send RTP packets
    if (mgr->state.is_source && mgr->state.ptp_synchronized) {
        uint32_t rtp_timestamp = current_samples;  // RTP timestamp = current sample count
        // Capture audio from ALSA (e.g., RCA input) into a buffer
        mgr->alsa.alsa_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 0);  // 0 = capture
        // Send RTP packet with timestamp and audio data
        prepare_buffer_lives(&mgr->rtp.rtp_streams_manager);
        frame_process_begin(&mgr->rtp.rtp_streams_manager);
        frame_process_end(&mgr->rtp.rtp_streams_manager);
    }

    // Sink role: Play audio based on RTP timestamp + playout delay
    if (mgr->state.is_sink && mgr->state.ptp_synchronized) {
        uint32_t next_rtp_ts = get_next_rtp_timestamp(&mgr->rtp.rtp_streams_manager);
        uint32_t playout_ts = next_rtp_ts + mgr->state.playout_delay;  // In samples (e.g., 144 = 3 ms)

        if (current_samples >= playout_ts) {
            // Buffer is ready, trigger playback
            prepare_buffer_lives(&mgr->rtp.rtp_streams_manager);
            frame_process_begin(&mgr->rtp.rtp_streams_manager);
            mgr->alsa.alsa_callbacks->pcm_interrupt(mgr->alsa.alsa_chip, 1);  // 1 = playback
            frame_process_end(&mgr->rtp.rtp_streams_manager);
        }
    }

    // Set next tick (fixed 1 ms interval)
    next_tick_ns = current_phc_ns + (mgr->config.frame_size * 1000000000ULL / mgr->config.sample_rate);
    hrtimer_forward_now(timer, ns_to_ktime(next_tick_ns));
    return HRTIMER_RESTART;
}

static enum hrtimer_restart audio_frame_tic_hrtimer(struct hrtimer *timer) {
    struct fusion_aes67_manager *mgr = container_of(timer, struct fusion_aes67_manager, audio_timer);
    static uint64_t last_check = 0;
    static int64_t baseline_drift_ns = 0;
    static bool first_check = true;

    audio_frame_tic(mgr);
    ktime_t interval = ns_to_ktime((mgr->config.frame_size * 1000000000ULL) / mgr->config.sample_rate);

    if (ktime_to_ns(ktime_get()) - last_check > 1000000000ULL) {
        struct timespec phc_ts, mono_ts;
        clock_gettime(mgr->phc_clockid, &phc_ts);
        clock_gettime(CLOCK_MONOTONIC, &mono_ts);
        int64_t drift_ns = (phc_ts.tv_sec * 1000000000LL + phc_ts.tv_nsec) -
                          (mono_ts.tv_sec * 1000000000LL + mono_ts.tv_nsec);

        if (first_check || llabs(drift_ns - baseline_drift_ns) > 1000000000LL) {  // >1 s jump
            baseline_drift_ns = drift_ns;  // Reset on first run or PHC resync
            first_check = false;
        } else {
            int64_t relative_drift_ns = drift_ns - baseline_drift_ns;
            if (llabs(relative_drift_ns) > 5000) {  // >5 µs
                interval = ktime_add_ns(interval, relative_drift_ns / 100);
            }
        }
        last_check = ktime_to_ns(ktime_get());
    }

    hrtimer_forward_now(timer, interval);
    return HRTIMER_RESTART;
}

static irqreturn_t audio_frame_tic_gpio(int irq, void *dev_id) 
{
    struct fusion_aes67_manager *mgr = dev_id;
    audio_frame_tic(mgr);
    return IRQ_HANDLED;
}

static int init_gpio_interrupt(struct fusion_aes67_manager *mgr) 
{
    int err;
    if (!gpio_is_valid(mgr->gpio_pin)) {
        printk(KERN_ERR "fusion_aes67: Invalid GPIO pin: %d\n", mgr->gpio_pin);
        return -EINVAL;
    }
    if ((err = gpio_request(mgr->gpio_pin, "aes67_frame")) < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to request GPIO %d: %d\n", mgr->gpio_pin, err);
        return err;
    }
    if ((err = gpio_direction_input(mgr->gpio_pin)) < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to set GPIO %d as input: %d\n", mgr->gpio_pin, err);
        gpio_free(mgr->gpio_pin);
        return err;
    }
    int irq = gpio_to_irq(mgr->gpio_pin);
    if (irq < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to get IRQ for GPIO %d: %d\n", mgr->gpio_pin, irq);
        gpio_free(mgr->gpio_pin);
        return irq;
    }
    mgr->gpio_irq = irq;
    err = request_irq(irq, audio_frame_tic_gpio, IRQF_TRIGGER_RISING, "aes67_frame", mgr);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to request IRQ %d: %d\n", irq, err);
        gpio_free(mgr->gpio_pin);
        return err;
    }
    return 0;
}

/* Manager Functions */
static int fusion_aes67_config_init(struct fusion_aes67_manager *mgr) 
{
    mgr->config.sample_rate = DEFAULT_SAMPLERATE;
    mgr->config.tic_frame_size_at_1fs = DEFAULT_TICFRAMESIZE;
    mgr->config.max_frame_size = MAX_FRAME_SIZE;
    mgr->config.frame_size = DEFAULT_TICFRAMESIZE;
    mgr->config.ring_buffer_frame_size = RINGBUFFERSIZE;
    mgr->config.number_of_inputs = DEFAULT_NUM_INPUTS;
    mgr->config.number_of_outputs = DEFAULT_NUM_OUTPUTS;
    return 0;
}

static int fusion_aes67_state_init(struct fusion_aes67_manager *mgr) 
{
    mgr->state.is_started = false;
    mgr->state.is_source = false;
    mgr->state.is_sink = false;
    mgr->state.alsa_running = false;
    mgr->state.ptp_synchronized = false;
    mgr->state.playout_delay = 0;
    mgr->state.capture_delay = 0;
    return 0;
}

static int fusion_aes67_ethernet_init(struct fusion_aes67_manager *mgr) {

    return init_netfilter(&mgr->ethernet.ethernet_filter, mgr);
}

static int fusion_aes67_rtp_init(struct fusion_aes67_manager *mgr) 
{
    mgr->rtp.rtp_callbacks = fusion_aes67_rtp_callbacks;
    mgr->rtp.rtp_callbacks.user = mgr;
    return init_rtp_streams(&mgr->rtp.rtp_streams_manager, &mgr->rtp.rtp_callbacks, &mgr->ethernet.ethernet_filter);
}

static int fusion_aes67_alsa_init(struct fusion_aes67_manager *mgr) 
{
    mgr->alsa.alsa_chip = NULL;
    mgr->alsa.mgr_callbacks = NULL;
    mgr->alsa.alsa_callbacks = &fusion_aes67_alsa_callbacks;
    return fusion_aes67_card_init(mgr, &fusion_aes67_alsa_callbacks);
}

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
    msg_rcv.pid = nlh->nlmsg_pid; // Store sender's PID
    on_new_message(mgr, &msg_rcv);
}

static int fusion_aes67_netlink_init(struct fusion_aes67_manager *mgr)
{
    struct netlink_kernel_cfg cfg = {
        .input = fusion_aes67_nl_recv_msg,
    };
    mgr->nl_family = NETLINK_USERSOCK; // Or a custom family
    mgr->nl_sock = netlink_kernel_create(&init_net, mgr->nl_family, &cfg);
    if (!mgr->nl_sock) {
        printk(KERN_ERR "fusion_aes67: Failed to create netlink socket\n");
        return -ENOMEM;
    }
    mgr->nl_sock->sk_private_data = mgr; // Store mgr for callback
    return 0;
}

int fusion_aes67_mgr_init(struct fusion_aes67_manager *mgr) 
{
    int err;
    if (!mgr) {
        printk(KERN_ERR "fusion_aes67: Null manager pointer\n");
        return -EINVAL;
    }
    if ((err = fusion_aes67_nf_init(mgr)) < 0) return err;
    if ((err = fusion_aes67_config_init(mgr)) < 0) return err;
    if ((err = fusion_aes67_state_init(mgr)) < 0) return err;
    if ((err = fusion_aes67_rtp_init(mgr)) < 0) {
        destroy_ethernet(&mgr->ethernet.ethernet_filter);
        return err;
    }
    if ((err = fusion_aes67_alsa_init(mgr)) < 0) {
        destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
        destroy_ethernet(&mgr->ethernet.ethernet_filter);
        return err;
    }
    if ((err = fusion_aes67_netlink_init(mgr)) < 0) {
        fusion_aes67_card_exit();
        destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
        destroy_ethernet(&mgr->ethernet.ethernet_filter);
        return err;
    }
    if (mgr->timing_mode == TIMING_GPIO_INTERRUPT) {
        if (mgr->gpio_pin < 0) {
            printk(KERN_ERR "fusion_aes67: Invalid GPIO pin number: %d\n", mgr->gpio_pin);
            err = -EINVAL;
        } else if ((err = init_gpio_interrupt(mgr)) < 0) {
            printk(KERN_ERR "fusion_aes67: Failed to initialize GPIO interrupt: %d\n", err);
            destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
            destroy_ethernet(&mgr->ethernet.ethernet_filter);
            return err;
        }
    } else {
        mgr->timing_mode = TIMING_HRTIMER;
        mgr->phc_clockid = get_phc_clockid();
        if (mgr->phc_clockid < 0) return -EINVAL;
        hrtimer_init(&mgr->audio_timer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);
        mgr->audio_timer.function = audio_timer_process;
        mgr->gpio_irq = -1;
        mgr->gpio_pin = -1;
    }
    update_frame_size(mgr);
    printk(KERN_INFO "fusion_aes67: Manager initialized with %s timing\n",
           mgr->timing_mode == TIMING_HRTIMER ? "hrtimer" : "GPIO interrupt");
    return 0;
}

void destroy_netlink(struct fusion_aes67_manager *mgr) 
{
    if (mgr->nl_sock) {
        netlink_kernel_release(mgr->nl_sock);
        mgr->nl_sock = NULL;
    }
}

void fusion_aes67_mgr_destroy(struct fusion_aes67_manager *mgr) 
{
    if (!mgr) return;
    if (mgr->timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->audio_timer);
    } else if (mgr->timing_mode == TIMING_GPIO_INTERRUPT && mgr->gpio_irq >= 0) {
        free_irq(mgr->gpio_irq, mgr);
        if (gpio_is_valid(mgr->gpio_pin)) gpio_free(mgr->gpio_pin);
    }
    fusion_aes67_card_exit();
    destroy_rtp_streams(&mgr->rtp.rtp_streams_manager);
    destroy_ethernet(&mgr->ethernet.ethernet_filter);
    destroy_netlink(mgr);
    printk(KERN_INFO "fusion_aes67: Manager destroyed\n");
}

bool fusion_aes67_mgr_start(struct fusion_aes67_manager *mgr) 
{
    if (!mgr || mgr->state.is_started) return false;
    if (mgr->timing_mode == TIMING_HRTIMER) {
        hrtimer_start(&mgr->audio_timer, ns_to_ktime((mgr->config.frame_size * 1000000000ULL) / mgr->config.sample_rate), HRTIMER_MODE_REL);
    } else if (mgr->timing_mode == TIMING_GPIO_INTERRUPT && mgr->gpio_irq >= 0) {
        enable_irq(mgr->gpio_irq);
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
    if (mgr->timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->audio_timer);
    } else if (mgr->timing_mode == TIMING_GPIO_INTERRUPT && mgr->gpio_irq >= 0) {
        disable_irq(mgr->gpio_irq);
    }
    mgr->state.is_started = false;
    return true;
}

bool fusion_aes67_mgr_start_alsa(struct fusion_aes67_manager *mgr) 
{
    if (!mgr || mgr->state.alsa_running || !mgr->state.is_started) return false;
    if (mgr->alsa.alsa_callbacks->start_interrupts) {
        mgr->alsa.alsa_callbacks->start_interrupts(mgr);
    }
    mgr->state.alsa_running = true;
    return true;
}

bool fusion_aes67_mgr_stop_alsa(struct fusion_aes67_manager *mgr) 
{
    if (!mgr || !mgr->state.alsa_running) return false;
    if (mgr->alsa.alsa_callbacks->stop_interrupts) {
        mgr->alsa.alsa_callbacks->stop_interrupts(mgr);
    }
    mgr->state.alsa_running = false;
    return true;
}

int fusion_aes67_mgr_set_sample_rate(struct fusion_aes67_manager *mgr, uint32_t rate) 
{
    if (!mgr || rate == 0) return -EINVAL;
    if (mgr->state.alsa_running) {
        printk(KERN_ERR "fusion_aes67: set_sample_rate(%u) not allowed when IO is running\n", rate);
        return -EBUSY;
    }
    mgr->config.sample_rate = rate;
    update_frame_size(mgr);
    mute_output_buffer(mgr);
    if (mgr->state.is_started) {
        fusion_aes67_mgr_stop(mgr);
        fusion_aes67_mgr_start(mgr);
    }
    return 0;
}

int fusion_aes67_mgr_set_tic_frame_size(struct fusion_aes67_manager *mgr, uint64_t size) 
{
    if (!mgr) return -EINVAL;
    bool restart = mgr->state.is_started;
    if (restart) fusion_aes67_mgr_stop(mgr);
    mgr->config.tic_frame_size_at_1fs = size;
    update_frame_size(mgr);
    if (restart) fusion_aes67_mgr_start(mgr);
    return 0;
}

int fusion_aes67_mgr_set_max_frame_size(struct fusion_aes67_manager *mgr, uint64_t size) 
{
    if (!mgr) return -EINVAL;
    bool restart = mgr->state.is_started;
    if (restart) fusion_aes67_mgr_stop(mgr);
    mgr->config.max_frame_size = (uint32_t)size;
    update_frame_size(mgr);
    if (restart) fusion_aes67_mgr_start(mgr);
    return 0;
}

int fusion_aes67_mgr_set_num_inputs(struct fusion_aes67_manager *mgr, uint32_t num) 
{
    if (!mgr) return -EINVAL;
    bool restart = mgr->state.is_started;
    if (restart) fusion_aes67_mgr_stop(mgr);
    mgr->config.number_of_inputs = num;
    if (restart) fusion_aes67_mgr_start(mgr);
    return 0;
}

int fusion_aes67_mgr_set_num_outputs(struct fusion_aes67_manager *mgr, uint32_t num) 
{
    if (!mgr) return -EINVAL;
    bool restart = mgr->state.is_started;
    if (restart) fusion_aes67_mgr_stop(mgr);
    mgr->config.number_of_outputs = num;
    if (restart) fusion_aes67_mgr_start(mgr);
    return 0;
}

/* Message Handlers */
static int handle_get_rtp_stream_status(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) {
        printk(KERN_ERR "fusion_aes67: GetRTPStreamStatus invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
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

static int handle_reset(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    printk(KERN_INFO "fusion_aes67: Resetting all RTP streams\n");
    remove_all_rtp_streams(&mgr->rtp.rtp_streams_manager);
    return reply->err = 0;
}

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

static int handle_start_alsa(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    printk(KERN_INFO "fusion_aes67: Starting IO\n");
    return reply->err = fusion_aes67_mgr_start_alsa(mgr) ? 0 : -EIO;
}

static int handle_stop_alsa(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    printk(KERN_INFO "fusion_aes67: Stopping IO\n");
    return reply->err = fusion_aes67_mgr_stop_alsa(mgr) ? 0 : -EIO;
}

static int handle_set_sample_rate(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint32_t)) {
        printk(KERN_ERR "fusion_aes67: SetSampleRate invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint32_t *rate = (uint32_t *)msg->data;
    if (*rate == 0) {
        printk(KERN_ERR "fusion_aes67: SetSampleRate invalid value: %u\n", *rate);
        return reply->err = -EINVAL;
    }
    printk(KERN_INFO "fusion_aes67: Setting sample rate to %u\n", *rate);
    return reply->err = fusion_aes67_mgr_set_sample_rate(mgr, *rate);
}

static int handle_get_sample_rate(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    static uint32_t sample_rate;
    sample_rate = mgr->config.sample_rate;
    reply->err = 0;
    reply->data_size = sizeof(uint32_t);
    reply->data = &sample_rate;
    return 0;
}

static int handle_get_audio_mode(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    static uint32_t audio_mode = 0; /* Placeholder: PCM */
    printk(KERN_INFO "fusion_aes67: Getting audio mode (placeholder: %u)\n", audio_mode);
    reply->err = 0;
    reply->data_size = sizeof(uint32_t);
    reply->data = &audio_mode;
    return 0;
}

static int handle_set_tic_frame_size_at_1fs(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) {
        printk(KERN_ERR "fusion_aes67: SetTICFrameSizeAt1FS invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint64_t *size = (uint64_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Setting TIC frame size at 1FS to %llu\n", *size);
    return reply->err = fusion_aes67_mgr_set_tic_frame_size(mgr, *size);
}

static int handle_set_max_tic_frame_size(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) {
        printk(KERN_ERR "fusion_aes67: SetMaxTICFrameSize invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint64_t *size = (uint64_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Setting max TIC frame size to %llu\n", *size);
    return reply->err = fusion_aes67_mgr_set_max_frame_size(mgr, *size);
}

static int handle_set_number_of_inputs(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint32_t)) {
        printk(KERN_ERR "fusion_aes67: SetNumberOfInputs invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint32_t *num = (uint32_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Setting number of inputs to %u\n", *num);
    return reply->err = fusion_aes67_mgr_set_num_inputs(mgr, *num);
}

static int handle_set_number_of_outputs(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint32_t)) {
        printk(KERN_ERR "fusion_aes67: SetNumberOfOutputs invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint32_t *num = (uint32_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Setting number of outputs to %u\n", *num);
    return reply->err = fusion_aes67_mgr_set_num_outputs(mgr, *num);
}

static int handle_get_number_of_inputs(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    static uint32_t num_inputs;
    num_inputs = mgr->config.number_of_inputs;
    reply->err = 0;
    reply->data_size = sizeof(uint32_t);
    reply->data = &num_inputs;
    return 0;
}

static int handle_get_number_of_outputs(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    static uint32_t num_outputs;
    num_outputs = mgr->config.number_of_outputs;
    reply->err = 0;
    reply->data_size = sizeof(uint32_t);
    reply->data = &num_outputs;
    return 0;
}

static int handle_add_rtp_stream(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(struct aes67_stream_config)) {
        printk(KERN_ERR "fusion_aes67: Add_RTPStream invalid data size: %d, expected %zu\n", 
               msg->data_size, sizeof(struct aes67_stream_config));
        return reply->err = -EINVAL;
    }

    struct aes67_stream_config *config = (struct aes67_stream_config *)msg->data;
    bool restart_required = false;

    // Validate basic parameters
    if (config->sample_rate == 0 || config->channels == 0 || config->samples_per_packet == 0 || config->stream_handle == 0) {
        printk(KERN_ERR "fusion_aes67: Invalid stream config: handle=%llu, rate=%u, channels=%u, samples=%u\n",
               config->stream_handle, config->sample_rate, config->channels, config->samples_per_packet);
        return reply->err = -EINVAL;
    }

    // Check for handle uniqueness
    struct RTPStream *stream;
    LIST_FOR_EACH_ENTRY(stream, &mgr->rtp.rtp_streams_manager.streams, list) {
        if (stream->handle == config->stream_handle) { // Assuming RTPStream has a handle field
            printk(KERN_ERR "fusion_aes67: Stream handle %llu already exists\n", config->stream_handle);
            return reply->err = -EEXIST;
        }
    }

    // Stop streams if running
    if (mgr->state.is_started) {
        fusion_aes67_mgr_stop(mgr);
        restart_required = true;
    }
    if (mgr->state.alsa_running) {
        fusion_aes67_mgr_stop_alsa(mgr);
    }

    printk(KERN_INFO "fusion_aes67: Adding RTP stream %llu: %s, rate=%u, format=%d, channels=%u, packet=%u, dest=%pI4:%u\n",
           config->stream_handle, config->name, config->sample_rate, config->format, config->channels, 
           config->samples_per_packet, &config->dest_ip, config->dest_port);

    // Create RTP stream (assuming refactored RTP layer will use this)
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
        .m_ui32SSRC = (uint32_t)config->stream_handle, // Use lower 32 bits for SSRC
        .m_bSSRCInitialized = 1,
        .m_byTTL = 255,
        .m_ucDSCP = 46, // EF per AES67
    };
    strlcpy(rtp_info.m_cName, config->name, MAX_STREAM_NAME_SIZE);

    if (!add_rtp_stream(&mgr->rtp.rtp_streams_manager, &rtp_info, &config->stream_handle)) {
        printk(KERN_ERR "fusion_aes67: Failed to add RTP stream %llu\n", config->stream_handle);
        return reply->err = -EIO;
    }

    // Configure ALSA substream
    if (mgr->alsa.alsa_callbacks && mgr->alsa.alsa_callbacks->set_stream_params) {
        int ret = mgr->alsa.alsa_callbacks->set_stream_params(mgr, config->stream_handle, 
                                                              config->sample_rate, 
                                                              config->channels, 
                                                              config->format);
        if (ret < 0) {
            printk(KERN_ERR "fusion_aes67: Failed to set ALSA stream params for %llu: %d\n", 
                   config->stream_handle, ret);
            remove_rtp_stream(&mgr->rtp.rtp_streams_manager, config->stream_handle);
            return reply->err = ret;
        }
    }

    // Update manager state
    if (config->is_source) {
        mgr->config.number_of_inputs += config->channels;
    } else {
        mgr->config.number_of_outputs += config->channels;
    }
    if (config->is_source) {
        mgr->state.is_source = true;
    } else {
        mgr->state.is_sink = true;
    }

    // Return the same handle as confirmation
    reply->err = 0;
    reply->data_size = sizeof(uint64_t);
    reply->data = &config->stream_handle;

    // Restart if needed
    if (restart_required) {
        fusion_aes67_mgr_start(mgr);
    }
    if (mgr->state.is_started) {
        fusion_aes67_mgr_start_alsa(mgr);
    }

    return 0;
}

static int handle_remove_rtp_stream(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(uint64_t)) {
        printk(KERN_ERR "fusion_aes67: Remove_RTPStream invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    uint64_t *handle = (uint64_t *)msg->data;
    printk(KERN_INFO "fusion_aes67: Removing RTP stream handle = %llu\n", *handle);
    return reply->err = remove_rtp_stream(&mgr->rtp.rtp_streams_manager, *handle) ? 0 : -EIO;
}

static int handle_update_rtp_stream_name(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(CRTP_stream_update_name)) {
        printk(KERN_ERR "fusion_aes67: Update_RTPStream_Name invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    printk(KERN_WARNING "fusion_aes67: Update_RTPStream_Name not implemented\n");
    return reply->err = -ENOSYS;
}

static int handle_set_playout_delay(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(int32_t)) {
        printk(KERN_ERR "fusion_aes67: SetPlayoutDelay invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    int32_t *delay = (int32_t *)msg->data;
    mgr->state.playout_delay = *delay;
    printk(KERN_INFO "fusion_aes67: Set playout delay to %d\n", *delay);
    return reply->err = 0;
}

static int handle_set_capture_delay(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply) 
{
    if (msg->data_size != sizeof(int32_t)) {
        printk(KERN_ERR "fusion_aes67: SetCaptureDelay invalid data size: %d\n", msg->data_size);
        return reply->err = -EINVAL;
    }
    int32_t *delay = (int32_t *)msg->data;
    mgr->state.capture_delay = *delay;
    printk(KERN_INFO "fusion_aes67: Set capture delay to %d\n", *delay);
    return reply->err = 0;
}

/* Supporting Functions */
static void mute_output_buffer(struct fusion_aes67_manager *mgr) 
{
    unsigned long flags;
    int32_t *output_buffer;
    uint32_t buffer_length = mgr->alsa.alsa_callbacks->get_playback_buffer_size_in_frames(mgr->alsa.alsa_chip);
    if (buffer_length == 0) {
        printk(KERN_ERR "fusion_aes67: mute_output_buffer failed: buffer size is 0\n");
        return;
    }
    mgr->alsa.mgr_callbacks->lock_playback_buffer(mgr->alsa.alsa_chip, &flags);
    output_buffer = (int32_t *)mgr->alsa.alsa_callbacks->get_playback_buffer(mgr->alsa.alsa_chip);
    if (!output_buffer) {
        printk(KERN_ERR "fusion_aes67: mute_output_buffer failed: no playback buffer\n");
        mgr->alsa.mgr_callbacks->unlock_playback_buffer(mgr->alsa.alsa_chip, &flags);
        return;
    }
    memset(output_buffer, 0, sizeof(int32_t) * buffer_length * mgr->config.number_of_outputs);
    mgr->alsa.mgr_callbacks->unlock_playback_buffer(mgr->alsa.alsa_chip, &flags);
}

/* Message Handling */
typedef int (*message_handler_t)(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg, struct fusion_aes67_ctrl_msg *reply);

struct message_handler_entry {
    enum fusion_aes67_ctrl_cmd cmd;
    message_handler_t handler;
};

static const struct message_handler_entry message_handlers[] = {
    { FUSION_AES67_CTRL_CMD_GetRTPStreamStatus, handle_get_rtp_stream_status },
    { FUSION_AES67_CTRL_CMD_Reset, handle_reset },
    { FUSION_AES67_CTRL_CMD_Start, handle_start },
    { FUSION_AES67_CTRL_CMD_Stop, handle_stop },
    { FUSION_AES67_CTRL_CMD_StartIO, handle_start_alsa },
    { FUSION_AES67_CTRL_CMD_StopIO, handle_stop_alsa },
    { FUSION_AES67_CTRL_CMD_SetSampleRate, handle_set_sample_rate },
    { FUSION_AES67_CTRL_CMD_GetSampleRate, handle_get_sample_rate },
    { FUSION_AES67_CTRL_CMD_GetAudioMode, handle_get_audio_mode },
    { FUSION_AES67_CTRL_CMD_SetTICFrameSizeAt1FS, handle_set_tic_frame_size_at_1fs },
    { FUSION_AES67_CTRL_CMD_SetMaxTICFrameSize, handle_set_max_tic_frame_size },
    { FUSION_AES67_CTRL_CMD_SetNumberOfInputs, handle_set_number_of_inputs },
    { FUSION_AES67_CTRL_CMD_SetNumberOfOutputs, handle_set_number_of_outputs },
    { FUSION_AES67_CTRL_CMD_GetNumberOfInputs, handle_get_number_of_inputs },
    { FUSION_AES67_CTRL_CMD_GetNumberOfOutputs, handle_get_number_of_outputs },
    { FUSION_AES67_CTRL_CMD_Add_RTPStream, handle_add_rtp_stream },
    { FUSION_AES67_CTRL_CMD_Remove_RTPStream, handle_remove_rtp_stream },
    { FUSION_AES67_CTRL_CMD_Update_RTPStream_Name, handle_update_rtp_stream_name },
    { FUSION_AES67_CTRL_CMD_SetPlayoutDelay, handle_set_playout_delay },
    { FUSION_AES67_CTRL_CMD_SetCaptureDelay, handle_set_capture_delay },
    { 0, NULL }
};

static void fusion_aes67_nl_send_msg(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *reply)
{
    struct sk_buff *skb;
    struct nlmsghdr *nlh;
    int msg_size = sizeof(*reply) + reply->data_size;

    if (!mgr || !mgr->nl_sock) {
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

    if (netlink_unicast(mgr->nl_sock, skb, reply->pid, MSG_DONTWAIT) < 0) {
        printk(KERN_ERR "fusion_aes67: Failed to send netlink reply\n");
        kfree_skb(skb);
    }
}

void on_new_message(struct fusion_aes67_manager *mgr, struct fusion_aes67_ctrl_msg *msg_rcv) 
{
    struct fusion_aes67_ctrl_msg msg_reply = {
        .cmd = msg_rcv ? msg_rcv->cmd : 0,
        .err = -ENOENT,
        .data_size = 0,
        .data = NULL
    };
    if (!mgr || !msg_rcv) {
        printk(KERN_ERR "fusion_aes67: on_new_message received NULL mgr or msg\n");
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
    fusion_aes67_nl_send_msg(mgr, &msg_reply); /* Placeholder */
}

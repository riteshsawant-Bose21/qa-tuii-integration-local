#include <linux/types.h>
#include <linux/unistd.h>
#include <linux/fcntl.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/time.h>
#include <linux/ktime.h>
#include <linux/kthread.h>
#include <linux/sched.h>
#include <linux/sched/types.h>
#include <linux/cpumask.h>
#include <linux/smp.h>
#include <linux/math64.h>
#include <linux/netlink.h>
#include <net/netlink.h>
#include "fusion_connect_manager.h"
#include "fusion_connect_metrics.h"
#include "fusion_gpt_client.h"

/* Some builds may carry an older fusion_gpt_client.h without read_ticks; declare locally */
extern u64 fusion_gpt_read_ticks64(void);


#define TIMER_BASE_INTERVAL_NS 333333
#define GPT_TICK_NS            100

#ifndef abs64
#define abs64(x) ((x) >= 0 ? (x) : -(x))
#endif


/* === Audio Frame Process deferral to kthread_worker (PREEMPT_RT-friendly) === */
static struct kthread_worker *process_worker;
static struct task_struct    *process_thread;
static struct kthread_work    process_work;
static atomic_t               process_pending;

static struct fusion_cn_manager *g_fusion_cn_mgr;

void fusion_cn_nl_destroy(struct fusion_cn_manager *mgr);
int fusion_cn_mgr_start(struct fusion_cn_manager *mgr);
bool fusion_cn_mgr_stop(struct fusion_cn_manager *mgr);

/* ALSA Callbacks */
static int alsa_ops_register_alsa_driver(void *cn_mgr, struct fusion_cn_chip *alsa_chip)
{
    struct fusion_cn_manager *mgr = cn_mgr;
    if (!alsa_chip) return -EINVAL;
    mgr->alsa.alsa_chip = alsa_chip;
    mgr->alsa.alsa_chip->debug = mgr->debug;
    return 0;
}

static int alsa_ops_start_interrupts(void *cn_mgr, u64 stream_handle, struct fusion_cn_substream *stream)
{
    struct fusion_cn_manager *mgr = cn_mgr;

    if (!mgr || !mgr->rtp.cn_mgr) {
        printk(KERN_ERR "fusion_cn: start_interrupts: Invalid manager or uninitialized RTP for stream %llu\n", stream_handle);
        return -EINVAL;
    }

    return fusion_cn_rtp_set_stream_running(&mgr->rtp, stream_handle, true, stream);
}

static int alsa_ops_stop_interrupts(void *cn_mgr, u64 stream_handle)
{
    struct fusion_cn_manager *mgr = cn_mgr;

    if (!mgr || !mgr->rtp.cn_mgr) {
        printk(KERN_ERR "fusion_cn: stop_interrupts: Invalid manager or uninitialized RTP for stream %llu\n", stream_handle);
        return -EINVAL;
    }

    return fusion_cn_rtp_set_stream_running(&mgr->rtp, stream_handle, false, NULL);
}

const struct fusion_cn_alsa_ops fusion_cn_alsa_ops = {
    .register_alsa_driver = alsa_ops_register_alsa_driver,
    .start_interrupts = alsa_ops_start_interrupts,
    .stop_interrupts = alsa_ops_stop_interrupts
};

/* RTP Callbacks */
static u64 fusion_cn_rtp_get_phc_ns(void)
{
    return fusion_cn_gpt_get_phc_ns();
}

static void *fusion_cn_rtp_ops_get_buffer(void *alsa_stream)
{
    struct fusion_cn_substream *stream = alsa_stream;
    return stream->substream->runtime->dma_area;
}

static u32 fusion_cn_rtp_ops_get_buffer_size_in_frames(void *alsa_stream)
{
    struct fusion_cn_substream *stream = alsa_stream;
    return stream->substream->runtime->buffer_size;
}

static u32 fusion_cn_rtp_ops_get_buffer_offset(void *alsa_stream)
{
    struct fusion_cn_substream *stream = alsa_stream;
    return stream->buffer_pos;
}

/* In GPT timing mode, synthesize ns from the 10 MHz counter (100 ns/tick) */
static u64 fusion_cn_gpt_get_phc_ns(void)
{
    u64 ticks = fusion_gpt_read_ticks64();
    return ticks ? ticks * GPT_TICK_NS : 0;
}

/* helpers: compute how many interrupts are due, and advance state */
static inline int rtp_compute_sink_interrupts(struct fusion_cn_rtp_stream *s, u64 now)
{ 
    int count = 0;

    spin_lock(&s->lock);

    if (s->playback_index < s->buf_size_in_packets) {
        u64 window = 2 * s->packet_time;

        while (count < s->buf_size_in_packets) {
            s64 delta = (s64)now - (s64)s->next_action_times[s->playback_index];
            if (delta < 0 && (u64)-(delta) > EARLY_SLACK_NS) {
                break;
            } else if (abs64(delta) > window) {
                break;
            }

            if (g_fusion_cn_mgr->debug) printk(KERN_DEBUG "fusion_cn: compute_sink: stream %s playback_idx=%u count=%u now=%llu\n", s->info.stream_name, s->playback_index, count, now);

            if (++s->playback_index >= s->buf_size_in_packets)
                s->playback_index = 0;
            count++;
        }
    }
    spin_unlock(&s->lock);
    return count;
}

static inline int rtp_compute_source_interrupts(struct fusion_cn_rtp_stream *s, u64 now, u64 next_tick)
{
    int count = 0;

    spin_lock(&s->lock);
    if (s->next_action_time == 0)
        s->next_action_time = now;

    while (s->next_action_time <= (now + EARLY_SLACK_NS)) {
        if (s->packet_time == TIMER_BASE_INTERVAL_NS)
            s->next_action_time = next_tick;
        else
            s->next_action_time += s->packet_time;
        count++;
    }
    spin_unlock(&s->lock);
    return count;
}

static void audio_frame_process(struct fusion_cn_manager *mgr)
{
    struct stream_node *node, *tmp;
    unsigned long flags;

    struct {
        struct fusion_cn_rtp_stream *rtp;
        struct fusion_cn_substream  *alsa;
        int n;
    } fn_sink[32], other[32];
    int fn_sink_cnt = 0, other_cnt = 0;

    if (!atomic_read(&mgr->state.ptp_synchronized) ||
        !atomic_read(&mgr->state.is_started))
        return;

    /* -------- Phase 1: FusionConnect sinks (low latency priority) -------- */
    read_lock_irqsave(&mgr->rtp.lock, flags);
    list_for_each_entry_safe(node, tmp, &mgr->active_streams.fn_sink, node) {
        struct fusion_cn_rtp_stream *r = node->rtp_stream;
        struct fusion_cn_substream  *a = node->alsa_stream;

        if (!r || !a || fusion_cn_alsa_stream_disconnected(a))
            continue;
        if (!atomic_read(&r->is_running) || r->info.is_source || !r->info.is_fusion_connect)
            continue;

        /* compute due interrupts with stream->lock, still under mgr->rtp.lock */
        {
            int n = rtp_compute_sink_interrupts(r, mgr->ptp.hrtimer_last_tick_ns);
            if (n > 0 && fn_sink_cnt < 32) {
                if (!kref_get_unless_zero(&r->ref))
                    continue;
                if (!kref_get_unless_zero(&a->ref)) {
                    kref_put(&r->ref, fusion_cn_rtp_stream_release);
                    continue;
                }
                fn_sink[fn_sink_cnt++] = (typeof(fn_sink[0])){ .rtp = r, .alsa = a, .n = n };
            }
        }
    }
    read_unlock_irqrestore(&mgr->rtp.lock, flags);

    /* execute */
    for (int i = 0; i < fn_sink_cnt; i++) {
        struct stream_node *sn = fn_sink[i].rtp->stream_node;
        for (int k = 0; k < fn_sink[i].n; k++)
            fusion_cn_alsa_pcm_interrupt(mgr->alsa.alsa_chip, fn_sink[i].alsa);

        atomic_set(&sn->metrics_pending, 1);

        kref_put(&fn_sink[i].rtp->ref,  fusion_cn_rtp_stream_release);
        kref_put(&fn_sink[i].alsa->ref, fusion_cn_alsa_substream_release);
    }

    /* -------- Phase 2: FC sources + AES67 sinks + AES67 sources -------- */
    read_lock_irqsave(&mgr->rtp.lock, flags);

    /* FC sources */
    list_for_each_entry_safe(node, tmp, &mgr->active_streams.fn_source, node) {
        struct fusion_cn_rtp_stream *r = node->rtp_stream;
        struct fusion_cn_substream  *a = node->alsa_stream;
        if (!r || !a) continue;
        if (!atomic_read(&r->is_running) || !r->info.is_source || !r->info.is_fusion_connect) continue;

        int n = rtp_compute_source_interrupts(r, mgr->ptp.hrtimer_last_tick_ns, mgr->ptp.hrtimer_next_tick_ns);
        if (n > 0 && other_cnt < 32) {
            if (!kref_get_unless_zero(&r->ref)) continue;
            if (!kref_get_unless_zero(&a->ref)) { kref_put(&r->ref, fusion_cn_rtp_stream_release); continue; }
            other[other_cnt++] = (typeof(other[0])){ .rtp = r, .alsa = a, .n = n };
        }
    }

    /* AES67 sinks */
    list_for_each_entry_safe(node, tmp, &mgr->active_streams.aes67_sink, node) {
        struct fusion_cn_rtp_stream *r = node->rtp_stream;
        struct fusion_cn_substream  *a = node->alsa_stream;
        if (!r || !a) continue;
        if (!atomic_read(&r->is_running) || r->info.is_source || r->info.is_fusion_connect) continue;

        int n = rtp_compute_sink_interrupts(r, mgr->ptp.hrtimer_last_tick_ns);
        if (n > 0 && other_cnt < 32) {
            if (!kref_get_unless_zero(&r->ref)) continue;
            if (!kref_get_unless_zero(&a->ref)) { kref_put(&r->ref, fusion_cn_rtp_stream_release); continue; }
            other[other_cnt++] = (typeof(other[0])){ .rtp = r, .alsa = a, .n = n };
        }
    }

    /* AES67 sources */
    list_for_each_entry_safe(node, tmp, &mgr->active_streams.aes67_source, node) {
        struct fusion_cn_rtp_stream *r = node->rtp_stream;
        struct fusion_cn_substream  *a = node->alsa_stream;
        if (!r || !a) continue;
        if (!atomic_read(&r->is_running) || !r->info.is_source || r->info.is_fusion_connect) continue;

        int n = rtp_compute_source_interrupts(r, mgr->ptp.hrtimer_last_tick_ns, mgr->ptp.hrtimer_next_tick_ns);
        if (n > 0 && other_cnt < 32) {
            if (!kref_get_unless_zero(&r->ref)) continue;
            if (!kref_get_unless_zero(&a->ref)) { kref_put(&r->ref, fusion_cn_rtp_stream_release); continue; }
            other[other_cnt++] = (typeof(other[0])){ .rtp = r, .alsa = a, .n = n };
        }
    }

    read_unlock_irqrestore(&mgr->rtp.lock, flags);

    /* execute */
    for (int i = 0; i < other_cnt; i++) {
        struct stream_node *sn = other[i].rtp->stream_node;
        for (int k = 0; k < other[i].n; k++) {
            if (other[i].rtp->info.is_source)
                fusion_cn_rtp_send_packet(&mgr->rtp, other[i].rtp, other[i].alsa);
            fusion_cn_alsa_pcm_interrupt(mgr->alsa.alsa_chip, other[i].alsa);
        }

        atomic_set(&sn->metrics_pending, 1);

        kref_put(&other[i].rtp->ref,  fusion_cn_rtp_stream_release);
        kref_put(&other[i].alsa->ref, fusion_cn_alsa_substream_release);
    }
}

static void do_metrics(struct fusion_cn_manager *mgr)
{
    struct stream_node *node, *tmp;
    unsigned long flags;

    if (!atomic_read(&mgr->state.ptp_synchronized) ||
        !atomic_read(&mgr->state.is_started))
        return;

    read_lock_irqsave(&mgr->rtp.lock, flags);

    /* One helper macro to avoid duplication */
#define AGG_ON_PENDING(list_head)                                              \
    list_for_each_entry_safe(node, tmp, &(list_head), node) {                  \
        struct fusion_cn_rtp_stream *r = node->rtp_stream;                     \
        if (!r || !r->metrics) continue;                                       \
        if (!atomic_xchg(&node->metrics_pending, 0)) continue;                 \
        if (!r->info.is_source) {                                              \
            u32 jb = fusion_cn_alsa_get_buffer_depth(node->alsa_stream);       \
            fusion_cn_metrics_aggregate_rx(r->metrics, jb);                    \
        } else {                                                                \
            fusion_cn_metrics_aggregate_tx(r->metrics);                        \
        }                                                                       \
    }

    AGG_ON_PENDING(mgr->active_streams.fn_sink);
    AGG_ON_PENDING(mgr->active_streams.fn_source);
    AGG_ON_PENDING(mgr->active_streams.aes67_sink);
    AGG_ON_PENDING(mgr->active_streams.aes67_source);

#undef AGG_ON_PENDING

    read_unlock_irqrestore(&mgr->rtp.lock, flags);
}


static enum hrtimer_restart audio_frame_tick_hrtimer(struct hrtimer *timer)
{
    struct fusion_cn_manager *mgr = container_of(timer, struct fusion_cn_manager, ptp.audio_timer);

    mgr->ptp.hrtimer_last_tick_ns = mgr->ptp.hrtimer_next_tick_ns;

    mgr->ptp.hrtimer_next_tick_ns += TIMER_BASE_INTERVAL_NS;
    // after 3 ticks, square the tick with the ms
    if (++mgr->ptp.tick_count % 3 == 0) {
        mgr->ptp.tick_count = 0;
        mgr->ptp.hrtimer_next_tick_ns += 1;
    }

        /* Defer TX work to RT kthread */
    if (likely(atomic_inc_return(&process_pending) == 1))
        kthread_queue_work(process_worker, &process_work);

    hrtimer_start(timer, ns_to_ktime(mgr->ptp.hrtimer_next_tick_ns), HRTIMER_MODE_ABS);

    return HRTIMER_RESTART;
}

/* Manager Functions */
static int fusion_cn_state_init(struct fusion_cn_manager *mgr)
{
    atomic_set(&mgr->state.is_started, false);
    atomic_set(&mgr->state.ptp_synchronized, false);
    return 0;
}

static struct fusion_cn_rtp_ops rtp_ops = {
    .get_phc_ns = fusion_cn_rtp_get_phc_ns,
    .get_buffer = fusion_cn_rtp_ops_get_buffer,
    .get_buffer_size_in_frames = fusion_cn_rtp_ops_get_buffer_size_in_frames,
    .get_buffer_offset = fusion_cn_rtp_ops_get_buffer_offset
};

static int fusion_cn_alsa_init(struct fusion_cn_manager *mgr)
{
    mgr->alsa.alsa_callbacks = &fusion_cn_alsa_ops;
    return fusion_cn_alsa_driver_init(mgr, &fusion_cn_alsa_ops);
}

/* --- Coalesced queue helper (re-uses your existing worker) --- */
static inline void fusion_cn_queue_process(void)
{
    struct kthread_worker *worker = READ_ONCE(process_worker);

    /* Ignore ticks until worker is created and work item initialized */
    if (!worker)
        return;

    /* Coalesce: only queue if not already pending */
    if (atomic_cmpxchg(&process_pending, 0, 1) == 0)
        kthread_queue_work(worker, &process_work);
}

/* --- GPT client callback (softirq via irq_work) --- */
static void fusion_cn_gpt_tick(void *ctx, u64 tick64)
{
    struct fusion_cn_manager *mgr = ctx;
    u64 now_ns = tick64 * GPT_TICK_NS;

    mgr->ptp.hrtimer_last_tick_ns = now_ns;
    mgr->ptp.hrtimer_next_tick_ns = now_ns + TIMER_BASE_INTERVAL_NS;
    if (++mgr->ptp.tick_count == 3) {
        mgr->ptp.tick_count = 0;
        mgr->ptp.hrtimer_next_tick_ns += 1;
    }

    /* Keep it tiny: just queue your existing work */
    fusion_cn_queue_process();
}

static const struct fusion_gpt_client_ops fusion_cn_gpt_ops = {
    .tick = fusion_cn_gpt_tick,
};

static int fusion_cn_ptp_init(struct fusion_cn_manager *mgr)
{
    if (mgr->ptp.ptp_timing_mode == TIMING_GPT) {
        int ret;
        u64 now_ns;

        rtp_ops.get_phc_ns = fusion_cn_gpt_get_phc_ns;
        mgr->ptp.tick_count = 0;

        ret = fusion_gpt_register_client(&fusion_cn_gpt_ops, mgr, THIS_MODULE);
        if (ret) {
            pr_err("fusion_cn: GPT register failed: %d\n", ret);
            return ret;
        }

        /* Seed timebase from current GPT tick */
        now_ns = fusion_cn_gpt_get_phc_ns();
        mgr->ptp.hrtimer_last_tick_ns = now_ns;
        mgr->ptp.hrtimer_next_tick_ns = now_ns + TIMER_BASE_INTERVAL_NS;
        pr_info("fusion_cn: GPT timing active (10MHz, 1/3ms compares)\n");
    } else {
        mgr->ptp.ptp_timing_mode = TIMING_HRTIMER;
        hrtimer_init(&mgr->ptp.audio_timer, CLOCK_REALTIME, HRTIMER_MODE_ABS);
        mgr->ptp.audio_timer.function = audio_frame_tick_hrtimer;
        mgr->ptp.tick_count = 0;
    }
    printk(KERN_DEBUG "fusion_cn: Initialized with %s timing\n",
           mgr->ptp.ptp_timing_mode == TIMING_HRTIMER ? "hrtimer" : "GPT");
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

    atomic_set(&mgr->netlink.ready, true);

    return 0;
}

void fusion_cn_nl_destroy(struct fusion_cn_manager *mgr)
{
    atomic_set(&mgr->netlink.ready, false);

    if (mgr->netlink.nl_sock) {
        netlink_kernel_release(mgr->netlink.nl_sock);
    }
}

int fusion_cn_mgr_init(struct fusion_cn_manager *mgr)
{
    int ret;

    fusion_cn_state_init(mgr);
    if ((ret = fusion_cn_alsa_init(mgr)) < 0) goto err;
    if ((ret = fusion_cn_rtp_init(&mgr->rtp, &mgr->netfilter, &rtp_ops, mgr)) < 0) goto err_rtp;
    if ((ret = fusion_cn_nf_init(&mgr->rtp)) < 0) goto err_nf;
    if ((ret = fusion_cn_ptp_init(mgr)) < 0) goto err_ptp;
    if ((ret = fusion_cn_nl_init(mgr)) < 0) goto err_nl;

    return 0;

err_nl:
err_ptp:
    fusion_cn_nf_destroy(&mgr->netfilter);
err_nf:
    fusion_cn_rtp_destroy(&mgr->rtp);
err_rtp:
    fusion_cn_alsa_destroy();
err:
    return ret;
}

void fusion_cn_mgr_destroy(struct fusion_cn_manager *mgr)
{
    if (!mgr) return;

    /* Stop netlink communication first to prevent new commands */
    fusion_cn_nl_destroy(mgr);

    /* Unregister netfilter hook to stop packet processing */
    fusion_cn_nf_destroy(&mgr->netfilter);

    /* Stop PTP timing to prevent further audio frame processing */
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPT) {
        fusion_gpt_unregister_client();
    }

    /* Stop RTP streams, which might be using ALSA buffers */
    fusion_cn_rtp_destroy(&mgr->rtp);

    /* Finally, clean up the ALSA card */
    fusion_cn_alsa_destroy();

    /* Clear the RTP manager to prevent use-after-free */
    memset(&mgr->rtp, 0, sizeof(mgr->rtp));
}

enum mgr_start_errno {
    MGR_START_OK = 0,
    MGR_START_ERRNO_RUNNING,
    MGR_START_ERRNO_PTP,
    MGR_START_ERRNO_MODE
};

/* kthread worker routine: drains coalesced ticks */
static void audio_frame_process_work(struct kthread_work *work)
{
    int n = atomic_xchg(&process_pending, 0);
    while (n-- > 0) {
        audio_frame_process(g_fusion_cn_mgr);

        do_metrics(g_fusion_cn_mgr);
    }
}

int fusion_cn_mgr_start(struct fusion_cn_manager *mgr)
{
    struct kthread_worker *worker;

    if (atomic_read(&mgr->state.is_started)) {
        printk(KERN_DEBUG "fusion_cn: mgr already started\n");
        return -MGR_START_ERRNO_RUNNING;
    }
    if (!atomic_read(&mgr->state.ptp_synchronized)) {
        printk(KERN_ERR "fusion_cn: ptp not sync'd\n");
        return -MGR_START_ERRNO_PTP;
    }

    
    /* Initialize PREEMPT_RT-friendly TX worker once */
    if (!process_worker) {
        worker = kthread_create_worker(0, "fusion-cn");
        if (IS_ERR(worker)) {
            int err = PTR_ERR(worker);
            printk(KERN_ERR "fusion_cn: failed to create fusion-cn worker: %d\n", err);
            return err;
        }
        process_thread = worker->task;
        set_cpus_allowed_ptr(process_thread, cpumask_of(0));
        sched_set_fifo_low(process_thread);   /* or: sched_set_fifo(process_thread) for max RT prio */
        kthread_init_work(&process_work, audio_frame_process_work);
        atomic_set(&process_pending, 0);
        /* Publish the worker only after fully initialized */
        smp_wmb();
        process_worker = worker;
    }
    g_fusion_cn_mgr = mgr;
    INIT_LIST_HEAD(&mgr->active_streams.fn_sink);
    INIT_LIST_HEAD(&mgr->active_streams.fn_source);
    INIT_LIST_HEAD(&mgr->active_streams.aes67_sink);
    INIT_LIST_HEAD(&mgr->active_streams.aes67_source);

    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        u64 current_phc_ns;
        u64 first_tick;

        // Get current PHC time
        current_phc_ns = fusion_cn_rtp_get_phc_ns();
        if (current_phc_ns == 0) {
            printk(KERN_ERR "fusion_cn: mgr_start: Failed to get PHC time\n");
            return -MGR_START_ERRNO_PTP;
        }

        // Align to the next 1 ms boundary
        first_tick = current_phc_ns - (current_phc_ns % NSEC_PER_MSEC) + NSEC_PER_MSEC;

        // Start hrtimer first tick to the next 1 ms boundary
        hrtimer_start(&mgr->ptp.audio_timer, ns_to_ktime(first_tick), HRTIMER_MODE_ABS);
        mgr->ptp.hrtimer_next_tick_ns = first_tick;
        mgr->ptp.tick_count = 0; // start from 1 bc next tick
        printk(KERN_DEBUG "fusion_cn: mgr_start: Aligned hrtimer to PHC boundary, current_phc=%llu, first_tick=%llu ns\n",
               current_phc_ns, first_tick);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPT) {
        /* GPT ticks are driven by fusion_gpt; nothing to start here */
    } else {
        printk(KERN_ERR "fusion_cn: Invalid timing mode\n");
        return -MGR_START_ERRNO_MODE;
    }

    atomic_set(&mgr->netfilter.is_enabled, true);
    atomic_set(&mgr->state.is_started, true);
    printk(KERN_DEBUG "fusion_cn: mgr_start: Started manager\n");
    return MGR_START_OK;
}

bool fusion_cn_mgr_stop(struct fusion_cn_manager *mgr)
{
    if (!mgr || !atomic_read(&mgr->state.is_started)) return false;
    if (mgr->ptp.ptp_timing_mode == TIMING_HRTIMER) {
        hrtimer_cancel(&mgr->ptp.audio_timer);
    } else if (mgr->ptp.ptp_timing_mode == TIMING_GPT) {
        fusion_gpt_unregister_client();
    }
    
    /* Flush and destroy TX worker on stop */
    if (process_worker) {
        kthread_flush_worker(process_worker);
        kthread_destroy_worker(process_worker);
        process_worker = NULL;
        process_thread = NULL;
        atomic_set(&process_pending, 0);
        g_fusion_cn_mgr = NULL;
    }
    
    atomic_set(&mgr->netfilter.is_enabled, false);
    atomic_set(&mgr->state.is_started, false);
    printk(KERN_DEBUG "fusion_cn: mgr_start: Stopped manager\n");
    return true;
}

/* Message Handlers */
static int handle_start(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                        struct fusion_cn_ctrl_msg *reply)
{
    reply->err = fusion_cn_mgr_start(mgr);
    return 0;
}

static int handle_stop(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                    struct fusion_cn_ctrl_msg *reply)
{
    reply->err = fusion_cn_mgr_stop(mgr) ? 0 : -EIO;
    return 0;
}

static int handle_set_ptp_sync(struct fusion_cn_manager *mgr,
                               struct fusion_cn_ctrl_msg *msg,
                               struct fusion_cn_ctrl_msg *reply)
{
    u8 ptp_sync = 0;

    if (msg->data_size != sizeof(u8) || !msg->data) {
        reply->err = -EINVAL;
        return 0;
    }

    ptp_sync = *(u8 *)msg->data;
    printk(KERN_DEBUG "fusion_cn: Setting ptp sync=%s\n", ptp_sync ? "true" : "false");
    atomic_set(&mgr->state.ptp_synchronized, ptp_sync);
    reply->err = 0;
    return 0;
}

// does work to remove stream
// handle_add_stream krefs must be put OUTSIDE of func!
static int remove_stream(struct fusion_cn_manager *mgr,
                         u64 handle, char *stream_name,
                         struct fusion_cn_rtp_stream *rtp_stream,
                         struct fusion_cn_substream *alsa_stream)
{
    struct stream_node *sn = rtp_stream->stream_node;
    int ret;
    unsigned long flags;

    /* Stop stream activity */
    ret = alsa_ops_stop_interrupts(mgr, handle);
    if (ret < 0)
        pr_warn("fusion_cn: remove_stream: stop_interrupts (%s) = %d\n", stream_name, ret);

    /* Unlink node from active lists and clear back-pointer */
    write_lock_irqsave(&mgr->rtp.lock, flags);
    sn = rtp_stream->stream_node;
    list_del_init(&sn->node);
    kfree(sn);
    rtp_stream->stream_node = NULL;
    write_unlock_irqrestore(&mgr->rtp.lock, flags);

    /* Remove RTP stream from hash/lists */
    write_lock_irqsave(&mgr->rtp.lock, flags);
    ret = fusion_cn_rtp_remove_stream(&mgr->rtp, rtp_stream);
    write_unlock_irqrestore(&mgr->rtp.lock, flags);
    if (ret < 0) {
        pr_warn("fusion_cn: remove_stream: rtp_remove_stream (%s) failed with %d\n", stream_name, ret);
        return ret;
    }

    /* Free metrics and node now that readers can’t see it */
    fusion_cn_metrics_destroy(rtp_stream->metrics);
    rtp_stream->metrics = NULL;

    ret = fusion_cn_alsa_remove_substream(alsa_stream);
    
    return ret;
}

static int handle_add_stream(struct fusion_cn_manager *mgr, struct fusion_cn_ctrl_msg *msg,
                             struct fusion_cn_ctrl_msg *reply)
{
    struct fusion_cn_stream_config *config;
    struct fusion_cn_rtp_stream *rtp_stream;
    struct fusion_cn_substream *alsa_stream;
    struct fusion_cn_stream_metrics *stream_metrics;
    struct stream_node *stream_node;
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
            hlist_for_each_entry(rtp_stream, &mgr->rtp.streams[bucket], hnode) {
                if (rtp_stream->info.stream_handle == config->stream_handle) {
                    config->stream_handle = 0;
                    break;
                }
            }
            read_unlock_irqrestore(&mgr->rtp.lock, flags);
        } while (config->stream_handle == 0);
    } else {
        bucket = hash_64(config->stream_handle, FUSION_CN_RTP_HASH_BITS);
        read_lock_irqsave(&mgr->rtp.lock, flags);
        hlist_for_each_entry(rtp_stream, &mgr->rtp.streams[bucket], hnode) {
            if (rtp_stream->info.stream_handle == config->stream_handle) {
                read_unlock_irqrestore(&mgr->rtp.lock, flags);
                printk(KERN_ERR "fusion_cn: handle_add_stream: Stream handle %llu already exists\n", config->stream_handle);
                return reply->err = -EEXIST;
            }
        }
        read_unlock_irqrestore(&mgr->rtp.lock, flags);
    }

    /* for rtp source we have alsa playback and vice versa */
    direction = config->is_source ? SNDRV_PCM_STREAM_PLAYBACK : SNDRV_PCM_STREAM_CAPTURE;
    ret = fusion_cn_alsa_open_substream(mgr->alsa.alsa_chip, config->stream_handle, config->stream_name, direction,
                                        config->channels, config->sample_rate, config->format, config->frames_per_packet, &alsa_stream);
    if (ret < 0 || alsa_stream == NULL) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: alsa_open_substream failed for %s: %d\n", config->stream_name, ret);
        return reply->err = ret;
    }

    ret = fusion_cn_rtp_add_stream(&mgr->rtp, config, alsa_stream, &rtp_stream);
    if (ret < 0 || rtp_stream == NULL) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: fusion_cn_rtp_add_stream failed for %s: %d\n", config->stream_name, ret);
        fusion_cn_alsa_remove_substream(alsa_stream);
        return reply->err = ret;
    }

    stream_metrics = fusion_cn_metrics_create(rtp_stream->info.sample_rate, rtp_stream->info.playout_delay);
    if (!stream_metrics) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: Failed to create stream_metrics\n");
        fusion_cn_rtp_remove_stream(&mgr->rtp, rtp_stream);
        fusion_cn_alsa_remove_substream(alsa_stream);
        return reply->err = -ENOMEM;
    }

    stream_node = kzalloc(sizeof(*stream_node), GFP_KERNEL);
    if (!stream_node) {
        fusion_cn_metrics_destroy(stream_metrics);
        printk(KERN_ERR "fusion_cn: handle_add_stream: Failed to allocate stream_node\n");
        fusion_cn_rtp_remove_stream(&mgr->rtp, rtp_stream);
        fusion_cn_alsa_remove_substream(alsa_stream);
        return reply->err = -ENOMEM;
    }

    stream_node->rtp_stream  = rtp_stream;
    stream_node->alsa_stream = alsa_stream;
    rtp_stream->metrics = stream_metrics;

    rtp_stream->stream_node = stream_node;

    /* add to active list under write lock */
    write_lock_irqsave(&mgr->rtp.lock, flags);
    if (!config->is_source) {
        if (config->is_fusion_connect)
            list_add_tail(&stream_node->node, &mgr->active_streams.fn_sink);
        else
            list_add_tail(&stream_node->node, &mgr->active_streams.aes67_sink);
    } else {
        if (config->is_fusion_connect)
            list_add_tail(&stream_node->node, &mgr->active_streams.fn_source);
        else
            list_add_tail(&stream_node->node, &mgr->active_streams.aes67_source);
    }
    write_unlock_irqrestore(&mgr->rtp.lock, flags);

    reply->err = 0;
    reply->data_size = sizeof(u64);
    reply->data = kmemdup(&rtp_stream->info.stream_handle, sizeof(rtp_stream->info.stream_handle), GFP_KERNEL);
    if (!reply->data) {
        printk(KERN_ERR "fusion_cn: handle_add_stream: kmemdup failed\n");
        remove_stream(mgr, config->stream_handle, config->stream_name, rtp_stream, alsa_stream);
        return reply->err = -ENOMEM;
    }

    /* hold extra refs while on list */
    kref_get(&rtp_stream->ref);
    kref_get(&alsa_stream->ref);

    printk(KERN_DEBUG "fusion_cn: handle_add_stream: Success, name=%s, handle=%llu\n",
           config->stream_name, config->stream_handle);
    return 0;
}

static int handle_remove_stream(struct fusion_cn_manager *mgr,
                                struct fusion_cn_ctrl_msg *msg,
                                struct fusion_cn_ctrl_msg *reply)
{
    u64 handle;
    unsigned long flags;
    struct fusion_cn_rtp_stream *rtp_stream;
    struct fusion_cn_substream  *alsa_stream;
    char stream_name[FUSION_CN_NAME_MAX];

    if (msg->data_size != sizeof(u64))
        return (reply->err = -EINVAL);

    handle = *(u64 *)msg->data;

    /* Get RTP (with ref) and copy name */
    read_lock_irqsave(&mgr->rtp.lock, flags);
    rtp_stream = fusion_cn_rtp_get_stream(&mgr->rtp, handle);
    if (!rtp_stream) {
        read_unlock_irqrestore(&mgr->rtp.lock, flags);
        pr_err("fusion_cn: handle_remove_stream: rtp stream %llu not found\n", handle);
        return (reply->err = -ENOENT);
    }
    strscpy(stream_name, rtp_stream->info.stream_name, sizeof(stream_name));
    read_unlock_irqrestore(&mgr->rtp.lock, flags);

    alsa_stream = fusion_cn_find_substream(stream_name);
    if (!alsa_stream) {
        pr_warn("fusion_cn: handle_remove_stream: alsa stream %s not found\n", stream_name);
        return (reply->err = -ENOENT);
    }

    reply->err = remove_stream(mgr, handle, stream_name, rtp_stream, alsa_stream);

    /* Drop temp refs from find/get stream() */
    kref_put(&alsa_stream->ref, fusion_cn_alsa_substream_release);
    kref_put(&rtp_stream->ref, fusion_cn_rtp_stream_release);

    /* Drop temp refs from handle_add_stream */
    kref_put(&alsa_stream->ref, fusion_cn_alsa_substream_release);
    kref_put(&rtp_stream->ref, fusion_cn_rtp_stream_release);

    return reply->err;
}

static int handle_get_metrics(struct fusion_cn_manager *mgr,
                              struct fusion_cn_ctrl_msg *msg,
                              struct fusion_cn_ctrl_msg *reply)
{
    u64 req_handle = 0;
    unsigned long flags;
    size_t count = 0, cap = 0;
    struct fusion_cn_metrics_record *out = NULL;

    if (msg->data_size == sizeof(u64)) {
        req_handle = *(u64 *)msg->data;
    } else if (msg->data_size != 0) {
        return reply->err = -EINVAL;
    }

    if (req_handle != 0) {
        /* fusion_cn_rtp_get_stream() acquires/releases mgr->rtp.lock internally */
        struct fusion_cn_rtp_stream *r = fusion_cn_rtp_get_stream(&mgr->rtp, req_handle);
        if (!r) {
            return reply->err = -ENOENT;
        }

        out = kmalloc(sizeof(*out), GFP_KERNEL);
        if (!out) {
            kref_put(&r->ref, fusion_cn_rtp_stream_release);
            return reply->err = -ENOMEM;
        }

        fusion_cn_metrics_read_snapshot(r->metrics, &out->snap);
        out->handle = req_handle;
        strscpy(out->stream_name, r->info.stream_name, sizeof(out->stream_name));

        /* drop temp ref from _get_stream */
        kref_put(&r->ref, fusion_cn_rtp_stream_release);

        reply->data      = (void *)out;
        reply->data_size = sizeof(*out);
        reply->err       = 0;
        return 0;
    }

    /* --- enumerate all active streams --- */
#define COUNT_LIST(head) \
    list_for_each_entry(tmp_node, &(head), node) { count++; }

    read_lock_irqsave(&mgr->rtp.lock, flags);
    {
        struct stream_node *tmp_node;
        COUNT_LIST(mgr->active_streams.fn_sink);
        COUNT_LIST(mgr->active_streams.fn_source);
        COUNT_LIST(mgr->active_streams.aes67_sink);
        COUNT_LIST(mgr->active_streams.aes67_source);
    }
    cap = count;
    read_unlock_irqrestore(&mgr->rtp.lock, flags);

    if (!cap) {
        reply->data = NULL;
        reply->data_size = 0;
        reply->err = 0;
        return 0;
    }

    out = kcalloc(cap, sizeof(*out), GFP_KERNEL);
    if (!out) return reply->err = -ENOMEM;

    /* Second pass: fill (re-lock for stable traversal) */
    read_lock_irqsave(&mgr->rtp.lock, flags);
    {
        struct stream_node *n;
        size_t i = 0;

#define FILL_LIST(head) \
    list_for_each_entry(n, &(head), node) { \
        struct fusion_cn_rtp_stream *r = n->rtp_stream; \
        if (!r || !r->metrics) continue; \
        if (!atomic_read(&r->is_running)) continue; \
        out[i].handle = r->info.stream_handle; \
        strscpy(out[i].stream_name, r->info.stream_name, sizeof(out[i].stream_name)); \
        fusion_cn_metrics_read_snapshot(r->metrics, &out[i].snap); \
        i++; \
    }

        FILL_LIST(mgr->active_streams.fn_sink);
        FILL_LIST(mgr->active_streams.fn_source);
        FILL_LIST(mgr->active_streams.aes67_sink);
        FILL_LIST(mgr->active_streams.aes67_source);

        cap = i;
    }
    read_unlock_irqrestore(&mgr->rtp.lock, flags);

    reply->data      = out;
    reply->data_size = cap * sizeof(*out);
    reply->err       = 0;
    return 0;
}

static const struct message_handler_entry message_handlers[] = {
    { FUSION_CN_CTRL_CMD_START_MANAGER, handle_start },
    { FUSION_CN_CTRL_CMD_STOP_MANAGER,  handle_stop },
    { FUSION_CN_CTRL_CMD_SET_PTP_SYNC,  handle_set_ptp_sync },
    { FUSION_CN_CTRL_CMD_ADD_STREAM,    handle_add_stream },
    { FUSION_CN_CTRL_CMD_REMOVE_STREAM, handle_remove_stream },
    { FUSION_CN_CTRL_CMD_GET_METRICS,   handle_get_metrics },
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

    if (!atomic_read(&mgr->netlink.ready)) return;

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
    struct fusion_cn_manager *mgr = skb->sk ? skb->sk->sk_user_data : NULL;
    struct nlmsghdr *nlh;
    struct fusion_cn_ctrl_msg msg_rcv;

    if (!mgr) return;

    nlh = nlmsg_hdr(skb);
    if (!nlmsg_ok(nlh, skb->len)) {
        pr_err("fusion_cn: Netlink message malformed (nlmsg_ok fail)\n");
        return;
    }

    /* Require at least the header */
    if (nlmsg_len(nlh) < sizeof(struct fusion_cn_ctrl_msg)) {
        pr_err("fusion_cn: Netlink message too short (%u < %zu)\n",
               nlmsg_len(nlh), sizeof(struct fusion_cn_ctrl_msg));
        return;
    }

    memcpy(&msg_rcv, nlmsg_data(nlh), sizeof(msg_rcv));

    {
        u32 payload_avail = nlmsg_len(nlh) - sizeof(struct fusion_cn_ctrl_msg);
        if (msg_rcv.data_size > payload_avail) {
            pr_err("fusion_cn: Netlink data_size %u > payload %u\n",
                   msg_rcv.data_size, payload_avail);
            msg_rcv.data_size = 0;
            msg_rcv.data = NULL;
        } else if (msg_rcv.data_size) {
            msg_rcv.data = (u8 *)nlmsg_data(nlh) + sizeof(struct fusion_cn_ctrl_msg);
        } else {
            msg_rcv.data = NULL;
        }
    }

    msg_rcv.pid = nlh->nlmsg_pid;
    fusion_cn_process_nl_msg(mgr, &msg_rcv);
}

#include <linux/slab.h>
#include <linux/errno.h>
#include <linux/jiffies.h>
#include <linux/minmax.h>
#include <linux/ktime.h>
#include <linux/smp.h>
#include "fusion_connect_manager.h"
#include "fusion_connect_metrics.h"

#define EWMA_P50_SHIFT 3   /* 1/8 */
#define EWMA_P99_UP   2    /* 1/4 up */
#define EWMA_P99_DOWN 5    /* 1/32 down */

static inline u32 abs32s(s32 x) { return x < 0 ? -x : x; }

/* convert RTP timestamp-domain delta to nanoseconds */
static inline u32 rtp_units_to_ns(u32 units, u32 rate)
{
    if (!rate) return 0;
    /* (units * 1e9) / rate, rounded */
    u64 n = (u64)units * 1000000000ULL + (rate/2);
    do_div(n, rate);
    return (u32)n;
}

/* convert ns delta to RTP timestamp domain (for jitter transit calc)
 * NOTE: expects a *delta* (can be negative), not an absolute timestamp.
 */
static inline s32 ns_delta_to_rtp_units(s64 ns, u32 rate)
{
    if (!rate) return 0;
    /* (ns * rate) / 1e9 */
    return (s32)div_s64(ns * (s64)rate, 1000000000LL);
}

/* wrap-safe 32-bit RTP delta (signed) */
static inline s32 rtp32_delta(u32 a, u32 b) { return (s32)(a - b); }

/* Fold-only TX path: per-CPU counters -> snapshot, and stamp ts */
void fusion_cn_metrics_aggregate_tx(struct fusion_cn_stream_metrics *m)
{
    u64 tx_pkts = 0, tx_bytes = 0;
    int cpu;

    for_each_possible_cpu(cpu) {
        const struct fusion_cn_metrics_pcpu *p = per_cpu_ptr(m->pcpu, cpu);
        unsigned int start;
        u64 tp, tb;

        do {
            start = u64_stats_fetch_begin(&p->syncp);
            tp = p->tx_packets_total;
            tb = p->tx_bytes_total;
        } while (u64_stats_fetch_retry(&p->syncp, start));

        tx_pkts  += tp;
        tx_bytes += tb;
    }

    m->snap.tx_packets_total = tx_pkts;
    m->snap.tx_bytes_total   = tx_bytes;

    /* copy EMAs from window */
    m->snap.tx_iat_min_ns            = m->win.tx_iat_min_ns;
    m->snap.tx_iat_p50_ns            = m->win.tx_iat_p50_ns;
    m->snap.tx_iat_p99_ns            = m->win.tx_iat_p99_ns;
    m->snap.tx_sched_err_abs_p50_ns  = m->win.tx_sched_err_abs_p50_ns;

    /* Always give TX streams a fresh timestamp so userspace sees progress */
    m->snap.ts_snapshot_ns = fusion_cn_get_phc_ns();
}

/* Helpers for 16-bit sequence arithmetic */
static inline bool seq16_after(u16 a, u16 b)  { return (s16)(a - b) > 0; }
static inline bool seq16_before(u16 a, u16 b) { return seq16_after(b, a); }

void fusion_cn_metrics_aggregate_rx(struct fusion_cn_stream_metrics *m,
                                    u32 jb_depth_samples)
{
    struct fusion_cn_metrics_window *w = &m->win;

    /* === 1) Drain RX ring ===
     * Producer publishes wr_idx with store-release; we load with acquire.
     */
    u32 rd = m->rd_idx;
    u32 wr = smp_load_acquire(&m->wr_idx);

    u64 last_arrival = w->last_arrival_ns;
    bool last_rtp_ts_valid = false;
    u32 last_rtp_ts = 0;

    while (rd != wr) {
        const struct fusion_cn_pkt_sample s = m->ring[rd & m->ring_mask];
        rd++;

        /* --- Inter-arrival time (ns) with EWMA(p50) and pseudo-p99 --- */
        if (last_arrival) {
            u32 iat = (u32)(s.arrival_phc_ns - last_arrival);

            if (!w->iat_min_ns || iat < w->iat_min_ns)
                w->iat_min_ns = iat;

            if (!w->iat_p50_ns) w->iat_p50_ns = iat;
            if (!w->iat_p99_ns) w->iat_p99_ns = iat;

            /* p50 EWMA: small right shift => slow/robust */
            w->iat_p50_ns += ((s32)iat - (s32)w->iat_p50_ns) >> EWMA_P50_SHIFT;

            /* pseudo-p99: chase up fast, decay down slow */
            if (iat > w->iat_p99_ns)
                w->iat_p99_ns += (iat - w->iat_p99_ns) >> EWMA_P99_UP;
            else
                w->iat_p99_ns -= (w->iat_p99_ns - iat) >> EWMA_P99_DOWN;
        }
        last_arrival = s.arrival_phc_ns;

        /* --- Loss / reorder across 16-bit sequence space --- */
        if (!w->expected_seq_valid) {
            w->expected_seq = (u16)(s.seq + 1);
            w->expected_seq_valid = true;
            w->burst_loss_cur = 0;
        } else {
            u16 exp = (u16)w->expected_seq;
            u16 got = (u16)s.seq;

            if (got == exp) {
                /* in-order */
                w->expected_seq = (u16)(exp + 1);
                w->burst_loss_cur = 0;
            } else if (seq16_after(got, exp)) {
                /* forward jump => gap => lost packets */
                u16 fwd = (u16)(got - exp);
                w->packets_lost += fwd;
                w->burst_loss_cur += fwd;
                if (w->burst_loss_cur > w->burst_loss_max)
                    w->burst_loss_max = w->burst_loss_cur;
                w->expected_seq = (u16)(got + 1);
            } else {
                /* got < exp => reordering */
                w->packets_reordered++;
            }
        }

        /* --- RFC3550 jitter (transit variance), keep signed math then cast --- */
        if (w->rtp_clock_rate) {
            if (last_rtp_ts_valid) {
                s64 d_arrival_ns = (s64)s.arrival_phc_ns - (s64)w->last_arrival_ns;
                s32 dR = rtp32_delta(s.rtp_ts, last_rtp_ts);
                s32 dA = ns_delta_to_rtp_units(d_arrival_ns, w->rtp_clock_rate);

                s32 D = dA - dR;
                if (D < 0) D = -D;

                /* J = J + (|D| - J)/16 */
                s64 acc  = (s64)w->rfc3550_jitter_ts_fp;
                s64 diff = (s64)D - acc;
                acc += diff >> 4;
                if (acc < 0) acc = 0;

                w->rfc3550_jitter_ts_fp = (u64)acc;
                w->rfc3550_jitter_ns    = rtp_units_to_ns((u32)acc, w->rtp_clock_rate);
            }
            last_rtp_ts = s.rtp_ts;
            last_rtp_ts_valid = true;
        }

        /* ---- path/e2e latencies (clamped to u32) ---- */
        {
            s64 path = (s64)s.arrival_phc_ns - (s64)s.recon_phc_ns;
            if (path < 0) path = 0;
            if (path > (s64)U32_MAX) path = (s64)U32_MAX;
            w->path_latency_est_ns = (u32)path;

            s64 e2e = (s64)s.sched_ns - (s64)s.recon_phc_ns;
            if (e2e < 0) e2e = 0;
            if (e2e > (s64)U32_MAX) e2e = (s64)U32_MAX;
            w->e2e_playout_latency_ns = (u32)e2e;
        }

        w->last_arrival_ns = s.arrival_phc_ns;
    }
    m->rd_idx = rd;

    /* === 2) Fold per-CPU counters into snapshot === */
    {
        u64 pkts=0, bytes=0, dup=0, marked=0, mal=0, late_d=0;
        u64 tx_pkts=0, tx_bytes=0;
        int cpu;

        for_each_possible_cpu(cpu) {
            const struct fusion_cn_metrics_pcpu *p = per_cpu_ptr(m->pcpu, cpu);
            unsigned int start;
            u64 a,b,c,d,e,f, txp, txb;

            do {
                start = u64_stats_fetch_begin(&p->syncp);
                a = p->packets_total;
                b = p->bytes_total;
                c = p->packets_dup;
                d = p->packets_marked;
                e = p->malformed_count;
                f = p->late_drop_count;
                txp = p->tx_packets_total;
                txb = p->tx_bytes_total;
            } while (u64_stats_fetch_retry(&p->syncp, start));

            pkts   += a; bytes += b; dup += c; marked += d; mal += e;
            late_d += f;
            tx_pkts += txp; tx_bytes += txb;
        }

        m->snap.packets_total    = pkts;
        m->snap.bytes_total      = bytes;
        m->snap.packets_dup      = dup;
        m->snap.packets_marked   = marked;
        m->snap.malformed_count  = mal;
        m->snap.late_drop_count  = late_d;

        m->snap.packets_reordered = w->packets_reordered;
        m->snap.packets_lost      = w->packets_lost;
        m->snap.burst_loss_max    = w->burst_loss_max;

        m->snap.rfc3550_jitter_ns = w->rfc3550_jitter_ns;

        m->snap.iat_min_ns = w->iat_min_ns;
        m->snap.iat_p50_ns = w->iat_p50_ns;
        m->snap.iat_p99_ns = w->iat_p99_ns;

        /* Mirror TX totals here so the snapshot is self-contained */
        m->snap.tx_packets_total = tx_pkts;
        m->snap.tx_bytes_total   = tx_bytes;

        m->snap.path_latency_est_ns    = w->path_latency_est_ns;
        m->snap.e2e_playout_latency_ns = w->e2e_playout_latency_ns;
    }

    /* === 3) JB depth stats (samples) === */
    w->jb_depth_cur_samples = jb_depth_samples;
    if (w->jb_depth_min_samples == UINT_MAX)
        w->jb_depth_min_samples = jb_depth_samples;
    if (jb_depth_samples < w->jb_depth_min_samples)
        w->jb_depth_min_samples = jb_depth_samples;
    if (jb_depth_samples > w->jb_depth_max_samples)
        w->jb_depth_max_samples = jb_depth_samples;
    w->jb_depth_sum_samples += jb_depth_samples;
    w->jb_depth_count++;

    m->snap.jb_depth_cur_samples = w->jb_depth_cur_samples;
    m->snap.jb_depth_min_samples = w->jb_depth_min_samples;
    m->snap.jb_depth_max_samples = w->jb_depth_max_samples;
    m->snap.jb_depth_avg_samples =
        w->jb_depth_count ? (u32)(w->jb_depth_sum_samples / w->jb_depth_count) : 0;

    /* === 4) Final snapshot timestamp === */
    m->snap.ts_snapshot_ns = fusion_cn_get_phc_ns();
}

static inline u32 fc_ns_to_samples(u64 ns, u32 rate)
{
    /* half-up rounding */
    return (u32)((ns * rate + 500000000ULL) / 1000000000ULL);
}

struct fusion_cn_stream_metrics *fusion_cn_metrics_create(u32 sample_rate, u64 playout_delay)
{
    struct fusion_cn_stream_metrics *m;
    int cpu;

    m = kzalloc(sizeof(*m), GFP_KERNEL);
    if (!m)
        return NULL;

    m->ring = kmalloc_array(FUSION_CN_METRICS_RING_SIZE,
                            sizeof(*m->ring), GFP_KERNEL | __GFP_ZERO);
    if (!m->ring)
        goto err_free_ctx;

    m->ring_mask = FUSION_CN_METRICS_RING_SIZE - 1;
    m->wr_idx = 0;   /* SPSC producer index (published with store-release) */
    m->rd_idx = 0;

    m->pcpu = alloc_percpu(struct fusion_cn_metrics_pcpu);
    if (!m->pcpu)
        goto err_free_ring;

    /* init per-cpu seq counters */
    for_each_possible_cpu(cpu) {
        struct fusion_cn_metrics_pcpu *p = per_cpu_ptr(m->pcpu, cpu);
        u64_stats_init(&p->syncp);
    }

    /* ---- Window defaults ---- */
    m->win.expected_seq_valid = false;
    m->win.burst_loss_cur = 0;
    m->win.burst_loss_max = 0;

    m->win.last_arrival_ns = 0;
    m->win.iat_min_ns = UINT_MAX;
    m->win.iat_p50_ns = 0;
    m->win.iat_p99_ns = 0;

    m->win.jb_depth_cur_samples = 0;
    m->win.jb_depth_min_samples = UINT_MAX;
    m->win.jb_depth_max_samples = 0;
    m->win.jb_depth_sum_samples = 0;
    m->win.jb_depth_count = 0;

    m->win.rtp_clock_rate = sample_rate;

    /* Snapshot starts empty; aggregator will fill */
    m->snap.ts_snapshot_ns = 0;

    return m;

err_free_ring:
    kfree(m->ring);
err_free_ctx:
    kfree(m);
    return NULL;
}

void fusion_cn_metrics_read_snapshot(
    const struct fusion_cn_stream_metrics *m,
    struct fusion_cn_metrics_snapshot *out)
{
    /* Best-effort copy; writer updates m->snap in do_metrics/aggregate */
    memcpy(out, &m->snap, sizeof(*out));
}

void fusion_cn_metrics_destroy(struct fusion_cn_stream_metrics *m)
{
    if (!m)
        return;

    free_percpu(m->pcpu);
    kfree(m->ring);
    kfree(m);
}

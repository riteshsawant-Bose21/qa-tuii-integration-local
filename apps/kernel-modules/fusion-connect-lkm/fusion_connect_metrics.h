#pragma once

#include <linux/percpu.h>
#include <linux/u64_stats_sync.h>
#include <linux/atomic.h>
#include <linux/types.h>

#define FUSION_CN_METRICS_RING_ORDER   10
#define FUSION_CN_METRICS_RING_SIZE    (1U << FUSION_CN_METRICS_RING_ORDER)

enum fusion_cn_pkt_flags
{
    FUSION_CN_PKTF_MARKER      = BIT(0),
    FUSION_CN_PKTF_MALFORMED   = BIT(1),
    FUSION_CN_PKTF_DUP         = BIT(2),
    FUSION_CN_PKTF_REORDERHINT = BIT(3),
    FUSION_CN_PKTF_LATE        = BIT(4),
};

struct fusion_cn_pkt_sample
{
    u32  seq;
    u32  rtp_ts;           /* RTP timestamp in sender rate domain */
    u64  arrival_phc_ns;   /* reconstructed PHC ns (RX) */
    u16  payload_len;
    u16  flags;

    /* New: values known in RX path, consumed by aggregator */
    u64  recon_phc_ns;     /* reconstructed sender time (ns) for this packet */
    u64  sched_ns;         /* this packet's playout deadline (ns) */
};

struct fusion_cn_metrics_pcpu {
    struct u64_stats_sync syncp;
    /* RX */
    u64 packets_total, bytes_total;
    u64 packets_dup, packets_marked, malformed_count;
    u64 late_drop_count;

    /* TX */
    u64 tx_packets_total, tx_bytes_total;
} ____cacheline_aligned;

struct fusion_cn_metrics_window
{
    /* sequence / loss / reorder */
    u32 expected_seq;
    bool expected_seq_valid;
    u64 packets_lost;
    u64 packets_reordered;
    u64 burst_loss_cur;
    u64 burst_loss_max;

    /* jitter / inter-arrival */
    u32 rtp_clock_rate;        /* = info.sample_rate for L16/L24 */
    u64 rfc3550_jitter_ts_fp;  /* internal accumulator */
    u32 rfc3550_jitter_ns;

    u64 last_arrival_ns;
    u32 iat_min_ns;
    u32 iat_p50_ns;
    u32 iat_p99_ns;
    u32 batch_max;

    /* jitter buffer & deadlines (fed by ALSA / scheduler sites) */
    u32 jb_depth_cur_samples;
    u32 jb_depth_min_samples;
    u32 jb_depth_max_samples;
    u64 jb_depth_sum_samples;
    u32 jb_depth_count;
    u32 resync_count;

    /* latency / clock */
    u32 path_latency_est_ns;
    u32 path_latency_min_ns;
    u32 path_latency_max_ns;
    u32 path_latency_p50_ns;
    u32 path_latency_p99_ns;

    /* TX timing (egress) – kept in window; mirror later if you expose */
    u64 tx_last_send_ns;
    u32 tx_iat_min_ns;
    u32 tx_iat_p50_ns;
    u32 tx_iat_p99_ns;
    u32 tx_sched_err_abs_p50_ns;
};

struct fusion_cn_metrics_snapshot
{
    u64 ts_snapshot_ns;

    /* RX */
    u64 packets_total, bytes_total;
    u64 packets_lost, packets_reordered, packets_dup;
    u64 packets_marked, malformed_count;
    u64 late_drop_count;
    u64 burst_loss_max;

    u32 rfc3550_jitter_ns;
    u32 iat_min_ns, iat_p50_ns, iat_p99_ns;
    u32 batch_max;

    u32 jb_depth_cur_samples, jb_depth_min_samples, jb_depth_max_samples, jb_depth_avg_samples;
    u32 resync_count;

    u32 path_latency_est_ns, path_latency_min_ns, path_latency_max_ns;
    u32 path_latency_p50_ns, path_latency_p99_ns;

    /* TX */
    u64 tx_packets_total;
    u64 tx_bytes_total;

    u32 tx_iat_min_ns;
    u32 tx_iat_p50_ns;
    u32 tx_iat_p99_ns;
    u32 tx_sched_err_abs_p50_ns;
} __attribute__((packed));

struct fusion_cn_metrics_record {
    u64 handle;
    char stream_name[32];
    struct fusion_cn_metrics_snapshot snap;
} __attribute__((packed));

struct fusion_cn_stream_metrics
{
    /* hot path ring (SPSC: producer=packet path, consumer=aggregator) */
    struct fusion_cn_pkt_sample *ring;
    u32                          ring_mask;
    u32                          wr_idx;   /* producer publishes with store_release */
    u32                          rd_idx;   /* consumer loads wr_idx with load_acquire */

    /* per-CPU counters (folded in aggregator) */
    struct fusion_cn_metrics_pcpu __percpu *pcpu;

    /* cold window + last snapshot */
    struct fusion_cn_metrics_window   win;
    struct fusion_cn_metrics_snapshot snap;
};

/* lifecycle */
struct fusion_cn_stream_metrics *fusion_cn_metrics_create(u32 sample_rate, u64 playout_delay);
void fusion_cn_metrics_destroy(struct fusion_cn_stream_metrics *m);

/* hot-path stash (inline) */
static inline void fusion_cn_metrics_rx_stash(struct fusion_cn_stream_metrics *m,
                                              u32 seq, u32 rtp_ts, u64 arrival_phc_ns,
                                              u16 payload_len, u16 flags,
                                              u64 recon_phc_ns, u64 sched_ns)
{
    /* per-CPU counters (unchanged) */
    {
        struct fusion_cn_metrics_pcpu *p = this_cpu_ptr(m->pcpu);
        u64_stats_update_begin(&p->syncp);
        p->packets_total++;
        p->bytes_total += payload_len;
        if (flags & FUSION_CN_PKTF_MARKER)    p->packets_marked++;
        if (flags & FUSION_CN_PKTF_MALFORMED) p->malformed_count++;
        if (flags & FUSION_CN_PKTF_DUP)       p->packets_dup++;
        if (flags & FUSION_CN_PKTF_LATE)      p->late_drop_count++;
        u64_stats_update_end(&p->syncp);
    }

    /* SPSC ring write + publish */
    {
        u32 i = READ_ONCE(m->wr_idx);
        m->ring[i & m->ring_mask] = (struct fusion_cn_pkt_sample) {
            .seq            = seq,
            .rtp_ts         = rtp_ts,
            .arrival_phc_ns = arrival_phc_ns,
            .payload_len    = payload_len,
            .flags          = flags,
            .recon_phc_ns   = recon_phc_ns,
            .sched_ns       = sched_ns
        };
        smp_wmb();
        WRITE_ONCE(m->wr_idx, i + 1);
    }
}

static inline void fusion_cn_metrics_tx_stash(struct fusion_cn_stream_metrics *m,
                                              u64 send_phc_ns, u16 payload_len,
                                              u64 scheduled_send_ns)
{
    struct fusion_cn_metrics_pcpu *p = this_cpu_ptr(m->pcpu);

    /* per-CPU TX counters */
    u64_stats_update_begin(&p->syncp);
    p->tx_packets_total++;
    p->tx_bytes_total += payload_len;
    u64_stats_update_end(&p->syncp);

    /* optional TX timing EMAs (benign races OK) */
    {
        u64 last = READ_ONCE(m->win.tx_last_send_ns);
        if (last) {
            u32 iat = (u32)(send_phc_ns - last);
            if (!m->win.tx_iat_min_ns || iat < m->win.tx_iat_min_ns) m->win.tx_iat_min_ns = iat;
            if (!m->win.tx_iat_p50_ns) m->win.tx_iat_p50_ns = iat;
            if (!m->win.tx_iat_p99_ns) m->win.tx_iat_p99_ns = iat;

            m->win.tx_iat_p50_ns = m->win.tx_iat_p50_ns + ((s32)iat - (s32)m->win.tx_iat_p50_ns) / 8;
            if (iat > m->win.tx_iat_p99_ns)
                m->win.tx_iat_p99_ns += (iat - m->win.tx_iat_p99_ns) / 4;
            else
                m->win.tx_iat_p99_ns -= (m->win.tx_iat_p99_ns - iat) / 32;
        }
        WRITE_ONCE(m->win.tx_last_send_ns, send_phc_ns);

        if (scheduled_send_ns) {
            u64 diff = (send_phc_ns > scheduled_send_ns)
                    ? (send_phc_ns - scheduled_send_ns)
                    : (scheduled_send_ns - send_phc_ns);
            u32 err = (diff > U32_MAX) ? U32_MAX : (u32)diff;

            if (!m->win.tx_sched_err_abs_p50_ns)
                m->win.tx_sched_err_abs_p50_ns = err;
            else
                m->win.tx_sched_err_abs_p50_ns =
                    m->win.tx_sched_err_abs_p50_ns +
                    ((s32)err - (s32)m->win.tx_sched_err_abs_p50_ns) / 8;
        }
    }
}

void fusion_cn_metrics_aggregate_tx(struct fusion_cn_stream_metrics *m);
void fusion_cn_metrics_aggregate_rx(struct fusion_cn_stream_metrics *m, u32 jb_depth_samples);

void fusion_cn_metrics_read_snapshot(const struct fusion_cn_stream_metrics *m,
                                     struct fusion_cn_metrics_snapshot *out);

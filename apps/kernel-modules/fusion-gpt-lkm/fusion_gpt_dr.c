// SPDX-License-Identifier: GPL-2.0
// GPT1 shim: DT compatible "bosepro,fusion-gpt"
// - binds to GPT1 (10 MHz on GPT1_CLK), runs compare at 1/3 ms
// - exports a client API (non-GPL symbols) to deliver ticks in softirq

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/io.h>
#include <linux/interrupt.h>
#include <linux/spinlock.h>
#include <linux/math64.h>
#include <linux/seqlock.h>
#include <linux/clk.h>
#include <linux/rcupdate.h>
#include <linux/string.h>
#include "fusion_gpt_client.h"

/* VCXO disciplining */
#include <linux/workqueue.h>
#include <linux/i2c.h>
#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/slab.h>

#define GPT_CR      0x00
#define GPT_PR      0x04
#define GPT_SR      0x08
#define GPT_IR      0x0C
#define GPT_OCR1    0x10
#define GPT_ICR1    0x1C
#define GPT_ICR2    0x20
#define GPT_CNT     0x24

/* CR bits */
#define CR_EN           BIT(0)
#define CR_ENMOD        BIT(1)
#define CR_DBGEN        BIT(2)
#define CR_WAITEN       BIT(3)
#define CR_CLKSRC_SHIFT 6
#define CR_CLKSRC_EXT   (0x3 << CR_CLKSRC_SHIFT)
#define CR_FRR          BIT(9)
#define CR_IM1_SHIFT    16
#define CR_IM1_RISING   (0x1 << CR_IM1_SHIFT)
#define CR_IM1_BOTH     (0x3 << CR_IM1_SHIFT) /* 1pps on both edges */
#define CR_IM2_SHIFT    18
#define CR_IM2_RISING   (0x1 << CR_IM2_SHIFT) /* LRCLK on rising edge */

/* SR (status, W1C) and IR (enable) bits */
#define SR_OF1   BIT(0)
#define SR_IF1   BIT(3)
#define SR_IF2   BIT(4)
#define IR_OF1IE BIT(0)
#define IR_IF1IE BIT(3)
#define IR_IF2IE BIT(4)

/* 10 MHz -> 100 ns/tick; 1/3 ms = 333333.333 ns -> 3333,3333,3334 ticks */
#define PERIOD_TICKS_BASE 3333U
/* 10 MHz -> 10,000,000 ticks per second for 1PPS capture cadence */
#define PPS_TICKS 10000000ULL

#define DEFAULT_DAC_I2C_BUS      0
#define DEFAULT_DAC_I2C_ADDR     0x62
#define DEFAULT_SI5351B_I2C_ADDR 0x60

enum cal_state {
	CAL_IDLE = 0,
	CAL_CONFIG_CHECK,
	CAL_PREBAKE_WAIT,
	CAL_APPLY_POINT,
	CAL_SETTLE,
	CAL_MEASURE,
	CAL_FIT,
	CAL_APPLY_JUMP,
	CAL_DONE,
	CAL_FAIL,
};

/* Startup local-surface identification + one-shot jump */
static bool cal_enable = true;
module_param(cal_enable, bool, 0644);
MODULE_PARM_DESC(cal_enable, "Enable startup gain/dac surface calibration");

static u32 cal_gain_delta = 20000;
module_param(cal_gain_delta, uint, 0644);
MODULE_PARM_DESC(cal_gain_delta, "Gain perturbation for startup probes");

static u32 cal_dac_delta = 8;
module_param(cal_dac_delta, uint, 0644);
MODULE_PARM_DESC(cal_dac_delta, "DAC perturbation for startup probes");

static u32 cal_settle_pps = 2;
module_param(cal_settle_pps, uint, 0644);
MODULE_PARM_DESC(cal_settle_pps, "PPS samples to settle after each probe write");

static u32 cal_measure_pps = 4;
module_param(cal_measure_pps, uint, 0644);
MODULE_PARM_DESC(cal_measure_pps, "PPS samples to average per probe point");

static u32 cal_fit_residual_thresh = 30;
module_param(cal_fit_residual_thresh, uint, 0644);
MODULE_PARM_DESC(cal_fit_residual_thresh, "Maximum mean residual (ticks) accepted for model fit");

static u32 cal_lambda_gain = 4;
module_param(cal_lambda_gain, uint, 0644);
MODULE_PARM_DESC(cal_lambda_gain, "Gain move penalty for one-shot optimization");

static u32 cal_lambda_dac = 4;
module_param(cal_lambda_dac, uint, 0644);
MODULE_PARM_DESC(cal_lambda_dac, "DAC move penalty for one-shot optimization");

static u32 cal_max_gain_step = 60000;
module_param(cal_max_gain_step, uint, 0644);
MODULE_PARM_DESC(cal_max_gain_step, "Maximum absolute gain jump from startup center");

static u32 cal_max_dac_step = 64;
module_param(cal_max_dac_step, uint, 0644);
MODULE_PARM_DESC(cal_max_dac_step, "Maximum absolute DAC jump from startup center");

static u32 cal_gain_search_step = 1000;
module_param(cal_gain_search_step, uint, 0644);
MODULE_PARM_DESC(cal_gain_search_step, "Gain step used in bounded one-shot target search");

static u32 si_gain_start = 70000;
module_param(si_gain_start, uint, 0644);
MODULE_PARM_DESC(si_gain_start, "Starting Si5351b gain for startup, calibration center, and inverse-model jump search");

static u32 cal_inverse_gain_step = 10000;
module_param(cal_inverse_gain_step, uint, 0644);
MODULE_PARM_DESC(cal_inverse_gain_step, "Absolute gain increment for inverse-model startup solve");

static int cal_jump_dac_min = 30;
module_param(cal_jump_dac_min, int, 0644);
MODULE_PARM_DESC(cal_jump_dac_min, "Minimum acceptable DAC value for the one-shot calibration jump");

static int cal_jump_dac_max = 225;
module_param(cal_jump_dac_max, int, 0644);
MODULE_PARM_DESC(cal_jump_dac_max, "Maximum acceptable DAC value for the one-shot calibration jump");

static bool cal_use_prebaked = false;
module_param(cal_use_prebaked, bool, 0644);
MODULE_PARM_DESC(cal_use_prebaked, "Skip startup probing and use prebaked model coefficients");

#define CAL_CONFIG_PATH_MAX 256
static char cal_config_path[CAL_CONFIG_PATH_MAX] = "/var/lib/fusion/fusion-gpt-calibration.conf";
module_param_string(cal_config_path, cal_config_path, sizeof(cal_config_path), 0644);
MODULE_PARM_DESC(cal_config_path, "Path to persisted prebaked model coefficient file");

static bool cal_config_autoload = true;
module_param(cal_config_autoload, bool, 0644);
MODULE_PARM_DESC(cal_config_autoload, "Load prebaked model coefficients from cal_config_path at startup");

static bool cal_config_autosave = true;
module_param(cal_config_autosave, bool, 0644);
MODULE_PARM_DESC(cal_config_autosave, "Save fitted model coefficients to cal_config_path after calibration");

static bool cal_pre_valid = false;
module_param(cal_pre_valid, bool, 0644);
MODULE_PARM_DESC(cal_pre_valid, "Prebaked model coefficients are valid");

static int cal_pre_k1_q16 = 0;
module_param(cal_pre_k1_q16, int, 0644);
MODULE_PARM_DESC(cal_pre_k1_q16, "Prebaked k1 coefficient in Q16");

static int cal_pre_k2_q16 = 0;
module_param(cal_pre_k2_q16, int, 0644);
MODULE_PARM_DESC(cal_pre_k2_q16, "Prebaked k2 coefficient in Q16");

static int cal_pre_k3_q16 = 0;
module_param(cal_pre_k3_q16, int, 0644);
MODULE_PARM_DESC(cal_pre_k3_q16, "Prebaked k3 coefficient in Q16");

static bool cal_capture_fit = true;
module_param(cal_capture_fit, bool, 0644);
MODULE_PARM_DESC(cal_capture_fit, "Capture fitted coefficients into cal_last_* for reuse");

static int cal_last_k1_q16;
module_param(cal_last_k1_q16, int, 0444);
MODULE_PARM_DESC(cal_last_k1_q16, "Last fitted k1 coefficient in Q16 (read-only)");

static int cal_last_k2_q16;
module_param(cal_last_k2_q16, int, 0444);
MODULE_PARM_DESC(cal_last_k2_q16, "Last fitted k2 coefficient in Q16 (read-only)");

static int cal_last_k3_q16;
module_param(cal_last_k3_q16, int, 0444);
MODULE_PARM_DESC(cal_last_k3_q16, "Last fitted k3 coefficient in Q16 (read-only)");

static u32 cal_pre_e0_samples = 3;
module_param(cal_pre_e0_samples, uint, 0644);
MODULE_PARM_DESC(cal_pre_e0_samples, "Number of sane PPS errors to average for prebaked e0");

static u32 cal_pre_e0_abs_max = 1000;
module_param(cal_pre_e0_abs_max, uint, 0644);
MODULE_PARM_DESC(cal_pre_e0_abs_max, "Maximum absolute PPS error accepted for prebaked e0 collection");

static u32 cal_pre_e0_max_wait = 12;
module_param(cal_pre_e0_max_wait, uint, 0644);
MODULE_PARM_DESC(cal_pre_e0_max_wait, "Maximum PPS intervals to wait for sane prebaked e0 samples");

static u32 lock_err_thresh = 1;
module_param(lock_err_thresh, uint, 0644);
MODULE_PARM_DESC(lock_err_thresh, "Absolute PPS error threshold in ticks required to declare discipline ready");

static u32 lock_consecutive = 5;
module_param(lock_consecutive, uint, 0644);
MODULE_PARM_DESC(lock_consecutive, "Consecutive in-threshold PPS samples required to declare discipline ready");

struct fusion_gpt
{
	void __iomem *base;
	int irq;

	u32 next_ocr1;
	u8  frac;

	u32 last32;
	u64 hi;
	seqcount_t ticks_sl;

	const struct fusion_gpt_client_ops *ops;
	void *ops_ctx;
	struct module *ops_owner;
	struct mutex ops_lock;

	struct clk *clk_ipg;
	struct clk *clk_per;

	/* PPS & PHC epoch */
	u32  pps_seq;                 /* increments on each ICR1 latch */
	u32  pps_icr1_last32;         /* raw 32-bit capture value for latest PPS */
	u64  pps_icr1_last64;         /* 64-bit extended capture */
	bool pps_valid;
  u64 last_if2_cap64; /* Timestamp of the last 48k capture */
  bool if2_valid;     /* True if we have captured at least one 48k pulse */

	u64  phc_epoch_ns;            /* PHC time at the anchored PPS */
	u64  pps_epoch_cnt64;         /* 64-bit CNT at the anchored PPS */
	bool phc_epoch_valid;
	raw_spinlock_t pps_lock;      /* protects the PPS/epoch fields */

	bool phc_aligned;             /* true after one-shot phase align */

	/* "Arm-next-PPS" anchor from userspace (pps_seq == 0 mode) */
	bool pending_future_anchor;
	u64  pending_future_phc_ns;

  /* DAC control */
  struct work_struct dac_work;
  struct i2c_client *dac_client;
  u16 current_dac_value;
	  long latest_freq_error;    /* The most recent frequency delta */
	  s64 cumulative_error_ticks_total;
	  s64 cumulative_error_ticks_locked;

  /* PI loop */
  long error_integrator;
  u64 sq_err_sum;
  u32 err_count;
  int dac_target;

  /* Si5351b gain control */
  struct i2c_client *si5351b_client;
  u32 si_gain_current;
  u32 si_gain_target;
  u32 si_gain_min;
  u32 si_gain_max;
  bool si_gain_pending;

  /* Startup calibration state */
  enum cal_state cal_state;
  int cal_probe_idx;
  u32 cal_settle_left;
  u32 cal_measure_left;
  s64 cal_err_accum;
  u32 cal_err_samples;
  u32 cal_center_gain;
  int cal_center_dac;
  u32 cal_probe_gain[5];
  int cal_probe_dac[5];
  long cal_probe_mean[5];
  s32 cal_k1_q16;
  s32 cal_k2_q16;
  s32 cal_k3_q16;
  bool cal_config_checked;

  /* Sticky startup-ready flag for downstream GPT clients. */
  bool discipline_ready;
  u32 lock_streak;
};


static struct fusion_gpt *gpt_singleton;
static DEFINE_MUTEX(gpt_singleton_lock);
static int si5351b_write_gain(struct fusion_gpt *g, u32 gain);

static int cal_load_prebaked_config(s32 *k1_q16, s32 *k2_q16, s32 *k3_q16)
{
	struct file *filp;
	char *buf;
	loff_t pos = 0;
	ssize_t nread;
	unsigned int version = 0;
	int k1 = 0, k2 = 0, k3 = 0;
	int parsed;
	int ret = 0;

	if (!cal_config_path[0])
		return -ENOENT;

	filp = filp_open(cal_config_path, O_RDONLY, 0);
	if (IS_ERR(filp))
		return PTR_ERR(filp);

	buf = kmalloc(PAGE_SIZE, GFP_KERNEL);
	if (!buf) {
		ret = -ENOMEM;
		goto out_close;
	}

	nread = kernel_read(filp, buf, PAGE_SIZE - 1, &pos);
	if (nread < 0) {
		ret = (int)nread;
		goto out_free;
	}

	buf[nread] = '\0';
	parsed = sscanf(buf, "version=%u\nk1_q16=%d\nk2_q16=%d\nk3_q16=%d",
			&version, &k1, &k2, &k3);
	if (parsed != 4 || version != 1) {
		ret = -EINVAL;
		goto out_free;
	}

	*k1_q16 = (s32)k1;
	*k2_q16 = (s32)k2;
	*k3_q16 = (s32)k3;

out_free:
	kfree(buf);
out_close:
	filp_close(filp, NULL);
	return ret;
}

static int cal_save_prebaked_config(s32 k1_q16, s32 k2_q16, s32 k3_q16)
{
	struct file *filp;
	char buf[128];
	loff_t pos = 0;
	int len;
	ssize_t nwritten;

	if (!cal_config_path[0])
		return -ENOENT;

	len = scnprintf(buf, sizeof(buf),
			"version=1\nk1_q16=%d\nk2_q16=%d\nk3_q16=%d\n",
			(int)k1_q16, (int)k2_q16, (int)k3_q16);

	filp = filp_open(cal_config_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
	if (IS_ERR(filp))
		return PTR_ERR(filp);

	nwritten = kernel_write(filp, buf, len, &pos);
	filp_close(filp, NULL);
	if (nwritten < 0)
		return (int)nwritten;
	if (nwritten != len)
		return -EIO;

	return 0;
}

static inline u32 rdl(struct fusion_gpt *g, u32 off) { return readl_relaxed(g->base + off); }
static inline void wrl(struct fusion_gpt *g, u32 v, u32 off) { writel_relaxed(v, g->base + off); }

static inline u64 ceil_div_u64(u64 a, u64 b)
{
	return (a + b - 1) / b;
}

static inline u32 fusion_start_gain_value(void)
{
	return clamp_t(u32, si_gain_start, 40000, 250000);
}

static inline int cal_jump_dac_min_value(void)
{
	return clamp_t(int, min_t(int, cal_jump_dac_min, cal_jump_dac_max), 0, 255);
}

static inline int cal_jump_dac_max_value(void)
{
	return clamp_t(int, max_t(int, cal_jump_dac_min, cal_jump_dac_max), 0, 255);
}

static void gpt_reset_timing_state_locked(struct fusion_gpt *g)
{
	g->pps_seq = 0;
	g->pps_icr1_last32 = 0;
	g->pps_icr1_last64 = 0;
	g->pps_valid = false;
	g->last_if2_cap64 = 0;
	g->if2_valid = false;
	g->phc_epoch_ns = 0;
	g->pps_epoch_cnt64 = 0;
	g->phc_epoch_valid = false;
	g->phc_aligned = false;
	g->pending_future_anchor = false;
	g->pending_future_phc_ns = 0;
	g->latest_freq_error = 0;
	g->cumulative_error_ticks_total = 0;
	g->cumulative_error_ticks_locked = 0;
	g->error_integrator = 0;
	g->sq_err_sum = 0;
	g->err_count = 0;
	WRITE_ONCE(g->si_gain_pending, false);
	WRITE_ONCE(g->discipline_ready, false);
	g->lock_streak = 0;
	g->cal_state = cal_enable ? CAL_IDLE : CAL_DONE;
	g->cal_probe_idx = 0;
	g->cal_settle_left = 0;
	g->cal_measure_left = 0;
	g->cal_err_accum = 0;
	g->cal_err_samples = 0;
	g->cal_center_gain = g->si_gain_current;
	g->cal_center_dac = clamp(g->dac_target, 0, 255);
	memset(g->cal_probe_gain, 0, sizeof(g->cal_probe_gain));
	memset(g->cal_probe_dac, 0, sizeof(g->cal_probe_dac));
	memset(g->cal_probe_mean, 0, sizeof(g->cal_probe_mean));
	g->cal_k1_q16 = 0;
	g->cal_k2_q16 = 0;
	g->cal_k3_q16 = 0;
	g->cal_config_checked = false;
}

/* 64-bit tick synth (read-mostly) */
static u64 gpt_read_ticks64(struct fusion_gpt *g)
{
	unsigned seq; u32 lo; u64 hi;
	do {
		seq = read_seqcount_begin(&g->ticks_sl);
		hi = g->hi; lo = g->last32;
	} while (read_seqcount_retry(&g->ticks_sl, seq));
	return (hi | lo);
}

static inline void gpt_tick_direct(struct fusion_gpt *g)
{
	if (!READ_ONCE(g->discipline_ready))
		return;

	const struct fusion_gpt_client_ops *ops = READ_ONCE(g->ops);
	if (ops && ops->tick)
		ops->tick(g->ops_ctx, gpt_read_ticks64(g));
}

u64 fusion_gpt_read_ticks64(void)
{
	struct fusion_gpt *g;
	u64 ret = 0;

	rcu_read_lock();
	g = rcu_dereference(gpt_singleton);
	if (g)
		ret = gpt_read_ticks64(g);
	rcu_read_unlock();

	return ret;
}
EXPORT_SYMBOL(fusion_gpt_read_ticks64);

/* exported client API */
int fusion_gpt_register_client(const struct fusion_gpt_client_ops *ops,
			       void *ctx, struct module *owner)
{
	struct fusion_gpt *g;
	int ret = -ENODEV;

	if (!ops || !ops->tick || !owner)
		return -EINVAL;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	mutex_unlock(&gpt_singleton_lock);
	if (!g)
		return -ENODEV;

	mutex_lock(&g->ops_lock);
	if (g->ops) {
		ret = -EBUSY;
		goto out;
	}
	if (!try_module_get(owner)) { ret = -ENODEV; goto out; }

	g->ops = ops;
	g->ops_ctx = ctx;
	g->ops_owner = owner;
	ret = 0;
out:
	mutex_unlock(&g->ops_lock);
	return ret;
}
EXPORT_SYMBOL(fusion_gpt_register_client);  /* non-GPL */

void fusion_gpt_unregister_client(void)
{
	struct fusion_gpt *g;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	mutex_unlock(&gpt_singleton_lock);
	if (!g) return;

	mutex_lock(&g->ops_lock);
	/* Make readers see NULL first */
	WRITE_ONCE(g->ops, NULL);
	smp_mb(); /* publish NULL before we flush */

	if (g->ops_owner)
		module_put(g->ops_owner);

	g->ops_ctx   = NULL;
	g->ops_owner = NULL;
	mutex_unlock(&g->ops_lock);
}
EXPORT_SYMBOL(fusion_gpt_unregister_client); /* non-GPL */

/*
 * Bind the *next* GPT ICR1 (1PPS) edge to the provided PHC time.
 * - Arms a pending anchor that will be consumed on the next ICR1 interrupt.
 * - Clears phc_epoch_valid so the epoch becomes valid exactly at that edge.
 * - Forces a one-shot OF1 phase realign after the epoch is established.
 */
int fusion_gpt_set_phc_anchor(u64 phc_ns_at_pps)
{
    struct fusion_gpt *g;
    unsigned long flags;

    mutex_lock(&gpt_singleton_lock);
    g = gpt_singleton;
    mutex_unlock(&gpt_singleton_lock);
    if (!g)
        return -ENODEV;

    raw_spin_lock_irqsave(&g->pps_lock, flags);

    if (phc_ns_at_pps == 0) {
        g->pending_future_anchor = false;
        g->pending_future_phc_ns = 0;
        pr_debug("fusion_gpt: phc anchor cleared\n");
        raw_spin_unlock_irqrestore(&g->pps_lock, flags);
        return 0;
    }

    /* Touch shared PPS/epoch state from process context: IRQ-safe */
    g->pending_future_anchor = true;
    g->pending_future_phc_ns = phc_ns_at_pps;

    /* Ensure the OF1 handler performs the one-shot phase alignment */
    g->phc_aligned       = false;

    /* Epoch becomes valid at the next ICR1 edge (when we bind cap64 -> PHC) */
    g->phc_epoch_valid   = false;

    pr_debug("fusion_gpt: phc anchor armed %llu\n", phc_ns_at_pps);
    raw_spin_unlock_irqrestore(&g->pps_lock, flags);
    return 0;
}
EXPORT_SYMBOL(fusion_gpt_set_phc_anchor);

int fusion_gpt_get_phc_status(bool *epoch_valid, bool *aligned, u32 *pps_seq)
{
	struct fusion_gpt *g;
	unsigned long flags;
	if (!epoch_valid || !aligned || !pps_seq) return -EINVAL;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	mutex_unlock(&gpt_singleton_lock);
	if (!g) return -ENODEV;

	/* single spin-locked snapshot */
	raw_spin_lock_irqsave(&g->pps_lock, flags);
	*epoch_valid = g->phc_epoch_valid;
	*aligned     = READ_ONCE(g->phc_aligned);
	*pps_seq     = g->pps_seq;
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	return 0;
}
EXPORT_SYMBOL(fusion_gpt_get_phc_status);

int fusion_gpt_get_timing_status(struct fusion_gpt_timing_status *status)
{
	struct fusion_gpt *g;
	unsigned long flags;

	if (!status)
		return -EINVAL;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	mutex_unlock(&gpt_singleton_lock);
	if (!g)
		return -ENODEV;

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	status->discipline_ready = READ_ONCE(g->discipline_ready);
	status->epoch_valid = g->phc_epoch_valid;
	status->aligned = READ_ONCE(g->phc_aligned);
	status->pps_seq = g->pps_seq;
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	return 0;
}
EXPORT_SYMBOL(fusion_gpt_get_timing_status);

int fusion_gpt_reset_timing_state(void)
{
	struct fusion_gpt *g;
	unsigned long flags;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	mutex_unlock(&gpt_singleton_lock);
	if (!g)
		return -ENODEV;

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	gpt_reset_timing_state_locked(g);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

	pr_info("fusion_gpt: timing state reset\n");
	return 0;
}
EXPORT_SYMBOL(fusion_gpt_reset_timing_state);

u64 fusion_gpt_read_phc_ns(void)
{
	struct fusion_gpt *g;
	unsigned long flags;
	u64 now64, epoch_cnt64, epoch_ns, dt_ticks, ns = 0;
	bool valid;

	rcu_read_lock();
	g = rcu_dereference(gpt_singleton);
	if (!g) {
		rcu_read_unlock();
		return 0;
	}
	if (!g) return 0;

	/* Snapshot epoch under pps_lock */
	raw_spin_lock_irqsave(&g->pps_lock, flags);
	valid       = g->phc_epoch_valid;
	epoch_ns    = g->phc_epoch_ns;
	epoch_cnt64 = g->pps_epoch_cnt64;
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	if (!valid) {
		rcu_read_unlock();
		return 0;
	}

	/* Read current 64-bit counter safely */
	now64 = gpt_read_ticks64(g);

	/* Convert ticks→ns with 10 MHz = 100 ns/tick */
	dt_ticks = now64 - epoch_cnt64;
	ns = epoch_ns + dt_ticks * 100ULL;
	rcu_read_unlock();
	return ns;
}
EXPORT_SYMBOL(fusion_gpt_read_phc_ns);

bool fusion_gpt_clock_ready(void)
{
	struct fusion_gpt *g;
	bool ready = false;

	rcu_read_lock();
	g = rcu_dereference(gpt_singleton);
	if (g)
		ready = READ_ONCE(g->discipline_ready);
	rcu_read_unlock();

	return ready;
}
EXPORT_SYMBOL(fusion_gpt_clock_ready);

static void gpt_program_next_compare(struct fusion_gpt *g)
{
	u32 inc = PERIOD_TICKS_BASE;
	if (++g->frac == 3) { inc += 1; g->frac = 0; }
	g->next_ocr1 += inc;

	if ((s32)(g->next_ocr1 - g->last32) <= 0) {
		u32 now = rdl(g, GPT_CNT);     /* fresh */
		g->next_ocr1 = now + inc;      /* rebase compare only */
	}
	wrl(g, g->next_ocr1, GPT_OCR1);
}

static inline bool cal_active(const struct fusion_gpt *g)
{
	return g->cal_state != CAL_IDLE &&
	       g->cal_state != CAL_DONE &&
	       g->cal_state != CAL_FAIL;
}

static void gpt_update_discipline_ready(struct fusion_gpt *g, long freq_error)
{
	long abs_err = (freq_error < 0) ? -freq_error : freq_error;
	u32 thresh = READ_ONCE(lock_err_thresh);
	u32 needed = max_t(u32, 1, READ_ONCE(lock_consecutive));

	if (READ_ONCE(g->discipline_ready))
		return;

	if (cal_active(g)) {
		g->lock_streak = 0;
		return;
	}

	if (abs_err > thresh) {
		g->lock_streak = 0;
		return;
	}

	if (g->lock_streak < needed)
		g->lock_streak++;

	if (g->lock_streak >= needed) {
		WRITE_ONCE(g->discipline_ready, true);
		pr_info("fusion_gpt: lock achieved\n");
		pr_info("fusion_gpt: discipline ready (|err| <= %u ticks for %u PPS)\n",
			thresh, needed);
	}
}

static void cal_prepare_points(struct fusion_gpt *g)
{
	u32 g0 = g->si_gain_current;
	int d0 = clamp(g->dac_target, 0, 255);
	u32 dg = max_t(u32, 1, cal_gain_delta);
	int dd = max_t(int, 1, (int)cal_dac_delta);
	u32 g1, g2, g4;

	g->cal_center_gain = g0;
	g->cal_center_dac = d0;

	/*
	 * Boundary-aware gain stencil:
	 * - near min gain: use +dg / +2dg (never probe below min)
	 * - near max gain: use -dg / -2dg
	 * - otherwise: use +/-dg around center
	 */
	if (g0 <= g->si_gain_min + dg) {
		g1 = clamp(g0 + dg, g->si_gain_min, g->si_gain_max);
		g2 = clamp(g0 + 2 * dg, g->si_gain_min, g->si_gain_max);
		g4 = g1;
	} else if (g0 >= g->si_gain_max - dg) {
		g1 = clamp(g0 - dg, g->si_gain_min, g->si_gain_max);
		g2 = clamp(g0 - 2 * dg, g->si_gain_min, g->si_gain_max);
		g4 = g1;
	} else {
		g1 = clamp(g0 + dg, g->si_gain_min, g->si_gain_max);
		g2 = clamp(g0 - dg, g->si_gain_min, g->si_gain_max);
		g4 = g1;
	}

	g->cal_probe_gain[0] = g0;
	g->cal_probe_dac[0] = d0;
	g->cal_probe_gain[1] = g1;
	g->cal_probe_dac[1] = d0;
	g->cal_probe_gain[2] = g2;
	g->cal_probe_dac[2] = d0;
	g->cal_probe_gain[3] = g0;
	g->cal_probe_dac[3] = clamp(d0 + dd, 0, 255);
	g->cal_probe_gain[4] = g4;
	g->cal_probe_dac[4] = clamp(d0 + dd, 0, 255);

	g->cal_probe_idx = 0;
	g->cal_settle_left = 0;
	g->cal_measure_left = 0;
	g->cal_err_accum = 0;
	g->cal_err_samples = 0;
}

static bool cal_fit_model(struct fusion_gpt *g, u32 *mean_residual_out)
{
	s64 e0 = g->cal_probe_mean[0];
	s64 e1 = g->cal_probe_mean[1];
	s64 e2 = g->cal_probe_mean[2];
	s64 e3 = g->cal_probe_mean[3];
	s64 e4 = g->cal_probe_mean[4];
	s64 dg1 = (s64)g->cal_probe_gain[1] - (s64)g->cal_center_gain;
	s64 dg2 = (s64)g->cal_probe_gain[2] - (s64)g->cal_center_gain;
	s64 dd3 = (s64)g->cal_probe_dac[3] - (s64)g->cal_center_dac;
	s64 dg4 = (s64)g->cal_probe_gain[4] - (s64)g->cal_center_gain;
	s64 dd4 = (s64)g->cal_probe_dac[4] - (s64)g->cal_center_dac;
	s64 denom_g = dg1 - dg2;
	s64 k1_q16, k2_q16, k3_q16;
	s64 pred_q16, residual_sum = 0;
	int i;

	if (denom_g == 0 || dd3 == 0 || dg4 == 0 || dd4 == 0)
		return false;

	k1_q16 = div_s64((e1 - e2) << 16, denom_g);
	k2_q16 = div_s64((e3 - e0) << 16, dd3);
	k3_q16 = div_s64(((e4 - e0) << 16) - k1_q16 * dg4 - k2_q16 * dd4, dg4 * dd4);

	for (i = 0; i < 5; i++) {
		s64 dg = (s64)g->cal_probe_gain[i] - (s64)g->cal_center_gain;
		s64 dd = (s64)g->cal_probe_dac[i] - (s64)g->cal_center_dac;
		s64 pred = (e0 << 16) + k1_q16 * dg + k2_q16 * dd + k3_q16 * dg * dd;
		s64 err = g->cal_probe_mean[i] - (pred >> 16);

		residual_sum += (err < 0) ? -err : err;
	}

	pred_q16 = (e0 << 16) + k1_q16 * dg4 + k2_q16 * dd4 + k3_q16 * dg4 * dd4;
	pr_info("fusion_gpt: cal fit k1_q16=%lld k2_q16=%lld k3_q16=%lld p4_meas=%lld p4_pred=%lld\n",
		(long long)k1_q16, (long long)k2_q16, (long long)k3_q16,
		(long long)e4, (long long)(pred_q16 >> 16));

	g->cal_k1_q16 = (s32)k1_q16;
	g->cal_k2_q16 = (s32)k2_q16;
	g->cal_k3_q16 = (s32)k3_q16;
	if (cal_capture_fit) {
		cal_last_k1_q16 = g->cal_k1_q16;
		cal_last_k2_q16 = g->cal_k2_q16;
		cal_last_k3_q16 = g->cal_k3_q16;
	}

	*mean_residual_out = (u32)div_s64(residual_sum, 5);
	return true;
}

static s64 cal_div_round_closest_s64(s64 num, s64 den)
{
	s64 q = div_s64(num, den);
	s64 r = num - q * den;
	s64 abs_r = (r < 0) ? -r : r;
	s64 abs_den = (den < 0) ? -den : den;

	if (abs_r * 2 >= abs_den)
		q += ((num < 0) ^ (den < 0)) ? -1 : 1;

	return q;
}

static bool cal_find_best_target(struct fusion_gpt *g, u32 *best_gain, int *best_dac)
{
	s64 e0_q16 = (s64)g->cal_probe_mean[0] << 16;
	u32 gv;
	u32 gain_step = max_t(u32, 1, cal_inverse_gain_step);
	u32 gain_start = clamp(max_t(u32, g->si_gain_min, fusion_start_gain_value()),
			       g->si_gain_min, g->si_gain_max);

	*best_gain = g->cal_center_gain;
	*best_dac = g->cal_center_dac;

	for (gv = gain_start; gv <= g->si_gain_max; gv += gain_step) {
		s64 dg = (s64)gv - (s64)g->cal_center_gain;
		s64 numer = -(e0_q16 + (s64)g->cal_k1_q16 * dg);
		s64 denom = (s64)g->cal_k2_q16 + (s64)g->cal_k3_q16 * dg;
		s64 dd;
		s64 dv;

		if (denom == 0) {
			pr_info("fusion_gpt: cal inverse reject gain=%u dac=undefined denom=0\n",
				gv);
			goto next_gain;
		}

		dd = cal_div_round_closest_s64(numer, denom);
		dv = (s64)g->cal_center_dac + dd;
		if (dv >= cal_jump_dac_min_value() && dv <= cal_jump_dac_max_value()) {
			*best_gain = gv;
			*best_dac = (int)dv;
			pr_info("fusion_gpt: cal inverse target gain=%u dac=%d (center gain=%u dac=%d)\n",
				*best_gain, *best_dac,
				g->cal_center_gain, g->cal_center_dac);
			return true;
		}

		pr_info("fusion_gpt: cal inverse reject gain=%u dac=%lld (allowed %d..%d)\n",
			gv, (long long)dv,
			cal_jump_dac_min_value(),
			cal_jump_dac_max_value());

next_gain:
		if (gv > g->si_gain_max - gain_step)
			break;
	}

	pr_warn("fusion_gpt: cal inverse solve found no in-range DAC from gain=%u..%u step=%u\n",
		gain_start, g->si_gain_max, gain_step);
	return false;
}

static irqreturn_t gpt_irq(int irq, void *dev_id)
{
	struct fusion_gpt *g = dev_id;
	u32 sr = rdl(g, GPT_SR);
  u32 clr = 0;
  static DEFINE_RATELIMIT_STATE(_rs, HZ, 1);
	if (!sr) return IRQ_NONE;

	/* extend 64-bit ticks on any event */
	write_seqcount_begin(&g->ticks_sl);
	{
		u32 cnt = rdl(g, GPT_CNT);
		if (cnt < g->last32) g->hi += 1ULL << 32;
		g->last32 = cnt;
	}
	write_seqcount_end(&g->ticks_sl);

	/* If compare was programmed behind CNT, pull it forward so OF1 keeps firing */
	if (!(sr & SR_OF1) && (s32)(g->next_ocr1 - g->last32) <= 0)
		gpt_program_next_compare(g);

  /* ------------------------------------------------------------------
   * IF2: 48kHz Capture (Processed first to update timestamp for IF1 stats)
   * ------------------------------------------------------------------ */
  if (sr & SR_IF2) {
    u32 cap = rdl(g, GPT_ICR2);   /* latches & clears capture2 */

    /* Reconstruct 64-bit capture time */
    u64 now64 = gpt_read_ticks64(g);
    u64 cap64 = (now64 & ~0xffffffffULL) | cap;

    /* Handle wrap-around where capture happened before the upper 32-bits incremented */
    if (cap64 > now64)
        cap64 -= 1ULL << 32;

    g->last_if2_cap64 = cap64;
    g->if2_valid = true;

    clr |= SR_IF2;
  }

  /* IF1: 1PPS capture and disciplining */
  if (sr & SR_IF1) {
      u32 cap = rdl(g, GPT_ICR1);   /* latches & clears capture1 */
      u64 prev_cap64 = 0;
      bool had_prev = false;
      bool epoch_valid = false;
      u64 epoch_ns = 0;
      u64 epoch_cnt64 = 0;

      /* Build a monotonic 64-bit capture close to "now" */
      u64 now64 = gpt_read_ticks64(g);                /* seq-safe read */
      u64 cap64 = (now64 & ~0xffffffffULL) | cap;
      if (cap64 > now64)
          cap64 -= 1ULL << 32;

      raw_spin_lock(&g->pps_lock);
      had_prev = g->pps_valid;

	      if (g->pps_valid) {
	          u64 diff = cap64 - g->pps_icr1_last64;
	          long freq_error = (long)diff - 10000000L;
	          long phase_error = 0;
	          bool was_ready = READ_ONCE(g->discipline_ready);
          
          /* Accumulate squared error for RMS jitter */
          g->sq_err_sum += (s64)freq_error * (s64)freq_error;
          g->err_count++;

          if (cal_enable && g->cal_state == CAL_IDLE &&
              g->dac_client && g->si5351b_client) {
              g->error_integrator = 0;
              WRITE_ONCE(g->si_gain_pending, false);

              if (!g->cal_config_checked) {
                  g->cal_state = CAL_CONFIG_CHECK;
                  schedule_work(&g->dac_work);
              } else if (cal_use_prebaked && cal_pre_valid) {
                  g->cal_center_gain = g->si_gain_current;
                  g->cal_center_dac = clamp(g->dac_target, 0, 255);
                  g->cal_err_accum = 0;
                  g->cal_err_samples = 0;
                  g->cal_measure_left = max_t(u32, 1, cal_pre_e0_samples);
                  g->cal_settle_left = max_t(u32, 1, cal_pre_e0_max_wait);
                  g->cal_state = CAL_PREBAKE_WAIT;
                  pr_info("fusion_gpt: cal prebaked wait center gain=%u dac=%d k=[%d %d %d] need=%u abs<=%u wait<=%u\n",
                          g->cal_center_gain, g->cal_center_dac,
                          cal_pre_k1_q16, cal_pre_k2_q16, cal_pre_k3_q16,
                          max_t(u32, 1, cal_pre_e0_samples),
                          cal_pre_e0_abs_max,
                          max_t(u32, 1, cal_pre_e0_max_wait));
              } else {
                  cal_prepare_points(g);
                  g->cal_state = CAL_APPLY_POINT;
                  pr_info("fusion_gpt: cal start center gain=%u dac=%d settle=%u measure=%u\n",
                          g->cal_center_gain, g->cal_center_dac,
                          max_t(u32, 1, cal_settle_pps),
                          max_t(u32, 1, cal_measure_pps));
                  schedule_work(&g->dac_work);
              }
          } else if (cal_enable && g->cal_state == CAL_IDLE &&
                     (!g->dac_client || !g->si5351b_client)) {
              g->cal_state = CAL_DONE;
              pr_warn_ratelimited("fusion_gpt: cal skipped (missing DAC or Si5351 client)\n");
          }

          if (cal_active(g)) {
              if (g->cal_state == CAL_PREBAKE_WAIT) {
                  long abs_err = (freq_error < 0) ? -freq_error : freq_error;

                  if (abs_err <= cal_pre_e0_abs_max) {
                      g->cal_err_accum += freq_error;
                      g->cal_err_samples++;
                  }

                  if (g->cal_settle_left > 0)
                      g->cal_settle_left--;

                  if (g->cal_err_samples >= max_t(u32, 1, cal_pre_e0_samples)) {
                      long e0 = (long)div_s64(g->cal_err_accum,
                                              max_t(u32, 1, g->cal_err_samples));
                      g->cal_probe_mean[0] = e0;
                      g->cal_k1_q16 = cal_pre_k1_q16;
                      g->cal_k2_q16 = cal_pre_k2_q16;
                      g->cal_k3_q16 = cal_pre_k3_q16;
                      if (cal_find_best_target(g, &g->si_gain_target, &g->dac_target)) {
                          g->cal_state = CAL_APPLY_JUMP;
                          pr_info("fusion_gpt: cal prebaked jump start center gain=%u dac=%d e0=%ld k=[%d %d %d]\n",
                                  g->cal_center_gain, g->cal_center_dac, e0,
                                  g->cal_k1_q16, g->cal_k2_q16, g->cal_k3_q16);
                          schedule_work(&g->dac_work);
                      } else {
                          g->cal_state = CAL_FAIL;
                          schedule_work(&g->dac_work);
                      }
                  } else if (g->cal_settle_left == 0) {
                      g->cal_state = CAL_FAIL;
                      pr_warn("fusion_gpt: cal prebaked e0 collection timed out, fallback to PI\n");
                      schedule_work(&g->dac_work);
                  }
              } else if (g->cal_state == CAL_SETTLE) {
                  if (g->cal_settle_left > 0)
                      g->cal_settle_left--;
                  if (g->cal_settle_left == 0) {
                      g->cal_err_accum = 0;
                      g->cal_err_samples = 0;
                      g->cal_measure_left = max_t(u32, 1, cal_measure_pps);
                      g->cal_state = CAL_MEASURE;
                  }
              } else if (g->cal_state == CAL_MEASURE) {
                  g->cal_err_accum += freq_error;
                  g->cal_err_samples++;
                  if (g->cal_measure_left > 0)
                      g->cal_measure_left--;
                  if (g->cal_measure_left == 0) {
                      long mean = (long)div_s64(g->cal_err_accum,
                                                max_t(u32, 1, g->cal_err_samples));
                      int idx = g->cal_probe_idx;

                      if (idx >= 0 && idx < 5)
                          g->cal_probe_mean[idx] = mean;
                      else
                          idx = 0;

                      pr_info("fusion_gpt: cal probe[%d] gain=%u dac=%d mean_err=%ld\n",
                              idx,
                              g->cal_probe_gain[idx],
                              g->cal_probe_dac[idx],
                              mean);

                      if (idx < 4) {
                          g->cal_probe_idx++;
                          g->cal_state = CAL_APPLY_POINT;
                          schedule_work(&g->dac_work);
                      } else {
                          g->cal_state = CAL_FIT;
                          schedule_work(&g->dac_work);
                      }
                  }
              }
          } else {
              /* Accumulate error into the integrator */
              g->error_integrator += freq_error;

              /* Threshold in ticks for dithering */
              const int INTEGRATOR_LIMIT = 5;
              const int P_THRESHOLD = 20;
              const int P_DIV = 10;
              const int P_MAX_STEP = 10;

              /* Proportional term: only act when error exceeds threshold */
              {
                  long abs_err = (freq_error < 0) ? -freq_error : freq_error;
                  int p_step = 0;

                  if (abs_err > P_THRESHOLD) {
                      p_step = (int)(abs_err / P_DIV);
                      p_step = clamp(p_step, 1, P_MAX_STEP);

                      if (freq_error > 0)
                          g->dac_target -= p_step; /* too fast: slow down */
                      else
                          g->dac_target += p_step; /* too slow: speed up */
                  }
              }

              if (g->error_integrator > INTEGRATOR_LIMIT) {
                  /* Positive error (too fast): slow down */
                  g->dac_target--;
                  g->error_integrator = 0;
              }
              else if (g->error_integrator < -INTEGRATOR_LIMIT) {
                  /* Negative error (too slow): speed up */
                  g->dac_target++;
                  g->error_integrator = 0;
              }
              {
                  const u32 SI_GAIN_STEP = 10000;
                  bool sat_high = (g->dac_target > 255);
                  bool sat_low = (g->dac_target < 0);

                  if (sat_high || sat_low) {
                      if (sat_high) {
                          g->dac_target = 255;
                          pr_warn_ratelimited("fusion_gpt: DAC saturated high (freq_err=%ld tick, integ=%ld)\n",
                                              freq_error, g->error_integrator);
                      } else {
                          g->dac_target = 0;
                          pr_warn_ratelimited("fusion_gpt: DAC saturated low (freq_err=%ld tick, integ=%ld)\n",
                                              freq_error, g->error_integrator);
                      }

                      if (g->si5351b_client) {
                          if (!READ_ONCE(g->si_gain_pending)) {
                              u32 next_gain = g->si_gain_current + SI_GAIN_STEP;

                              if (next_gain > g->si_gain_max)
                                  next_gain = g->si_gain_max;

                              if (next_gain > g->si_gain_current) {
                                  WRITE_ONCE(g->si_gain_target, next_gain);
                                  WRITE_ONCE(g->si_gain_pending, true);
                                  pr_info_ratelimited("fusion_gpt: Queued Si5351b gain increase to %u\n",
                                                      next_gain);
                              } else {
                                  pr_debug_ratelimited("fusion_gpt: DAC saturated at max Si5351b gain (%u)\n",
                                                       g->si_gain_current);
                              }
                          }
                      } else {
                          pr_debug_ratelimited("fusion_gpt: Si5351b client missing, cannot adjust gain\n");
                      }
                  }
              }
          }

          /* 48kHz offset: time from last 48k edge to current PPS */
          long if2_offset_ns = 0;
          if (g->if2_valid) {
              if2_offset_ns = (long)(cap64 - g->last_if2_cap64) * 100L;
              
              /* Normalize to a positive phase within one 48k period */
              if (if2_offset_ns < 0) {
                   if2_offset_ns += 20833;
              }
          }

          if (g->phc_epoch_valid) {
               u64 ticks_from_start = cap64 - g->pps_epoch_cnt64;
               long rem = ticks_from_start % 10000000l;
               if (rem > 5000000) phase_error = rem - 10000000l;
               else phase_error = rem;
	          }
	          g->latest_freq_error = freq_error;
	          g->cumulative_error_ticks_total += freq_error;
	          gpt_update_discipline_ready(g, freq_error);
	          if (was_ready || READ_ONCE(g->discipline_ready))
	              g->cumulative_error_ticks_locked += freq_error;

	          u32 rms_jitter = 0;
	          if (g->err_count > 0) {
	              rms_jitter = int_sqrt(g->sq_err_sum / g->err_count);
          }

	          if (__ratelimit(&_rs)) {
	              pr_alert("fusion_gpt: [PPS] diff=%llu ticks, err=%ld ticks, rms=%u ticks, cum=%lld ticks, cum_lock=%lld ticks | [48K] off=%ldns | DAC=%d\n",
	                       diff, freq_error, rms_jitter,
	                       (long long)g->cumulative_error_ticks_total,
	                       (long long)g->cumulative_error_ticks_locked,
	                       if2_offset_ns, g->dac_target);
	              
	              g->sq_err_sum = 0;
	              g->err_count = 0;
          }
      }
		prev_cap64 = g->pps_icr1_last64;
		epoch_valid = g->phc_epoch_valid;
		epoch_ns = g->phc_epoch_ns;
		epoch_cnt64 = g->pps_epoch_cnt64;
		g->pps_seq++;
		g->pps_icr1_last32 = cap;
		g->pps_icr1_last64 = cap64;
		g->pps_valid       = true;

		/* If armed for the next PPS, bind the epoch now */
        if (g->pending_future_anchor) {
            g->phc_epoch_ns        = g->pending_future_phc_ns;
            g->pps_epoch_cnt64     = cap64;
            g->phc_epoch_valid     = true;
            g->phc_aligned         = false; /* ensure OF1 one-shot align runs */
            g->pending_future_anchor = false;
            pr_info("fusion_gpt: phc anchor latched epoch=%llu cnt=%llu\n",
                    g->phc_epoch_ns, g->pps_epoch_cnt64);
        }
		raw_spin_unlock(&g->pps_lock);

		/* Unconditional PPS capture log for timing/health */
		{
			u64 missed = 0;
			u64 delta_ticks = 0;
			u64 phc_ns = 0;

			if (had_prev) {
				u64 intervals;
				delta_ticks = cap64 - prev_cap64;
				intervals = (delta_ticks + (PPS_TICKS / 2)) / PPS_TICKS;
				if (intervals == 0)
					intervals = 1;
				missed = intervals - 1;
			}

			if (epoch_valid && cap64 >= epoch_cnt64)
				phc_ns = epoch_ns + (cap64 - epoch_cnt64) * 100ULL;
		}

		if (READ_ONCE(g->dac_target) != READ_ONCE(g->current_dac_value) ||
		    READ_ONCE(g->si_gain_pending) ||
		    cal_active(g) ||
		    READ_ONCE(g->cal_state) == CAL_FIT ||
		    READ_ONCE(g->cal_state) == CAL_APPLY_JUMP)
			schedule_work(&g->dac_work);
		clr |= SR_IF1;

	}

	if (sr & SR_IF2)
		clr |= SR_IF2;

	if (sr & SR_OF1) {
		bool do_align = false;
		u64 epoch_ns = 0, epoch_cnt64 = 0;

		/* One-shot phase align: if we have a valid PHC epoch and haven't aligned yet */
		if (!READ_ONCE(g->phc_aligned)) {
			unsigned long flags;
			bool valid;

			/* Snapshot epoch under pps_lock */
			raw_spin_lock_irqsave(&g->pps_lock, flags);
			valid       = g->phc_epoch_valid;
			epoch_ns    = g->phc_epoch_ns;
			epoch_cnt64 = g->pps_epoch_cnt64;
			raw_spin_unlock_irqrestore(&g->pps_lock, flags);

			do_align = valid;
		}

		if (do_align) {
			/*
			 * Compute current PHC time from GPT ticks:
			 *   phc_now_ns = epoch_ns + (now64 - epoch_cnt64) * 100
			 * Then retarget next OCR1 so that the next OF1 occurs at the next
			 * PHC multiple of 333,333 ns (i.e., 1/3 ms boundary).
			 */
			u64 now64 = (g->hi | g->last32);          /* extended earlier in this IRQ */
			u64 dt_ticks = now64 - epoch_cnt64;
			u64 phc_now_ns = epoch_ns + dt_ticks * 100ULL;

			const u64 grid_ns = 333333ULL;
			u64 rem = phc_now_ns % grid_ns;
			u64 delta_ns = (rem == 0) ? grid_ns : (grid_ns - rem);  /* next future boundary */
			u64 delta_ticks = ceil_div_u64(delta_ns, 100ULL);       /* 100 ns per tick */

			/* Constrain to a sane window: 1x .. 3x period to avoid huge gaps */
			u32 min_inc = PERIOD_TICKS_BASE;
			u32 max_inc = PERIOD_TICKS_BASE * 3;
			u32 inc = (delta_ticks < min_inc) ? min_inc :
				  (delta_ticks > max_inc) ? max_inc : (u32)delta_ticks;

			g->frac = 0;                               /* restart 3333/3333/3334 cadence after align */
			g->next_ocr1 = g->last32 + inc;
			wrl(g, g->next_ocr1, GPT_OCR1);

            WRITE_ONCE(g->phc_aligned, true);          /* only once */
            pr_info("fusion_gpt: phc aligned to 1/3ms grid\n");

			clr |= SR_OF1;                              /* clear the latched OF1 */
			if (clr) wrl(g, clr, GPT_SR);

			/* Still notify the client for this tick */
			gpt_tick_direct(g);

			return IRQ_HANDLED;                         /* skip normal schedule this time */
		}

		/* Normal path once aligned (or if no epoch yet) */
		gpt_program_next_compare(g);
		clr |= SR_OF1;
		gpt_tick_direct(g);
	}

	if (clr) wrl(g, clr, GPT_SR);
	return IRQ_HANDLED;
}

static int fusion_write_dac(struct fusion_gpt *g, int target, bool ratelimited_log)
{
	int ret;
	u8 buf[3];

	target = clamp(target, 0, 255);
	if (target == g->current_dac_value)
		return 0;

	buf[0] = 0x00; /* Register/Command Byte (device specific) */
	buf[1] = 0x00; /* Often MSB or Control */
	buf[2] = (u8)(target & 0xFF);

	if (!g->dac_client)
		return -ENODEV;

	ret = i2c_master_send(g->dac_client, buf, 3);
	if (ret < 0)
		return ret;

	g->current_dac_value = target;
	if (ratelimited_log)
		pr_info_ratelimited("fusion_gpt: Updated DAC to %u (Integrator Move)\n", target);

	return 0;
}

static void fusion_dac_work_handler(struct work_struct *work)
{
    struct fusion_gpt *g = container_of(work, struct fusion_gpt, dac_work);
    int ret = 0;
    int target = READ_ONCE(g->dac_target);
    bool gain_pending = READ_ONCE(g->si_gain_pending);
    u32 gain_target = READ_ONCE(g->si_gain_target);

    if (g->cal_state == CAL_CONFIG_CHECK) {
        s32 k1_q16 = 0, k2_q16 = 0, k3_q16 = 0;

        g->cal_config_checked = true;

        if (cal_config_autoload) {
            ret = cal_load_prebaked_config(&k1_q16, &k2_q16, &k3_q16);
            if (ret == 0) {
                cal_pre_k1_q16 = k1_q16;
                cal_pre_k2_q16 = k2_q16;
                cal_pre_k3_q16 = k3_q16;
                cal_pre_valid = true;
                cal_use_prebaked = true;
                pr_info("fusion_gpt: loaded prebaked coefficients from %s k=[%d %d %d]\n",
                        cal_config_path, cal_pre_k1_q16, cal_pre_k2_q16, cal_pre_k3_q16);
            } else if (ret != -ENOENT) {
                pr_warn("fusion_gpt: failed to load prebaked coefficients from %s ret=%d, running live calibration\n",
                        cal_config_path, ret);
            }
        }

        if (cal_use_prebaked && cal_pre_valid) {
            g->cal_center_gain = g->si_gain_current;
            g->cal_center_dac = clamp(g->dac_target, 0, 255);
            g->cal_err_accum = 0;
            g->cal_err_samples = 0;
            g->cal_measure_left = max_t(u32, 1, cal_pre_e0_samples);
            g->cal_settle_left = max_t(u32, 1, cal_pre_e0_max_wait);
            g->cal_state = CAL_PREBAKE_WAIT;
            pr_info("fusion_gpt: cal prebaked wait center gain=%u dac=%d k=[%d %d %d] need=%u abs<=%u wait<=%u\n",
                    g->cal_center_gain, g->cal_center_dac,
                    cal_pre_k1_q16, cal_pre_k2_q16, cal_pre_k3_q16,
                    max_t(u32, 1, cal_pre_e0_samples),
                    cal_pre_e0_abs_max,
                    max_t(u32, 1, cal_pre_e0_max_wait));
        } else {
            cal_prepare_points(g);
            g->cal_state = CAL_APPLY_POINT;
            pr_info("fusion_gpt: cal start center gain=%u dac=%d settle=%u measure=%u\n",
                    g->cal_center_gain, g->cal_center_dac,
                    max_t(u32, 1, cal_settle_pps),
                    max_t(u32, 1, cal_measure_pps));
            schedule_work(&g->dac_work);
        }
        return;
    }

    if (g->cal_state == CAL_APPLY_POINT) {
        u32 probe_gain = g->cal_probe_gain[g->cal_probe_idx];
        int probe_dac = g->cal_probe_dac[g->cal_probe_idx];

        if (probe_gain != g->si_gain_current) {
            ret = si5351b_write_gain(g, probe_gain);
            if (ret < 0) {
                pr_err("fusion_gpt: cal failed applying probe gain idx=%d ret=%d\n",
                       g->cal_probe_idx, ret);
                g->cal_state = CAL_FAIL;
                return;
            }
            g->si_gain_current = probe_gain;
        }

        ret = fusion_write_dac(g, probe_dac, false);
        if (ret < 0) {
            pr_err("fusion_gpt: cal failed applying probe dac idx=%d ret=%d\n",
                   g->cal_probe_idx, ret);
            g->cal_state = CAL_FAIL;
            return;
        }

        g->dac_target = probe_dac;
        g->error_integrator = 0;
        g->cal_settle_left = max_t(u32, 1, cal_settle_pps);
        g->cal_state = CAL_SETTLE;
        return;
    }

    if (g->cal_state == CAL_FIT) {
        u32 residual = 0;

        if (!cal_fit_model(g, &residual)) {
            pr_warn("fusion_gpt: cal fit failed (degenerate probe geometry)\n");
            g->cal_state = CAL_FAIL;
            return;
        }

        if (residual > cal_fit_residual_thresh) {
            pr_warn("fusion_gpt: cal fit residual too high (%u > %u), skipping jump\n",
                    residual, cal_fit_residual_thresh);
            g->cal_state = CAL_FAIL;
            return;
        }

        cal_pre_k1_q16 = g->cal_k1_q16;
        cal_pre_k2_q16 = g->cal_k2_q16;
        cal_pre_k3_q16 = g->cal_k3_q16;
        cal_pre_valid = true;
        cal_use_prebaked = true;
        if (cal_config_autosave) {
            ret = cal_save_prebaked_config(g->cal_k1_q16, g->cal_k2_q16, g->cal_k3_q16);
            if (ret < 0) {
                if (ret == -ENOENT)
                    pr_warn("fusion_gpt: failed to save prebaked coefficients to %s ret=%d (missing parent directory?)\n",
                            cal_config_path, ret);
                else
                    pr_warn("fusion_gpt: failed to save prebaked coefficients to %s ret=%d\n",
                            cal_config_path, ret);
            } else {
                pr_info("fusion_gpt: saved prebaked coefficients to %s\n",
                        cal_config_path);
            }
        }

        if (cal_find_best_target(g, &g->si_gain_target, &g->dac_target)) {
            g->cal_state = CAL_APPLY_JUMP;
            schedule_work(&g->dac_work);
        } else {
            g->cal_state = CAL_FAIL;
            schedule_work(&g->dac_work);
        }
        return;
    }

    if (g->cal_state == CAL_APPLY_JUMP) {
        u32 jump_gain = clamp(g->si_gain_target, g->si_gain_min, g->si_gain_max);
        int jump_dac = clamp(g->dac_target,
                             cal_jump_dac_min_value(),
                             cal_jump_dac_max_value());

        if (jump_gain != g->si_gain_current) {
            ret = si5351b_write_gain(g, jump_gain);
            if (ret < 0) {
                pr_warn("fusion_gpt: cal jump gain write failed ret=%d, fallback to PI\n", ret);
                g->cal_state = CAL_FAIL;
                return;
            }
            g->si_gain_current = jump_gain;
        }

        ret = fusion_write_dac(g, jump_dac, false);
        if (ret < 0) {
            pr_warn("fusion_gpt: cal jump dac write failed ret=%d, fallback to PI\n", ret);
            g->cal_state = CAL_FAIL;
            return;
        }

        g->error_integrator = 0;
        g->cal_state = CAL_DONE;
        pr_info("fusion_gpt: cal jump applied gain=%u dac=%d (center gain=%u dac=%d)\n",
                g->si_gain_current, g->current_dac_value,
                g->cal_center_gain, g->cal_center_dac);
        return;
    }

    if (g->cal_state == CAL_FAIL) {
        g->cal_state = CAL_DONE;
        g->error_integrator = 0;
        pr_info("fusion_gpt: cal fallback to PI loop\n");
        return;
    }

    target = clamp(target, 0, 255);

    ret = fusion_write_dac(g, target, true);
    if (ret == -ENODEV) {
        pr_info_ratelimited("fusion_gpt: DAC client missing\n");
    } else if (ret < 0) {
        pr_err_ratelimited("fusion_gpt: I2C DAC write failed: %d\n", ret);
    }

    if (gain_pending) {
        gain_target = clamp(gain_target, g->si_gain_min, g->si_gain_max);
        if (gain_target > g->si_gain_current) {
            if (si5351b_write_gain(g, gain_target) >= 0) {
                g->si_gain_current = gain_target;
                WRITE_ONCE(g->si_gain_pending, false);
                pr_info_ratelimited("fusion_gpt: Si5351b gain increased to %u\n",
                                    g->si_gain_current);
            }
        } else {
            WRITE_ONCE(g->si_gain_pending, false);
        }
    }
}

static int si5351b_write_gain(struct fusion_gpt *g, u32 gain)
{
    int ret;
    u8 buf[4];

    if (!g->si5351b_client)
        return -ENODEV;

    buf[0] = 0xA2;
    buf[1] = (u8)(gain & 0xFF);
    buf[2] = (u8)((gain >> 8) & 0xFF);
    buf[3] = (u8)((gain >> 16) & 0xFF);

    ret = i2c_master_send(g->si5351b_client, buf, 4);
    if (ret < 0)
        pr_err_ratelimited("fusion_gpt: Si5351b gain write failed: %d\n", ret);

    return ret;
}
static int gpt_start(struct fusion_gpt *g)
{
	u32 cr;

	wrl(g, 0, GPT_CR);
	wrl(g, 0, GPT_PR);
	wrl(g, SR_OF1 | SR_IF1 | SR_IF2, GPT_SR);
	wrl(g, IR_OF1IE | IR_IF1IE, GPT_IR);

	cr = CR_ENMOD | CR_FRR | CR_CLKSRC_EXT | CR_DBGEN | CR_WAITEN |
	      CR_IM1_BOTH | CR_IM2_RISING;
	wrl(g, cr, GPT_CR);

	g->frac = 0;
	g->last32 = rdl(g, GPT_CNT);
	g->hi = 0;
	seqcount_init(&g->ticks_sl);

	raw_spin_lock_init(&g->pps_lock);
	gpt_reset_timing_state_locked(g);

	g->next_ocr1 = g->last32 + PERIOD_TICKS_BASE;
	wrl(g, g->next_ocr1, GPT_OCR1);

	wrl(g, cr | CR_EN, GPT_CR);
	return 0;
}

static int gpt_probe(struct platform_device *pdev)
{
	struct fusion_gpt *g;
	struct resource *res;
	int irq, ret;
	struct i2c_adapter *adapter;
	struct i2c_board_info dac_info = {
		I2C_BOARD_INFO("mcp4725", DEFAULT_DAC_I2C_ADDR),
	};
	struct i2c_board_info si_info = {
		I2C_BOARD_INFO("fusion-si5351b", DEFAULT_SI5351B_I2C_ADDR),
	};

	g = devm_kzalloc(&pdev->dev, sizeof(*g), GFP_KERNEL);
	if (!g)
		return -ENOMEM;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	g->base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(g->base))
		return PTR_ERR(g->base);

	irq = platform_get_irq(pdev, 0);
	if (irq < 0)
		return irq;
	g->irq = irq;

	/* Get and enable clocks */
	g->clk_ipg = devm_clk_get(&pdev->dev, "ipg");
	if (IS_ERR(g->clk_ipg))
		return dev_err_probe(&pdev->dev, PTR_ERR(g->clk_ipg),
				     "failed to get ipg clk\n");

	g->clk_per = devm_clk_get(&pdev->dev, "per");
	if (IS_ERR(g->clk_per))
		return dev_err_probe(&pdev->dev, PTR_ERR(g->clk_per),
				     "failed to get per clk\n");

	ret = clk_prepare_enable(g->clk_ipg);
	if (ret)
		return dev_err_probe(&pdev->dev, ret,
				     "failed to enable ipg clk\n");

	ret = clk_prepare_enable(g->clk_per);
	if (ret) {
		clk_disable_unprepare(g->clk_ipg);
		return dev_err_probe(&pdev->dev, ret,
				     "failed to enable per clk\n");
	}

	platform_set_drvdata(pdev, g);
	
	mutex_init(&g->ops_lock);

	ret = devm_request_irq(&pdev->dev, g->irq, gpt_irq, IRQF_NO_THREAD,
			       dev_name(&pdev->dev), g);
	if (ret) goto err_disable_clks;

	/* DAC + VCXO disciplining setup */
	g->dac_target = 128;
	g->current_dac_value = 0xFFFF; /* force first write */
	g->si_gain_min = 40000;
	g->si_gain_max = 250000;
	g->si_gain_current = clamp(fusion_start_gain_value(),
				   g->si_gain_min, g->si_gain_max);
	g->si_gain_target = g->si_gain_current;
	g->si_gain_pending = false;
	INIT_WORK(&g->dac_work, fusion_dac_work_handler);

	/* Get the discipline I2C adapter (defer if not ready). */
	adapter = i2c_get_adapter(DEFAULT_DAC_I2C_BUS);
	if (!adapter) {
		dev_dbg(&pdev->dev, "I2C bus %u not ready, deferring probe\n",
			DEFAULT_DAC_I2C_BUS);
		ret = -EPROBE_DEFER;
		goto err_disable_clks;
	}

	/* Create DAC client. */
	g->dac_client = i2c_new_client_device(adapter, &dac_info);
	if (IS_ERR(g->dac_client)) {
		ret = PTR_ERR(g->dac_client);
		g->dac_client = NULL;
		i2c_put_adapter(adapter);
		dev_err_probe(&pdev->dev, ret, "failed to create I2C client for DAC\n");
		goto err_disable_clks;
	}

	/* Create Si5351b client. */
	g->si5351b_client = i2c_new_client_device(adapter, &si_info);
	if (IS_ERR(g->si5351b_client)) {
		dev_warn(&pdev->dev, "failed to create I2C client for Si5351b: %ld\n",
			 PTR_ERR(g->si5351b_client));
		g->si5351b_client = NULL;
	} else if (si5351b_write_gain(g, g->si_gain_current) < 0) {
		dev_warn(&pdev->dev, "failed to initialize Si5351b gain\n");
	}

	i2c_put_adapter(adapter);

	ret = gpt_start(g);
	if (ret)
		goto err_cleanup_i2c;

	/* publish after start */
	mutex_lock(&gpt_singleton_lock);
	rcu_assign_pointer(gpt_singleton, g);
	mutex_unlock(&gpt_singleton_lock);

	dev_info(&pdev->dev,
		 "GPT1 shim running (EXT 10MHz, 1/3ms compares)\n");
	return 0;

err_cleanup_i2c:
	cancel_work_sync(&g->dac_work);
	if (g->dac_client)
		i2c_unregister_device(g->dac_client);
	if (g->si5351b_client)
		i2c_unregister_device(g->si5351b_client);
err_disable_clks:
	clk_disable_unprepare(g->clk_per);
	clk_disable_unprepare(g->clk_ipg);
	return ret;
}

static void gpt_remove(struct platform_device *pdev)
{
	struct fusion_gpt *g = platform_get_drvdata(pdev);
	u32 cr = rdl(g, GPT_CR);

	mutex_lock(&gpt_singleton_lock);
	rcu_assign_pointer(gpt_singleton, NULL);
	mutex_unlock(&gpt_singleton_lock);
	synchronize_rcu();

	wrl(g, 0, GPT_IR);                               /* mask all */
	wrl(g, SR_OF1 | SR_IF1 | SR_IF2, GPT_SR);        /* W1C clear any latched */
	wrl(g, cr & ~CR_EN, GPT_CR);                     /* stop */

	cancel_work_sync(&g->dac_work);

	/* Gate clocks */
	clk_disable_unprepare(g->clk_per);
	clk_disable_unprepare(g->clk_ipg);
	if (g->dac_client)
		i2c_unregister_device(g->dac_client);
	if (g->si5351b_client)
		i2c_unregister_device(g->si5351b_client);
}

static const struct of_device_id of_match[] = {
	{ .compatible = "bosepro,fusion-gpt" },
	{ }
};
MODULE_DEVICE_TABLE(of, of_match);

static struct platform_driver drv = {
	.probe = gpt_probe,
	.remove = gpt_remove,
	.driver = {
		.name = "fusion-gpt",
		.of_match_table = of_match,
	},
};
module_platform_driver(drv);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Bose Pro");
MODULE_DESCRIPTION("GPT1 SHIM EXPORTING 1/3MS TICKS");
MODULE_VERSION("1.0.1-configuration-save");

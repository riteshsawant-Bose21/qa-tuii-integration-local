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
#include "fusion_gpt_client.h"

/* VCXO disciplining */
#include <linux/workqueue.h>
#include <linux/i2c.h>

#define GPT_CR		0x00
#define GPT_PR		0x04
#define GPT_SR		0x08
#define GPT_IR		0x0C
#define GPT_OCR1	0x10
#define GPT_ICR1	0x1C
#define GPT_ICR2	0x20
#define GPT_CNT		0x24

/* CR bits */
#define CR_EN			BIT(0)
#define CR_ENMOD		BIT(1)
#define CR_DBGEN		BIT(2)
#define CR_WAITEN		BIT(3)
#define CR_CLKSRC_SHIFT 6
#define CR_CLKSRC_EXT	(0x3 << CR_CLKSRC_SHIFT)
#define CR_FRR			BIT(9)
#define CR_IM1_SHIFT	16
#define CR_IM1_RISING	(0x1 << CR_IM1_SHIFT)
#define CR_IM1_BOTH		(0x3 << CR_IM1_SHIFT) /* 1pps on both edges */
#define CR_IM2_SHIFT	18
#define CR_IM2_RISING	(0x1 << CR_IM2_SHIFT) /* LRCLK on rising edge */

/* SR (status, W1C) and IR (enable) bits */
#define SR_OF1	 BIT(0)
#define SR_IF1	 BIT(3)
#define SR_IF2	 BIT(4)
#define IR_OF1IE BIT(0)
#define IR_IF1IE BIT(3)
#define IR_IF2IE BIT(4)

/* 10 MHz -> 100 ns/tick; 1/3 ms = 333333.333 ns -> 3333,3333,3334 ticks */
#define PERIOD_TICKS_BASE 3333U
/* 10 MHz -> 10,000,000 ticks per second for 1PPS capture cadence */
#define PPS_TICKS 10000000ULL

#define DEFAULT_DAC_I2C_BUS	 0
#define DEFAULT_DAC_I2C_ADDR 0x62

#define DAC_MIN_VALUE 0
#define DAC_MAX_VALUE 65535
#define DAC_MID_VALUE 32768
#define DAC_INVALID_VALUE -1

#define DISCIPLINE_LOCK_CONSECUTIVE 5U
#define DISCIPLINE_GM_LOCK_TIMEOUT_MS 1500U
#define MODEL_MAX_SAMPLES 16U

static bool pps_debug_param;
module_param(pps_debug_param, bool, 0644);
MODULE_PARM_DESC(pps_debug_param, "Enable periodic 1PPS diagnostic logging");

static uint error_thresh_param = 20;
module_param(error_thresh_param, uint, 0644);
MODULE_PARM_DESC(error_thresh_param, "Raise discipline_gm_locked after 5 PPS samples with abs_error < this threshold");

static uint max_valid_pps_error_param = 10000;
module_param(max_valid_pps_error_param, uint, 0644);
MODULE_PARM_DESC(max_valid_pps_error_param, "Maximum absolute PPS interval error in ticks for a sample to be used by servo and discipline logic");

static uint discipline_holdover_timeout_ms_param = 30000;
module_param_named(discipline_holdover_timeout_ms,
		   discipline_holdover_timeout_ms_param, uint, 0644);
MODULE_PARM_DESC(discipline_holdover_timeout_ms,
		 "Milliseconds to keep discipline_continuity_ready without PPS; 0 disables the timeout");

static uint pi_p_threshold_param = 20;
module_param(pi_p_threshold_param, uint, 0644);
MODULE_PARM_DESC(pi_p_threshold_param, "PI P-term activation threshold in PPS error ticks");

static uint pi_p_gain_q16_param = 262144;
module_param(pi_p_gain_q16_param, uint, 0644);
MODULE_PARM_DESC(pi_p_gain_q16_param, "PI P-term gain in Q16 fixed-point DAC-counts per PPS-error tick");

static uint pi_i_gain_q16_param = 65536;
module_param(pi_i_gain_q16_param, uint, 0644);
MODULE_PARM_DESC(pi_i_gain_q16_param, "PI I-term gain in Q16 fixed-point DAC-counts per accumulated PPS-error tick");

static uint pi_integrator_clamp_param = 5;
module_param(pi_integrator_clamp_param, uint, 0644);
MODULE_PARM_DESC(pi_integrator_clamp_param, "Absolute clamp applied to the PI error integrator state");

static uint model_window_size_param = 8;
module_param(model_window_size_param, uint, 0644);
MODULE_PARM_DESC(model_window_size_param, "Rolling sample window size for DAC/error linear fit");

static uint model_min_samples_param = 4;
module_param(model_min_samples_param, uint, 0644);
MODULE_PARM_DESC(model_min_samples_param, "Minimum PI samples required before allowing a model-driven jump");

static uint model_min_dac_span_param = 64;
module_param(model_min_dac_span_param, uint, 0644);
MODULE_PARM_DESC(model_min_dac_span_param, "Minimum DAC span required across model samples");

static uint model_max_mean_residual_param = 10;
module_param(model_max_mean_residual_param, uint, 0644);
MODULE_PARM_DESC(model_max_mean_residual_param, "Maximum mean absolute residual in PPS ticks for a valid jump model");

static uint model_jump_min_error_param = 10;
module_param(model_jump_min_error_param, uint, 0644);
MODULE_PARM_DESC(model_jump_min_error_param, "Minimum absolute PPS error in ticks before taking a model-driven jump");

int fusion_gpt_reset_timing_state(void);
int fusion_gpt_reset_timing_session(void);
static int fusion_gpt_reset_timing_state_internal(bool preserve_ready_for_recheck,
						  bool simulate_pps_gap);
static int fusion_gpt_simulate_pps_gap_only(void);

static int timing_reset_trigger_param;
static int timing_reset_sim_trigger_param;
static int timing_pps_gap_sim_trigger_param;
static uint timing_reset_sim_duration_ms_param;

static int gpt_param_set_timing_reset_trigger(const char *val,
					      const struct kernel_param *kp)
{
	unsigned int trigger;
	int *trigger_param = kp->arg;
	int ret;

	ret = kstrtouint(val, 0, &trigger);
	if (ret)
		return ret;

	if (!trigger) {
		*trigger_param = 0;
		return 0;
	}

	ret = fusion_gpt_reset_timing_state();
	*trigger_param = 0;
	return ret;
}

static int gpt_param_get_timing_reset_trigger(char *buffer,
					      const struct kernel_param *kp)
{
	int *trigger_param = kp->arg;

	*trigger_param = 0;
	return scnprintf(buffer, PAGE_SIZE, "0\n");
}

static const struct kernel_param_ops timing_reset_trigger_param_ops = {
	.set = gpt_param_set_timing_reset_trigger,
	.get = gpt_param_get_timing_reset_trigger,
};

module_param_cb(timing_reset_trigger, &timing_reset_trigger_param_ops,
		&timing_reset_trigger_param, 0200);
MODULE_PARM_DESC(timing_reset_trigger,
		 "Write non-zero to trigger a one-shot timing reset");

static int gpt_param_set_timing_reset_sim_trigger(const char *val,
						  const struct kernel_param *kp)
{
	unsigned int trigger;
	int *trigger_param = kp->arg;
	int ret;

	ret = kstrtouint(val, 0, &trigger);
	if (ret)
		return ret;

	if (!trigger) {
		*trigger_param = 0;
		return 0;
	}

	ret = fusion_gpt_reset_timing_state_internal(true, true);
	*trigger_param = 0;
	return ret;
}

static int gpt_param_get_timing_reset_sim_trigger(char *buffer,
						  const struct kernel_param *kp)
{
	int *trigger_param = kp->arg;

	*trigger_param = 0;
	return scnprintf(buffer, PAGE_SIZE, "0\n");
}

static const struct kernel_param_ops timing_reset_sim_trigger_param_ops = {
	.set = gpt_param_set_timing_reset_sim_trigger,
	.get = gpt_param_get_timing_reset_sim_trigger,
};

module_param_cb(timing_reset_sim_trigger, &timing_reset_sim_trigger_param_ops,
		&timing_reset_sim_trigger_param, 0200);
MODULE_PARM_DESC(timing_reset_sim_trigger,
		 "Write non-zero to trigger a timing reset and suppress PPS handling for timing_reset_sim_duration_ms");

module_param_named(timing_reset_sim_duration_ms, timing_reset_sim_duration_ms_param,
		   uint, 0644);
MODULE_PARM_DESC(timing_reset_sim_duration_ms,
		 "Milliseconds to suppress PPS handling after timing_reset_sim_trigger");

static int gpt_param_set_timing_pps_gap_sim_trigger(const char *val,
						    const struct kernel_param *kp)
{
	unsigned int trigger;
	int *trigger_param = kp->arg;
	int ret;

	ret = kstrtouint(val, 0, &trigger);
	if (ret)
		return ret;

	if (!trigger) {
		*trigger_param = 0;
		return 0;
	}

	ret = fusion_gpt_simulate_pps_gap_only();
	*trigger_param = 0;
	return ret;
}

static int gpt_param_get_timing_pps_gap_sim_trigger(char *buffer,
						    const struct kernel_param *kp)
{
	int *trigger_param = kp->arg;

	*trigger_param = 0;
	return scnprintf(buffer, PAGE_SIZE, "0\n");
}

static const struct kernel_param_ops timing_pps_gap_sim_trigger_param_ops = {
	.set = gpt_param_set_timing_pps_gap_sim_trigger,
	.get = gpt_param_get_timing_pps_gap_sim_trigger,
};

module_param_cb(timing_pps_gap_sim_trigger, &timing_pps_gap_sim_trigger_param_ops,
		&timing_pps_gap_sim_trigger_param, 0200);
MODULE_PARM_DESC(timing_pps_gap_sim_trigger,
		 "Write non-zero to suppress PPS handling for timing_reset_sim_duration_ms without resetting timing state");

struct fusion_gpt
{
	void __iomem *base;
	int irq;

	u32 next_ocr1;
	u8	frac;

	u32 last32;
	u64 hi;
	seqcount_t ticks_sl;

	const struct fusion_gpt_client_ops *ops;
	void *ops_ctx;
	struct module *ops_owner;
	struct mutex ops_lock;

	struct clk *clk_ipg;
	struct clk *clk_per;

	/* PPS and PHC epoch state protected by pps_lock. */
	u32  pps_seq;
	u32  pps_icr1_last32;
	u64  pps_icr1_last64;
	bool pps_valid;
	u64  last_if2_cap64;
	bool if2_valid;

	u64  phc_epoch_ns;
	u64  pps_epoch_cnt64;
	bool phc_epoch_valid;
	raw_spinlock_t pps_lock;
	raw_spinlock_t ctrl_lock;
	struct device *dev;

	bool phc_aligned;
	u64  next_tick_phc_ns;
	u8   tick_phase;

	/* "Arm-next-PPS" anchor from userspace. */
	bool pending_future_anchor;
	u64  pending_future_phc_ns;
	unsigned long last_pps_jiffies;
	unsigned long pps_suppress_until_jiffies;

	/* PI servo and DAC state protected by ctrl_lock. */
	struct work_struct dac_work;
	struct i2c_client *dac_client;
	int current_dac_value;
	int dac_target;
	long latest_freq_error;
	long error_integrator;
	u64 sq_err_sum;
	u32 err_count;
	bool baseline_restore_pending;
	bool baseline_restore_session_reset;
	int model_dac_samples[MODEL_MAX_SAMPLES];
	long model_error_samples[MODEL_MAX_SAMPLES];
	u32 model_sample_count;
	u32 model_sample_head;
	s32 model_slope_q16;
	s32 model_intercept_q16;
	u32 model_mean_abs_residual;
	u32 model_dac_span;
	int model_predicted_dac;
	bool discipline_model_valid;
	bool discipline_model_jump_ready;
	bool discipline_model_jump_consumed;

	/* Servo readiness and diagnostics. */
	bool discipline_continuity_ready;
	bool discipline_gm_locked;
	bool discipline_reacquire_pending;
	u64 discipline_reacquire_cap64;
	bool discipline_reacquire_jump_pending;
	u32 discipline_lock_streak;
	unsigned long pps_diag_next_jiffies;
};


static struct fusion_gpt *gpt_singleton;
static DEFINE_MUTEX(gpt_singleton_lock);
static struct fusion_gpt *fusion_gpt_get_locked(void);
static void fusion_gpt_put_locked(struct fusion_gpt *g);
static void gpt_init_dac_baseline_locked(struct fusion_gpt *g);
static void gpt_reset_discipline_control_locked(struct fusion_gpt *g,
						bool preserve_dac,
						bool preserve_continuity_for_reacquire,
						bool last_pps_valid,
						u64 last_pps_cap64);
static void gpt_reset_discipline_model_locked(struct fusion_gpt *g);

static inline u32 rdl(struct fusion_gpt *g, u32 off) { return readl_relaxed(g->base + off); }
static inline void wrl(struct fusion_gpt *g, u32 v, u32 off) { writel_relaxed(v, g->base + off); }

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
	g->next_tick_phc_ns = 0;
	g->tick_phase = 0;
	g->pending_future_anchor = false;
	g->pending_future_phc_ns = 0;
	g->last_pps_jiffies = 0;
	g->pps_suppress_until_jiffies = 0;
}

static void gpt_init_dac_baseline_locked(struct fusion_gpt *g)
{
	g->dac_target = DAC_MID_VALUE;
	g->current_dac_value = DAC_INVALID_VALUE; /* force next DAC write */
}

static void gpt_reset_discipline_model_locked(struct fusion_gpt *g)
{
	g->model_sample_count = 0;
	g->model_sample_head = 0;
	g->model_slope_q16 = 0;
	g->model_intercept_q16 = 0;
	g->model_mean_abs_residual = 0;
	g->model_dac_span = 0;
	g->model_predicted_dac = DAC_INVALID_VALUE;
	g->discipline_model_valid = false;
	g->discipline_model_jump_ready = false;
	g->discipline_model_jump_consumed = false;
	g->discipline_reacquire_jump_pending = false;
}

static void gpt_reset_discipline_control_locked(struct fusion_gpt *g,
						bool preserve_dac,
						bool preserve_continuity_for_reacquire,
						bool last_pps_valid,
						u64 last_pps_cap64)
{
	int preserved_dac = (g->current_dac_value >= DAC_MIN_VALUE &&
			     g->current_dac_value <= DAC_MAX_VALUE) ?
		g->current_dac_value : clamp(g->dac_target, DAC_MIN_VALUE,
					       DAC_MAX_VALUE);
	bool reacquire_pending = g->discipline_reacquire_pending;
	bool keep_continuity = preserve_continuity_for_reacquire &&
		((READ_ONCE(g->discipline_continuity_ready) && last_pps_valid) ||
		 reacquire_pending);

	g->latest_freq_error = 0;
	g->error_integrator = 0;
	g->sq_err_sum = 0;
	g->err_count = 0;
	g->discipline_reacquire_pending = keep_continuity;
	g->discipline_reacquire_cap64 = keep_continuity ?
		(reacquire_pending ? g->discipline_reacquire_cap64 : last_pps_cap64) : 0;
	g->discipline_reacquire_jump_pending = keep_continuity;
	WRITE_ONCE(g->discipline_continuity_ready, keep_continuity);
	WRITE_ONCE(g->discipline_gm_locked, false);
	g->discipline_lock_streak = 0;
	g->pps_diag_next_jiffies = jiffies + HZ;
	g->discipline_model_jump_ready = false;
	g->discipline_model_jump_consumed = false;

	if (preserve_dac) {
		g->dac_target = preserved_dac;
		g->current_dac_value = DAC_INVALID_VALUE;
		g->baseline_restore_pending = true;
		g->baseline_restore_session_reset =
			!preserve_continuity_for_reacquire;
	} else {
		gpt_init_dac_baseline_locked(g);
		g->baseline_restore_pending = false;
		g->baseline_restore_session_reset = false;
	}
}

static struct fusion_gpt *fusion_gpt_get_locked(void)
{
	struct fusion_gpt *g;

	mutex_lock(&gpt_singleton_lock);
	g = gpt_singleton;
	if (!g || !get_device(g->dev))
		g = NULL;
	mutex_unlock(&gpt_singleton_lock);

	return g;
}

static void fusion_gpt_put_locked(struct fusion_gpt *g)
{
	if (g)
		put_device(g->dev);
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

static inline void gpt_fusion_cn_tick(struct fusion_gpt *g)
{
	unsigned long flags;
	bool ready;
	u64 tick_phc_ns = 0;
	u64 step_ns;
	u8 next_phase;
	const struct fusion_gpt_client_ops *ops;
	void *ops_ctx;

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	ready = READ_ONCE(g->discipline_continuity_ready) &&
		g->phc_epoch_valid && g->phc_aligned;
	if (ready) {
		tick_phc_ns = g->next_tick_phc_ns;
		next_phase = g->tick_phase + 1;
		if (next_phase == 3) {
			next_phase = 0;
			step_ns = 333334ULL;
		} else {
			step_ns = 333333ULL;
		}
		g->next_tick_phc_ns += step_ns;
		g->tick_phase = next_phase;
	}
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

	if (!ready)
		return;

	ops = READ_ONCE(g->ops);
	ops_ctx = READ_ONCE(g->ops_ctx);
	if (ops && ops->tick)
		ops->tick(ops_ctx, tick_phc_ns);
}

static void gpt_rephase_of1_from_pps_locked(struct fusion_gpt *g, u64 cap64)
{
	u32 cap32 = (u32)cap64;
	u32 next = cap32 + PERIOD_TICKS_BASE;

	if ((s32)(next - g->last32) <= 0)
		next = g->last32 + PERIOD_TICKS_BASE;

	g->frac = 0;
	g->next_ocr1 = next;
	wrl(g, g->next_ocr1, GPT_OCR1);
	g->phc_aligned = true;
	g->next_tick_phc_ns = g->phc_epoch_ns + 333333ULL;
	g->tick_phase = 1;
}

static void gpt_rebase_phc_epoch_locked(struct fusion_gpt *g, u64 cap64,
		bool had_prev, u64 prev_cap64)
{
	if (g->pending_future_anchor) {
		u64 prev_epoch_ns = g->phc_epoch_ns;
		u64 prev_epoch_cnt64 = g->pps_epoch_cnt64;

		g->phc_epoch_ns = g->pending_future_phc_ns;
		g->pps_epoch_cnt64 = cap64;
		g->phc_epoch_valid = true;
		g->phc_aligned = false;
		g->pending_future_anchor = false;
		pr_info("fusion_gpt: phc anchor latched epoch=%llu cnt=%llu\n",
				g->phc_epoch_ns, g->pps_epoch_cnt64);
		return;
	}

	if (!g->phc_epoch_valid || !had_prev)
		return;

	{
		u64 prev_epoch_ns = g->phc_epoch_ns;
		u64 prev_epoch_cnt64 = g->pps_epoch_cnt64;
		u64 delta_ticks = cap64 - prev_cap64;
		u64 intervals = (delta_ticks + (PPS_TICKS / 2)) / PPS_TICKS;
		s64 tick_error;

		if (intervals == 0)
			intervals = 1;

		tick_error = (s64)delta_ticks - ((s64)intervals * (s64)PPS_TICKS);
		g->phc_epoch_ns += intervals * 1000000000ULL;
		g->pps_epoch_cnt64 = cap64;

		pr_debug("fusion_gpt: rebase kind=pps prev_epoch=%llu prev_cnt=%llu cap=%llu delta_ticks=%llu intervals=%llu tick_err=%lld new_epoch=%llu new_cnt=%llu\n",
				prev_epoch_ns, prev_epoch_cnt64, cap64, delta_ticks, intervals,
				(long long)tick_error, g->phc_epoch_ns, g->pps_epoch_cnt64);
	}
}

/* exported client API */
int fusion_gpt_register_client(const struct fusion_gpt_client_ops *ops,
		void *ctx, struct module *owner)
{
	struct fusion_gpt *g;
	int ret = -ENODEV;

	if (!ops || !ops->tick || !owner)
		return -EINVAL;

	g = fusion_gpt_get_locked();
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
	fusion_gpt_put_locked(g);
	return ret;
}
EXPORT_SYMBOL(fusion_gpt_register_client);	/* non-GPL */

void fusion_gpt_unregister_client(void)
{
	struct fusion_gpt *g;
	struct module *owner = NULL;

	g = fusion_gpt_get_locked();
	if (!g)
		return;

	mutex_lock(&g->ops_lock);
	/* Make readers see NULL first */
	WRITE_ONCE(g->ops, NULL);
	smp_mb(); /* publish NULL before we flush */
	synchronize_irq(g->irq);
	owner = g->ops_owner;
	g->ops_ctx = NULL;
	g->ops_owner = NULL;
	mutex_unlock(&g->ops_lock);

	if (owner)
		module_put(owner);
	fusion_gpt_put_locked(g);
}
EXPORT_SYMBOL(fusion_gpt_unregister_client); /* non-GPL */

/*
 * Bind the *next* GPT ICR1 (1PPS) edge to the provided PHC time.
 * - Arms a pending anchor that will be consumed on the next ICR1 interrupt.
 * - Leaves the current local timeline running while a new anchor is pending.
 * - Forces a one-shot OF1 phase realign after the new epoch is established.
 */
int fusion_gpt_set_phc_anchor(u64 phc_ns_at_pps)
{
	struct fusion_gpt *g;
	unsigned long flags;

	g = fusion_gpt_get_locked();
	if (!g)
		return -ENODEV;

	raw_spin_lock_irqsave(&g->pps_lock, flags);

	if (phc_ns_at_pps == 0) {
		g->pending_future_anchor = false;
		g->pending_future_phc_ns = 0;
		pr_debug("fusion_gpt: phc anchor cleared\n");
		raw_spin_unlock_irqrestore(&g->pps_lock, flags);
		fusion_gpt_put_locked(g);
		return 0;
	}

	/* Touch shared PPS/epoch state from process context: IRQ-safe */
	g->pending_future_anchor = true;
	g->pending_future_phc_ns = phc_ns_at_pps;

	pr_debug("fusion_gpt: phc anchor armed %llu\n", phc_ns_at_pps);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	fusion_gpt_put_locked(g);
	return 0;
}
EXPORT_SYMBOL(fusion_gpt_set_phc_anchor);

int fusion_gpt_get_timing_status(struct fusion_gpt_timing_status *status)
{
	struct fusion_gpt *g;
	unsigned long flags;

	if (!status)
		return -EINVAL;

	g = fusion_gpt_get_locked();
	if (!g)
		return -ENODEV;

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	status->discipline_continuity_ready = READ_ONCE(g->discipline_continuity_ready);
	status->discipline_gm_locked = READ_ONCE(g->discipline_gm_locked);
	status->epoch_valid = g->phc_epoch_valid;
	status->aligned = g->phc_aligned;
	status->pps_seq = g->pps_seq;
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	fusion_gpt_put_locked(g);
	return 0;
}
EXPORT_SYMBOL(fusion_gpt_get_timing_status);

static int fusion_gpt_reset_timing_state_internal(bool preserve_ready_for_recheck,
						  bool simulate_pps_gap)
{
	struct fusion_gpt *g;
	unsigned long flags;
	u32 prev_pps_seq;
	long prev_freq_error;
	int baseline_dac;
	bool prev_epoch_valid, prev_aligned, prev_continuity, prev_gm_locked;
	bool prev_pending;
	bool prev_pps_valid;
	u64 prev_pps_cap64;
	unsigned long prev_last_pps_jiffies;
	bool changed;
	const char *reset_log_name;
	const char *reset_reason_name;
	unsigned long suppress_until = 0;
	g = fusion_gpt_get_locked();
	if (!g)
		return -ENODEV;

	reset_log_name = preserve_ready_for_recheck ?
		"timing reset" : "timing session reset";
	reset_reason_name = preserve_ready_for_recheck ?
		"timing_reset" : "timing_session_reset";

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	raw_spin_lock(&g->ctrl_lock);
	prev_pps_seq = g->pps_seq;
	prev_freq_error = g->latest_freq_error;
	prev_epoch_valid = g->phc_epoch_valid;
	prev_aligned = g->phc_aligned;
	prev_continuity = READ_ONCE(g->discipline_continuity_ready);
	prev_gm_locked = READ_ONCE(g->discipline_gm_locked);
	prev_pending = g->pending_future_anchor;
	prev_pps_valid = g->pps_valid;
	prev_pps_cap64 = g->pps_icr1_last64;
	prev_last_pps_jiffies = g->last_pps_jiffies;
	changed = g->pps_valid || g->if2_valid || g->phc_epoch_valid ||
		g->pending_future_anchor || g->pps_seq ||
		prev_continuity || prev_gm_locked || g->discipline_lock_streak ||
		g->latest_freq_error ||
		g->error_integrator;
	gpt_reset_timing_state_locked(g);
	if (simulate_pps_gap)
		suppress_until = jiffies +
			msecs_to_jiffies(READ_ONCE(timing_reset_sim_duration_ms_param));
	g->pps_suppress_until_jiffies = suppress_until;
	gpt_reset_discipline_control_locked(g, true, preserve_ready_for_recheck,
					    prev_pps_valid, prev_pps_cap64);
	if (READ_ONCE(g->discipline_continuity_ready) ||
	    g->discipline_reacquire_pending)
		g->last_pps_jiffies = prev_last_pps_jiffies;
	baseline_dac = clamp(g->dac_target, DAC_MIN_VALUE, DAC_MAX_VALUE);
	raw_spin_unlock(&g->ctrl_lock);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

	if (changed)
		pr_info("fusion_gpt: %s reason=api prev{pps_seq=%u epoch=%u aligned=%u continuity=%u gm_locked=%u pending=%u freq_err=%ld}\n",
			reset_log_name, prev_pps_seq, prev_epoch_valid, prev_aligned,
			prev_continuity, prev_gm_locked, prev_pending,
			prev_freq_error);
	pr_info("fusion_gpt: dac restore queued reason=%s dac=%d\n",
		reset_reason_name, baseline_dac);
	if (simulate_pps_gap)
		pr_info("fusion_gpt: simulating PPS gap for %u ms after %s\n",
			READ_ONCE(timing_reset_sim_duration_ms_param), reset_log_name);
	schedule_work(&g->dac_work);
	fusion_gpt_put_locked(g);
	return 0;
}

int fusion_gpt_reset_timing_state(void)
{
	return fusion_gpt_reset_timing_state_internal(true, false);
}
EXPORT_SYMBOL(fusion_gpt_reset_timing_state);

int fusion_gpt_reset_timing_session(void)
{
	return fusion_gpt_reset_timing_state_internal(false, false);
}
EXPORT_SYMBOL(fusion_gpt_reset_timing_session);

static int fusion_gpt_simulate_pps_gap_only(void)
{
	struct fusion_gpt *g;
	unsigned long flags;
	unsigned int duration_ms;

	g = fusion_gpt_get_locked();
	if (!g)
		return -ENODEV;

	duration_ms = READ_ONCE(timing_reset_sim_duration_ms_param);
	raw_spin_lock_irqsave(&g->pps_lock, flags);
	g->pps_suppress_until_jiffies = jiffies + msecs_to_jiffies(duration_ms);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

	pr_info("fusion_gpt: simulating PPS gap only for %u ms\n", duration_ms);
	fusion_gpt_put_locked(g);
	return 0;
}

u64 fusion_gpt_read_phc_ns(void)
{
	struct fusion_gpt *g;
	unsigned long flags;
	u64 now64, epoch_cnt64, epoch_ns, dt_ticks, ns = 0;
	bool valid;

	g = READ_ONCE(gpt_singleton);
	if (!g)
		return 0;

	/* Snapshot epoch under pps_lock */
	raw_spin_lock_irqsave(&g->pps_lock, flags);
	valid		= g->phc_epoch_valid;
	epoch_ns	= g->phc_epoch_ns;
	epoch_cnt64 = g->pps_epoch_cnt64;
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);
	if (!valid)
		return 0;

	/* Read current 64-bit counter safely */
	now64 = gpt_read_ticks64(g);

	/* Convert ticks to ns with 10 MHz = 100 ns/tick */
	dt_ticks = now64 - epoch_cnt64;
	ns = epoch_ns + dt_ticks * 100ULL;
	return ns;
}
EXPORT_SYMBOL(fusion_gpt_read_phc_ns);

static void gpt_program_next_compare(struct fusion_gpt *g)
{
	u32 inc = PERIOD_TICKS_BASE;
	if (++g->frac == 3) { inc += 1; g->frac = 0; }
	g->next_ocr1 += inc;

	if ((s32)(g->next_ocr1 - g->last32) <= 0) {
		u32 now = rdl(g, GPT_CNT);	   /* fresh */
		g->next_ocr1 = now + inc;	   /* rebase compare only */
	}
	wrl(g, g->next_ocr1, GPT_OCR1);
}

static void gpt_update_ticks64(struct fusion_gpt *g)
{
	write_seqcount_begin(&g->ticks_sl);
	{
		u32 cnt = rdl(g, GPT_CNT);

		if (cnt < g->last32)
			g->hi += 1ULL << 32;
		g->last32 = cnt;
	}
	write_seqcount_end(&g->ticks_sl);
}

static u64 gpt_extend_capture64(struct fusion_gpt *g, u32 cap, u64 now64)
{
	u64 cap64 = (now64 & ~0xffffffffULL) | cap;

	if (cap64 > now64)
		cap64 -= 1ULL << 32;

	return cap64;
}

static void gpt_handle_if2_capture(struct fusion_gpt *g)
{
	u32 cap = rdl(g, GPT_ICR2);
	u64 now64 = gpt_read_ticks64(g);
	u64 cap64 = gpt_extend_capture64(g, cap, now64);

	raw_spin_lock(&g->pps_lock);
	g->last_if2_cap64 = cap64;
	g->if2_valid = true;
	raw_spin_unlock(&g->pps_lock);
}

static bool gpt_handle_pps_capture(struct fusion_gpt *g, u64 *cap64_out,
				       u64 *prev_cap64_out, long *if2_offset_ns_out,
				       bool *rebase_ready_out)
{
	u32 cap = rdl(g, GPT_ICR1);
	u64 now64 = gpt_read_ticks64(g);
	u64 cap64 = gpt_extend_capture64(g, cap, now64);
	u64 prev_cap64 = 0;
	long if2_offset_ns = 0;
	bool had_prev;

	raw_spin_lock(&g->pps_lock);
	had_prev = g->pps_valid;
	prev_cap64 = g->pps_icr1_last64;
	if (had_prev && g->if2_valid) {
		if2_offset_ns = (long)(cap64 - g->last_if2_cap64) * 100L;
		if (if2_offset_ns < 0)
			if2_offset_ns += 20833;
	}
	g->pps_seq++;
	g->pps_icr1_last32 = cap;
	g->pps_icr1_last64 = cap64;
	g->pps_valid = true;
	g->last_pps_jiffies = jiffies;
	gpt_rebase_phc_epoch_locked(g, cap64, had_prev, prev_cap64);
	if (g->phc_epoch_valid)
		gpt_rephase_of1_from_pps_locked(g, cap64);
	*rebase_ready_out = g->phc_epoch_valid && !g->pending_future_anchor;
	raw_spin_unlock(&g->pps_lock);

	*cap64_out = cap64;
	*prev_cap64_out = prev_cap64;
	*if2_offset_ns_out = if2_offset_ns;
	return had_prev;
}

static long gpt_compute_freq_error(u64 cap64, u64 prev_cap64)
{
	return (long)(cap64 - prev_cap64) - (long)PPS_TICKS;
}

static bool gpt_is_valid_pps_interval(long freq_error)
{
	return abs(freq_error) <= READ_ONCE(max_valid_pps_error_param);
}

static void gpt_update_discipline_state_locked(struct fusion_gpt *g, u64 cap64,
					       bool have_freq_error,
					       bool valid_pps_interval,
					       long freq_error)
{
	u32 thresh = READ_ONCE(error_thresh_param);
	u32 needed = max_t(u32, 1, DISCIPLINE_LOCK_CONSECUTIVE);
	long abs_err;

	if (g->discipline_reacquire_pending) {
		long reacquire_error =
			gpt_compute_freq_error(cap64, g->discipline_reacquire_cap64);
		bool reacquire_valid_pps_interval =
			gpt_is_valid_pps_interval(reacquire_error);

		g->discipline_reacquire_pending = false;
		g->discipline_reacquire_cap64 = 0;
		abs_err = abs(reacquire_error);

		if (!reacquire_valid_pps_interval || abs_err >= thresh) {
			WRITE_ONCE(g->discipline_continuity_ready, false);
			WRITE_ONCE(g->discipline_gm_locked, false);
			g->discipline_reacquire_jump_pending = false;
			g->discipline_lock_streak = 0;
			pr_warn("fusion_gpt: discipline continuity lost on reacquire err=%ld thresh=%u valid=%u max_valid_err=%u\n",
				reacquire_error, thresh,
				reacquire_valid_pps_interval ? 1U : 0U,
				READ_ONCE(max_valid_pps_error_param));
			return;
		}

		WRITE_ONCE(g->discipline_gm_locked, false);
		g->discipline_lock_streak = 1;
		pr_info("fusion_gpt: discipline continuity preserved on reacquire err=%ld thresh=%u lock_streak=%u\n",
			reacquire_error, thresh, g->discipline_lock_streak);
		return;
	}

	if (!have_freq_error)
		return;

	if (!valid_pps_interval)
		return;

	abs_err = abs(freq_error);

	if (abs_err >= thresh) {
		g->discipline_lock_streak = 0;
		if (g->discipline_gm_locked)
			WRITE_ONCE(g->discipline_gm_locked, false);
		return;
	}

	if (g->discipline_lock_streak < needed)
		g->discipline_lock_streak++;

	if (!g->discipline_gm_locked && g->discipline_lock_streak >= needed) {
		WRITE_ONCE(g->discipline_continuity_ready, true);
		WRITE_ONCE(g->discipline_gm_locked, true);
		pr_info("fusion_gpt: discipline GM locked (|err| < %u ticks for %u PPS) dac=%d\n",
			thresh, needed, g->dac_target);
	}
}

static void gpt_pi_step_locked(struct fusion_gpt *g, long freq_error,
			       long *p_term_log, long *i_term_log,
			       long *integrator_log)
{
	u32 p_threshold = READ_ONCE(pi_p_threshold_param);
	u32 p_gain_q16 = READ_ONCE(pi_p_gain_q16_param);
	u32 i_gain_q16 = READ_ONCE(pi_i_gain_q16_param);
	long integrator_clamp = max_t(long, 1,
				      (long)READ_ONCE(pi_integrator_clamp_param));
	long p_term = 0;
	long i_term;
	int dac_after_p;
	bool hold_integrator = false;

	if (abs(freq_error) > p_threshold) {
		p_term = (long)(((s64)freq_error * (s64)p_gain_q16) >> 16);
		if (p_term == 0)
			p_term = (freq_error > 0) ? 1 : -1;
	}

	dac_after_p = g->dac_target - (int)p_term;

	/*
	 * Anti-windup: if the controller is already demanding a saturated DAC
	 * value, only integrate when the new error would pull the command back
	 * toward the usable range.
	 */
	if ((dac_after_p >= DAC_MAX_VALUE && freq_error < 0) ||
	    (dac_after_p <= DAC_MIN_VALUE && freq_error > 0))
		hold_integrator = true;

	if (!hold_integrator) {
		if (freq_error == 0) {
			if (g->error_integrator > 0)
				g->error_integrator--;
			else if (g->error_integrator < 0)
				g->error_integrator++;
		} else {
			g->error_integrator += freq_error;
		}

		g->error_integrator = clamp_t(long, g->error_integrator,
					      -integrator_clamp, integrator_clamp);
	}

	g->dac_target = dac_after_p;

	i_term = (long)(((s64)g->error_integrator * (s64)i_gain_q16) >> 16);
	if (i_term != 0)
		g->dac_target -= (int)i_term;

	if (g->dac_target > DAC_MAX_VALUE) {
		g->dac_target = DAC_MAX_VALUE;
		pr_debug("fusion_gpt: DAC saturated high (freq_err=%ld tick, integ=%ld)\n",
			 freq_error, g->error_integrator);
	} else if (g->dac_target < DAC_MIN_VALUE) {
		g->dac_target = DAC_MIN_VALUE;
		pr_debug("fusion_gpt: DAC saturated low (freq_err=%ld tick, integ=%ld)\n",
			 freq_error, g->error_integrator);
	}

	*p_term_log = -p_term;
	*i_term_log = -i_term;
	*integrator_log = g->error_integrator;
}

static u32 gpt_update_jitter_stats_locked(struct fusion_gpt *g, long freq_error)
{
	g->sq_err_sum += (s64)freq_error * (s64)freq_error;
	g->err_count++;

	if (!g->err_count)
		return 0;

	return int_sqrt(g->sq_err_sum / g->err_count);
}

static int gpt_get_observed_dac_locked(const struct fusion_gpt *g)
{
	if (g->current_dac_value >= DAC_MIN_VALUE &&
	    g->current_dac_value <= DAC_MAX_VALUE)
		return g->current_dac_value;

	return clamp(g->dac_target, DAC_MIN_VALUE, DAC_MAX_VALUE);
}

static void gpt_store_model_sample_locked(struct fusion_gpt *g, int observed_dac,
					  long freq_error)
{
	u32 idx = g->model_sample_head;

	g->model_dac_samples[idx] = observed_dac;
	g->model_error_samples[idx] = freq_error;
	g->model_sample_head = (idx + 1) % MODEL_MAX_SAMPLES;
	if (g->model_sample_count < MODEL_MAX_SAMPLES)
		g->model_sample_count++;
}

static bool gpt_fit_jump_model_locked(struct fusion_gpt *g)
{
	u32 window_size = clamp_t(u32, READ_ONCE(model_window_size_param), 2,
				  MODEL_MAX_SAMPLES);
	u32 min_samples = clamp_t(u32, READ_ONCE(model_min_samples_param), 2,
				  MODEL_MAX_SAMPLES);
	u32 max_mean_residual = READ_ONCE(model_max_mean_residual_param);
	u32 min_dac_span = READ_ONCE(model_min_dac_span_param);
	u32 sample_count = min(g->model_sample_count, window_size);
	s64 sum_x = 0;
	s64 sum_y = 0;
	s64 sum_xx = 0;
	s64 sum_xy = 0;
	s64 denom;
	s64 slope_q16;
	s64 intercept_q16;
	s64 residual_sum = 0;
	int min_dac = DAC_MAX_VALUE;
	int max_dac = DAC_MIN_VALUE;
	u32 i;

	g->discipline_model_valid = false;
	g->discipline_model_jump_ready = false;
	g->model_slope_q16 = 0;
	g->model_intercept_q16 = 0;
	g->model_mean_abs_residual = 0;
	g->model_dac_span = 0;
	g->model_predicted_dac = DAC_INVALID_VALUE;

	if (sample_count < min_samples || min_samples > window_size)
		return false;

	for (i = 0; i < sample_count; i++) {
		u32 idx = (g->model_sample_head + MODEL_MAX_SAMPLES - sample_count + i) %
			  MODEL_MAX_SAMPLES;
		s64 x = g->model_dac_samples[idx];
		s64 y = g->model_error_samples[idx];

		sum_x += x;
		sum_y += y;
		sum_xx += x * x;
		sum_xy += x * y;
		min_dac = min_t(int, min_dac, (int)x);
		max_dac = max_t(int, max_dac, (int)x);
	}

	g->model_dac_span = max_dac - min_dac;
	if (g->model_dac_span < min_dac_span)
		return false;

	denom = (s64)sample_count * sum_xx - sum_x * sum_x;
	if (denom <= 0)
		return false;

	slope_q16 = div_s64((((s64)sample_count * sum_xy) - (sum_x * sum_y)) << 16,
			    denom);
	if (slope_q16 <= 0)
		return false;

	intercept_q16 = div_s64((sum_y << 16) - slope_q16 * sum_x, sample_count);

	for (i = 0; i < sample_count; i++) {
		u32 idx = (g->model_sample_head + MODEL_MAX_SAMPLES - sample_count + i) %
			  MODEL_MAX_SAMPLES;
		s64 x = g->model_dac_samples[idx];
		s64 pred_q16 = slope_q16 * x + intercept_q16;
		s64 pred = pred_q16 >> 16;
		s64 err = (s64)g->model_error_samples[idx] - pred;

		residual_sum += (err < 0) ? -err : err;
	}

	g->model_mean_abs_residual = (u32)div_s64(residual_sum, sample_count);
	if (g->model_mean_abs_residual > max_mean_residual)
		return false;

	{
		s64 predicted_dac = div_s64(-intercept_q16, slope_q16);

		if (predicted_dac < DAC_MIN_VALUE || predicted_dac > DAC_MAX_VALUE)
			return false;

		g->model_slope_q16 = (s32)slope_q16;
		g->model_intercept_q16 = (s32)intercept_q16;
		g->model_predicted_dac = (int)predicted_dac;
		g->discipline_model_valid = true;
		return true;
	}
}

static bool gpt_maybe_apply_reacquire_model_jump_locked(struct fusion_gpt *g,
							int observed_dac,
							long freq_error)
{
	long abs_error = abs(freq_error);
	u32 jump_min_error = READ_ONCE(model_jump_min_error_param);

	if (!g->discipline_reacquire_jump_pending)
		return false;

	g->discipline_reacquire_jump_pending = false;
	if (!g->discipline_model_valid || g->discipline_model_jump_consumed ||
	    abs_error < jump_min_error)
		return false;

	g->discipline_model_jump_ready = true;
	g->discipline_model_jump_consumed = true;

	if (g->model_predicted_dac == g->dac_target) {
		g->discipline_model_jump_ready = false;
		return false;
	}

	g->dac_target = g->model_predicted_dac;
	g->error_integrator = 0;
	g->discipline_model_jump_ready = false;

	pr_info("fusion_gpt: discipline reacquire model jump applied dac=%d from=%d err=%ld slope_q16=%d residual=%u span=%u\n",
		g->dac_target, observed_dac, freq_error, g->model_slope_q16,
		g->model_mean_abs_residual, g->model_dac_span);

	return true;
}

static bool gpt_should_schedule_dac_work_locked(const struct fusion_gpt *g)
{
	return g->baseline_restore_pending ||
		(g->dac_target != g->current_dac_value);
}

static void gpt_maybe_reset_diag_window_locked(struct fusion_gpt *g)
{
	g->sq_err_sum = 0;
	g->err_count = 0;
	g->pps_diag_next_jiffies = jiffies + HZ;
}

static void gpt_maybe_expire_discipline_holdover(struct fusion_gpt *g)
{
	unsigned long flags;
	unsigned long last_pps;
	unsigned long gm_lock_timeout_jiffies;
	unsigned long timeout_jiffies;
	unsigned int timeout_ms = READ_ONCE(discipline_holdover_timeout_ms_param);
	unsigned int gm_lock_timeout_ms = DISCIPLINE_GM_LOCK_TIMEOUT_MS;
	unsigned int elapsed_ms = 0;
	bool expired = false;
	bool gm_lock_expired = false;

	gm_lock_timeout_jiffies = msecs_to_jiffies(gm_lock_timeout_ms);
	timeout_jiffies = timeout_ms ? msecs_to_jiffies(timeout_ms) : 0;

	raw_spin_lock_irqsave(&g->pps_lock, flags);
	raw_spin_lock(&g->ctrl_lock);

	last_pps = g->last_pps_jiffies;
	if (last_pps && READ_ONCE(g->discipline_gm_locked) &&
	    time_after_eq(jiffies, last_pps + gm_lock_timeout_jiffies)) {
		WRITE_ONCE(g->discipline_gm_locked, false);
		g->discipline_lock_streak = 0;
		gm_lock_expired = true;
	}
	if (last_pps &&
	    (READ_ONCE(g->discipline_continuity_ready) ||
	     g->discipline_reacquire_pending) &&
	    timeout_ms &&
	    time_after_eq(jiffies, last_pps + timeout_jiffies)) {
		WRITE_ONCE(g->discipline_continuity_ready, false);
		WRITE_ONCE(g->discipline_gm_locked, false);
		g->discipline_reacquire_pending = false;
		g->discipline_reacquire_cap64 = 0;
		g->discipline_reacquire_jump_pending = false;
		g->discipline_lock_streak = 0;
		elapsed_ms = jiffies_to_msecs(jiffies - last_pps);
		expired = true;
	}

	raw_spin_unlock(&g->ctrl_lock);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

	if (gm_lock_expired)
		pr_info("fusion_gpt: discipline GM lock expired after %u ms without PPS\n",
			gm_lock_timeout_ms);
	if (expired)
		pr_warn("fusion_gpt: discipline holdover expired after %u ms without PPS (timeout=%u ms)\n",
			elapsed_ms, timeout_ms);
}

static void gpt_handle_of1_compare(struct fusion_gpt *g)
{
	gpt_program_next_compare(g);
	gpt_maybe_expire_discipline_holdover(g);
	gpt_fusion_cn_tick(g);
}

static irqreturn_t gpt_irq(int irq, void *dev_id)
{
	struct fusion_gpt *g = dev_id;
	u32 sr = rdl(g, GPT_SR);
	u32 clr = 0;

	if (!sr)
		return IRQ_NONE;

	gpt_update_ticks64(g);

	if (!(sr & SR_OF1) && (s32)(g->next_ocr1 - g->last32) <= 0)
		gpt_program_next_compare(g);

	if (sr & SR_IF2) {
		gpt_handle_if2_capture(g);
		clr |= SR_IF2;
	}

	if (sr & SR_IF1) {
		unsigned long flags;
		bool suppress_pps;

		raw_spin_lock_irqsave(&g->pps_lock, flags);
		suppress_pps = time_before(jiffies, g->pps_suppress_until_jiffies);
		raw_spin_unlock_irqrestore(&g->pps_lock, flags);
		if (suppress_pps) {
			clr |= SR_IF1;
			goto if1_done;
		}

		u64 cap64 = 0;
		u64 prev_cap64 = 0;
		u64 diff = 0;
		u32 rms_jitter = 0;
		bool had_prev = false;
		bool valid_pps_interval = false;
		bool need_dac_work = false;
		bool do_pps_log = false;
		bool rebase_ready = false;
		long freq_error = 0;
		long if2_offset_ns = 0;
		long p_term_log = 0;
		long i_term_log = 0;
		long integrator_log = 0;
		bool model_jump_log = false;
		int observed_dac = DAC_INVALID_VALUE;
		bool model_valid_log = false;
		bool model_jump_consumed_log = false;
		bool continuity_ready_log = false;
		bool gm_locked_log = false;
		u32 model_mean_abs_residual_log = 0;
		u32 model_dac_span_log = 0;
		int model_predicted_dac_log = DAC_INVALID_VALUE;
		int dac_target = 0;

		had_prev = gpt_handle_pps_capture(g, &cap64, &prev_cap64,
						  &if2_offset_ns, &rebase_ready);
		if (had_prev || READ_ONCE(g->discipline_reacquire_pending)) {
			bool have_freq_error = had_prev;

			raw_spin_lock(&g->ctrl_lock);
			if (had_prev) {
				diff = cap64 - prev_cap64;
				freq_error = gpt_compute_freq_error(cap64, prev_cap64);
				valid_pps_interval = gpt_is_valid_pps_interval(freq_error);

				if (valid_pps_interval) {
					rms_jitter = gpt_update_jitter_stats_locked(g, freq_error);
					observed_dac = gpt_get_observed_dac_locked(g);
					model_jump_log = gpt_maybe_apply_reacquire_model_jump_locked(g,
									     observed_dac,
									     freq_error);
					if (!model_jump_log)
						gpt_pi_step_locked(g, freq_error, &p_term_log,
								   &i_term_log,
								   &integrator_log);
					gpt_store_model_sample_locked(g, observed_dac, freq_error);
					gpt_fit_jump_model_locked(g);
					integrator_log = g->error_integrator;
					g->latest_freq_error = freq_error;
					dac_target = g->dac_target;
					model_valid_log = g->discipline_model_valid;
					model_jump_consumed_log =
						g->discipline_model_jump_consumed;
					model_mean_abs_residual_log = g->model_mean_abs_residual;
					model_dac_span_log = g->model_dac_span;
					model_predicted_dac_log = g->model_predicted_dac;
					need_dac_work = gpt_should_schedule_dac_work_locked(g);
				}
			}
			gpt_update_discipline_state_locked(g, cap64, have_freq_error,
							   valid_pps_interval,
							   freq_error);
			continuity_ready_log = READ_ONCE(g->discipline_continuity_ready);
			gm_locked_log = READ_ONCE(g->discipline_gm_locked);
			if (had_prev) {
				do_pps_log = READ_ONCE(pps_debug_param);
				if (valid_pps_interval)
					gpt_maybe_reset_diag_window_locked(g);
			}
			raw_spin_unlock(&g->ctrl_lock);

			if (had_prev) {
				if (!valid_pps_interval)
					pr_warn_ratelimited("fusion_gpt: ignoring invalid PPS interval diff=%llu err=%ld max_valid_err=%u\n",
							    diff, freq_error,
							    READ_ONCE(max_valid_pps_error_param));
				if (do_pps_log)
					pr_info("fusion_gpt: [PPS] diff=%llu ticks err=%ld ticks rms=%u ticks 48k_off=%ldns valid=%u continuity=%u gm_locked=%u dac=%d obs_dac_applied=%d p=%ld i=%ld integ=%ld model_valid=%u jump_used=%u jump=%u pred_dac=%d resid=%u span_dac=%u rebase=%d\n",
						diff, freq_error, rms_jitter, if2_offset_ns,
						valid_pps_interval ? 1U : 0U,
						continuity_ready_log ? 1U : 0U,
						gm_locked_log ? 1U : 0U,
						dac_target, observed_dac, p_term_log, i_term_log,
						integrator_log, model_valid_log ? 1U : 0U,
						model_jump_consumed_log ? 1U : 0U,
						model_jump_log ? 1U : 0U, model_predicted_dac_log,
						model_mean_abs_residual_log, model_dac_span_log,
						rebase_ready);

				if (need_dac_work)
					schedule_work(&g->dac_work);
			}
		}

		clr |= SR_IF1;
	}
if1_done:

	if (sr & SR_OF1) {
		gpt_handle_of1_compare(g);
		clr |= SR_OF1;
	}

	if (clr)
		wrl(g, clr, GPT_SR);

	return IRQ_HANDLED;
}

static int fusion_write_dac(struct fusion_gpt *g, int target, bool ratelimited_log)
{
	int ret;
	u8 buf[6];

	target = clamp(target, DAC_MIN_VALUE, DAC_MAX_VALUE);

	buf[0] = 0x00; /* DAC0 MSB */
	buf[1] = 0x00;
	buf[2] = (u8)((target & 0xFF00) >> 8);
	buf[3] = 0x08; /* DAC1 LSB */
	buf[4] = 0x00;
	buf[5] = (u8)(target & 0xFF);

	if (!g->dac_client)
		return -ENODEV;

	ret = i2c_master_send(g->dac_client, buf, ARRAY_SIZE(buf));
	if (ret < 0)
		return ret;
	if (ret != ARRAY_SIZE(buf))
		return -EIO;

	if (ratelimited_log)
		pr_debug("fusion_gpt: updated DAC to %u\n", target);

	return 0;
}

static void fusion_dac_work_handler(struct work_struct *work)
{
	struct fusion_gpt *g = container_of(work, struct fusion_gpt, dac_work);
	unsigned long flags;
	int ret;
	int target;
	int current_dac;
	bool baseline_restore_pending;
	bool baseline_restore_session_reset;

	raw_spin_lock_irqsave(&g->ctrl_lock, flags);
	target = clamp(g->dac_target, DAC_MIN_VALUE, DAC_MAX_VALUE);
	current_dac = g->current_dac_value;
	baseline_restore_pending = g->baseline_restore_pending;
	baseline_restore_session_reset = g->baseline_restore_session_reset;
	raw_spin_unlock_irqrestore(&g->ctrl_lock, flags);

	if (target != current_dac) {
		ret = fusion_write_dac(g, target, true);
		if (ret == -ENODEV) {
			pr_debug("fusion_gpt: DAC client missing\n");
		} else if (ret < 0) {
			pr_debug("fusion_gpt: I2C DAC write failed: %d\n", ret);
			return;
		} else {
			raw_spin_lock_irqsave(&g->ctrl_lock, flags);
			g->current_dac_value = target;
			raw_spin_unlock_irqrestore(&g->ctrl_lock, flags);
			current_dac = target;
		}
	}

	if (baseline_restore_pending) {
		raw_spin_lock_irqsave(&g->ctrl_lock, flags);
		g->baseline_restore_pending = false;
		g->baseline_restore_session_reset = false;
		raw_spin_unlock_irqrestore(&g->ctrl_lock, flags);

		pr_info("fusion_gpt: dac restore applied reason=%s dac=%d applied_dac=%u\n",
			baseline_restore_session_reset ?
				"timing_session_reset" : "timing_reset",
			target, current_dac == target ? 1U : 0U);
	}
}
static int gpt_start(struct fusion_gpt *g)
{
	u32 cr;
	unsigned long flags;

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
	raw_spin_lock_init(&g->ctrl_lock);
	raw_spin_lock_irqsave(&g->pps_lock, flags);
	raw_spin_lock(&g->ctrl_lock);
	gpt_reset_timing_state_locked(g);
	gpt_reset_discipline_model_locked(g);
	gpt_reset_discipline_control_locked(g, false, false, false, 0);
	raw_spin_unlock(&g->ctrl_lock);
	raw_spin_unlock_irqrestore(&g->pps_lock, flags);

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

	g = devm_kzalloc(&pdev->dev, sizeof(*g), GFP_KERNEL);
	if (!g)
		return -ENOMEM;
	g->dev = &pdev->dev;

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

	/* DAC-based VCXO disciplining setup */
	g->baseline_restore_pending = false;
	gpt_init_dac_baseline_locked(g);
	INIT_WORK(&g->dac_work, fusion_dac_work_handler);

	/* Get the discipline I2C adapter (defer if not ready). */
	adapter = i2c_get_adapter(DEFAULT_DAC_I2C_BUS);
	if (!adapter) {
		dev_dbg(&pdev->dev, "I2C bus %u not ready, deferring probe\n",
				DEFAULT_DAC_I2C_BUS);
		ret = -EPROBE_DEFER;
		goto err_disable_clks;
	}

	/*
	 * Use a dummy client so the kernel does not try to bind a real
	 * MCP4725 driver when we only need raw I2C access for DAC writes.
	 */
	g->dac_client = i2c_new_dummy_device(adapter, DEFAULT_DAC_I2C_ADDR);
	if (IS_ERR(g->dac_client)) {
		ret = PTR_ERR(g->dac_client);
		g->dac_client = NULL;
		i2c_put_adapter(adapter);
		dev_err_probe(&pdev->dev, ret, "failed to create I2C client for DAC\n");
		goto err_disable_clks;
	}

	i2c_put_adapter(adapter);

	ret = gpt_start(g);
	if (ret)
		goto err_cleanup_i2c;

	/* publish after start */
	mutex_lock(&gpt_singleton_lock);
	gpt_singleton = g;
	mutex_unlock(&gpt_singleton_lock);

	dev_info(&pdev->dev,
			"GPT1 shim running (EXT 10MHz, 1/3ms compares)\n");
	return 0;

err_cleanup_i2c:
	cancel_work_sync(&g->dac_work);
	if (g->dac_client)
		i2c_unregister_device(g->dac_client);
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
	gpt_singleton = NULL;
	mutex_unlock(&gpt_singleton_lock);

	wrl(g, 0, GPT_IR);								 /* mask all */
	wrl(g, SR_OF1 | SR_IF1 | SR_IF2, GPT_SR);		 /* W1C clear any latched */
	wrl(g, cr & ~CR_EN, GPT_CR);					 /* stop */

	cancel_work_sync(&g->dac_work);

	/* Gate clocks */
	clk_disable_unprepare(g->clk_per);
	clk_disable_unprepare(g->clk_ipg);
	if (g->dac_client)
		i2c_unregister_device(g->dac_client);
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
MODULE_VERSION("1.0.1-linear-model");

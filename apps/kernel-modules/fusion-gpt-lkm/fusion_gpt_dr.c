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
#include <linux/irq_work.h>
#include <linux/spinlock.h>
#include <linux/math64.h>
#include <linux/seqlock.h>
#include <linux/clk.h>
#include <linux/rcupdate.h>
#include "fusion_gpt_client.h"

// VCXO Disiplining
#include <linux/workqueue.h>
#include <linux/i2c.h>
#include <linux/delay.h>

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

struct fusion_gpt
{
	void __iomem *base;
	int irq;

	u32 next_ocr1;
	u8  frac;

	struct irq_work tick_iw;

	u32 last32;
	u64 hi;
	seqlock_t ticks_sl;

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

  /* PI loop */
  long error_integrator;
  u64 sq_err_sum;
  u32 err_count;
  int dac_target;
};


static struct fusion_gpt *gpt_singleton;
static DEFINE_MUTEX(gpt_singleton_lock);

static inline u32 rdl(struct fusion_gpt *g, u32 off) { return readl_relaxed(g->base + off); }
static inline void wrl(struct fusion_gpt *g, u32 v, u32 off) { writel_relaxed(v, g->base + off); }

static inline u64 ceil_div_u64(u64 a, u64 b)
{
	return (a + b - 1) / b;
}

/* 64-bit tick synth (read-mostly) */
static u64 gpt_read_ticks64(struct fusion_gpt *g)
{
	unsigned seq; u32 lo; u64 hi;
	do {
		seq = read_seqbegin(&g->ticks_sl);
		hi = g->hi; lo = g->last32;
	} while (read_seqretry(&g->ticks_sl, seq));
	return (hi | lo);
}

static void gpt_tick_iw(struct irq_work *iw)
{
	struct fusion_gpt *g = container_of(iw, struct fusion_gpt, tick_iw);
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

	/* Ensure any queued work that might have captured a non-NULL ops is done */
	irq_work_sync(&g->tick_iw);

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
    int rc = -ENODEV;

    mutex_lock(&gpt_singleton_lock);
    g = gpt_singleton;
    mutex_unlock(&gpt_singleton_lock);
    if (!g)
        return -ENODEV;

    raw_spin_lock_irqsave(&g->pps_lock, flags);

    if (phc_ns_at_pps == 0) {
        g->pending_future_anchor = false;
        g->pending_future_phc_ns = 0;
        g->phc_epoch_ns = 0;
        g->pps_epoch_cnt64 = 0;
        g->phc_epoch_valid = false;
        g->phc_aligned = false;
        pr_debug("fusion_gpt: phc anchor cleared\n");
        rc = 0;
        raw_spin_unlock_irqrestore(&g->pps_lock, flags);
        return rc;
    }

    /* Touch shared PPS/epoch state from process context: IRQ-safe */
    g->pending_future_anchor = true;
    g->pending_future_phc_ns = phc_ns_at_pps;

    /* Ensure the OF1 handler performs the one-shot phase alignment */
    g->phc_aligned       = false;

    /* Epoch becomes valid at the next ICR1 edge (when we bind cap64 -> PHC) */
    g->phc_epoch_valid   = false;

    pr_debug("fusion_gpt: phc anchor armed %llu\n", phc_ns_at_pps);
    rc = 0;
    raw_spin_unlock_irqrestore(&g->pps_lock, flags);

    return rc;
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

static irqreturn_t gpt_irq(int irq, void *dev_id)
{
	struct fusion_gpt *g = dev_id;
	u32 sr = rdl(g, GPT_SR);
  u32 clr = 0;
  static DEFINE_RATELIMIT_STATE(_rs, HZ, 1);
	if (!sr) return IRQ_NONE;


		/* extend 64-bit ticks on any event */
	write_seqlock(&g->ticks_sl);
	{
		u32 cnt = rdl(g, GPT_CNT);
		if (cnt < g->last32) g->hi += 1ULL << 32;
		g->last32 = cnt;
	}
	write_sequnlock(&g->ticks_sl);

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
          
          /* Accumulate squared error for RMS jitter */
          g->sq_err_sum += (s64)freq_error * (s64)freq_error;
          g->err_count++;

          /* Accumulate error into the integrator */
          g->error_integrator += freq_error;

          /* Threshold in ticks for dithering */
          const int INTEGRATOR_LIMIT = 5; 

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
          // g->dac_request = g->dac_target; 
          if (g->dac_target > 255)
              g->dac_target = 255;
          else if (g->dac_target < 0)
              g->dac_target = 0;

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

          u32 rms_jitter = 0;
          if (g->err_count > 0) {
              rms_jitter = int_sqrt(g->sq_err_sum / g->err_count);
          }

          if (__ratelimit(&_rs)) {
              pr_alert("fusion_gpt: [PPS] diff=%llutick err=%ldtick rms=%utick | [48K] off=%ldns | DAC=%d\n",
                       diff, freq_error, rms_jitter, if2_offset_ns, g->dac_target);
              
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
			if (READ_ONCE(g->ops))
				irq_work_queue(&g->tick_iw);

			return IRQ_HANDLED;                         /* skip normal schedule this time */
		}

		/* Normal path once aligned (or if no epoch yet) */
		gpt_program_next_compare(g);
		clr |= SR_OF1;
		if (READ_ONCE(g->ops))
			irq_work_queue(&g->tick_iw);
	}

	if (clr) wrl(g, clr, GPT_SR);
	return IRQ_HANDLED;
}

static void fusion_dac_work_handler(struct work_struct *work)
{
    struct fusion_gpt *g = container_of(work, struct fusion_gpt, dac_work);
    int ret;
    u8 buf[3];

    int target = READ_ONCE(g->dac_target);

    target = clamp(target, 0, 255);

    if (target == g->current_dac_value) {
        return;
    }

    buf[0] = 0x00; /* Register/Command Byte (device specific) */
    buf[1] = 0x00; /* Often MSB or Control */
    buf[2] = (u8)(target & 0xFF); 

    if (g->dac_client) {
        ret = i2c_master_send(g->dac_client, buf, 3);
        
        if (ret < 0) {
            pr_err_ratelimited("fusion_gpt: I2C DAC write failed: %d\n", ret);
        } else {
            g->current_dac_value = target;
            
            pr_info_ratelimited("fusion_gpt: Updated DAC to %u (Integrator Move)\n", target);
        }
    } else {
        pr_info_ratelimited("fusion_gpt: DAC client missing\n");
    } 
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
	seqlock_init(&g->ticks_sl);

	raw_spin_lock_init(&g->pps_lock);
	g->pps_seq = 0;
	g->pps_icr1_last32 = 0;
	g->pps_icr1_last64 = 0;
	g->pps_valid = false;
	g->phc_epoch_ns = 0;
	g->pps_epoch_cnt64 = 0;
	g->phc_epoch_valid = false;
	g->phc_aligned = false;
	g->pending_future_anchor = false;
	g->pending_future_phc_ns = 0;

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
      I2C_BOARD_INFO("mcp4725", 0x62), // Use DAC's name or a dummy string
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
	init_irq_work(&g->tick_iw, gpt_tick_iw);
	mutex_init(&g->ops_lock);

	ret = devm_request_irq(&pdev->dev, g->irq, gpt_irq, IRQF_NO_THREAD,
			       dev_name(&pdev->dev), g);
	if (ret) goto err_disable_clks;

  /* DAC handler */
  g->dac_target = 128;
  adapter = i2c_get_adapter(0); /* Bus 0 */
  if (!adapter) {
    dev_dbg(&pdev->dev, "I2C bus not ready yet, deferring probe...\n");
    ret = -EPROBE_DEFER;
    goto err_disable_clks;
  }
  g->dac_client = i2c_new_client_device(adapter, &dac_info);
  i2c_put_adapter(adapter); // Release the adapter reference once client is made

  if (IS_ERR(g->dac_client)) {
    dev_err(&pdev->dev, "Failed to create I2C client for DAC\n");
    ret = PTR_ERR(g->dac_client);
    goto err_disable_clks;
  } else {
    INIT_WORK(&g->dac_work, fusion_dac_work_handler);
  }

	ret = gpt_start(g);
	if (ret) goto err_disable_clks;

	/* publish after start */
	mutex_lock(&gpt_singleton_lock);
	rcu_assign_pointer(gpt_singleton, g);
	mutex_unlock(&gpt_singleton_lock);

	dev_info(&pdev->dev,
		 "GPT1 shim running (EXT 10MHz, 1/3ms compares)\n");
  return 0;

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
MODULE_VERSION("1.0.1");

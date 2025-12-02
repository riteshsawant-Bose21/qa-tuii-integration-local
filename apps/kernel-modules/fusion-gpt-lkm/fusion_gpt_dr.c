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
#include "fusion_gpt_client.h"


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
#define CR_CLKSRC_EXT   (0x7 << CR_CLKSRC_SHIFT)
#define CR_FRR          BIT(9)

/* SR (status, W1C) and IR (enable) bits */
#define SR_OF1  BIT(0)
#define SR_IF1  BIT(3)
#define SR_IF2  BIT(4)
#define IR_OF1IE BIT(0)
#define IR_IF1IE BIT(3)
#define IR_IF2IE BIT(4)

/* 10 MHz -> 100 ns/tick; 1/3 ms = 333333.333 ns -> 3333,3333,3334 ticks */
#define PERIOD_TICKS_BASE 3333U

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
};

static struct fusion_gpt *gpt_singleton;
static DEFINE_MUTEX(gpt_singleton_lock);

static inline u32 rdl(struct fusion_gpt *g, u32 off) { return readl_relaxed(g->base + off); }
static inline void wrl(struct fusion_gpt *g, u32 v, u32 off) { writel_relaxed(v, g->base + off); }

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
    if (!g)
        return;

    mutex_lock(&g->ops_lock);
    if (g->ops_owner)
        module_put(g->ops_owner);
    g->ops = NULL;
    g->ops_ctx = NULL;
    g->ops_owner = NULL;
    mutex_unlock(&g->ops_lock);
}
EXPORT_SYMBOL(fusion_gpt_unregister_client); /* non-GPL */

static void gpt_program_next_compare(struct fusion_gpt *g)
{
    u32 inc = PERIOD_TICKS_BASE;
    if (++g->frac == 3) { inc += 1; g->frac = 0; }
    g->next_ocr1 += inc;
    wrl(g, g->next_ocr1, GPT_OCR1);
}

static irqreturn_t gpt_irq(int irq, void *dev_id)
{
    struct fusion_gpt *g = dev_id;
    u32 sr = rdl(g, GPT_SR);
    u32 clr = 0;

    if (!sr) return IRQ_NONE;

    /* extend 64-bit ticks on any event */
    write_seqlock(&g->ticks_sl);
    {
        u32 cnt = rdl(g, GPT_CNT);
        if (cnt < g->last32) g->hi += 1ULL << 32;
        g->last32 = cnt;
    }
    write_sequnlock(&g->ticks_sl);

    if (sr & SR_IF1) { (void)rdl(g, GPT_ICR1); clr |= SR_IF1; }
    if (sr & SR_IF2) { (void)rdl(g, GPT_ICR2); clr |= SR_IF2; }

    if (sr & SR_OF1) {
        gpt_program_next_compare(g);
        clr |= SR_OF1;
        if (READ_ONCE(g->ops))
            irq_work_queue(&g->tick_iw);
    }

    if (clr) wrl(g, clr, GPT_SR);
    return IRQ_HANDLED;
}

static int gpt_start(struct fusion_gpt *g)
{
    u32 cr;

    wrl(g, 0, GPT_CR);
    wrl(g, 0, GPT_PR);
    wrl(g, SR_OF1 | SR_IF1 | SR_IF2, GPT_SR);
    wrl(g, IR_OF1IE /* | IR_IF1IE | IR_IF2IE */, GPT_IR);

    cr = CR_ENMOD | CR_FRR | CR_CLKSRC_EXT | CR_DBGEN | CR_WAITEN;
    wrl(g, cr, GPT_CR);

    g->frac = 0;
    g->last32 = rdl(g, GPT_CNT);
    g->hi = 0;
    seqlock_init(&g->ticks_sl);

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

	init_irq_work(&g->tick_iw, gpt_tick_iw);
	mutex_init(&g->ops_lock);
	platform_set_drvdata(pdev, g);
	mutex_lock(&gpt_singleton_lock);
	gpt_singleton = g;
	mutex_unlock(&gpt_singleton_lock);

	ret = devm_request_irq(&pdev->dev, g->irq, gpt_irq, IRQF_NO_THREAD,
			       dev_name(&pdev->dev), g);
	if (ret)
		goto err_disable_clks;

	ret = gpt_start(g);
	if (ret)
		goto err_disable_clks;

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
	gpt_singleton = NULL;
	mutex_unlock(&gpt_singleton_lock);

	/* Stop timer */
	wrl(g, cr & ~CR_EN, GPT_CR);

	/* Gate clocks */
	clk_disable_unprepare(g->clk_per);
	clk_disable_unprepare(g->clk_ipg);
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
MODULE_DESCRIPTION("GPT1 shim exporting 1/3ms ticks");

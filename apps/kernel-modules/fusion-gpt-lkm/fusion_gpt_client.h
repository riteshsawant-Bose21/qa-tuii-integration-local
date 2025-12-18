/* SPDX-License-Identifier: GPL-2.0 */
#pragma once
#include <linux/types.h>
#include <linux/module.h>

/* Called once per GPT compare (1/3 ms). Softirq context (irq_work). */
struct fusion_gpt_client_ops {
    void (*tick)(void *ctx, u64 gpt_tick64);
};

int fusion_gpt_register_client(const struct fusion_gpt_client_ops *ops,
                               void *ctx, struct module *owner);
void fusion_gpt_unregister_client(void);
u64 fusion_gpt_read_ticks64(void);

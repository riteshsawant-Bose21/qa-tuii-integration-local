/* SPDX-License-Identifier: GPL-2.0 */
#pragma once
#include <linux/types.h>
#include <linux/module.h>

/* Called once per GPT compare (1/3 ms) with the grid-locked PHC time for that tick. Direct IRQ context. */
struct fusion_gpt_client_ops {
    void (*tick)(void *ctx, u64 tick_phc_ns);
};

struct fusion_gpt_timing_status {
	bool discipline_ready;
	bool epoch_valid;
	bool aligned;
	u32 pps_seq;
};

int fusion_gpt_register_client(const struct fusion_gpt_client_ops *ops,
                               void *ctx, struct module *owner);
void fusion_gpt_unregister_client(void);
int  fusion_gpt_set_phc_anchor(u64 phc_ns_at_pps);
int fusion_gpt_get_timing_status(struct fusion_gpt_timing_status *status);
int fusion_gpt_reset_timing_state(void);
u64  fusion_gpt_read_phc_ns(void);
u64  fusion_gpt_read_phc_ns_fast(void);

/*
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

#include <linux/module.h>
#include <linux/kernel.h>
#include "fusion_connect_manager.h"

static bool gpt = false; /* Default to hrtimer */
module_param(gpt, bool, 0444);
MODULE_PARM_DESC(gpt, "Use the GPT_CLK Compare interrupts to clock the driver (default: false to use hrtimer)");

static char *eth_iface = "lan4";
module_param(eth_iface, charp, 0444);
MODULE_PARM_DESC(eth_iface, "Ethernet interface for CONNECT traffic (default: lan4)");

static bool internal_loopback = false;
module_param(internal_loopback, bool, 0444);
MODULE_PARM_DESC(internal_loopback, "Turn on internal loopback (default: false)");

static bool debug = false;
module_param(debug, bool, 0444);
MODULE_PARM_DESC(internal_loopback, "Turn on debug printks (default: false)");

static struct fusion_cn_manager mgr;

static int __init fusion_cn_init(void)
{
  int ret;
  strscpy(mgr.netfilter.iface_name, eth_iface, IFNAMSIZ);
  mgr.rtp.internal_loopback = internal_loopback;
  mgr.ptp.ptp_timing_mode = gpt ? TIMING_GPT : TIMING_HRTIMER;
  mgr.debug = mgr.rtp.debug = debug;

  ret = fusion_cn_mgr_init(&mgr);
  if (ret) printk(KERN_ERR"fusion_cn: Module init failed: %d\n", ret);
  
  return ret;
}

static void __exit fusion_cn_exit(void)
{
  fusion_cn_mgr_destroy(&mgr);
}

module_init(fusion_cn_init);
module_exit(fusion_cn_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Nathan Mark");
MODULE_DESCRIPTION("Bose Professional Fusion CONNECT driver");
MODULE_VERSION("0.2");

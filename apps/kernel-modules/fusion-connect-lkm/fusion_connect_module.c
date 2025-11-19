#include <linux/module.h>
#include <linux/kernel.h>
#include "fusion_connect_manager.h"

static char *eth_iface = "lan3";
module_param(eth_iface, charp, 0444);
MODULE_PARM_DESC(eth_iface, "Ethernet interface for FusionConnect traffic (default: lan3)");

static bool debug = false;
module_param(debug, bool, 0444);
MODULE_PARM_DESC(debug, "Turn on debug printks (default: false)");

static struct fusion_cn_manager mgr;

static int __init fusion_cn_init(void)
{
  int ret;
  strscpy(mgr.netfilter.iface_name, eth_iface, IFNAMSIZ);
  mgr.ptp.ptp_timing_mode = TIMING_HRTIMER;
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

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Bose Professional");
MODULE_DESCRIPTION("Bose Professional Fusion CONNECT driver");
MODULE_VERSION("0.1");

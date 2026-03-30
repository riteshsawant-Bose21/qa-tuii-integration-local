#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/if.h>
#include "fusion_connect_manager.h"

#define FUSION_CN_DEFAULT_IFACE "lan1"

static char *eth_iface = FUSION_CN_DEFAULT_IFACE;
module_param_named(eth_iface, eth_iface, charp, 0444);
MODULE_PARM_DESC(eth_iface, "Network interface name used by Fusion Connect");

static bool debug = false;
module_param_named(debug, debug, bool, 0444);
MODULE_PARM_DESC(debug, "Enable Fusion Connect debug logging");

static struct fusion_cn_manager fusion_cn_mgr;

static int __init fusion_cn_init(void)
{
    int ret;

    strscpy(fusion_cn_mgr.netfilter.iface_name, eth_iface, IFNAMSIZ);
    fusion_cn_mgr.debug = debug;
    fusion_cn_mgr.rtp.debug = debug;

    ret = fusion_cn_mgr_init(&fusion_cn_mgr);
    if (ret)
        pr_err("fusion_cn: module init failed: %d\n", ret);

    return ret;
}

static void __exit fusion_cn_exit(void)
{
    fusion_cn_mgr_destroy(&fusion_cn_mgr);
}

module_init(fusion_cn_init);
module_exit(fusion_cn_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Bose Professional");
MODULE_DESCRIPTION("Bose Professional Fusion CONNECT driver");
MODULE_VERSION("0.1");

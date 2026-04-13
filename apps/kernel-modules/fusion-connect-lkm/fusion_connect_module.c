#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/if.h>
#include "fusion_connect_manager.h"

#define FUSION_CN_DEFAULT_IFACE "lan1"

static char *eth_iface = FUSION_CN_DEFAULT_IFACE;
module_param_named(eth_iface, eth_iface, charp, 0644);
MODULE_PARM_DESC(eth_iface, "Network interface name used by Fusion Connect");

static bool debug = false;
module_param_named(debug, debug, bool, 0644);
MODULE_PARM_DESC(debug, "Enable Fusion Connect debug logging");

static bool trace_debug = false;
module_param_named(trace_debug, trace_debug, bool, 0644);
MODULE_PARM_DESC(trace_debug, "Enable high-volume Fusion Connect trace logging");


static struct fusion_cn_manager fusion_cn_mgr;

void fusion_cn_refresh_runtime_params(struct fusion_cn_manager *mgr)
{
    bool debug_now;
    bool trace_now;

    if (!mgr)
        return;

    debug_now = READ_ONCE(debug);
    trace_now = READ_ONCE(trace_debug);

    strscpy(mgr->netfilter.iface_name, eth_iface, IFNAMSIZ);
    mgr->debug = debug_now;
    mgr->trace_debug = trace_now;
    mgr->rtp.debug = debug_now;
    mgr->rtp.trace_debug = trace_now;
    if (mgr->alsa.alsa_chip) {
        mgr->alsa.alsa_chip->debug = debug_now;
        mgr->alsa.alsa_chip->trace_debug = trace_now;
    }
}

static int __init fusion_cn_init(void)
{
    int ret;

    fusion_cn_refresh_runtime_params(&fusion_cn_mgr);

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

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/if.h>
#include "fusion_connect_manager.h"

#define FUSION_CN_DEFAULT_IFACE "lan1"

static int fusion_cn_probe(struct platform_device *pdev)
{
    struct fusion_cn_manager *mgr;
    int ret;

    mgr = devm_kzalloc(&pdev->dev, sizeof(*mgr), GFP_KERNEL);
    if (!mgr)
        return -ENOMEM;

    mgr->pdev = pdev;
    strscpy(mgr->netfilter.iface_name, FUSION_CN_DEFAULT_IFACE, IFNAMSIZ);
    mgr->debug = false;
    mgr->rtp.debug = false;

    ret = fusion_cn_mgr_init(mgr);
    if (ret) {
        dev_err(&pdev->dev, "fusion_cn init failed: %d\n", ret);
        return ret;
    }

    platform_set_drvdata(pdev, mgr);
    return 0;
}

static void fusion_cn_remove(struct platform_device *pdev)
{
    struct fusion_cn_manager *mgr = platform_get_drvdata(pdev);

    if (mgr)
        fusion_cn_mgr_destroy(mgr);
}

static const struct of_device_id fusion_cn_of_match[] = {
    { .compatible = "bosepro,fusion-connect" },
    { }
};
MODULE_DEVICE_TABLE(of, fusion_cn_of_match);

static struct platform_driver fusion_cn_driver = {
    .probe = fusion_cn_probe,
    .remove = fusion_cn_remove,
    .driver = {
        .name = "fusion-connect",
        .of_match_table = fusion_cn_of_match,
    },
};
module_platform_driver(fusion_cn_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Bose Professional");
MODULE_DESCRIPTION("Bose Professional Fusion CONNECT driver");
MODULE_VERSION("0.1");

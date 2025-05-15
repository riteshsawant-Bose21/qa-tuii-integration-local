/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright 2024 Bose Professional.
 */

#include <linux/module.h>
#include <linux/i2c.h>
#include <sound/soc.h>
#include <sound/control.h>
#include <sound/pcm_params.h>
#include <linux/of.h>

#define CODEC_DRIVER_NAME "fusion-codec"

#define MAX_IO_CARDS  4
#define MAX_TDM_SLOTS 8

struct fusion_codec_priv {
    u32 rxtx_pins;
    u32 tdm_slots;
    struct snd_soc_dai_driver dai_drv;
};

static int fusion_codec_hw_params(struct snd_pcm_substream *substream,
                                      struct snd_pcm_hw_params *params,
                                      struct snd_soc_dai *dai)
{
    pr_info("%s: hw_params - rate=%d, width=%d, channels=%d\n",
             CODEC_DRIVER_NAME, params_rate(params), 
             params_width(params), params_channels(params));
    return 0;
}

static const struct snd_soc_dai_ops fusion_codec_dai_ops = {
    .hw_params = fusion_codec_hw_params,
};

static int fusion_codec_soc_probe(struct snd_soc_component *component)
{
    return 0;
}

// Codec component driver
static const struct snd_soc_component_driver soc_component_dev_fusion_codec = {
    .probe            = fusion_codec_soc_probe,
    .dapm_widgets     = NULL,
    .num_dapm_widgets = 0,
    .dapm_routes      = NULL,
    .num_dapm_routes  = 0,
};

static int fusion_codec_probe(struct platform_device *pdev)
{
    struct fusion_codec_priv *priv;
    int ret;

    priv = devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);
    if (!priv)
        return -ENOMEM;

    /* Read 'tdm_slots' property from device tree */
    ret = of_property_read_u32(pdev->dev.of_node, "tdm_slots", &priv->tdm_slots);
    if (ret) {
        dev_err(&pdev->dev, "Failed to read 'tdm_slots' property\n");
        return ret;
    }

    /* Read 'rxtx_pins' property from device tree */
    ret = of_property_read_u32(pdev->dev.of_node, "rxtx_pins", &priv->rxtx_pins);
    if (ret) {
        dev_err(&pdev->dev, "Failed to read 'rxtx_pins' property\n");
        return ret;
    }

    /* Initialize the DAI driver structure */
    priv->dai_drv = (struct snd_soc_dai_driver) {
        .name = "fusion-codec",
        .playback = {
            .stream_name = "Fusion Playback",
            .channels_min = 1,
            .channels_max = priv->tdm_slots * priv->rxtx_pins,
            .rates = SNDRV_PCM_RATE_8000_192000,
            .formats = SNDRV_PCM_FMTBIT_S16_LE |
                       SNDRV_PCM_FMTBIT_S24_LE |
                       SNDRV_PCM_FMTBIT_S32_LE |
                       SNDRV_PCM_FMTBIT_S24_3LE,
        },
        .capture = {
            .stream_name = "Fusion Capture",
            .channels_min = 1,
            .channels_max = priv->tdm_slots * priv->rxtx_pins,
            .rates = SNDRV_PCM_RATE_8000_192000,
            .formats = SNDRV_PCM_FMTBIT_S16_LE |
                       SNDRV_PCM_FMTBIT_S24_LE |
                       SNDRV_PCM_FMTBIT_S32_LE |
                       SNDRV_PCM_FMTBIT_S24_3LE,
        },
        .ops = &fusion_codec_dai_ops,
    };

    /* Store the private data in the device's driver data */
    dev_set_drvdata(&pdev->dev, priv);

    ret = devm_snd_soc_register_component(&pdev->dev,
                                          &soc_component_dev_fusion_codec,
                                          &priv->dai_drv, 1);
    if (ret) {
        dev_err(&pdev->dev, "%s: Failed to register codec component: %d\n",
                CODEC_DRIVER_NAME, ret);
    } else {
        dev_info(&pdev->dev, "%s: Codec registered successfully\n",
                 CODEC_DRIVER_NAME);
    }

    return ret;
}



static const struct of_device_id fusion_codec_of_match[] = {
    { .compatible = "bosepro,fusion-codec", },
    { }
};
MODULE_DEVICE_TABLE(of, fusion_codec_of_match);

static struct platform_driver fusion_codec_driver = {
	.driver = {
			.name = "fusion-codec",
            .of_match_table = fusion_codec_of_match,
	},
	.probe = fusion_codec_probe,
};
module_platform_driver(fusion_codec_driver);

MODULE_AUTHOR("Nathan Mark");
MODULE_DESCRIPTION("Fusion Dummy Codec Driver");
MODULE_LICENSE("GPL");

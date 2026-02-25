/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright 2024 Bose Professional.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of_platform.h>
#include <sound/soc.h>
#include <linux/of.h>
#include <linux/clk.h>
#include <sound/pcm_params.h>
#include <sound/pcm.h>

#include <sound/soc/fsl/fsl_sai.h>

struct cpu_priv {
	u32 slots;
	u32 slot_width;
};

struct fusion_sound_card_priv {
    struct snd_soc_dai_link dai_link;
    struct cpu_priv cpu_priv;
    struct platform_device *pdev;
    struct snd_soc_card card;
    u32 sample_rate;
    snd_pcm_format_t sample_format;
    bool period_coalesce;
    bool period_coalesce_master_capture;
};

//static const struct snd_soc_dapm_widget fusion_sound_card_dapm_widgets[] = {
//    SND_SOC_DAPM_LINE("Fusion Playback", NULL), // Map to TX in codec
//    SND_SOC_DAPM_LINE("Fusion Capture", NULL),  // Map to RX in codec
//};

//static const struct snd_soc_dapm_route fusion_sound_card_dapm_routes[] = {
//    {"Fusion Playback", NULL, "TX"}, // Connect to TX in codec
//    {"RX", NULL, "Fusion Capture"}, // Connect to RX in codec
//};

static int fusion_sound_card_hw_params(struct snd_pcm_substream *substream,
                                       struct snd_pcm_hw_params *params)
{
    struct snd_soc_pcm_runtime *rtd = snd_soc_substream_to_rtd(substream);
    struct fusion_sound_card_priv *priv = snd_soc_card_get_drvdata(rtd->card);
    struct cpu_priv *cpu_priv = &priv->cpu_priv;
    struct device *dev = rtd->card->dev;
    int slots = cpu_priv->slots;
    int slot_width = cpu_priv->slot_width;
    int ret;

    unsigned int channels = params_channels(params);
    priv->sample_rate = params_rate(params);
    priv->sample_format = params_format(params);

    dev_dbg(dev, "Setting HW params:\n");
    dev_dbg(dev, "sample_rate = %d, sample_format = %d, channels = %d\n", 
             priv->sample_rate, priv->sample_format, channels);
    dev_dbg(dev, "slots = %d, slot_width = %d\n", slots, slot_width);

    ret = snd_soc_dai_set_fmt(snd_soc_rtd_to_cpu(rtd, 0), 
                              snd_soc_daifmt_clock_provider_flipped(rtd->dai_link->dai_fmt));
    if (ret) {
        dev_err(rtd->card->dev, "Failed to set SAI format: %d\n", ret);
        return ret;
    }

    ret = snd_soc_dai_set_sysclk(snd_soc_rtd_to_cpu(rtd, 0), 
                                 FSL_SAI_CLK_MAST1,
                                 24576000,
                                 SND_SOC_CLOCK_IN);
    if (ret && ret != -ENOTSUPP) {
        dev_err(dev, "failed to set sysclk for IO cards\n");
        return ret;
    }

    /* Set TDM slot configuration */
    ret = snd_soc_dai_set_tdm_slot(snd_soc_rtd_to_cpu(rtd, 0), 
                                   BIT(slots) - 1, BIT(slots) - 1, 
                                   slots, slot_width);
    if (ret && ret != -ENOTSUPP) {
        dev_err(dev, "Failed to set TDM slot: %d\n", ret);
        return ret;
    }

    return 0;
}

static int fusion_sound_card_hw_free(struct snd_pcm_substream *substream)
{
    
    return 0;
}

static int fusion_sound_card_startup(struct snd_pcm_substream *substream)
{
    
    return 0;
}

static int fusion_sound_card_prepare(struct snd_pcm_substream *substream)
{
    struct snd_soc_pcm_runtime *rtd = snd_soc_substream_to_rtd(substream);
    struct fusion_sound_card_priv *priv = snd_soc_card_get_drvdata(rtd->card);
    struct snd_pcm_runtime *runtime = substream->runtime;
    bool is_capture;
    bool is_master;

    if (!runtime)
        return 0;

    if (!priv->period_coalesce)
        return 0;

    is_capture = substream->stream == SNDRV_PCM_STREAM_CAPTURE;
    is_master = priv->period_coalesce_master_capture ? is_capture : !is_capture;
    runtime->no_period_wakeup = is_master ? 0 : 1;

    return 0;
}

static const struct snd_soc_ops fusion_sound_card_ops = {
    .hw_params = fusion_sound_card_hw_params,
    .hw_free = fusion_sound_card_hw_free,
    .startup = fusion_sound_card_startup,
    .prepare = fusion_sound_card_prepare,
};

SND_SOC_DAILINK_DEFS(analog,
	DAILINK_COMP_ARRAY(COMP_EMPTY()),
	DAILINK_COMP_ARRAY(COMP_EMPTY()),
	DAILINK_COMP_ARRAY(COMP_EMPTY()));
	
static struct snd_soc_dai_link fusion_sound_card_dai[] = {
	{
		.name = "analog",
		.stream_name = "analog-stream",
		.ops = &fusion_sound_card_ops,
		.ignore_pmdown_time = 1,
		SND_SOC_DAILINK_REG(analog),
	},
};

static int fusion_sound_card_probe(struct platform_device *pdev)
{
    struct fusion_sound_card_priv *priv;
    struct device_node *np = pdev->dev.of_node;
    struct device_node *cpu_node, *codec_node;
    struct device_node *cpu_np, *codec_np;
    struct platform_device *cpu_pdev;
    const char *format;
    const char *coalesce_master;
    int ret;
    u32 slots, slot_width;

    priv = devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);
    if (!priv) {
        dev_err(&pdev->dev, "Failed to allocate memory for private data.\n");
        return -ENOMEM;
    }
    
    memcpy(&priv->dai_link, &fusion_sound_card_dai, sizeof(struct snd_soc_dai_link));

    /* Default sample rate and format, will be updated in hw_params() */
	priv->sample_rate = 48000;
	priv->sample_format = SNDRV_PCM_FORMAT_S24_LE;

    priv->pdev = pdev;
    priv->card.dev = &pdev->dev;
    priv->card.name = "FusionSoundCard";
    priv->card.owner = THIS_MODULE;
    priv->card.dai_link = &priv->dai_link;
    priv->card.num_links = 1;
    
    //priv->card.dapm_routes = fusion_sound_card_dapm_routes;
    //priv->card.num_dapm_routes = ARRAY_SIZE(fusion_sound_card_dapm_routes);
    //priv->card.dapm_widgets = fusion_sound_card_dapm_widgets;
	//priv->card.num_dapm_widgets = ARRAY_SIZE(fusion_sound_card_dapm_widgets);
	
	priv->card.dapm_routes = NULL;
    priv->card.num_dapm_routes = 0;
    priv->card.dapm_widgets = NULL;
	priv->card.num_dapm_widgets = 0;
    
    if (!of_property_read_u32(np, "slots", &slots)) {
        priv->cpu_priv.slots = slots;
    } else {
        dev_err(&pdev->dev, "Failed to read slots property.\n");
    }

    if (!of_property_read_u32(np, "slot-width", &slot_width)) {
        priv->cpu_priv.slot_width = slot_width;
    } else {
        dev_err(&pdev->dev, "Failed to read slot-width property.\n");
    }

    priv->period_coalesce = of_property_read_bool(np, "bose,coalesce-period-elapsed");
    priv->period_coalesce_master_capture = true;
    if (priv->period_coalesce) {
        ret = of_property_read_string(np, "bose,coalesce-master", &coalesce_master);
        if (ret || !strcmp(coalesce_master, "capture")) {
            priv->period_coalesce_master_capture = true;
        } else if (!strcmp(coalesce_master, "playback")) {
            priv->period_coalesce_master_capture = false;
        } else {
            dev_warn(&pdev->dev,
                     "Invalid bose,coalesce-master='%s', defaulting to capture\n",
                     coalesce_master);
            priv->period_coalesce_master_capture = true;
        }
    }

    cpu_node = of_get_child_by_name(np, "cpu");
    codec_node = of_get_child_by_name(np, "codec");

    if (!cpu_node || !codec_node) {
        dev_err(&pdev->dev, "Failed to get CPU or Codec node for IO Cards\n");
        ret = -EINVAL;
        goto error;
    }

    // Parse the 'sound-dai' property with arguments
    cpu_np = of_parse_phandle(cpu_node, "sound-dai", 0);
    codec_np = of_parse_phandle(codec_node, "sound-dai", 0);

    if (!cpu_np || !codec_np) {
        dev_err(&pdev->dev, "Failed to get CPU or Codec DAI node for IO Cards\n");
        ret = -EINVAL;
        goto error;
    }

    cpu_pdev = of_find_device_by_node(cpu_np);
    if (!cpu_pdev) {
        dev_err(&pdev->dev, "Failed to find CPU DAI device\n");
        ret = -EINVAL;
        goto error;
    }
    
    if (of_property_read_string(np, "format", &format)) {
        dev_warn(&pdev->dev, "Missing 'format' property, using default 'left_j'.\n");
        priv->dai_link.dai_fmt = SND_SOC_DAIFMT_LEFT_J;
    } else {
        if (!strcmp(format, "left_j"))
            priv->dai_link.dai_fmt = SND_SOC_DAIFMT_LEFT_J;
        else {
            dev_warn(&pdev->dev, "Unsupported format '%s', using 'left_j'.\n", format);
            priv->dai_link.dai_fmt = SND_SOC_DAIFMT_LEFT_J;
        }
    }
    
    priv->dai_link.dai_fmt |= SND_SOC_DAIFMT_CBP_CFP | SND_SOC_DAIFMT_IB_NF;
    
    priv->dai_link.cpus->of_node = cpu_np;
    priv->dai_link.codecs->of_node = codec_np;
    priv->dai_link.codecs->dai_name = "fusion-codec";
    priv->dai_link.platforms->of_node = cpu_np;
    priv->dai_link.num_cpus = 1;
    priv->dai_link.num_codecs = 1;
    priv->dai_link.num_platforms = 1;

    platform_set_drvdata(pdev, priv);
    snd_soc_card_set_drvdata(&priv->card, priv);

    ret = devm_snd_soc_register_card(&pdev->dev, &priv->card);
    if (ret) {
        dev_err_probe(&pdev->dev, ret, "snd_soc_register_card failed\n");
        goto error;
    }

    dev_info(&pdev->dev, "Fusion sound card registered successfully.\n");
    return 0;

error:
    // Cleanup any allocated resources
    of_node_put(cpu_node);
    of_node_put(codec_node);
    of_node_put(cpu_np);
    of_node_put(codec_np);
    put_device(&cpu_pdev->dev);
    return ret;
}

static void fusion_sound_card_remove(struct platform_device *pdev)
{
    // auto unregister because of devm?
    dev_info(&pdev->dev, "Removing fusion sound card.\n");
}

static const struct of_device_id fusion_sound_card_of_match[] = {
    { .compatible = "bosepro,fusion-sound-card", },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, fusion_sound_card_of_match);

static struct platform_driver fusion_sound_card_driver = {
    .driver = {
        .name = "fusion-sound-card",
        .of_match_table = fusion_sound_card_of_match,
    },
    .probe = fusion_sound_card_probe,
    .remove = fusion_sound_card_remove,
};
module_platform_driver(fusion_sound_card_driver);

MODULE_AUTHOR("Nathan Mark");
MODULE_DESCRIPTION("Fusion Audio ALSA Driver");
MODULE_LICENSE("GPL");



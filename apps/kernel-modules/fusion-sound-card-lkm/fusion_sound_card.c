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

#include <sound/soc/fsl/fsl_sai.h>

#define rx 0
#define tx 1

struct cpu_priv {
	unsigned long sysclk_freq[2];
	u32 sysclk_dir[2];
	u32 sysclk_id[2];
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

    dev_info(dev, "Setting HW params for IO Cards\n");
    dev_info(dev, "sample_rate = %d, sample_format = %d, channels = %d\n", 
             priv->sample_rate, priv->sample_format, channels);
    dev_info(dev, "slots = %d, slot_width = %d\n", slots, slot_width);

    /* Configure sysclk separately for each IO card */
    ret = snd_soc_dai_set_sysclk(snd_soc_rtd_to_cpu(rtd, 0), 
                                 cpu_priv->sysclk_id[tx],
                                 cpu_priv->sysclk_freq[tx],
                                 cpu_priv->sysclk_dir[tx]);
    if (ret && ret != -ENOTSUPP) {
        dev_err(dev, "failed to set sysclk for IO cards\n");
        return ret;
    }

    /* Set TDM slot configuration */
    ret = snd_soc_dai_set_tdm_slot(snd_soc_rtd_to_cpu(rtd, 0), 
                                   BIT(slots) - 1, BIT(slots) - 1, 
                                   slots, slot_width);
    if (ret && ret != -ENOTSUPP) {
        dev_err(dev, "Failed to set TDM slot for IO cards: %d\n", ret);
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

static const struct snd_soc_ops fusion_sound_card_ops = {
    .hw_params = fusion_sound_card_hw_params,
    .hw_free = fusion_sound_card_hw_free,
    .startup = fusion_sound_card_startup,
};

SND_SOC_DAILINK_DEFS(iocards,
	DAILINK_COMP_ARRAY(COMP_EMPTY()),
	DAILINK_COMP_ARRAY(COMP_EMPTY()),
	DAILINK_COMP_ARRAY(COMP_EMPTY()));
	
static struct snd_soc_dai_link fusion_sound_card_dai[] = {
	{
		.name = "iocards",
		.stream_name = "iocards-stream",
		.ops = &fusion_sound_card_ops,
		.ignore_pmdown_time = 1,
		SND_SOC_DAILINK_REG(iocards),
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
    struct clk *sai_clk;
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

	priv->cpu_priv.sysclk_dir[tx] = SND_SOC_CLOCK_IN;
	priv->cpu_priv.sysclk_dir[rx] = SND_SOC_CLOCK_IN;
    priv->cpu_priv.sysclk_id[tx] = FSL_SAI_CLK_MAST1;
    priv->cpu_priv.sysclk_id[rx] = FSL_SAI_CLK_MAST1;
    
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

    sai_clk = clk_get(&cpu_pdev->dev, "mclk1");
    if (IS_ERR(sai_clk)) {
        dev_err(&pdev->dev, "Failed to get sai_clk: %ld\n", PTR_ERR(sai_clk));
        ret = PTR_ERR(sai_clk);
        goto error;
    }

    priv->cpu_priv.sysclk_freq[tx] = clk_get_rate(sai_clk);
    priv->cpu_priv.sysclk_freq[rx] = clk_get_rate(sai_clk);
    clk_put(sai_clk);
    
    if (of_property_read_string(np, "format", &format)) {
        dev_warn(&pdev->dev, "IO Cards: Missing 'format' property, using default 'i2s'.\n");
        priv->dai_link.dai_fmt = SND_SOC_DAIFMT_I2S;
    } else {
        if (!strcmp(format, "i2s"))
            priv->dai_link.dai_fmt = SND_SOC_DAIFMT_I2S;
        else {
            dev_warn(&pdev->dev, "IO Cards: Unsupported format '%s', using 'i2s'.\n", format);
            priv->dai_link.dai_fmt = SND_SOC_DAIFMT_I2S;
        }
    }
    
    priv->dai_link.dai_fmt |= SND_SOC_DAIFMT_CBP_CFP | SND_SOC_DAIFMT_NB_NF;
    
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



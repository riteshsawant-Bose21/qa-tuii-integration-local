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

#include <linux/platform_device.h>
#include <linux/slab.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>
#include <sound/memalloc.h>
#include "fusion_connect_alsa.h"

static struct platform_device *g_pdev;

static const unsigned int supported_rates[] = { 44100, 48000, 96000 };
static const struct snd_pcm_hw_constraint_list constraints_rates = {
    .count = ARRAY_SIZE(supported_rates),
    .list = supported_rates,
};

static const unsigned int supported_period_sizes[] = { 6, 12, 16, 48, 192 };
static const struct snd_pcm_hw_constraint_list constraints_period_sizes = {
    .count = ARRAY_SIZE(supported_period_sizes),
    .list = supported_period_sizes,
};

static inline unsigned int hash_name(const char *name)
{
    unsigned long hash = init_name_hash(0);
    while (*name) {
        hash = partial_name_hash(*name++, hash);
    }
    return hash % (1 << FUSION_CN_ALSA_HASH_BITS);
}

struct fusion_cn_substream *fusion_cn_find_substream(const char *stream_name)
{
    struct fusion_cn_chip *chip = platform_get_drvdata(g_pdev);
    struct fusion_cn_substream *stream;
    unsigned int bucket = hash_name(stream_name);

    hlist_for_each_entry(stream, &chip->streams[bucket], hnode) {
        if (strcmp(stream->stream_name, stream_name) == 0) {
            kref_get(&stream->ref);
            return stream;
        }
    }
    return NULL;
}

inline bool fusion_cn_alsa_stream_disconnected(struct fusion_cn_substream *s)
{
    return atomic_read(&s->disconnected) != 0;
}

static int fusion_cn_pcm_hw_params(struct snd_pcm_substream *substream, struct snd_pcm_hw_params *params)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned int rate = params_rate(params);
    snd_pcm_format_t format = params_format(params);
    unsigned int channels = params_channels(params);
    unsigned int period_size = params_period_size(params);
    unsigned int buffer_bytes = params_buffer_bytes(params);
    int err;

    if (fusion_cn_alsa_stream_disconnected(stream)) return -ENODEV;

    spin_lock_irq(&stream->lock);
    if (stream->rate != rate || stream->format != format || stream->channels != channels) {
        printk(KERN_ERR "fusion_cn_alsa: hw_params: Mismatch for stream %s: rate %u/%u, format %d/%d, channels %u/%u\n",
               stream->stream_name, rate, stream->rate, format, stream->format, channels, stream->channels);
        spin_unlock_irq(&stream->lock);
        return -EINVAL;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &constraints_rates);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: hw_params: Rate constraint failed for stream %s, err=%d\n",
               stream->stream_name, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &constraints_period_sizes);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: hw_params: Period size constraint failed for stream %s, err=%d\n",
               stream->stream_name, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }
    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: hw_params: Periods constraint failed for stream %s, err=%d\n",
               stream->stream_name, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }

    runtime->buffer_size = buffer_bytes / (stream->sample_width * stream->channels);
    runtime->period_size = period_size;
    runtime->periods = buffer_bytes / (period_size * stream->sample_width * stream->channels);

    printk(KERN_INFO "fusion_cn_alsa: hw_params: buffer_size=%lu frames, period_size=%lu, periods=%u for stream %s\n",
           runtime->buffer_size, runtime->period_size, runtime->periods, stream->stream_name);

    stream->pcm_indirect.hw_buffer_size = buffer_bytes;
    stream->pcm_indirect.sw_buffer_size = buffer_bytes;
    atomic_set(&stream->dma_offset, 0);

    spin_unlock_irq(&stream->lock);
    return 0;
}

void fusion_cn_alsa_substream_release(struct kref *kref)
{
    struct fusion_cn_substream *s =
        container_of(kref, struct fusion_cn_substream, ref);

    /* Free PCM only if it’s not open and not attached to a live substream */
    if (s->pcm && atomic_read(&s->open_count) == 0 && !s->substream) {
        struct snd_card *card = s->pcm->card;
        struct snd_pcm  *pcm  = s->pcm;
        s->pcm = NULL;
        snd_device_free(card, pcm);  /* non-GPL */
    }

    printk(KERN_INFO "fusion_cn_alsa: substream_release: release stream %s\n", s->stream_name);

    kfree(s);
}

int fusion_cn_alsa_pcm_interrupt(struct fusion_cn_chip *alsa_chip, struct fusion_cn_substream *stream)
{
    struct fusion_cn_chip *chip = alsa_chip;
    struct snd_pcm_substream *ss;
    struct snd_pcm_runtime *rt;

    if (fusion_cn_alsa_stream_disconnected(stream))
        return 0;

    spin_lock_irq(&stream->lock);
    ss = READ_ONCE(stream->substream);
    if (!ss) {
        spin_unlock_irq(&stream->lock);
        return 0;
    }
    rt = ss->runtime;

    stream->buffer_pos += stream->rtp_frame_size;
    if (stream->buffer_pos >= rt->buffer_size)
        stream->buffer_pos -= rt->buffer_size;

    if (chip->debug) printk(KERN_DEBUG "fusion_cn_alsa: pcm_interrupt: stream %s, buffer_pos=%d\n", stream->stream_name, stream->buffer_pos);

    stream->interrupt_idx++;
    if (stream->interrupt_idx >= stream->interrupts_per_period) {
        stream->interrupt_idx = 0;
        snd_pcm_period_elapsed(stream->substream);
    }

    spin_unlock_irq(&stream->lock);

    return 0;
}

static int fusion_cn_pcm_copy(struct snd_pcm_substream *substream,
                              int channel, unsigned long pos,
                              struct iov_iter *iter, unsigned long bytes)
{
    struct snd_pcm_runtime *rt = substream->runtime;
    void *dst = rt->dma_area + pos;

    if (fusion_cn_alsa_stream_disconnected(rt->private_data)) return -ENODEV;

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        size_t copied = copy_from_iter(dst, bytes, iter);
        if (copied != bytes) {
            return -EFAULT;
        }
    } else {
        size_t copied = copy_to_iter(dst, bytes, iter);
        if (copied != bytes) {
            return -EFAULT;
        }
    }
    return 0;
}

static int fusion_cn_pcm_silence(struct snd_pcm_substream *substream,
                                int channel, snd_pcm_uframes_t pos,
                                snd_pcm_uframes_t count)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    size_t buffer_size_per_channel = runtime->buffer_size * stream->sample_width;
    const unsigned char *silence = snd_pcm_format_silence_64(runtime->format);
    unsigned char *dma_area = runtime->dma_area;

    if (fusion_cn_alsa_stream_disconnected(runtime->private_data)) return -ENODEV;

    if (substream->stream != SNDRV_PCM_STREAM_PLAYBACK) return 0;

    if (pos + count > runtime->buffer_size) {
        count = runtime->buffer_size - pos;
    }
    if (count == 0) return 0;

    spin_lock_irq(&stream->lock);

    if (channel == -1) {
        for (int ch = 0; ch < stream->channels; ch++) {
            unsigned char *channel_buf = dma_area + ch * buffer_size_per_channel + pos * stream->sample_width;
            for (snd_pcm_uframes_t i = 0; i < count; i++) {
                memcpy(channel_buf + i * stream->sample_width, silence, stream->sample_width);
            }
        }
    } else {
        unsigned char *channel_buf = dma_area + channel * buffer_size_per_channel + pos * stream->sample_width;
        if (channel >= stream->channels) {
            spin_unlock_irq(&stream->lock);
            return -EINVAL;
        }
        for (snd_pcm_uframes_t i = 0; i < count; i++) {
            memcpy(channel_buf + i * stream->sample_width, silence, stream->sample_width);
        }
    }

    spin_unlock_irq(&stream->lock);
    return (int)count;
}

static int fusion_cn_pcm_fill_silence(struct snd_pcm_substream *substream,
                                     int channel, unsigned long pos,
                                     unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    return fusion_cn_pcm_silence(substream, channel, pos / bytes_per_frame, frames);
}

/* Called when you want the device to disappear */
int fusion_cn_alsa_remove_substream(struct fusion_cn_substream *stream)
{
    struct fusion_cn_chip *chip;
    unsigned long flags;

    if (!stream)
        return -EINVAL;

    chip = platform_get_drvdata(g_pdev);

    // Mark disconnected and force ALSA state change if still open
    spin_lock_irqsave(&stream->lock, flags);
    if (stream->substream) {
        atomic_set(&stream->disconnected, 1);
        // Force wake of any blocking I/O on this substream
        snd_pcm_stop(stream->substream, SNDRV_PCM_STATE_DISCONNECTED);
        /* DO NOT clear stream->substream here; ALSA still owns it until close */
    }
    spin_unlock_irqrestore(&stream->lock, flags);

    // unlink from hash and free device index
    if (chip) {
        write_lock_irqsave(&chip->lock, flags);
        if (!hlist_unhashed(&stream->hnode))
            hlist_del_init(&stream->hnode);
        clear_bit(stream->stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
    }

    // If not open anymore, unregister now; otherwise defer
    if (atomic_read(&stream->open_count) == 0 && !stream->substream) {
        if (stream->pcm) {
            struct snd_card *card = stream->pcm->card;
            struct snd_pcm  *pcm  = stream->pcm;
            stream->pcm = NULL;
            snd_device_free(card, pcm);
        }
    } else {
        stream->pending_free = true;
    }

    // remove ref taken in add_substream
    kref_put(&stream->ref, fusion_cn_alsa_substream_release);

    pr_info("fusion_cn_alsa: remove_substream: Stream %s removed, device=%d%s\n",
            stream->stream_name, stream->stream_index,
            stream->pending_free ? " (pending free)" : "");
    return 0;
}

static int fusion_cn_pcm_open(struct snd_pcm_substream *substream)
{
    struct fusion_cn_chip *chip = snd_pcm_substream_chip(substream);
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long flags;
    char stream_name[FUSION_CN_NAME_MAX];
    struct fusion_cn_substream *stream;
    struct snd_pcm_hardware hw;
    int err;

    strscpy(stream_name, substream->pcm->name, sizeof(stream_name));

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(stream_name);
    if (!stream) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_WARNING "fusion_cn_alsa: pcm_open: Stream %s not found\n", stream_name);
        return -ENOENT;
    }

    if (stream->substream) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_WARNING "fusion_cn_alsa: pcm_open: Stream %s already open\n", stream_name);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        return -EBUSY;
    }

    stream->substream = substream;

    hw.info = SNDRV_PCM_INFO_INTERLEAVED |
              SNDRV_PCM_INFO_BLOCK_TRANSFER;
    switch (stream->format) {
    case SNDRV_PCM_FORMAT_S16_BE:
        hw.formats = SNDRV_PCM_FMTBIT_S16_BE;
        break;
    case SNDRV_PCM_FORMAT_S24_3BE:
        hw.formats = SNDRV_PCM_FMTBIT_S24_3BE;
        break;
    case SNDRV_PCM_FORMAT_FLOAT_BE:
        hw.formats = SNDRV_PCM_FMTBIT_FLOAT_BE;
        break;
    default:
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        printk(KERN_ERR "fusion_cn_alsa: pcm_open: Invalid format %d for stream %s\n", stream->format, stream_name);
        return -EINVAL;
    }
    switch (stream->rate) {
    case 44100:
        hw.rates = SNDRV_PCM_RATE_44100;
        break;
    case 48000:
        hw.rates = SNDRV_PCM_RATE_48000;
        break;
    case 96000:
        hw.rates = SNDRV_PCM_RATE_96000;
        break;
    default:
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        printk(KERN_ERR "fusion_cn_alsa: pcm_open: Invalid rate %u for stream %s\n", stream->rate, stream_name);
        return -EINVAL;
    }
    hw.rate_min = stream->rate;
    hw.rate_max = stream->rate;
    hw.channels_min = stream->channels;
    hw.channels_max = stream->channels;
    hw.buffer_bytes_max = 3072 * FUSION_CN_NUM_CHANNELS_MAX * 4;
    hw.period_bytes_min = 6 * 2;
    hw.period_bytes_max = 192 * FUSION_CN_NUM_CHANNELS_MAX * 4;
    hw.periods_min = 2;
    hw.periods_max = 64;

    runtime->hw = hw;
    runtime->private_data = stream;

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &constraints_rates);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &constraints_period_sizes);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_minmax(runtime, SNDRV_PCM_HW_PARAM_BUFFER_SIZE, 
                                       stream->rtp_frame_size * 2, stream->rtp_frame_size * 64);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_alsa_substream_release);
        return err;
    }

    read_unlock_irqrestore(&chip->lock, flags);

    if (substream->dma_buffer.dev.type == SNDRV_DMA_TYPE_UNKNOWN) {
        err = snd_pcm_set_managed_buffer(substream,
                                        SNDRV_DMA_TYPE_VMALLOC, 
                                        NULL,
                                        0, 0);
        if (err < 0)
        {
            pr_err("fusion_cn_alsa: set_managed_buffer failed (%d)\n", err);
            return err;
        }
    }

    atomic_inc(&stream->open_count);

    printk(KERN_INFO "fusion_cn_alsa: pcm_open: Opened stream %s\n", stream_name);
    return 0;
}

static int fusion_cn_pcm_close(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned long flags;

    spin_lock_irqsave(&stream->lock, flags);
    if (stream->substream) {
        snd_pcm_stream_lock_irq(stream->substream);
        stream->substream->runtime->status->hw_ptr = 0;
        stream->substream->runtime->control->appl_ptr = 0;
        stream->substream->runtime->boundary = 0;
        snd_pcm_stream_unlock_irq(stream->substream);
        stream->substream = NULL;
    }
    spin_unlock_irqrestore(&stream->lock, flags);

    if (atomic_dec_and_test(&stream->open_count)) {
        if (stream->pending_free && stream->pcm) {
            struct snd_card *card = stream->pcm->card;
            struct snd_pcm  *pcm  = stream->pcm;
            stream->pcm = NULL;
            snd_device_free(card, pcm);
        }
    }

    atomic_set(&stream->disconnected, 0);
    kref_put(&stream->ref, fusion_cn_alsa_substream_release);

    printk(KERN_INFO "fusion_cn_alsa: pcm_close: Closed stream %s\n", stream->stream_name);

    return 0;
}

static int fusion_cn_pcm_prepare(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    if (fusion_cn_alsa_stream_disconnected(runtime->private_data)) return -ENODEV;

    spin_lock_irq(&stream->lock);
    stream->interrupts_per_period = runtime->period_size / stream->rtp_frame_size;
    if (stream->interrupts_per_period == 0) stream->interrupts_per_period = 1;
    stream->interrupt_idx = 0;
    stream->buffer_pos = 0;
    stream->pcm_indirect.hw_data = 0;
    stream->pcm_indirect.sw_data = 0;
    stream->pcm_indirect.hw_buffer_size = snd_pcm_lib_buffer_bytes(substream);
    stream->pcm_indirect.sw_buffer_size = snd_pcm_lib_buffer_bytes(substream);
    atomic_set(&stream->dma_offset, 0);
    memset(runtime->dma_area, 0, runtime->buffer_size * stream->channels * stream->sample_width);
    spin_unlock_irq(&stream->lock);

    return 0;
}

static snd_pcm_uframes_t fusion_cn_pcm_pointer(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    snd_pcm_uframes_t offset;

    if (fusion_cn_alsa_stream_disconnected(runtime->private_data)) return -ENODEV;

    offset = stream->buffer_pos;
    if (offset >= runtime->buffer_size) offset %= runtime->buffer_size;

    return offset;
}

static int fusion_cn_pcm_trigger(struct snd_pcm_substream *substream, int cmd)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct fusion_cn_chip *chip = snd_pcm_substream_chip(substream);
    int err;

    if (fusion_cn_alsa_stream_disconnected(stream)) return -ENODEV;

    switch (cmd) {
    case SNDRV_PCM_TRIGGER_START:
    case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
    case SNDRV_PCM_TRIGGER_RESUME:
        err = chip->alsa_ops->start_interrupts(chip->fusion_cn_mgr, stream->stream_handle, stream);
        if (err < 0) {
            printk(KERN_ERR "fusion_cn_alsa: pcm_trigger: start_interrupts failed for stream %s, err=%d\n",
                   stream->stream_name, err);
            return err;
        }
        printk(KERN_INFO "fusion_cn_alsa: pcm_trigger: Stream %s started\n", stream->stream_name);
        return 0;
    case SNDRV_PCM_TRIGGER_STOP:
    case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
    case SNDRV_PCM_TRIGGER_SUSPEND:
    {
        int err = 0;

        err = chip->alsa_ops->stop_interrupts(chip->fusion_cn_mgr, stream->stream_handle);
        if (err == -ENOENT) {  // stream already gone on RTP side → not an error
            err = 0;
        } else if (err < 0) {
            printk(KERN_ERR "fusion_cn_alsa: pcm_trigger: stop_interrupts failed for stream %s, err=%d\n",
                stream->stream_name, err);
            return err;
        }
        printk(KERN_INFO "fusion_cn_alsa: pcm_trigger: Stream %s stopped\n", stream->stream_name);
        return 0;
    }
    default:
        printk(KERN_ERR "fusion_cn_alsa: pcm_trigger: Invalid cmd %d for stream %s\n",
               cmd, stream->stream_name);
        return -EINVAL;
    }
}

static int fusion_cn_pcm_hw_free(struct snd_pcm_substream *substream)
{
    return 0;
}

static struct snd_pcm_ops fusion_cn_pcm_ops = {
    .open = fusion_cn_pcm_open,
    .close = fusion_cn_pcm_close,
    .hw_params = fusion_cn_pcm_hw_params,
    .hw_free = fusion_cn_pcm_hw_free,
    .prepare = fusion_cn_pcm_prepare,
    .trigger = fusion_cn_pcm_trigger,
    .pointer = fusion_cn_pcm_pointer,
    .copy = fusion_cn_pcm_copy,
    .fill_silence = fusion_cn_pcm_fill_silence,
};

int fusion_cn_alsa_open_substream(struct fusion_cn_chip *alsa_chip, uint64_t stream_handle, const char *stream_name,
                                    int direction, unsigned int channels, uint32_t rate, snd_pcm_format_t format, 
                                    uint32_t frames_per_packet, struct fusion_cn_substream **alsa_substream)
{
    struct fusion_cn_chip *chip = alsa_chip;
    unsigned long flags;
    struct snd_pcm *pcm;
    int err;
    int bucket;
    struct fusion_cn_substream *stream;
    uint64_t packet_time_ns;
    int max_channels;
    bool is_96khz;
    bool is_32b;
    bool is_24b;
    int stream_index;

    if (!chip->fusion_cn_mgr) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: fusion_cn_mgr is NULL for stream %s\n", stream_name);
        return -EINVAL;
    }

    if (format != SNDRV_PCM_FORMAT_S16_BE && 
        format != SNDRV_PCM_FORMAT_S24_3BE && 
        format != SNDRV_PCM_FORMAT_FLOAT_BE) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: Stream %s invalid format %d\n", stream_name, format);
        return -EINVAL;
    }

    write_lock_irqsave(&chip->lock, flags);
    stream_index = find_first_zero_bit(chip->stream_indices, FUSION_CN_MAX_STREAMS);
    if (stream_index >= FUSION_CN_MAX_STREAMS) {
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn_alsa: open_substream: No available device indices for stream %s\n", stream_name);
        return -ENOSPC;
    }
    set_bit(stream_index, chip->stream_indices);
    write_unlock_irqrestore(&chip->lock, flags);

    err = snd_pcm_new(chip->card, stream_name, stream_index,
                      direction == SNDRV_PCM_STREAM_PLAYBACK ? 1 : 0,
                      direction == SNDRV_PCM_STREAM_CAPTURE ? 1 : 0, &pcm);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: snd_pcm_new failed for stream %s, device=%d, err=%d\n", stream_name, stream_index, err);
        goto clr_idx;
    }

    pcm->private_data = chip;
    pcm->card = chip->card;
    strscpy(pcm->name, stream_name, sizeof(pcm->name));
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_PLAYBACK, &fusion_cn_pcm_ops);
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_CAPTURE, &fusion_cn_pcm_ops);

    stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: kzalloc failed for stream %s\n", stream_name);
        err = -ENOMEM;
        goto dev_free;
    }

    spin_lock_init(&stream->lock);
    kref_init(&stream->ref);
    stream->stream_handle = stream_handle;
    strscpy(stream->stream_name, stream_name, sizeof(stream->stream_name));
    stream->sample_width = snd_pcm_format_physical_width(format) >> 3;
    stream->channels = channels;
    stream->rate = rate;
    stream->format = format;
    stream->rtp_frame_size = frames_per_packet;
    stream->stream_index = stream_index;
    stream->pcm = pcm;

    if (rate != 44100 && rate != 48000 && rate != 96000) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: Stream %s rate %u invalid\n", stream_name, rate);
        err = -EINVAL;
        goto stream_free;
    }

    packet_time_ns = ((uint64_t)frames_per_packet * NSEC_PER_SEC) / rate;
    is_96khz = rate == 96000;
    is_32b = (format == SNDRV_PCM_FORMAT_FLOAT_BE);
    is_24b = (format == SNDRV_PCM_FORMAT_S24_3BE);

    if (packet_time_ns <= 125000) {
        if (is_96khz) max_channels = is_32b ? 30 : 
                                     is_24b ? 40 : 60;
        else max_channels = is_32b ? 60 : 
                            is_24b ? 80 : 120;
    } else if (packet_time_ns <= 250000) {
        if (is_96khz) max_channels = is_32b ? 15 : 
                                     is_24b ? 20 : 30;
        else max_channels = is_32b ? 30 : 
                            is_24b ? 40 : 60;
    } else if (packet_time_ns <= 333333) {
        if (is_96khz) max_channels = is_32b ? 11 : 
                                     is_24b ? 15 : 22;
        else max_channels = is_32b ? 22 : 
                            is_24b ? 30 : 45;
    } else if (packet_time_ns <= 1000000) {
        if (is_96khz) max_channels = is_32b ? 3 : 
                                     is_24b ? 5 : 7;
        else max_channels = is_32b ? 7 : 
                            is_24b ? 10 : 15;          
    } else {
        if (is_96khz) max_channels = is_32b ? 0 : 1;
        else max_channels = is_32b ? 1 : 
                            is_24b ? 2 : 3;
    }

    if (channels == 0 || channels > max_channels) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: Stream %s bad # channels (%d) for rate=%u, format=%s\n",
               stream_name, channels, rate, snd_pcm_format_name(format));
        err = -EINVAL;
        goto stream_free;
    }

    read_lock_irqsave(&chip->lock, flags);
    if (fusion_cn_find_substream(stream_name)) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_WARNING "fusion_cn_alsa: open_substream: Stream %s already exists\n", stream_name);
        err = -EEXIST;
        goto stream_free;
    }
    read_unlock_irqrestore(&chip->lock, flags);

    write_lock_irqsave(&chip->lock, flags);
    bucket = hash_name(stream_name);
    hlist_add_head(&stream->hnode, &chip->streams[bucket]);
    write_unlock_irqrestore(&chip->lock, flags);

    err = snd_device_register(chip->card, pcm);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: open_substream: snd_device_register failed for stream %s, device=%d, err=%d\n", stream_name, stream_index, err);
        goto clr_hnode;
    }

    atomic_set(&stream->open_count, 0);
    stream->pending_free = false;
    atomic_set(&stream->disconnected, 0);

    printk(KERN_INFO "fusion_cn_alsa: open_substream: Successfully created substream for stream %s, device=%d, format=%d, channels=%u, rate=%u, frames_per_packet=%u\n", 
                                                                                      stream_name, stream_index, format, 
                                                                                      channels, rate, frames_per_packet);
    
    *alsa_substream = stream;
    return 0;

clr_hnode:
    write_lock_irqsave(&chip->lock, flags);
    hlist_del(&stream->hnode);
    write_unlock_irqrestore(&chip->lock, flags);
stream_free:
    kref_put(&stream->ref, fusion_cn_alsa_substream_release);
dev_free:
    snd_device_free(chip->card, pcm);
clr_idx:
    write_lock_irqsave(&chip->lock, flags);
    clear_bit(stream_index, chip->stream_indices);
    write_unlock_irqrestore(&chip->lock, flags);

    return err;
}

static int fusion_cn_chip_probe(struct platform_device *pdev)
{
    struct fusion_cn_chip *chip;
    struct snd_card *card;
    int err;

    err = snd_card_new(&pdev->dev, -1, "FusionConnect", THIS_MODULE,
                       sizeof(struct fusion_cn_chip), &card);
    if (err < 0) {
        dev_err(&pdev->dev, "fusion_cn_alsa: Failed to create FusionConnect card: %d\n", err);
        return err;
    }

    chip = card->private_data;
    chip->card = card;
    chip->fusion_cn_mgr = pdev->dev.platform_data;
    bitmap_zero(chip->stream_indices, FUSION_CN_MAX_STREAMS);

    rwlock_init(&chip->lock);
    for (int i = 0; i < 1 << FUSION_CN_ALSA_HASH_BITS; i++) {
        INIT_HLIST_HEAD(&chip->streams[i]);
    }

    strscpy(card->driver, "FusionConnect", sizeof(card->driver));
    strscpy(card->shortname, "FusionConnect", sizeof(card->shortname));
    strscpy(card->longname, "Fusion Connect Audio-over-IP", sizeof(card->longname));
    snd_card_set_dev(card, &pdev->dev);

    err = snd_card_register(card);
    if (err < 0) {
        snd_card_free(card);
        return err;
    }

    platform_set_drvdata(pdev, chip);
    return 0;
}

static void fusion_cn_chip_remove(struct platform_device *pdev)
{
    struct fusion_cn_chip *chip = platform_get_drvdata(pdev);
    struct snd_card *card;
    struct fusion_cn_substream *to_free[ FUSION_CN_MAX_STREAMS ];
    int n = 0;
    int i;
    unsigned long flags;

    if (!chip) {
        dev_err(&pdev->dev, "fusion_cn_alsa: No chip found for platform device\n");
        return;
    }

    card = chip->card;
    if (!card) {
        dev_err(&pdev->dev, "fusion_cn_alsa: No snd_card found in chip\n");
        platform_set_drvdata(pdev, NULL);
        return;
    }

    /* Block new user opens early */
    snd_card_disconnect(card);

    /* Collect & unlink under lock (no sleeping ops inside) */
    write_lock_irqsave(&chip->lock, flags);
    for (i = 0; i < (1 << FUSION_CN_ALSA_HASH_BITS); i++) {
        struct hlist_node *tmp;
        struct fusion_cn_substream *stream;
        hlist_for_each_entry_safe(stream, tmp, &chip->streams[i], hnode) {
            if (chip->alsa_ops && chip->alsa_ops->stop_interrupts)
                chip->alsa_ops->stop_interrupts(chip->fusion_cn_mgr, stream->stream_handle);

            if (stream->substream)
                snd_pcm_stop(stream->substream, SNDRV_PCM_STATE_DISCONNECTED);

            hlist_del_init(&stream->hnode);
            clear_bit(stream->stream_index, chip->stream_indices);

            to_free[n++] = stream;
        }
    }
    write_unlock_irqrestore(&chip->lock, flags);

    /* Now sleepable frees without holding chip->lock */
    for (i = 0; i < n; i++) {
        struct fusion_cn_substream *s = to_free[i];

        if (s->pcm) {
            /* If it isn’t open, free now; otherwise let .close do it (pending_free) */
            if (atomic_read(&s->open_count) == 0 && !s->substream) {
                struct snd_card *c = s->pcm->card;
                struct snd_pcm  *p = s->pcm;
                s->pcm = NULL;
                snd_device_free(c, p);    /* non-GPL */
            } else {
                s->pending_free = true;
            }
        }

        kref_put(&s->ref, fusion_cn_alsa_substream_release);
    }

    snd_card_free(card);

    platform_set_drvdata(pdev, NULL);
    dev_info(&pdev->dev, "FusionConnect card removed\n");
    return;
}

static struct platform_driver fusion_cn_driver = {
    .probe = fusion_cn_chip_probe,
    .remove_new = fusion_cn_chip_remove,
    .driver = {
        .name = "snd_fusion_cn"
    },
};

int fusion_cn_alsa_driver_init(void *fusion_cn_mgr, const struct fusion_cn_alsa_ops *callbacks)
{
    struct fusion_cn_chip *chip;
    int err;

    err = platform_driver_register(&fusion_cn_driver);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: platform_driver_register failed: %d\n", err);
        return err;
    }

    g_pdev = platform_device_alloc("snd_fusion_cn", 0);
    if (!g_pdev) {
        printk(KERN_ERR "fusion_cn_alsa: platform_device_alloc failed\n");
        platform_driver_unregister(&fusion_cn_driver);
        return -ENOMEM;
    }

    g_pdev->dev.platform_data = fusion_cn_mgr;

    err = platform_device_add(g_pdev);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: platform_device_add failed: %d\n", err);
        platform_device_put(g_pdev);
        g_pdev = NULL;
        platform_driver_unregister(&fusion_cn_driver);
        return err;
    }

    chip = platform_get_drvdata(g_pdev);
    if (!chip) {
        printk(KERN_ERR "fusion_cn_alsa: Failed to get chip from platform data\n");
        platform_device_unregister(g_pdev);
        g_pdev = NULL;
        platform_driver_unregister(&fusion_cn_driver);
        return -ENODEV;
    }

    err = callbacks->register_alsa_driver(fusion_cn_mgr, chip);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn_alsa: register_alsa_driver failed: %d\n", err);
        platform_device_unregister(g_pdev);
        g_pdev = NULL;
        platform_driver_unregister(&fusion_cn_driver);
        return err;
    }

    chip->alsa_ops = callbacks;
    return 0;
}

void fusion_cn_alsa_destroy(void)
{
    if (g_pdev) {
        platform_device_unregister(g_pdev);
        g_pdev = NULL;
    }
    platform_driver_unregister(&fusion_cn_driver);
    printk(KERN_INFO "fusion_cn_alsa: Card exit\n");
}

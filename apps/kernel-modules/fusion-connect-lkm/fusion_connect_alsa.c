/*
 * Copyright (C) 2017 Merging Technologies
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
#include <linux/hashtable.h>
#include <linux/version.h>
#include <linux/spinlock.h>
#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>
#include <sound/pcm-indirect.h>
#include "fusion_connect_alsa.h"

#define FUSION_CN_NUM_CHANNELS_MAX 120
#define FUSION_CN_DEFAULT_BUFFER_FRAMES 512

#define FUSION_CN_ALSA_HASH_BITS 6

struct fusion_cn_substream {
    struct snd_pcm_substream *substream;
    uint64_t stream_handle;
    snd_pcm_format_t format;
    uint32_t stride;
    uint32_t rate;
    uint32_t channels;
    uint32_t buffer_pos;
    uint32_t rtp_frame_size;
    uint32_t interrupts_per_period;
    uint32_t interrupt_idx;
    uint64_t alsa_sac;
    struct snd_pcm_indirect pcm_indirect;
    atomic_t dma_offset;
    spinlock_t lock;
    struct hlist_node hnode;
    struct kref ref;
};

struct fusion_cn_chip {
    void *fusion_cn_mgr;
    const struct fusion_cn_alsa_ops *alsa_ops;
    spinlock_t lock;
    struct hlist_head streams[FUSION_CN_ALSA_HASH_BITS];
    struct snd_card *card;
};

static struct snd_pcm_hardware fusion_cn_pcm_hw = {
    .info = SNDRV_PCM_INFO_MMAP | SNDRV_PCM_INFO_INTERLEAVED |
            SNDRV_PCM_INFO_BLOCK_TRANSFER | SNDRV_PCM_INFO_MMAP_VALID,
    .formats = SNDRV_PCM_FMTBIT_S16_BE | SNDRV_PCM_FMTBIT_S24_BE | SNDRV_PCM_FMTBIT_FLOAT_LE,
    .rates = SNDRV_PCM_RATE_44100 | SNDRV_PCM_RATE_48000 | SNDRV_PCM_RATE_96000,
    .rate_min = 44100,
    .rate_max = 96000,
    .channels_min = 1,
    .channels_max = FUSION_CN_NUM_CHANNELS_MAX,
    .buffer_bytes_max = FUSION_CN_DEFAULT_BUFFER_FRAMES * FUSION_CN_NUM_CHANNELS_MAX * 4,
    .period_bytes_min = 6 * 2, /* 0.125ms at 48kHz, L16 */
    .period_bytes_max = 192 * FUSION_CN_NUM_CHANNELS_MAX * 4,
    .periods_min = 2,
    .periods_max = 16
};

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

    spin_lock_irq(&stream->lock);
    if (stream->rate != rate || stream->format != format || stream->channels != channels) {
        pr_err("fusion_cn: Params mismatch for %llu: rate %u/%u, format %d/%d, channels %u/%u\n",
               stream->stream_handle, rate, stream->rate, format, stream->format, channels, stream->channels);
        spin_unlock_irq(&stream->lock);
        return -EINVAL;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &constraints_rates);
    if (err < 0) return err;
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &constraints_period_sizes);
    if (err < 0) return err;
    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) return err;

    runtime->buffer_size = buffer_bytes / (stream->stride * stream->channels);
    runtime->period_size = period_size;
    runtime->periods = buffer_bytes / (period_size * stream->stride * stream->channels);

    err = snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
    if (err < 0) {
        spin_unlock_irq(&stream->lock);
        return err;
    }
    stream->pcm_indirect.hw_buffer_size = buffer_bytes;
    stream->pcm_indirect.sw_buffer_size = buffer_bytes;
    atomic_set(&stream->dma_offset, 0);

    spin_unlock_irq(&stream->lock);
    return 0;
}

static struct platform_device *g_pdev;

static void fusion_cn_substream_release(struct kref *kref)
{
    struct fusion_cn_substream *stream = container_of(kref, struct fusion_cn_substream, ref);
    snd_device_disconnect(stream->substream->pcm->card, stream->substream->pcm);
    kfree(stream);
}

static struct fusion_cn_substream *fusion_cn_find_substream(struct fusion_cn_chip *chip, uint64_t stream_handle)
{
    int bucket;
    struct fusion_cn_substream *stream;

    bucket = hash_64(stream_handle, FUSION_CN_ALSA_HASH_BITS);
    hlist_for_each_entry(stream, &chip->streams[bucket], hnode) {
        if (stream->stream_handle == stream_handle) {
            kref_get(&stream->ref);
            return stream;
        }
    }
    return NULL;
}

static void *fusion_cn_get_playback_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    void *buf;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No playback stream for handle %llu\n", stream_handle);
        return NULL;
    }
    buf = stream->substream->runtime->dma_area;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return buf;
}

static uint32_t fusion_cn_get_playback_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t size;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No playback stream for handle %llu\n", stream_handle);
        return 0;
    }
    size = stream->substream->runtime->buffer_size;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return size;
}

static void *fusion_cn_get_capture_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    void *buf;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No capture stream for handle %llu\n", stream_handle);
        return NULL;
    }
    buf = stream->substream->runtime->dma_area;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return buf;
}

static uint32_t fusion_cn_get_capture_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t size;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No capture stream for handle %llu\n", stream_handle);
        return 0;
    }
    size = stream->substream->runtime->buffer_size;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return size;
}

static void fusion_cn_lock_playback_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream && stream->substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        spin_lock(&stream->lock);
    }
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_cn_unlock_playback_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream && stream->substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock(&stream->lock);
    }
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_cn_lock_capture_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream && stream->substream->stream == SNDRV_PCM_STREAM_CAPTURE) {
        spin_lock(&stream->lock);
    }
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_cn_unlock_capture_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream && stream->substream->stream == SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock(&stream->lock);
    }
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static uint32_t fusion_cn_get_playback_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t offset;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No playback stream for handle %llu\n", stream_handle);
        return 0;
    }
    offset = stream->buffer_pos;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return offset;
}

static uint32_t fusion_cn_get_capture_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t offset;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: No capture stream for handle %llu\n", stream_handle);
        return 0;
    }
    offset = stream->buffer_pos;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return offset;
}

static int fusion_cn_pcm_interrupt(void *rawchip, int direction, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t bytes_per_frame;
    unsigned int pos;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || !stream->substream || stream->substream->stream != direction) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Invalid stream for handle %llu, direction %d\n", stream_handle, direction);
        return -EINVAL;
    }

    spin_lock(&stream->lock);
    if (stream->substream->runtime->status->state != SNDRV_PCM_STATE_RUNNING) {
        spin_unlock(&stream->lock);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    bytes_per_frame = stream->channels * stream->stride;
    if (stream->substream->runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED |
                                             SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED |
                                             SNDRV_PCM_ACCESS_MMAP_COMPLEX)) {
        pos = atomic_read(&stream->dma_offset);
        pos += stream->rtp_frame_size * bytes_per_frame;
        if (pos >= stream->pcm_indirect.hw_buffer_size)
            pos -= stream->pcm_indirect.hw_buffer_size;
        atomic_set(&stream->dma_offset, pos);
    } else {
        stream->buffer_pos += stream->rtp_frame_size;
        if (stream->buffer_pos >= stream->substream->runtime->buffer_size)
            stream->buffer_pos -= stream->substream->runtime->buffer_size;
    }

    stream->interrupt_idx++;
    if (stream->interrupt_idx >= stream->interrupts_per_period) {
        stream->interrupt_idx = 0;
        stream->alsa_sac += stream->substream->runtime->period_size;
        snd_pcm_period_elapsed(stream->substream);
    }
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return 0;
}

static int fusion_cn_set_stream_params(void *rawchip, uint64_t stream_handle,
                                       unsigned int rate, unsigned int channels, snd_pcm_format_t format)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Stream %llu not found for set_stream_params\n", stream_handle);
        return -ENOENT;
    }

    spin_lock(&stream->lock);
    stream->rate = rate;
    if (stream->channels != channels || stream->format != format) {
        pr_warn("fusion_cn: Stream %llu params mismatch: channels %u/%u, format %d/%d\n",
                stream_handle, stream->channels, channels, stream->format, format);
    }
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return 0;
}

static int fusion_cn_pcm_copy(struct snd_pcm_substream *substream, int channel,
                              snd_pcm_uframes_t pos, void __user *buf, snd_pcm_uframes_t count)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    bool interleaved = runtime->access == SNDRV_PCM_ACCESS_RW_INTERLEAVED ||
                       runtime->access == SNDRV_PCM_ACCESS_MMAP_INTERLEAVED;
    unsigned char *dma_area = runtime->dma_area;
    size_t bytes_per_frame = stream->channels * stream->stride;
    int ret = 0;

    if (pos + count > runtime->buffer_size) {
        count = runtime->buffer_size - pos;
    }
    if (count == 0) return 0;
    if (!interleaved && (channel < 0 || channel >= stream->channels)) {
        return -EINVAL;
    }

    spin_lock_irq(&stream->lock);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        if (interleaved) {
            size_t bytes = count * bytes_per_frame;
            if (copy_from_user(dma_area + pos * bytes_per_frame, buf, bytes)) {
                ret = -EFAULT;
            }
        } else {
            size_t offset = pos * stream->stride + channel * runtime->buffer_size * stream->stride;
            if (copy_from_user(dma_area + offset, buf, count * stream->stride)) {
                ret = -EFAULT;
            }
        }
    } else {
        if (interleaved) {
            size_t bytes = count * bytes_per_frame;
            if (copy_to_user(buf, dma_area + pos * bytes_per_frame, bytes)) {
                ret = -EFAULT;
            }
        } else {
            size_t offset = pos * stream->stride + channel * runtime->buffer_size * stream->stride;
            if (copy_to_user(buf, dma_area + offset, count * stream->stride)) {
                ret = -EFAULT;
            }
        }
    }

    spin_unlock_irq(&stream->lock);
    return ret < 0 ? ret : (int)count;
}

static void fusion_cn_pcm_playback_ack_transfer(struct snd_pcm_substream *substream,
                                                struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;

    spin_lock_irq(&stream->lock);
    fusion_cn_pcm_copy(substream, -1, stream->buffer_pos, substream->runtime->dma_area + rec->sw_data, frames);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    spin_unlock_irq(&stream->lock);
}

static void fusion_cn_pcm_capture_ack_transfer(struct snd_pcm_substream *substream,
                                                struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;

    spin_lock_irq(&stream->lock);
    fusion_cn_pcm_copy(substream, -1, stream->buffer_pos, substream->runtime->dma_area + rec->sw_data, frames);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    spin_unlock_irq(&stream->lock);
}

static int fusion_cn_pcm_ack(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    if (!(runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED | SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED | SNDRV_PCM_ACCESS_MMAP_COMPLEX))) {
        return 0; // RW mode doesn't need ack
    }

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        return snd_pcm_indirect_playback_transfer(substream, &stream->pcm_indirect,
                                                  fusion_cn_pcm_playback_ack_transfer);
    } else {
        return snd_pcm_indirect_capture_transfer(substream, &stream->pcm_indirect,
                                                 fusion_cn_pcm_capture_ack_transfer);
    }
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
static int fusion_cn_pcm_copy_iter(struct snd_pcm_substream *substream,
                                   int channel, unsigned long pos,
                                   struct iov_iter *iter, unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    void __user *buf = iter_iov_addr(iter);
    return fusion_cn_pcm_copy(substream, channel, pos / bytes_per_frame, buf, frames);
}
#else
static int fusion_cn_pcm_copy_user(struct snd_pcm_substream *substream,
                                   int channel, unsigned long pos,
                                   void __user *buf, unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    return fusion_cn_pcm_copy(substream, channel, pos / bytes_per_frame, buf, frames);
}
#endif

static int fusion_cn_pcm_silence(struct snd_pcm_substream *substream,
                                 int channel, snd_pcm_uframes_t pos,
                                 snd_pcm_uframes_t count)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    size_t buffer_size_per_channel = runtime->buffer_size * stream->stride;
    const unsigned char *silence = snd_pcm_format_silence_64(runtime->format);
    unsigned char *dma_area = runtime->dma_area;

    if (substream->stream != SNDRV_PCM_STREAM_PLAYBACK) return 0;

    if (pos + count > runtime->buffer_size) {
        count = runtime->buffer_size - pos;
    }
    if (count == 0) return 0;

    spin_lock_irq(&stream->lock);

    if (channel == -1) {
        for (int ch = 0; ch < stream->channels; ch++) {
            unsigned char *channel_buf = dma_area + ch * buffer_size_per_channel + pos * stream->stride;
            for (snd_pcm_uframes_t i = 0; i < count; i++) {
                memcpy(channel_buf + i * stream->stride, silence, stream->stride);
            }
        }
    } else {
        unsigned char *channel_buf = dma_area + channel * buffer_size_per_channel + pos * stream->stride;
        if (channel >= stream->channels) {
            spin_unlock_irq(&stream->lock);
            return -EINVAL;
        }
        for (snd_pcm_uframes_t i = 0; i < count; i++) {
            memcpy(channel_buf + i * stream->stride, silence, stream->stride);
        }
    }

    spin_unlock_irq(&stream->lock);
    return (int)count;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
static int fusion_cn_pcm_fill_silence(struct snd_pcm_substream *substream,
                                      int channel, unsigned long pos,
                                      unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    return fusion_cn_pcm_silence(substream, channel, pos / bytes_per_frame, frames);
}
#endif

static int fusion_cn_remove_substream(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Stream %llu not found for removal\n", stream_handle);
        return -ENOENT;
    }

    if (stream->substream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_err("fusion_cn: Stream %llu still open\n", stream_handle);
        return -EBUSY;
    }

    hlist_del(&stream->hnode);
    kref_put(&stream->ref, fusion_cn_substream_release);
    spin_unlock_irqrestore(&chip->lock, flags);
    return 0;
}

static int fusion_cn_pcm_hw_free(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    int err = 0;

    spin_lock_irq(&stream->lock);
    if (substream->runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED | SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED | SNDRV_PCM_ACCESS_MMAP_COMPLEX)) {
        err = snd_pcm_lib_free_vmalloc_buffer(substream);
    }
    spin_unlock_irq(&stream->lock);
    return err;
}

static int fusion_cn_pcm_open(struct snd_pcm_substream *substream)
{
    struct fusion_cn_chip *chip = snd_pcm_substream_chip(substream);
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long flags;
    uint64_t stream_handle;
    struct fusion_cn_substream *stream;
    int err;

    if (sscanf(substream->pcm->name, "FusionConnect_%llu", &stream_handle) != 1) {
        pr_err("fusion_cn: Invalid PCM name %s\n", substream->pcm->name);
        return -EINVAL;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Stream %llu not found for open\n", stream_handle);
        return -ENOENT;
    }

    if (stream->substream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Stream %llu already open\n", stream_handle);
        return -EBUSY;
    }

    stream->substream = substream;
    err = chip->alsa_ops->get_rtp_frame_size(chip->fusion_cn_mgr, stream->stream_handle, &stream->rtp_frame_size);
    if (err < 0) {
        stream->substream = NULL;
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }

    runtime->hw = fusion_cn_pcm_hw;
    runtime->private_data = stream;
    spin_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return 0;
}

static int fusion_cn_pcm_close(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned long flags;

    spin_lock_irqsave(&stream->lock, flags);
    stream->substream = NULL; // Keep PCM for reuse
    spin_unlock_irqrestore(&stream->lock, flags);
    return 0;
}

static int fusion_cn_pcm_prepare(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    spin_lock_irq(&stream->lock);
    stream->interrupts_per_period = runtime->period_size / stream->rtp_frame_size;
    if (stream->interrupts_per_period == 0) stream->interrupts_per_period = 1;
    stream->interrupt_idx = 0;
    stream->buffer_pos = 0;
    stream->alsa_sac = 0;
    stream->pcm_indirect.hw_data = 0;
    stream->pcm_indirect.sw_data = 0;
    atomic_set(&stream->dma_offset, 0);
    spin_unlock_irq(&stream->lock);
    return 0;
}

static snd_pcm_uframes_t fusion_cn_pcm_pointer(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    snd_pcm_uframes_t offset;

    spin_lock_irq(&stream->lock);
    if (runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED |
                           SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED |
                           SNDRV_PCM_ACCESS_MMAP_COMPLEX)) {
        offset = (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) ?
                 snd_pcm_indirect_playback_pointer(substream, &stream->pcm_indirect,
                                                   atomic_read(&stream->dma_offset)) :
                 snd_pcm_indirect_capture_pointer(substream, &stream->pcm_indirect,
                                                  atomic_read(&stream->dma_offset));
    } else {
        offset = stream->buffer_pos;
    }
    if (offset >= runtime->buffer_size) offset %= runtime->buffer_size;
    spin_unlock_irq(&stream->lock);
    return offset;
}

static int fusion_cn_pcm_trigger(struct snd_pcm_substream *substream, int cmd)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct fusion_cn_chip *chip = snd_pcm_substream_chip(substream);
    int err;

    switch (cmd) {
    case SNDRV_PCM_TRIGGER_START:
    case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
    case SNDRV_PCM_TRIGGER_RESUME:
        if (chip->alsa_ops->start_interrupts) {
            err = chip->alsa_ops->start_interrupts(chip->fusion_cn_mgr, stream->stream_handle);
            if (err < 0) return err;
        }
        return 0;
    case SNDRV_PCM_TRIGGER_STOP:
    case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
    case SNDRV_PCM_TRIGGER_SUSPEND:
        if (chip->alsa_ops->stop_interrupts) {
            err = chip->alsa_ops->stop_interrupts(chip->fusion_cn_mgr, stream->stream_handle);
            if (err < 0) return err;
        }
        return 0;
    default:
        return -EINVAL;
    }
}

static struct snd_pcm_ops fusion_cn_pcm_ops = {
    .open = fusion_cn_pcm_open,
    .close = fusion_cn_pcm_close,
    .hw_params = fusion_cn_pcm_hw_params,
    .hw_free = fusion_cn_pcm_hw_free,
    .prepare = fusion_cn_pcm_prepare,
    .trigger = fusion_cn_pcm_trigger,
    .pointer = fusion_cn_pcm_pointer,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
    .copy_iter = fusion_cn_pcm_copy_iter,
    .fill_silence = fusion_cn_pcm_fill_silence,
#else
    .copy_user = fusion_cn_pcm_copy_user,
    .fill_silence = fusion_cn_pcm_silence,
#endif
    .ack = fusion_cn_pcm_ack,
};

static int fusion_cn_open_substream(void *rawchip, uint64_t stream_handle, int direction,
                                    unsigned int channels, snd_pcm_format_t format)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct snd_pcm *pcm;
    char name[32];
    int err;
    unsigned int rate, samples_per_packet;
    int bucket;
    struct fusion_cn_substream *stream;
    uint64_t packet_time_us; /* Packet time in microseconds */
    int max_channels;
    bool is_96khz;
    bool is_l24;

    /* Fetch stream params from manager to check AES67 format */
    err = chip->alsa_ops->get_rtp_frame_size(chip->fusion_cn_mgr, stream_handle, &samples_per_packet);
    if (err < 0) return err;

    /* AES67 streams must use L16 or L24 */
    if (format != SNDRV_PCM_FORMAT_S16_BE && format != SNDRV_PCM_FORMAT_S24_BE) {
        pr_err("fusion_cn: Stream %llu format %d invalid for AES67 (must be L16/L24)\n",
               stream_handle, format);
        return -EINVAL;
    }

    snprintf(name, sizeof(name), "FusionConnect_%llu", stream_handle);

    spin_lock_irqsave(&chip->lock, flags);
    if (fusion_cn_find_substream(chip, stream_handle)) {
        spin_unlock_irqrestore(&chip->lock, flags);
        pr_debug("fusion_cn: Stream %llu already exists\n", stream_handle);
        return -EEXIST;
    }

    err = snd_pcm_new(chip->card, name, 0,
                      direction == SNDRV_PCM_STREAM_PLAYBACK ? 1 : 0,
                      direction == SNDRV_PCM_STREAM_CAPTURE ? 1 : 0, &pcm);
    if (err < 0) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }

    pcm->private_data = chip;
    strscpy(pcm->name, name, sizeof(pcm->name));
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_PLAYBACK, &fusion_cn_pcm_ops);
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_CAPTURE, &fusion_cn_pcm_ops);

    stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) {
        snd_device_disconnect(chip->card, pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return -ENOMEM;
    }

    spin_lock_init(&stream->lock);
    kref_init(&stream->ref);
    stream->stream_handle = stream_handle;
    stream->channels = channels;
    stream->format = format;
    stream->stride = snd_pcm_format_physical_width(format) >> 3;

    /* Fetch rate after stream creation */
    err = chip->alsa_ops->set_stream_params(chip->fusion_cn_mgr, stream_handle, 0, 0, 0);
    if (err < 0) {
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }
    rate = stream->rate ? stream->rate : 48000;

    /* Calculate packet time in microseconds */
    packet_time_us = ((uint64_t)samples_per_packet * 1000000) / rate;

    /* Channel limits from table (thresholds in microseconds: 0.125ms = 125us, etc.) */
    is_96khz = rate == 96000;
    is_l24 = format == SNDRV_PCM_FORMAT_S24_BE;

    if (packet_time_us <= 125) { /* 0.125ms */
        if (is_96khz) max_channels = is_l24 ? 40 : 60;
        else max_channels = is_l24 ? 80 : 120;
    } else if (packet_time_us <= 250) { /* 0.25ms */
        if (is_96khz) max_channels = is_l24 ? 20 : 30;
        else max_channels = is_l24 ? 40 : 60;
    } else if (packet_time_us <= 333) { /* 0.333ms */
        if (is_96khz) max_channels = is_l24 ? 15 : 22;
        else max_channels = is_l24 ? 30 : 45;
    } else if (packet_time_us <= 1000) { /* 1.0ms */
        if (is_96khz) max_channels = is_l24 ? 5 : 7;
        else max_channels = is_l24 ? 10 : 15;
    } else { /* 4.0ms */
        if (is_96khz) max_channels = 1;
        else max_channels = is_l24 ? 2 : 3;
    }

    if (channels > max_channels) {
        pr_err("fusion_cn: Stream %llu exceeds max channels (%d) for %uHz, %s, %lluus\n",
               stream_handle, max_channels, rate, is_l24 ? "L24" : "L16", packet_time_us);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return -EINVAL;
    }

    bucket = hash_64(stream_handle, FUSION_CN_ALSA_HASH_BITS);
    hlist_add_head(&stream->hnode, &chip->streams[bucket]);

    err = snd_device_register(chip->card, pcm);
    if (err < 0) {
        hlist_del(&stream->hnode);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }

    spin_unlock_irqrestore(&chip->lock, flags);
    return 0;
}

static struct fusion_cn_mgr_ops mgr_ops = {
    .get_playback_buffer = fusion_cn_get_playback_buffer,
    .get_playback_buffer_size_in_frames = fusion_cn_get_playback_buffer_size_in_frames,
    .get_capture_buffer = fusion_cn_get_capture_buffer,
    .get_capture_buffer_size_in_frames = fusion_cn_get_capture_buffer_size_in_frames,
    .lock_playback_buffer = fusion_cn_lock_playback_buffer,
    .unlock_playback_buffer = fusion_cn_unlock_playback_buffer,
    .lock_capture_buffer = fusion_cn_lock_capture_buffer,
    .unlock_capture_buffer = fusion_cn_unlock_capture_buffer,
    .pcm_interrupt = fusion_cn_pcm_interrupt,
    .get_playback_buffer_offset = fusion_cn_get_playback_buffer_offset,
    .get_capture_buffer_offset = fusion_cn_get_capture_buffer_offset,
    .set_stream_params = fusion_cn_set_stream_params,
    .open_substream = fusion_cn_open_substream,
    .remove_substream = fusion_cn_remove_substream
};

static int fusion_cn_chip_probe(struct platform_device *pdev)
{
    struct fusion_cn_chip *chip;
    struct snd_card *card;
    int err;

    err = snd_card_new(&pdev->dev, -1, "FusionConnect", THIS_MODULE,
                       sizeof(struct fusion_cn_chip), &card);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to create FusionConnect card: %d\n", err);
        return err;
    }

    chip = card->private_data;
    chip->card = card;
    chip->fusion_cn_mgr = pdev->dev.platform_data;

    spin_lock_init(&chip->lock);
    for (int i = 0; i < FUSION_CN_ALSA_HASH_BITS; i++) {
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
    dev_info(&pdev->dev, "FusionConnect card registered\n");
    return 0;
}

static int fusion_cn_chip_remove(struct platform_device *pdev)
{
    struct snd_card *card = platform_get_drvdata(pdev);
    struct fusion_cn_chip *chip = card->private_data;
    struct hlist_node *tmp;
    struct fusion_cn_substream *stream;
    int i;

    if (chip) {
        spin_lock_irq(&chip->lock);
        for (i = 0; i < FUSION_CN_ALSA_HASH_BITS; i++) {
            hlist_for_each_entry_safe(stream, tmp, &chip->streams[i], hnode) {
                hlist_del(&stream->hnode);
                kref_put(&stream->ref, fusion_cn_substream_release);
            }
        }
        spin_unlock_irq(&chip->lock);
    }
    snd_card_free(card);
    platform_set_drvdata(pdev, NULL);
    dev_info(&pdev->dev, "FusionConnect card removed\n");
    return 0;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
static void fusion_cn_chip_remove_new(struct platform_device *pdev)
{
    fusion_cn_chip_remove(pdev);
}
#endif

static struct platform_driver fusion_cn_driver = {
    .probe = fusion_cn_chip_probe,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
    .remove_new = fusion_cn_chip_remove_new,
#else
    .remove = fusion_cn_chip_remove,
#endif
    .driver = {
        .name = "snd_fusion_cn"
    },
};

int fusion_cn_alsa_init_(void *fusion_cn_mgr, const struct fusion_cn_alsa_ops *callbacks)
{
    struct fusion_cn_chip *chip;
    int err;

    err = platform_driver_register(&fusion_cn_driver);
    if (err < 0) {
        pr_err("fusion_cn: platform_driver_register failed: %d\n", err);
        return err;
    }

    g_pdev = platform_device_register_simple("snd_fusion_cn", 0, NULL, 0);
    if (IS_ERR(g_pdev)) {
        err = PTR_ERR(g_pdev);
        pr_err("fusion_cn: platform_device_register_simple failed: %d\n", err);
        platform_driver_unregister(&fusion_cn_driver);
        return err;
    }

    g_pdev->dev.platform_data = fusion_cn_mgr;
    chip = platform_get_drvdata(g_pdev);
    if (!chip) {
        pr_err("fusion_cn: Failed to get chip from platform data\n");
        platform_device_unregister(g_pdev);
        platform_driver_unregister(&fusion_cn_driver);
        return -ENODEV;
    }

    err = callbacks->register_alsa_driver(fusion_cn_mgr, &mgr_ops, chip);
    if (err < 0) {
        pr_err("fusion_cn: register_alsa_driver failed: %d\n", err);
        platform_device_unregister(g_pdev);
        platform_driver_unregister(&fusion_cn_driver);
        return err;
    }

    chip->alsa_ops = callbacks;
    return 0;
}

void fusion_cn_card_exit(void)
{
    if (g_pdev) {
        platform_device_unregister(g_pdev);
    }
    platform_driver_unregister(&fusion_cn_driver);
    pr_info("fusion_cn: Card exit\n");
}

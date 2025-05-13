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

#define HASH_KEY(handle) hash_64(handle, FUSION_CN_ALSA_HASH_BITS)

struct fusion_cn_substream {
    struct snd_pcm_substream *substream;
    struct snd_pcm *pcm;
    uint64_t stream_handle;
    snd_pcm_format_t format;
    uint32_t stride;
    uint32_t rate;
    uint32_t channels;
    uint32_t buffer_pos;
    uint32_t rtp_frame_size;
    uint32_t interrupts_per_period;
    uint32_t interrupt_idx;
    struct snd_pcm_indirect pcm_indirect;
    atomic_t dma_offset;
    spinlock_t lock;
    struct hlist_node hnode;
    struct kref ref;
    uint16_t stream_index;
};

struct fusion_cn_chip {
    void *fusion_cn_mgr;
    const struct fusion_cn_alsa_ops *alsa_ops;
    rwlock_t lock; /* Changed from spinlock_t to rwlock_t */
    struct hlist_head streams[1 << FUSION_CN_ALSA_HASH_BITS];
    struct snd_card *card;
    DECLARE_BITMAP(stream_indices, FUSION_CN_MAX_STREAMS);
};

static struct snd_pcm_hardware fusion_cn_pcm_hw = {
    .info = SNDRV_PCM_INFO_MMAP | SNDRV_PCM_INFO_INTERLEAVED |
            SNDRV_PCM_INFO_BLOCK_TRANSFER | SNDRV_PCM_INFO_MMAP_VALID,
    .formats = SNDRV_PCM_FMTBIT_S16_LE | SNDRV_PCM_FMTBIT_S24_LE | SNDRV_PCM_FMTBIT_FLOAT_LE ,
    .rates = SNDRV_PCM_RATE_44100 | SNDRV_PCM_RATE_48000 | SNDRV_PCM_RATE_96000,
    .rate_min = 44100,
    .rate_max = 96000,
    .channels_min = 1,
    .channels_max = FUSION_CN_NUM_CHANNELS_MAX,
    .buffer_bytes_max = 768 * FUSION_CN_NUM_CHANNELS_MAX * 4,
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
        printk(KERN_ERR "fusion_cn: hw_params: Mismatch for stream %llu: rate %u/%u, format %d/%d, channels %u/%u\n",
               stream->stream_handle, rate, stream->rate, format, stream->format, channels, stream->channels);
        spin_unlock_irq(&stream->lock);
        return -EINVAL;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &constraints_rates);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: hw_params: Rate constraint failed for stream %llu, err=%d\n",
               stream->stream_handle, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &constraints_period_sizes);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: hw_params: Period size constraint failed for stream %llu, err=%d\n",
               stream->stream_handle, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }
    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: hw_params: Periods constraint failed for stream %llu, err=%d\n",
               stream->stream_handle, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }

    runtime->buffer_size = buffer_bytes / (stream->stride * stream->channels);
    runtime->period_size = period_size;
    runtime->periods = buffer_bytes / (period_size * stream->stride * stream->channels);

    err = snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: hw_params: Failed to allocate buffer for stream %llu, size=%u, err=%d\n",
               stream->stream_handle, buffer_bytes, err);
        spin_unlock_irq(&stream->lock);
        return err;
    }

    printk(KERN_INFO "fusion_cn: hw_params: Allocated buffer_size=%lu frames, period_size=%lu, periods=%u for stream %llu\n",
           runtime->buffer_size, runtime->period_size, runtime->periods, stream->stream_handle);

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
    if (stream->pcm) {
        printk(KERN_INFO "fusion_cn: substream_release: Freeing PCM for stream %llu, device=%d\n",
               stream->stream_handle, stream->stream_index);
        snd_device_disconnect(stream->substream->pcm->card, stream->pcm);
        snd_device_free(stream->substream->pcm->card, stream->pcm);
        stream->pcm = NULL;
    }
    kfree(stream);
}

static struct fusion_cn_substream *fusion_cn_find_substream(struct fusion_cn_chip *chip, uint64_t stream_handle)
{
    int bucket;
    struct fusion_cn_substream *stream;
    unsigned long flags;

    bucket = HASH_KEY(stream_handle);
    read_lock_irqsave(&chip->lock, flags);
    hlist_for_each_entry(stream, &chip->streams[bucket], hnode) {
        if (stream->stream_handle == stream_handle) {
            kref_get(&stream->ref);
            read_unlock_irqrestore(&chip->lock, flags);
            return stream;
        }
    }
    read_unlock_irqrestore(&chip->lock, flags);
    return NULL;
}

static void *fusion_cn_get_stream_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    void *buf;

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    buf = stream->substream->runtime->dma_area;
    read_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return buf;
}

static uint32_t fusion_cn_get_stream_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t size;

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    size = stream->substream->runtime->buffer_size;
    read_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return size;
}

static void fusion_cn_stream_buffer_lock(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    read_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream) {
        kref_get(&stream->ref); /* Keep stream alive after releasing chip->lock */
    }
    read_unlock_irqrestore(&chip->lock, *flags);

    if (stream) {
        spin_lock(&stream->lock);
        kref_put(&stream->ref, fusion_cn_substream_release);
    }
}

static void fusion_cn_stream_buffer_unlock(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;

    read_lock_irqsave(&chip->lock, *flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (stream) {
        kref_get(&stream->ref); /* Keep stream alive after releasing chip->lock */
    }
    read_unlock_irqrestore(&chip->lock, *flags);

    if (stream) {
        spin_unlock(&stream->lock);
        kref_put(&stream->ref, fusion_cn_substream_release);
    }
}

static uint32_t fusion_cn_get_stream_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t offset;

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    offset = stream->buffer_pos;
    read_unlock_irqrestore(&chip->lock, flags);
    kref_put(&stream->ref, fusion_cn_substream_release);
    return offset;
}

static int fusion_cn_pcm_interrupt(void *rawchip, int direction, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct fusion_cn_substream *stream;
    uint32_t bytes_per_frame;

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream || !stream->substream || stream->substream->stream != direction) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_DEBUG "fusion_cn: Invalid stream for handle %llu, direction %d\n", stream_handle, direction);
        return -EINVAL;
    }
    kref_get(&stream->ref);
    read_unlock_irqrestore(&chip->lock, flags);

    spin_lock_irq(&stream->lock);

    bytes_per_frame = stream->channels * stream->stride;
    if (stream->substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_INTERLEAVED ||
        stream->substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED ||
        stream->substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_COMPLEX) {
        unsigned int pos = atomic_read(&stream->dma_offset);
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
        snd_pcm_period_elapsed(stream->substream);
    }

    spin_unlock_irq(&stream->lock);

    kref_put(&stream->ref, fusion_cn_substream_release);
    return 0;
}

static void fusion_cn_pcm_playback_ack_transfer(struct snd_pcm_substream *substream,
                                               struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;
    unsigned char *dst = substream->runtime->dma_area + stream->buffer_pos * bytes_per_frame;
    unsigned char *src = substream->runtime->dma_area + rec->sw_data;

    spin_lock_irq(&stream->lock);
    memcpy(dst, src, frames * bytes_per_frame);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    spin_unlock_irq(&stream->lock);

    printk(KERN_DEBUG "fusion_cn: playback_ack_transfer: Copied %lu frames for stream %llu, buffer_pos=%u\n",
           frames, stream->stream_handle, stream->buffer_pos);
}

static void fusion_cn_pcm_capture_ack_transfer(struct snd_pcm_substream *substream,
                                              struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;
    unsigned char *src = substream->runtime->dma_area + stream->buffer_pos * bytes_per_frame;
    unsigned char *dst = substream->runtime->dma_area + rec->sw_data;

    spin_lock_irq(&stream->lock);
    memcpy(dst, src, frames * bytes_per_frame);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    spin_unlock_irq(&stream->lock);

    printk(KERN_DEBUG "fusion_cn: capture_ack_transfer: Copied %lu frames for stream %llu, buffer_pos=%u\n",
           frames, stream->stream_handle, stream->buffer_pos);
}

static int fusion_cn_pcm_ack(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    if (runtime->access != SNDRV_PCM_ACCESS_MMAP_INTERLEAVED  &&
        runtime->access != SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED &&
        runtime->access != SNDRV_PCM_ACCESS_MMAP_COMPLEX) {
        return 0;
    }

    printk(KERN_DEBUG "fusion_cn: pcm_ack: Access=%d\n", runtime->access);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        return snd_pcm_indirect_playback_transfer(substream, &stream->pcm_indirect,
                                                 fusion_cn_pcm_playback_ack_transfer);
    } else {
        return snd_pcm_indirect_capture_transfer(substream, &stream->pcm_indirect,
                                                fusion_cn_pcm_capture_ack_transfer);
    }
}

/* kernels < 6.6 */
#if LINUX_VERSION_CODE < KERNEL_VERSION(6,6,0)
static int fusion_cn_pcm_copy_user(struct snd_pcm_substream *substream,
                                   int channel, unsigned long pos,
                                   void __user *buf, unsigned long count)
{
    struct snd_pcm_runtime *rt = substream->runtime;
    struct fusion_cn_substream *stream = substream->runtime->private_data;

    spin_lock_irq(&stream->lock);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        // Playback: Copy from userspace to dma_area
        if (copy_from_user(rt->dma_area + pos, buf, count)) {
            spin_unlock_irq(&stream->lock);
            printk(KERN_ERR "fusion_cn: pcm_copy_user: Failed to copy from user for stream %llu\n",
                   stream->stream_handle);
            return -EFAULT;
        }
    } else {
        // Capture: Copy from dma_area to userspace
        if (copy_to_user(buf, rt->dma_area + pos, count)) {
            spin_unlock_irq(&stream->lock);
            printk(KERN_ERR "fusion_cn: pcm_copy_user: Failed to copy to user for stream %llu\n",
                   stream->stream_handle);
            return -EFAULT;
        }
    }

    spin_unlock_irq(&stream->lock);

    return count;
}
#else
/* kernels ≥ 6.6 */
static ssize_t fusion_cn_pcm_copy_iter(struct snd_pcm_substream *substream,
                                       int channel,
                                       unsigned long pos,      /* frames */
                                       struct iov_iter *iter,  /* user iterator */
                                       unsigned long count)    /* bytes */
{
    struct snd_pcm_runtime *rt = substream->runtime;
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    unsigned long bpf = (rt->frame_bits >> 3) * rt->channels;
    unsigned long offset = pos * bpf;
    void *dma_ptr = rt->dma_area + offset;

    spin_lock_irq(&stream->lock);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        // Playback: Copy from userspace to dma_area
        if (!copy_from_iter(dma_ptr, count, iter)) {
            spin_unlock_irq(&stream->lock);
            printk(KERN_ERR "fusion_cn: pcm_copy_iter: Failed to copy from user for stream %llu\n",
                   stream->stream_handle);
            return -EFAULT;
        }
    } else {
        // Capture: Copy from dma_area to userspace
        if (!copy_to_iter(dma_ptr, count, iter)) {
            spin_unlock_irq(&stream->lock);
            printk(KERN_ERR "fusion_cn: pcm_copy_iter: Failed to copy to user for stream %llu\n",
                   stream->stream_handle);
            return -EFAULT;
        }
    }

    spin_unlock_irq(&stream->lock);
    printk(KERN_DEBUG "fusion_cn: pcm_copy_iter: Stream %llu, direction=%d, pos=%lu, count=%lu\n",
           stream->stream_handle, substream->stream, pos, count);
    return count;
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

    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        printk(KERN_DEBUG "fusion_cn: remove_substream: Stream %llu not found\n", stream_handle);
        return -ENOENT;
    }

    /* Stop PCM to set DISCONNECTED state */
    if (stream->substream) {
        snd_pcm_stop(stream->substream, SNDRV_PCM_STATE_DISCONNECTED);
        printk(KERN_DEBUG "fusion_cn: remove_substream: Stopped PCM for stream %llu\n", stream_handle);
    }

    write_lock_irqsave(&chip->lock, flags);
    hlist_del(&stream->hnode);
    clear_bit(stream->stream_index, chip->stream_indices);
    write_unlock_irqrestore(&chip->lock, flags);

    if (stream->pcm) {
        printk(KERN_INFO "fusion_cn: remove_substream: Disconnecting PCM for stream %llu, device=%d\n",
               stream_handle, stream->stream_index);
        snd_device_disconnect(chip->card, stream->pcm);
        snd_device_free(chip->card, stream->pcm);
        stream->pcm = NULL;
    }

    if (stream->substream) {
        printk(KERN_INFO "fusion_cn: remove_substream: Clearing substream for stream %llu\n", stream_handle);
        stream->substream = NULL; /* Clear to prevent reuse */
    }

    kref_put(&stream->ref, fusion_cn_substream_release);
    printk(KERN_INFO "fusion_cn: remove_substream: Stream %llu removed, freed device=%d\n",
           stream_handle, stream->stream_index);
    return 0;
}

static uint32_t fusion_cn_alsa_ops_get_stream_available_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;
    snd_pcm_sframes_t avail;

    read_lock(&chip->lock);
    stream = fusion_cn_find_substream(chip, stream_handle);

    spin_lock(&stream->lock);
    avail = snd_pcm_playback_hw_avail(stream->substream->runtime);
    spin_unlock(&stream->lock);

    read_unlock(&chip->lock);

    return (uint32_t)avail;
}

static int fusion_cn_mute_stream_buffers(void *rawchip, uint64_t stream_handle)
{
    struct fusion_cn_chip *chip = rawchip;
    struct fusion_cn_substream *stream;
    struct snd_pcm_runtime *runtime;
    unsigned long flags;

    read_lock(&chip->lock);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        read_unlock(&chip->lock);
        printk(KERN_ERR "fusion_cn: mute_stream_buffers: Stream %llu not found\n",
               stream_handle);
        return -ENOENT;
    }

    if (!stream->substream) {
        read_unlock(&chip->lock);
        printk(KERN_ERR "fusion_cn: mute_stream_buffers: No substream for stream %llu\n",
               stream_handle);
        return -EINVAL;
    }

    runtime = stream->substream->runtime;
    if (!runtime->dma_area) {
        read_unlock(&chip->lock);
        printk(KERN_ERR "fusion_cn: mute_stream_buffers: dma_area is NULL for stream %llu\n",
               stream_handle);
        return -EINVAL;
    }

    spin_lock_irqsave(&stream->lock, flags);
    printk(KERN_DEBUG "fusion_cn: mute_stream_buffers: Zeroing buffer for stream %llu, size=%lu\n",
           stream_handle, runtime->buffer_size * stream->channels * stream->stride);
    memset(runtime->dma_area, 0, runtime->buffer_size * stream->channels * stream->stride);
    spin_unlock_irqrestore(&stream->lock, flags);

    read_unlock(&chip->lock);
    return 0;
}

static int fusion_cn_pcm_hw_free(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    int err = 0;

    spin_lock_irq(&stream->lock);
    if (substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_INTERLEAVED  ||
        substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED ||
        substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_COMPLEX) {
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

    if (sscanf(substream->pcm->name, "FC_%llu", &stream_handle) != 1) {
        printk(KERN_ERR "fusion_cn: pcm_open: Invalid PCM name %s\n", substream->pcm->name);
        return -EINVAL;
    }

    read_lock_irqsave(&chip->lock, flags);
    stream = fusion_cn_find_substream(chip, stream_handle);
    if (!stream) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_DEBUG "fusion_cn: pcm_open: Stream %llu not found\n", stream_handle);
        return -ENOENT;
    }

    if (stream->substream) {
        read_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_DEBUG "fusion_cn: pcm_open: Stream %llu already open\n", stream_handle);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return -EBUSY;
    }

    stream->substream = substream;
    err = chip->alsa_ops->get_rtp_frame_size(chip->fusion_cn_mgr, stream_handle, &stream->rtp_frame_size);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return err;
    }

    runtime->hw = fusion_cn_pcm_hw;
    runtime->private_data = stream;

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &constraints_rates);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &constraints_period_sizes);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return err;
    }

    err = snd_pcm_hw_constraint_minmax(runtime, SNDRV_PCM_HW_PARAM_BUFFER_SIZE, 
                                       stream->rtp_frame_size * 2, stream->rtp_frame_size * 16);
    if (err < 0) {
        stream->substream = NULL;
        read_unlock_irqrestore(&chip->lock, flags);
        kref_put(&stream->ref, fusion_cn_substream_release);
        return err;
    }

    read_unlock_irqrestore(&chip->lock, flags);
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
        stream->substream->runtime->boundary = 0; // Reset boundary counter
        snd_pcm_stream_unlock_irq(stream->substream);
        stream->substream = NULL;
    }
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
    stream->pcm_indirect.hw_data = 0;
    stream->pcm_indirect.sw_data = 0;
    stream->pcm_indirect.hw_buffer_size = snd_pcm_lib_buffer_bytes(substream);
    stream->pcm_indirect.sw_buffer_size = snd_pcm_lib_buffer_bytes(substream);
    atomic_set(&stream->dma_offset, 0);
    memset(runtime->dma_area, 0, runtime->buffer_size * stream->channels * stream->stride);
    spin_unlock_irq(&stream->lock);

    return 0;
}

static snd_pcm_uframes_t fusion_cn_pcm_pointer(struct snd_pcm_substream *substream)
{
    struct fusion_cn_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    snd_pcm_uframes_t offset;

    if (substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_INTERLEAVED  ||
        substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED ||
        substream->runtime->access == SNDRV_PCM_ACCESS_MMAP_COMPLEX) {
        offset = (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) ?
                snd_pcm_indirect_playback_pointer(substream, &stream->pcm_indirect,
                                                atomic_read(&stream->dma_offset)) :
                snd_pcm_indirect_capture_pointer(substream, &stream->pcm_indirect,
                                                atomic_read(&stream->dma_offset));
    } else {
        offset = stream->buffer_pos;
    }
    if (offset >= runtime->buffer_size) offset %= runtime->buffer_size;

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
        err = chip->alsa_ops->start_interrupts(chip->fusion_cn_mgr, stream->stream_handle);
        if (err < 0) {
            printk(KERN_ERR "fusion_cn: pcm_trigger: start_interrupts failed for stream %llu, err=%d\n",
                    stream->stream_handle, err);
            return err;
        }
        printk(KERN_DEBUG "fusion_cn: pcm_trigger: Stream %llu started\n", stream->stream_handle);
        return 0;
    case SNDRV_PCM_TRIGGER_STOP:
    case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
    case SNDRV_PCM_TRIGGER_SUSPEND:
        err = chip->alsa_ops->stop_interrupts(chip->fusion_cn_mgr, stream->stream_handle);
        if (err < 0) {
            printk(KERN_ERR "fusion_cn: pcm_trigger: stop_interrupts failed for stream %llu, err=%d\n",
                    stream->stream_handle, err);
            return err;
        }
        printk(KERN_DEBUG "fusion_cn: pcm_trigger: Stream %llu stopped\n",
                stream->stream_handle);
        return 0;
    default:
        printk(KERN_ERR "fusion_cn: pcm_trigger: Invalid cmd %d for stream %llu\n",
               cmd, stream->stream_handle);
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
                                    unsigned int channels, uint32_t rate, snd_pcm_format_t format)
{
    struct fusion_cn_chip *chip = rawchip;
    unsigned long flags;
    struct snd_pcm *pcm;
    char name[64];
    int err;
    uint32_t frames_per_packet;
    int bucket;
    struct fusion_cn_substream *stream;
    uint64_t packet_time_us;
    int max_channels;
    bool is_96khz;
    bool is_32b;
    int stream_index;

    if (!chip->fusion_cn_mgr) {
        printk(KERN_ERR "fusion_cn: open_substream: fusion_cn_mgr is NULL for stream %llu\n", stream_handle);
        return -EINVAL;
    }

    err = chip->alsa_ops->get_rtp_frame_size(chip->fusion_cn_mgr, stream_handle, &frames_per_packet);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: open_substream: Initial get_rtp_frame_size failed for stream %llu, err=%d\n", stream_handle, err);
        return err;
    }

    printk(KERN_INFO "fusion_cn: open_substream: stream %llu, format=%d, channels=%u, rate=%u, frames_per_packet=%u\n",
           stream_handle, format, channels, rate, frames_per_packet);

    if (format != SNDRV_PCM_FORMAT_S16_LE && 
        format != SNDRV_PCM_FORMAT_S24_LE && 
        format != SNDRV_PCM_FORMAT_FLOAT_LE) {
        printk(KERN_ERR "fusion_cn: open_substream: Stream %llu invalid format %d\n", stream_handle, format);
        return -EINVAL;
    }

    snprintf(name, sizeof(name), "FC_%llu", stream_handle);

    write_lock_irqsave(&chip->lock, flags);
    stream_index = find_first_zero_bit(chip->stream_indices, FUSION_CN_MAX_STREAMS);
    if (stream_index >= FUSION_CN_MAX_STREAMS) {
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn: open_substream: No available device indices for stream %llu\n", stream_handle);
        return -ENOSPC;
    }
    set_bit(stream_index, chip->stream_indices);
    write_unlock_irqrestore(&chip->lock, flags);

    err = snd_pcm_new(chip->card, name, stream_index,
                      direction == SNDRV_PCM_STREAM_PLAYBACK ? 1 : 0,
                      direction == SNDRV_PCM_STREAM_CAPTURE ? 1 : 0, &pcm);
    if (err < 0) {
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn: open_substream: snd_pcm_new failed for stream %llu, device=%d, err=%d\n", stream_handle, stream_index, err);
        return err;
    }

    pcm->private_data = chip;
    strscpy(pcm->name, name, sizeof(pcm->name));
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_PLAYBACK, &fusion_cn_pcm_ops);
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_CAPTURE, &fusion_cn_pcm_ops);

    stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) {
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn: open_substream: kzalloc failed for stream %llu\n", stream_handle);
        return -ENOMEM;
    }

    spin_lock_init(&stream->lock);
    kref_init(&stream->ref);
    stream->stream_handle = stream_handle;
    stream->stride = snd_pcm_format_physical_width(format) >> 3;
    stream->channels = channels;
    stream->rate = rate;
    stream->format = format;
    stream->stream_index = stream_index;
    stream->pcm = pcm; /* Store PCM device */

    printk(KERN_INFO "fusion_cn: open_substream: Allocated stream %llu at %p, refcount=%d, device=%d\n",
           stream_handle, stream, kref_read(&stream->ref), stream_index);

    if (rate != 44100 && rate != 48000 && rate != 96000) {
        printk(KERN_ERR "fusion_cn: open_substream: Stream %llu rate %u invalid\n", stream_handle, rate);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        return -EINVAL;
    }

    packet_time_us = ((uint64_t)frames_per_packet * 1000000) / rate;
    is_96khz = rate == 96000;
    is_32b = (format == SNDRV_PCM_FORMAT_FLOAT_LE || 
              format == SNDRV_PCM_FORMAT_S24_LE);

    if (packet_time_us <= 125) {
        if (is_96khz) max_channels = is_32b ? 40 : 60;
        else max_channels = is_32b ? 80 : 120;
    } else if (packet_time_us <= 250) {
        if (is_96khz) max_channels = is_32b ? 20 : 30;
        else max_channels = is_32b ? 40 : 60;
    } else if (packet_time_us <= 333) {
        if (is_96khz) max_channels = is_32b ? 15 : 22;
        else max_channels = is_32b ? 30 : 45;
    } else if (packet_time_us <= 1000) {
        if (is_96khz) max_channels = is_32b ? 5 : 7;
        else max_channels = is_32b ? 10 : 15;
    } else {
        if (is_96khz) max_channels = 1;
        else max_channels = is_32b ? 2 : 3;
    }

    if (channels > max_channels) {
        printk(KERN_ERR "fusion_cn: open_substream: Stream %llu exceeds max channels (%d) for %uHz, %s, %lluus\n",
               stream_handle, max_channels, rate, is_32b ? "L24 or float" : "L16", packet_time_us);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        return -EINVAL;
    }

    read_lock_irqsave(&chip->lock, flags);
    if (fusion_cn_find_substream(chip, stream_handle)) {
        read_unlock_irqrestore(&chip->lock, flags);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_DEBUG "fusion_cn: open_substream: Stream %llu already exists\n", stream_handle);
        return -EEXIST;
    }
    read_unlock_irqrestore(&chip->lock, flags);

    write_lock_irqsave(&chip->lock, flags);
    bucket = hash_64(stream_handle, FUSION_CN_ALSA_HASH_BITS);
    hlist_add_head(&stream->hnode, &chip->streams[bucket]);
    write_unlock_irqrestore(&chip->lock, flags);

    err = chip->alsa_ops->get_rtp_frame_size(chip->fusion_cn_mgr, stream_handle, &stream->rtp_frame_size);
    if (err < 0) {
        write_lock_irqsave(&chip->lock, flags);
        hlist_del(&stream->hnode);
        write_unlock_irqrestore(&chip->lock, flags);
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        kfree(stream);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn: open_substream: get_rtp_frame_size failed for stream %llu, err=%d\n", stream_handle, err);
        return err;
    }

    err = snd_device_register(chip->card, pcm);
    if (err < 0) {
        write_lock_irqsave(&chip->lock, flags);
        hlist_del(&stream->hnode);
        write_unlock_irqrestore(&chip->lock, flags);
        kfree(stream);
        snd_device_disconnect(chip->card, pcm);
        snd_device_free(chip->card, pcm);
        write_lock_irqsave(&chip->lock, flags);
        clear_bit(stream_index, chip->stream_indices);
        write_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_cn: open_substream: snd_device_register failed for stream %llu, device=%d, err=%d\n", stream_handle, stream_index, err);
        return err;
    }

    printk(KERN_INFO "fusion_cn: open_substream: Successfully created substream for stream %llu\n", stream_handle);
    return 0;
}

static struct fusion_cn_mgr_ops mgr_ops = {
    .get_stream_buffer = fusion_cn_get_stream_buffer,
    .get_stream_buffer_size_in_frames = fusion_cn_get_stream_buffer_size_in_frames,
    .get_stream_buffer_offset = fusion_cn_get_stream_buffer_offset,
    .lock_buffer = fusion_cn_stream_buffer_lock,      /* Consolidated callback */
    .unlock_buffer = fusion_cn_stream_buffer_unlock,  /* Consolidated callback */
    .pcm_interrupt = fusion_cn_pcm_interrupt,
    .open_substream = fusion_cn_open_substream,
    .remove_substream = fusion_cn_remove_substream,
    .get_stream_available_frames = fusion_cn_alsa_ops_get_stream_available_frames,
    .mute_stream_buffers = fusion_cn_mute_stream_buffers
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
    bitmap_zero(chip->stream_indices, FUSION_CN_MAX_STREAMS); /* Initialize bitmap */

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
    dev_info(&pdev->dev, "FusionConnect card registered\n");
    return 0;
}

int fusion_cn_chip_remove(struct platform_device *pdev)
{
    struct fusion_cn_chip *chip = platform_get_drvdata(pdev);
    struct snd_card *card;
    struct hlist_node *tmp;
    struct fusion_cn_substream *stream;
    int i;
    unsigned long flags;

    if (!chip) {
        dev_err(&pdev->dev, "fusion_cn: No chip found for platform device\n");
        return 0;
    }

    card = chip->card;
    if (!card) {
        dev_err(&pdev->dev, "fusion_cn: No snd_card found in chip\n");
        platform_set_drvdata(pdev, NULL);
        return 0;
    }

    /* Stop any active PCM streams */
    if (chip->alsa_ops && chip->alsa_ops->stop_interrupts) {
        write_lock_irqsave(&chip->lock, flags);
        for (i = 0; i < 1 << FUSION_CN_ALSA_HASH_BITS; i++) {
            hlist_for_each_entry(stream, &chip->streams[i], hnode) {
                chip->alsa_ops->stop_interrupts(chip, stream->stream_handle);
            }
        }
        write_unlock_irqrestore(&chip->lock, flags);
    }

    /* Clean up substreams */
    write_lock_irqsave(&chip->lock, flags);
    for (i = 0; i < 1 << FUSION_CN_ALSA_HASH_BITS; i++) {
        hlist_for_each_entry_safe(stream, tmp, &chip->streams[i], hnode) {
            hlist_del(&stream->hnode);
            kref_put(&stream->ref, fusion_cn_substream_release);
        }
    }
    write_unlock_irqrestore(&chip->lock, flags);

    /* Disconnect and free the card */
    snd_card_disconnect(card);
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
        printk(KERN_ERR "fusion_cn: platform_driver_register failed: %d\n", err);
        return err;
    }

    /* Allocate the platform device manually */
    g_pdev = platform_device_alloc("snd_fusion_cn", 0);
    if (!g_pdev) {
        printk(KERN_ERR "fusion_cn: platform_device_alloc failed\n");
        platform_driver_unregister(&fusion_cn_driver);
        return -ENOMEM;
    }

    /* Set platform data before registering the device */
    g_pdev->dev.platform_data = fusion_cn_mgr;

    /* Register the platform device, which will call fusion_cn_chip_probe */
    err = platform_device_add(g_pdev);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: platform_device_add failed: %d\n", err);
        platform_device_put(g_pdev);
        g_pdev = NULL;
        platform_driver_unregister(&fusion_cn_driver);
        return err;
    }

    chip = platform_get_drvdata(g_pdev);
    if (!chip) {
        printk(KERN_ERR "fusion_cn: Failed to get chip from platform data\n");
        platform_device_unregister(g_pdev);
        g_pdev = NULL;
        platform_driver_unregister(&fusion_cn_driver);
        return -ENODEV;
    }

    err = callbacks->register_alsa_driver(fusion_cn_mgr, &mgr_ops, chip);
    if (err < 0) {
        printk(KERN_ERR "fusion_cn: register_alsa_driver failed: %d\n", err);
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
        g_pdev = NULL; /* Clear g_pdev to prevent double-free */
    }
    platform_driver_unregister(&fusion_cn_driver);
    printk(KERN_INFO "fusion_cn: Card exit\n");
}

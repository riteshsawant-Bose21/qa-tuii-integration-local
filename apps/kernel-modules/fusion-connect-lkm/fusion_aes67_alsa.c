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

#include <linux/version.h>
#include <linux/err.h>
#include <linux/printk.h>
#include <linux/vmalloc.h>
#include <linux/list.h>
#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>

#include "fusion_aes67_alsa.h"

#define FUSION_AES67_NUM_CHANNELS_MAX 32
#define FUSION_AES67_RINGBUFFER_NUM_FRAMES 512

static void *g_aes67_mgr;
static struct fusion_aes67_alsa_ops *g_alsa_ops;
static struct platform_device *g_pdev;

struct fusion_aes67_substream {
    struct snd_pcm_substream *substream;
    struct snd_pcm *pcm; // Own PCM device per stream
    unsigned char *buffer;
    uint32_t buffer_pos;
    uint64_t alsa_sac;
    snd_pcm_format_t format;
    uint32_t stride;
    uint32_t rate;
    uint32_t channels;
    uint32_t rtp_frame_size;
    uint32_t interrupts_per_period;
    uint32_t interrupt_idx;
    atomic_t dma_offset;
    struct snd_pcm_indirect pcm_indirect;
    spinlock_t lock;
    uint64_t stream_handle;
    struct list_head list; // Link into chip->streams
};

struct fusion_aes67_chip {
    void *aes67_mgr;
    struct fusion_aes67_alsa_ops *alsa_ops;
    spinlock_t lock;
    struct list_head streams; // List of all substreams
    struct platform_device *pdev;
    struct snd_card *card;
};

static struct snd_pcm_hardware fusion_aes67_pcm_hw = {
    .info = (SNDRV_PCM_INFO_MMAP | SNDRV_PCM_INFO_INTERLEAVED |
            SNDRV_PCM_INFO_BLOCK_TRANSFER | SNDRV_PCM_INFO_MMAP_VALID),
    .formats = SNDRV_PCM_FMTBIT_S16_LE | SNDRV_PCM_FMTBIT_S24_LE |
            SNDRV_PCM_FMTBIT_S32_LE | SNDRV_PCM_FMTBIT_FLOAT_LE,
    .rates = SNDRV_PCM_RATE_44100 | SNDRV_PCM_RATE_48000 |
            SNDRV_PCM_RATE_88200 | SNDRV_PCM_RATE_96000,
    .rate_min = 44100,
    .rate_max = 96000,
    .channels_min = 1,
    .channels_max = FUSION_AES67_NUM_CHANNELS_MAX,
    .buffer_bytes_max = FUSION_AES67_RINGBUFFER_NUM_FRAMES * FUSION_AES67_NUM_CHANNELS_MAX * 4,
    .period_bytes_min = 6 * 1 * 2,
    .period_bytes_max = 192 * FUSION_AES67_NUM_CHANNELS_MAX * 4,
    .periods_min = 2,
    .periods_max = 16
};

static unsigned int g_supported_rates[] = {44100, 48000, 88200, 96000};
static struct snd_pcm_hw_constraint_list g_constraints_rates = {
    .count = ARRAY_SIZE(g_supported_rates),
    .list = g_supported_rates,
    .mask = 0,
};

static const unsigned int g_supported_period_sizes[] = {16, 32, 64, 128, 256, 512, 1024};
static const struct snd_pcm_hw_constraint_list g_constraints_period_sizes = {
    .count = ARRAY_SIZE(g_supported_period_sizes),
    .list = g_supported_period_sizes,
    .mask = 0
};

static struct fusion_aes67_substream *find_substream_by_handle(struct fusion_aes67_chip *chip, uint64_t stream_handle)
{
    struct fusion_aes67_substream *stream;
    list_for_each_entry(stream, &chip->streams, list) {
        if (stream->stream_handle == stream_handle) {
            return stream;
        }
    }
    return NULL;
}

static void *fusion_aes67_get_playback_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    void *buf;

    if (!chip) return NULL;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return NULL;
    }

    spin_lock(&stream->lock);
    buf = stream->buffer;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return buf;
}

static uint32_t fusion_aes67_get_playback_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) return 0;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    uint32_t size = FUSION_AES67_RINGBUFFER_NUM_FRAMES;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return size;
}

static void *fusion_aes67_get_capture_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    void *buf;

    if (!chip) return NULL;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return NULL;
    }

    spin_lock(&stream->lock);
    buf = stream->buffer;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return buf;
}

static uint32_t fusion_aes67_get_capture_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) return 0;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    uint32_t size = FUSION_AES67_RINGBUFFER_NUM_FRAMES;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return size;
}

static void fusion_aes67_lock_playback_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;

    if (!chip) return;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, *flags);
        return;
    }
    spin_lock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_aes67_unlock_playback_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;

    if (!chip) return;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, *flags);
        return;
    }
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_aes67_lock_capture_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;

    if (!chip) return;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, *flags);
        return;
    }
    spin_lock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static void fusion_aes67_unlock_capture_buffer(void *rawchip, uint64_t stream_handle, unsigned long *flags)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;

    if (!chip) return;

    spin_lock_irqsave(&chip->lock, *flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, *flags);
        return;
    }
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, *flags);
}

static uint32_t fusion_aes67_get_playback_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) return 0;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    uint32_t offset = stream->buffer_pos;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return offset;
}

static uint32_t fusion_aes67_get_capture_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) return 0;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || stream->substream->stream != SNDRV_PCM_STREAM_CAPTURE) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    uint32_t offset = stream->buffer_pos;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return offset;
}

static int fusion_aes67_pcm_interrupt(void *rawchip, int direction, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream || !stream->substream || stream->substream->stream != direction) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return -EINVAL;
    }

    spin_lock(&stream->lock);
    if (stream->substream->runtime->status->state != SNDRV_PCM_STATE_RUNNING) {
        spin_unlock(&stream->lock);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    uint32_t ring_buffer_size = stream->substream->runtime->buffer_size;
    unsigned int bytes_per_frame = stream->channels * stream->stride;

    if (stream->substream->runtime->access & SNDRV_PCM_ACCESS_MMAP) {
        unsigned int pos = atomic_read(&stream->dma_offset);
        pos += stream->rtp_frame_size * bytes_per_frame;
        if (pos >= stream->pcm_indirect.hw_buffer_size)
            pos -= stream->pcm_indirect.hw_buffer_size;
        atomic_set(&stream->dma_offset, pos);
    } else {
        stream->buffer_pos += stream->rtp_frame_size;
        if (stream->buffer_pos >= ring_buffer_size)
            stream->buffer_pos -= ring_buffer_size;
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
 
static int fusion_aes67_set_stream_params(void *rawchip, uint64_t stream_handle, unsigned int rate, unsigned int channels, snd_pcm_format_t format)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return -ENOENT;
    }

    spin_lock(&stream->lock);
    stream->rate = rate; // Only update rate, channels/format already set
    if (stream->channels != channels || stream->format != format) {
        printk(KERN_WARNING "fusion_aes67_set_stream_params: channels/format mismatch for handle %llu\n", stream_handle);
        // Not fatal - buffer already sized, but log inconsistency
    }
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
    return 0;
}
 
static int fusion_aes67_open_substream(void *rawchip, uint64_t stream_handle, int direction, unsigned int channels, snd_pcm_format_t format)
{
    struct fusion_aes67_chip *chip = rawchip;
    unsigned long flags;
    struct snd_pcm *pcm;
    char name[32];
    int err;

    snprintf(name, sizeof(name), "FusionAES67_%llu", stream_handle);

    spin_lock_irqsave(&chip->lock, flags);
    if (find_substream_by_handle(chip, stream_handle)) {
        spin_unlock_irqrestore(&chip->lock, flags);
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
    strscpy(pcm->name, name, SNDRV_PCM_NAME_MAX);
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_PLAYBACK, &fusion_aes67_pcm_ops);
    snd_pcm_set_ops(pcm, SNDRV_PCM_STREAM_CAPTURE, &fusion_aes67_pcm_ops);

    struct fusion_aes67_substream *stream = kzalloc(sizeof(*stream), GFP_KERNEL);
    if (!stream) {
        snd_pcm_free(pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return -ENOMEM;
    }

    spin_lock_init(&stream->lock);
    stream->stream_handle = stream_handle;
    stream->pcm = pcm;
    stream->channels = channels;
    stream->format = format;
    stream->stride = snd_pcm_format_physical_width(format) >> 3;
    size_t buffer_size = FUSION_AES67_RINGBUFFER_NUM_FRAMES * stream->channels * stream->stride;
    stream->buffer = vmalloc(buffer_size);
    if (!stream->buffer) {
        kfree(stream);
        snd_pcm_free(pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return -ENOMEM;
    }

    list_add(&stream->list, &chip->streams);
    err = snd_device_register(chip->card, pcm);
    if (err < 0) {
        vfree(stream->buffer);
        list_del(&stream->list);
        kfree(stream);
        snd_pcm_free(pcm);
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }

    spin_unlock_irqrestore(&chip->lock, flags);
    printk(KERN_DEBUG "fusion_aes67_open_substream: created stream %llu, size %zu bytes\n", stream_handle, buffer_size);
    return 0;
}
 
static int fusion_aes67_remove_substream(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_aes67_remove_substream: no substream for handle %llu\n", stream_handle);
        return -ENOENT;
    }

    if (stream->substream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        printk(KERN_ERR "fusion_aes67_remove_substream: substream %llu still open\n", stream_handle);
        return -EBUSY; // Userspace must close it first
    }

    if (stream->pcm) {
        snd_pcm_free(stream->pcm); // Free the PCM device
        stream->pcm = NULL;
    }
    vfree(stream->buffer);
    stream->buffer = NULL;
    list_del(&stream->list);
    kfree(stream);

    spin_unlock_irqrestore(&chip->lock, flags);
    printk(KERN_DEBUG "fusion_aes67_remove_substream: removed substream for handle %llu\n", stream_handle);
    return 0;
}

static struct fusion_aes67_mgr_ops g_mgr_ops = {
    .get_playback_buffer = fusion_aes67_get_playback_buffer,
    .get_playback_buffer_size_in_frames = fusion_aes67_get_playback_buffer_size_in_frames,
    .get_capture_buffer = fusion_aes67_get_capture_buffer,
    .get_capture_buffer_size_in_frames = fusion_aes67_get_capture_buffer_size_in_frames,
    .lock_playback_buffer = fusion_aes67_lock_playback_buffer,
    .unlock_playback_buffer = fusion_aes67_unlock_playback_buffer,
    .lock_capture_buffer = fusion_aes67_lock_capture_buffer,
    .unlock_capture_buffer = fusion_aes67_unlock_capture_buffer,
    .pcm_interrupt = fusion_aes67_pcm_interrupt,
    .get_playback_buffer_offset = fusion_aes67_get_playback_buffer_offset,
    .get_capture_buffer_offset = fusion_aes67_get_capture_buffer_offset,
    .set_stream_params = fusion_aes67_set_stream_params,
    .open_substream = fusion_aes67_open_substream,
    .remove_substream = fusion_aes67_remove_substream // Added
};

static int fusion_aes67_pcm_copy(struct snd_pcm_substream *substream,
                                int channel, snd_pcm_uframes_t pos,
                                void __user *buf, snd_pcm_uframes_t count)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    size_t buffer_size_per_channel = FUSION_AES67_RINGBUFFER_NUM_FRAMES * stream->stride;
    bool interleaved = (runtime->access == SNDRV_PCM_ACCESS_RW_INTERLEAVED ||
                        runtime->access == SNDRV_PCM_ACCESS_MMAP_INTERLEAVED);
    unsigned char *stream_buf;
    int ret = 0;

    if (pos + count > FUSION_AES67_RINGBUFFER_NUM_FRAMES) {
        count = FUSION_AES67_RINGBUFFER_NUM_FRAMES - pos;
    }
    if (count == 0) return 0;
    if (!interleaved && (channel < 0 || channel >= stream->channels)) {
        return -EINVAL;
    }

    spin_lock_irq(&stream->lock);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        if (interleaved) {
            size_t bytes = count * stream->channels * stream->stride;
            unsigned char *temp = kmalloc(bytes, GFP_KERNEL);
            if (!temp) {
                ret = -ENOMEM;
                goto unlock;
            }
            if (copy_from_user(temp, buf, bytes)) {
                kfree(temp);
                ret = -EFAULT;
                goto unlock;
            }
            for (int ch = 0; ch < stream->channels; ch++) {
                stream_buf = stream->buffer + ch * buffer_size_per_channel + pos * stream->stride;
                for (snd_pcm_uframes_t i = 0; i < count; i++) {
                    memcpy(stream_buf + i * stream->stride,
                            temp + (i * stream->channels + ch) * stream->stride,
                            stream->stride);
                }
            }
            kfree(temp);
        } else {
            stream_buf = stream->buffer + channel * buffer_size_per_channel + pos * stream->stride;
            if (copy_from_user(stream_buf, buf, count * stream->stride)) {
                ret = -EFAULT;
                goto unlock;
            }
        }
        stream->alsa_sac += count;
    } else {
        if (interleaved) {
            size_t bytes = count * stream->channels * stream->stride;
            unsigned char *temp = kmalloc(bytes, GFP_KERNEL);
            if (!temp) {
                ret = -ENOMEM;
                goto unlock;
            }
            for (int ch = 0; ch < stream->channels; ch++) {
                stream_buf = stream->buffer + ch * buffer_size_per_channel + pos * stream->stride;
                for (snd_pcm_uframes_t i = 0; i < count; i++) {
                    memcpy(temp + (i * stream->channels + ch) * stream->stride,
                            stream_buf + i * stream->stride,
                            stream->stride);
                }
            }
            if (copy_to_user(buf, temp, bytes)) {
                kfree(temp);
                ret = -EFAULT;
                goto unlock;
            }
            kfree(temp);
        } else {
            stream_buf = stream->buffer + channel * buffer_size_per_channel + pos * stream->stride;
            if (copy_to_user(buf, stream_buf, count * stream->stride)) {
                ret = -EFAULT;
                goto unlock;
            }
        }
    }

unlock:
    spin_unlock_irq(&stream->lock);
    return ret < 0 ? ret : (int)count;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
static int fusion_aes67_pcm_copy_iter(struct snd_pcm_substream *substream,
                                    int channel, unsigned long pos,
                                    struct iov_iter *iter, unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    void __user *buf = iter_iov_addr(iter);
    return fusion_aes67_pcm_copy(substream, channel, pos / bytes_per_frame, buf, frames);
}
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(4,13,0)
static int fusion_aes67_pcm_copy_user(struct snd_pcm_substream *substream,
                                    int channel, unsigned long pos,
                                    void __user *buf, unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    return fusion_aes67_pcm_copy(substream, channel, pos / bytes_per_frame, buf, frames);
}
#endif

static int fusion_aes67_pcm_silence(struct snd_pcm_substream *substream,
                                    int channel, snd_pcm_uframes_t pos,
                                    snd_pcm_uframes_t count)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    size_t buffer_size_per_channel = FUSION_AES67_RINGBUFFER_NUM_FRAMES * stream->stride;
    const unsigned char *silence = snd_pcm_format_silence_64(runtime->format);
    unsigned char *stream_buf;

    if (substream->stream != SNDRV_PCM_STREAM_PLAYBACK) return 0;

    if (pos + count > FUSION_AES67_RINGBUFFER_NUM_FRAMES) {
        count = FUSION_AES67_RINGBUFFER_NUM_FRAMES - pos;
    }
    if (count == 0) return 0;

    spin_lock_irq(&stream->lock);

    if (channel == -1) {
        for (int ch = 0; ch < stream->channels; ch++) {
            stream_buf = stream->buffer + ch * buffer_size_per_channel + pos * stream->stride;
            for (snd_pcm_uframes_t i = 0; i < count; i++) {
                memcpy(stream_buf + i * stream->stride, silence, stream->stride);
            }
        }
    } else {
        if (channel >= stream->channels) {
            spin_unlock_irq(&stream->lock);
            return -EINVAL;
        }
        stream_buf = stream->buffer + channel * buffer_size_per_channel + pos * stream->stride;
        for (snd_pcm_uframes_t i = 0; i < count; i++) {
            memcpy(stream_buf + i * stream->stride, silence, stream->stride);
        }
    }

    spin_unlock_irq(&stream->lock);
    return (int)count;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
static int fusion_aes67_pcm_fill_silence(struct snd_pcm_substream *substream,
                                        int channel, unsigned long pos,
                                        unsigned long count)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned long bytes_per_frame = runtime->channels * snd_pcm_format_physical_width(runtime->format) >> 3;
    snd_pcm_uframes_t frames = count / bytes_per_frame;
    return fusion_aes67_pcm_silence(substream, channel, pos / bytes_per_frame, frames);
}
#endif
 
static int fusion_aes67_pcm_ack(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    if (!(runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED | SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED | SNDRV_PCM_ACCESS_MMAP_COMPLEX))) {
        return 0; // RW mode doesn't need ack
    }

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        return snd_pcm_indirect_playback_transfer(substream, &stream->pcm_indirect,
                                                  fusion_aes67_pcm_playback_ack_transfer);
    } else {
        return snd_pcm_indirect_capture_transfer(substream, &stream->pcm_indirect,
                                                 fusion_aes67_pcm_capture_ack_transfer);
    }
}
 
static void fusion_aes67_pcm_playback_ack_transfer(struct snd_pcm_substream *substream,
                                                struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;

    spin_lock_irq(&stream->lock);
    fusion_aes67_pcm_copy(substream, -1, stream->buffer_pos, substream->runtime->dma_area + rec->sw_data, frames);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    stream->alsa_sac += frames;
    spin_unlock_irq(&stream->lock);
}

static void fusion_aes67_pcm_capture_ack_transfer(struct snd_pcm_substream *substream,
                                                struct snd_pcm_indirect *rec, size_t bytes)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    unsigned int bytes_per_frame = stream->channels * stream->stride;
    snd_pcm_uframes_t frames = bytes / bytes_per_frame;

    spin_lock_irq(&stream->lock);
    fusion_aes67_pcm_copy(substream, -1, stream->buffer_pos, substream->runtime->dma_area + rec->sw_data, frames);
    stream->buffer_pos += frames;
    if (stream->buffer_pos >= substream->runtime->buffer_size)
        stream->buffer_pos -= substream->runtime->buffer_size;
    stream->alsa_sac += frames;
    spin_unlock_irq(&stream->lock);
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
int fusion_snd_pcm_lib_alloc_vmalloc_buffer(struct snd_pcm_substream *substream, size_t size)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    if (runtime->dma_area) {
        if (runtime->dma_bytes >= size) return 0;
        vfree(runtime->dma_area);
    }
    runtime->dma_area = vzalloc(size);
    if (!runtime->dma_area) return -ENOMEM;
    runtime->dma_bytes = size;
    return 1;
}

int fusion_snd_pcm_lib_free_vmalloc_buffer(struct snd_pcm_substream *substream)
{
    struct snd_pcm_runtime *runtime = substream->runtime;
    vfree(runtime->dma_area);
    runtime->dma_area = NULL;
    return 0;
}

struct page *fusion_snd_pcm_lib_get_vmalloc_page(struct snd_pcm_substream *substream, unsigned long offset)
{
    return vmalloc_to_page(substream->runtime->dma_area + offset);
}
#endif

static int fusion_aes67_pcm_hw_free(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    int err = 0;

    spin_lock_irq(&stream->lock);
    if (substream->runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED | SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED | SNDRV_PCM_ACCESS_MMAP_COMPLEX)) {
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
        err = fusion_snd_pcm_lib_free_vmalloc_buffer(substream);
#else
        err = snd_pcm_lib_free_vmalloc_buffer(substream);
#endif
    }
    spin_unlock_irq(&stream->lock);
    return err;
}

static int fusion_aes67_pcm_open(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    struct snd_pcm_runtime *runtime = substream->runtime;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    uint64_t stream_handle;

    if (sscanf(substream->pcm->name, "FusionAES67_%llu", &stream_handle) != 1) {
        printk(KERN_ERR "fusion_aes67_pcm_open: invalid PCM name %s\n", substream->pcm->name);
        return -EINVAL;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle);
    if (!stream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return -ENOENT;
    }

    if (stream->substream) {
        spin_unlock_irqrestore(&chip->lock, flags);
        return -EBUSY;
    }

    stream->substream = substream;
    int err = chip->alsa_ops->get_rtp_frame_size_per_stream(chip->aes67_mgr, stream->stream_handle, &stream->rtp_frame_size);
    if (err < 0) {
        stream->substream = NULL;
        spin_unlock_irqrestore(&chip->lock, flags);
        return err;
    }

    runtime->hw = fusion_aes67_pcm_hw;
    runtime->private_data = stream;
    spin_unlock_irqsave(&chip->lock, flags);
    return 0;
}

static int fusion_aes67_pcm_close(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    unsigned long flags;

    spin_lock_irqsave(&stream->lock, flags);
    stream->substream = NULL; // Keep buffer and PCM for reuse
    spin_unlock_irqrestore(&stream->lock, flags);
    return 0;
}

static int fusion_aes67_pcm_prepare(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
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

static snd_pcm_uframes_t fusion_aes67_pcm_pointer(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
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

static int fusion_aes67_pcm_trigger(struct snd_pcm_substream *substream, int cmd)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    int err;

    switch (cmd) {
    case SNDRV_PCM_TRIGGER_START:
    case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
    case SNDRV_PCM_TRIGGER_RESUME:
        if (chip->alsa_ops->start_interrupts) {
            err = chip->alsa_ops->start_interrupts(chip->aes67_mgr, stream->stream_handle);
            if (err < 0) return err;
        }
        return 0;
    case SNDRV_PCM_TRIGGER_STOP:
    case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
    case SNDRV_PCM_TRIGGER_SUSPEND:
        if (chip->alsa_ops->stop_interrupts) {
            err = chip->alsa_ops->stop_interrupts(chip->aes67_mgr, stream->stream_handle);
            if (err < 0) return err;
        }
        return 0;
    default:
        return -EINVAL;
    }
}
 
static int fusion_aes67_pcm_hw_params(struct snd_pcm_substream *substream, struct snd_pcm_hw_params *params)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned int rate = params_rate(params);
    snd_pcm_format_t format = params_format(params);
    unsigned int channels = params_channels(params);
    unsigned int period_size = params_period_size(params);
    unsigned int buffer_bytes = params_buffer_bytes(params);
    int err;

    spin_lock_irq(&stream->lock);
    if (stream->rate != rate || stream->format != format || stream->channels != channels) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: params mismatch for handle %llu: rate=%u/%u, format=%d/%d, channels=%u/%u\n",
               stream->stream_handle, rate, stream->rate, format, stream->format, channels, stream->channels);
        spin_unlock_irq(&stream->lock);
        return -EINVAL;
    }

    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &g_constraints_rates);
    if (err < 0) return err;
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &g_constraints_period_sizes);
    if (err < 0) return err;
    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) return err;

    if (buffer_bytes > fusion_aes67_pcm_hw.buffer_bytes_max ||
        period_size < fusion_aes67_pcm_hw.period_bytes_min / (channels * stream->stride) ||
        period_size > fusion_aes67_pcm_hw.period_bytes_max / (channels * stream->stride)) {
        spin_unlock_irq(&stream->lock);
        return -EINVAL;
    }

    runtime->buffer_size = buffer_bytes / (stream->stride * stream->channels);
    runtime->period_size = period_size;
    runtime->periods = buffer_bytes / (period_size * stream->stride * stream->channels);

    if (runtime->access & (SNDRV_PCM_ACCESS_MMAP_INTERLEAVED | SNDRV_PCM_ACCESS_MMAP_NONINTERLEAVED | SNDRV_PCM_ACCESS_MMAP_COMPLEX)) {
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
        err = fusion_snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
#else
        err = snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
#endif
        if (err < 0) {
            spin_unlock_irq(&stream->lock);
            return err;
        }
        stream->pcm_indirect.hw_buffer_size = buffer_bytes;
        stream->pcm_indirect.sw_buffer_size = buffer_bytes;
        atomic_set(&stream->dma_offset, 0);
    } // No allocation for RW - uses stream->buffer directly

    spin_unlock_irq(&stream->lock);
    return 0;
}
 
static struct snd_pcm_ops fusion_aes67_pcm_ops = {
    .open = fusion_aes67_pcm_open,
    .close = fusion_aes67_pcm_close,
    .hw_params = fusion_aes67_pcm_hw_params,
    .hw_free = fusion_aes67_pcm_hw_free,
    .prepare = fusion_aes67_pcm_prepare,
    .trigger = fusion_aes67_pcm_trigger,
    .pointer = fusion_aes67_pcm_pointer,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
    .copy = fusion_aes67_pcm_copy_iter,
    .fill_silence = fusion_aes67_pcm_fill_silence,
#elif LINUX_VERSION_CODE >= KERNEL_VERSION(4,13,0)
    .copy_user = fusion_aes67_pcm_copy_user,
    .fill_silence = fusion_aes67_pcm_fill_silence,
#else
    .copy = fusion_aes67_pcm_copy,
    .silence = fusion_aes67_pcm_silence,
#endif
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
    .page = fusion_snd_pcm_lib_get_vmalloc_page,
#else
    .page = snd_pcm_lib_get_vmalloc_page,
#endif
    .ack = fusion_aes67_pcm_ack,
};

static int fusion_aes67_chip_probe(struct platform_device *pdev)
{
    struct fusion_aes67_chip *chip;
    struct snd_card *card;
    int err;

    err = snd_card_new(&pdev->dev, SNDRV_DEFAULT_IDX1, "FusionAES67",
                    THIS_MODULE, sizeof(struct fusion_aes67_chip), &card);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to create FusionAES67 card: %d\n", err);
        return err;
    }

    chip = card->private_data;
    chip->card = card;
    chip->pdev = pdev;
    chip->aes67_mgr = g_aes67_mgr;
    chip->alsa_ops = g_alsa_ops;

    spin_lock_init(&chip->lock);
    INIT_LIST_HEAD(&chip->streams);

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
    strscpy(card->driver, "FusionAES67", sizeof(card->driver));
    strscpy(card->shortname, "FusionAES67", sizeof(card->shortname));
#else
    strlcpy(card->driver, "FusionAES67", sizeof(card->driver));
    strlcpy(card->shortname, "FusionAES67", sizeof(card->shortname));
#endif
    strlcat(card->longname, "Fusion AES67 Audio-over-IP", sizeof(card->longname));
    snd_card_set_dev(card, &pdev->dev);

    err = snd_card_register(card);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to register card: %d\n", err);
        snd_card_free(card);
        return err;
    }

    platform_set_drvdata(pdev, card);
    dev_info(&pdev->dev, "FusionAES67 card registered successfully\n");
    return 0;
}

static int fusion_aes67_chip_remove(struct platform_device *pdev)
{
    struct snd_card *card = platform_get_drvdata(pdev);
    struct fusion_aes67_chip *chip = card->private_data;
    struct fusion_aes67_substream *stream, *tmp;

    if (chip) {
        spin_lock_irq(&chip->lock);
        list_for_each_entry_safe(stream, tmp, &chip->streams, list) {
            if (stream->pcm) snd_pcm_free(stream->pcm);
            vfree(stream->buffer);
            list_del(&stream->list);
            kfree(stream);
        }
        spin_unlock_irq(&chip->lock);
    }
    snd_card_free(card);
    platform_set_drvdata(pdev, NULL);
    dev_info(&pdev->dev, "FusionAES67 card removed\n");
    return 0;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
static void fusion_aes67_chip_remove_void(struct platform_device *pdev)
{
    fusion_aes67_chip_remove(pdev);
}
#endif

static struct platform_driver fusion_aes67_driver = {
    .probe = fusion_aes67_chip_probe,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
    .remove = fusion_aes67_chip_remove_void,
#else
    .remove = fusion_aes67_chip_remove,
#endif
    .driver = {
        .name = "snd_fusion_aes67"
    },
};

int fusion_aes67_card_init(void *aes67_mgr, struct fusion_aes67_alsa_ops *callbacks)
{
    struct platform_device *pdev = NULL;
    int err;

    g_aes67_mgr = aes67_mgr;
    g_alsa_ops = callbacks;

    err = platform_driver_register(&fusion_aes67_driver);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_card_init: platform_driver_register failed: %d\n", err);
        return err;
    }

    pdev = platform_device_register_simple("snd_fusion_aes67", 0, NULL, 0);
    if (IS_ERR(pdev)) {
        err = PTR_ERR(pdev);
        printk(KERN_ERR "fusion_aes67_card_init: platform_device_register_simple failed: %d\n", err);
        platform_driver_unregister(&fusion_aes67_driver);
        return err;
    }

    g_pdev = pdev;
    return 0;
}

void fusion_aes67_card_exit(void)
{
    printk(KERN_INFO "entering fusion_aes67_card_exit..\n");
    platform_device_unregister(g_pdev);
    platform_driver_unregister(&fusion_aes67_driver);
    printk(KERN_INFO "leaving fusion_aes67_card_exit..\n");
}

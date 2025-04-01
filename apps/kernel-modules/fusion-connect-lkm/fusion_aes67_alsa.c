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
#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>

#include "fusion_aes67_alsa.h"

#define FUSION_AES67_NUM_CHANNELS_MAX 32
#define FUSION_AES67_RINGBUFFER_NUM_FRAMES 1024
#define MAX_STREAMS 32  // Maximum number of RTP streams; adjustable based on system constraints

static void *g_aes67_mgr;
static struct fusion_aes67_alsa_ops *g_alsa_ops;
static struct platform_device *g_pdev;

/**
 * struct fusion_aes67_substream - Per-RTP-stream substream context
 * @substream: ALSA PCM substream pointer
 * @buffer: Ring buffer for this stream’s audio data (non-interleaved)
 * @buffer_pos: Current position in the ring buffer (in samples, channel-independent)
 * @alsa_sac: Sample accumulator for ALSA frames processed
 * @format: PCM format (e.g., SNDRV_PCM_FORMAT_S24_LE, SNDRV_PCM_FORMAT_FLOAT_LE)
 * @stride: Bytes per sample (e.g., 2 for S16_LE, 4 for S32_LE)
 * @rate: Sample rate in Hz (e.g., 44100, 96000)
 * @channels: Number of channels in this stream
 * @rtp_frame_size: Samples per RTP packet (e.g., 6, 12, 16, 192 at 48 kHz)
 * @interrupts_per_period: Number of interrupts per ALSA period
 * @interrupt_idx: Current interrupt counter (0 to interrupts_per_period - 1)
 * @dma_offset: Atomic offset for MMAP buffer tracking (in bytes)
 * @pcm_indirect: Indirect buffer management for MMAP
 * @lock: Spinlock for thread-safe access to this substream
 * @stream_handle: Unique identifier linking to an RTP stream from the manager
 */
struct fusion_aes67_substream {
    struct snd_pcm_substream *substream;
    unsigned char *buffer;          // Allocated per substream, sized for channels and frames
    uint32_t buffer_pos;            // Updated by interrupts and copy operations
    uint64_t alsa_sac;              // Tracks total samples processed for ALSA
    snd_pcm_format_t format;        // Set in hw_params
    uint32_t stride;                // Derived from format
    uint32_t rate;                  // Set in hw_params
    uint32_t channels;              // Set in hw_params
    uint32_t rtp_frame_size;        // Set in prepare, from manager
    uint32_t interrupts_per_period; // Calculated in prepare
    uint32_t interrupt_idx;         // Reset in prepare, incremented in interrupt
    atomic_t dma_offset;            // For MMAP buffer position
    struct snd_pcm_indirect pcm_indirect; // For MMAP buffer management
    spinlock_t lock;                // Protects buffer_pos, dma_offset, interrupt_idx
    uint64_t stream_handle;         // Assigned by manager to link to RTP stream
};

/**
 * struct fusion_aes67_chip - Main driver context for Fusion AES67
 * @aes67_mgr: Pointer to the AES67 manager instance
 * @alsa_ops: Callbacks to interact with the manager
 * @lock: Global lock for chip-level operations (e.g., stream addition/removal)
 * @playback_streams: Array of playback substream pointers
 * @capture_streams: Array of capture substream pointers
 * @num_playback_streams: Current number of active playback streams
 * @num_capture_streams: Current number of active capture streams
 * @pdev: Platform device for this driver
 * @card: ALSA sound card instance
 * @pcm: ALSA PCM device supporting multiple substreams
 */
struct fusion_aes67_chip {
    void *aes67_mgr;                              // From manager.h
    struct fusion_aes67_alsa_ops *alsa_ops;       // Manager callbacks
    spinlock_t lock;                              // Protects stream arrays and counts
    struct fusion_aes67_substream *playback_streams[MAX_STREAMS]; // Dynamic playback substreams
    struct fusion_aes67_substream *capture_streams[MAX_STREAMS];  // Dynamic capture substreams
    int num_playback_streams;                     // Current count of playback streams
    int num_capture_streams;                      // Current count of capture streams
    struct platform_device *pdev;                 // Platform device reference
    struct snd_card *card;                        // Single card instance
    struct snd_pcm *pcm;                          // PCM device with multiple substreams
};
 
/**
 * PCM hardware constraints (applies to all substreams, adjustable per stream in runtime)
 */
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
    .period_bytes_min = 6 * 1 * 2,  // 0.125 ms @ 48 kHz, 1 channel, 16-bit
    .period_bytes_max = 192 * FUSION_AES67_NUM_CHANNELS_MAX * 4,  // 4 ms @ 48 kHz, 32 channels, 32-bit
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

// Helper function to find substream by handle
static struct fusion_aes67_substream *find_substream_by_handle(struct fusion_aes67_chip *chip,
                                                              uint64_t stream_handle,
                                                              int direction)
{
    struct fusion_aes67_substream **streams = direction ? chip->capture_streams : chip->playback_streams;
    int num_streams = direction ? chip->num_capture_streams : chip->num_playback_streams;
    int i;

    for (i = 0; i < num_streams; i++) {
        if (streams[i] && streams[i]->stream_handle == stream_handle) {
            return streams[i];
        }
    }
    return NULL;
}

/**
 * fusion_aes67_get_playback_buffer - Get playback buffer for a specific stream
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 *
 * Returns the buffer pointer for the specified playback stream.
 */
static void *fusion_aes67_get_playback_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    void *buf;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer: chip is NULL\n");
        return NULL;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 0); // 0 = playback
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer: no playback stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return NULL;
    }

    spin_lock(&stream->lock);
    buf = stream->buffer;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return buf;
}

/**
 * fusion_aes67_get_playback_buffer_size_in_frames - Get playback buffer size
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 *
 * Returns the buffer size in frames (samples per channel).
 */
static uint32_t fusion_aes67_get_playback_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    uint32_t size;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer_size: chip is NULL\n");
        return 0;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 0);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer_size: no playback stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    size = FUSION_AES67_RINGBUFFER_NUM_FRAMES; // Fixed size per channel
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return size;
}

/**
 * fusion_aes67_get_capture_buffer - Get capture buffer for a specific stream
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static void *fusion_aes67_get_capture_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    void *buf;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer: chip is NULL\n");
        return NULL;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 1); // 1 = capture
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer: no capture stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return NULL;
    }

    spin_lock(&stream->lock);
    buf = stream->buffer;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return buf;
}

/**
 * fusion_aes67_get_capture_buffer_size_in_frames - Get capture buffer size
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static uint32_t fusion_aes67_get_capture_buffer_size_in_frames(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    uint32_t size;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer_size: chip is NULL\n");
        return 0;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 1);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer_size: no capture stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    size = FUSION_AES67_RINGBUFFER_NUM_FRAMES;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return size;
}

/**
 * fusion_aes67_lock_playback_buffer - Lock playback buffer for manager access
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static void fusion_aes67_lock_playback_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_lock_playback_buffer: chip is NULL\n");
        return;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 0);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_lock_playback_buffer: no playback stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return;
    }

    spin_lock(&stream->lock); // Nested lock held until unlock
    spin_unlock_irqrestore(&chip->lock, flags);
}

/**
 * fusion_aes67_unlock_playback_buffer - Unlock playback buffer
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static void fusion_aes67_unlock_playback_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_unlock_playback_buffer: chip is NULL\n");
        return;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 0);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_unlock_playback_buffer: no playback stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return;
    }

    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
}

/**
 * fusion_aes67_lock_capture_buffer - Lock capture buffer for manager access
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static void fusion_aes67_lock_capture_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_lock_capture_buffer: chip is NULL\n");
        return;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 1);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_lock_capture_buffer: no capture stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return;
    }

    spin_lock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
}

/**
 * fusion_aes67_unlock_capture_buffer - Unlock capture buffer
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static void fusion_aes67_unlock_capture_buffer(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_unlock_capture_buffer: chip is NULL\n");
        return;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 1);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_unlock_capture_buffer: no capture stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return;
    }

    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);
}

/**
 * fusion_aes67_get_playback_buffer_offset - Get current playback buffer offset
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static uint32_t fusion_aes67_get_playback_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    uint32_t offset;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer_offset: chip is NULL\n");
        return 0;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 0);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_playback_buffer_offset: no playback stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    offset = stream->buffer_pos;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return offset;
}

/**
 * fusion_aes67_get_capture_buffer_offset - Get current capture buffer offset
 * @rawchip: Pointer to fusion_aes67_chip
 * @stream_handle: Unique identifier of the RTP stream
 */
static uint32_t fusion_aes67_get_capture_buffer_offset(void *rawchip, uint64_t stream_handle)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream *stream;
    unsigned long flags;
    uint32_t offset;

    if (!chip) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer_offset: chip is NULL\n");
        return 0;
    }

    spin_lock_irqsave(&chip->lock, flags);
    stream = find_substream_by_handle(chip, stream_handle, 1);
    if (!stream) {
        printk(KERN_ERR "fusion_aes67_get_capture_buffer_offset: no capture stream for handle %llu\n",
               stream_handle);
        spin_unlock_irqrestore(&chip->lock, flags);
        return 0;
    }

    spin_lock(&stream->lock);
    offset = stream->buffer_pos;
    spin_unlock(&stream->lock);
    spin_unlock_irqrestore(&chip->lock, flags);

    return offset;
}

/**
 * fusion_aes67_pcm_interrupt - Handle periodic interrupt for all substreams
 * @rawchip: Pointer to fusion_aes67_chip
 * @direction: 0 for playback, 1 for capture
 *
 * Called by the manager’s PTP-locked clock at the frame rate. Advances each
 * active substream’s buffer position and triggers snd_pcm_period_elapsed when
 * a period is complete, respecting per-stream RTP frame sizes.
 */
static int fusion_aes67_pcm_interrupt(void *rawchip, int direction)
{
    struct fusion_aes67_chip *chip = rawchip;
    struct fusion_aes67_substream **streams = direction ? chip->capture_streams : chip->playback_streams;
    int num_streams = direction ? chip->num_capture_streams : chip->num_playback_streams;
    unsigned long flags;
    int i;

    spin_lock_irqsave(&chip->lock, flags);
    for (i = 0; i < num_streams; i++) {
        struct fusion_aes67_substream *stream = streams[i];
        if (!stream || !stream->substream || !stream->substream->runtime)
            continue;

        spin_lock(&stream->lock);
        if (stream->substream->runtime->status->state != SNDRV_PCM_STATE_RUNNING) {
            spin_unlock(&stream->lock);
            continue;
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
    }
    spin_unlock_irqrestore(&chip->lock, flags);
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
    .get_playback_buffer_offset = fusion_aes67_get_playback_buffer_offset,
    .get_capture_buffer_offset = fusion_aes67_get_capture_buffer_offset,
    .pcm_interrupt = fusion_aes67_pcm_interrupt
};

static int fusion_aes67_pcm_trigger(struct snd_pcm_substream *substream, int cmd)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    int err;

    switch (cmd) {
    case SNDRV_PCM_TRIGGER_START:
    case SNDRV_PCM_TRIGGER_RESUME:
        if (chip->alsa_ops->start_stream_interrupts) {
            err = chip->alsa_ops->start_stream_interrupts(chip->aes67_mgr, stream->stream_handle);
            if (err < 0)
                return err;
        }
        return 0;
    case SNDRV_PCM_TRIGGER_STOP:
    case SNDRV_PCM_TRIGGER_SUSPEND:
        if (chip->alsa_ops->stop_stream_interrupts) {
            err = chip->alsa_ops->stop_stream_interrupts(chip->aes67_mgr, stream->stream_handle);
            if (err < 0)
                return err;
        }
        return 0;
    default:
        return -EINVAL;
    }
}

static int fusion_aes67_pcm_prepare(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

    spin_lock_irq(&stream->lock);
    stream->interrupts_per_period = runtime->period_size / stream->rtp_frame_size;
    if (stream->interrupts_per_period == 0)
        stream->interrupts_per_period = 1;
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

    if (offset >= runtime->buffer_size) {
        offset %= runtime->buffer_size;
    }

    spin_unlock_irq(&stream->lock);
    return offset;
}

/**
 * fusion_aes67_pcm_copy - Copy data between user space and substream buffer
 * @substream: ALSA PCM substream
 * @channel: Channel index (-1 for interleaved)
 * @pos: Position in frames
 * @buf: User-space buffer
 * @count: Number of frames to copy
 *
 * Handles both playback (user to driver) and capture (driver to user) data transfer.
 */
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

    // Validate inputs
    if (pos + count > FUSION_AES67_RINGBUFFER_NUM_FRAMES) {
        printk(KERN_WARNING "fusion_aes67_pcm_copy: pos %lu + count %lu exceeds %u\n",
               pos, count, FUSION_AES67_RINGBUFFER_NUM_FRAMES);
        count = FUSION_AES67_RINGBUFFER_NUM_FRAMES - pos;
    }
    if (count == 0) {
        return 0;
    }
    if (!interleaved && (channel < 0 || channel >= stream->channels)) {
        printk(KERN_ERR "fusion_aes67_pcm_copy: invalid channel %d\n", channel);
        return -EINVAL;
    }

    spin_lock_irq(&stream->lock);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        if (interleaved) {
            // De-interleave from user-space to per-channel buffers
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
            // Direct copy to specific channel
            stream_buf = stream->buffer + channel * buffer_size_per_channel + pos * stream->stride;
            if (copy_from_user(stream_buf, buf, count * stream->stride)) {
                ret = -EFAULT;
                goto unlock;
            }
        }
        stream->alsa_sac += count;
    } else { // Capture
        if (interleaved) {
            // Interleave from per-channel buffers to user-space
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
            // Direct copy from specific channel
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

// Kernel version-specific wrappers
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

/**
 * fusion_aes67_pcm_silence - Fill substream buffer with silence
 * @substream: ALSA PCM substream (playback only)
 * @channel: Channel index (-1 for all channels)
 * @pos: Position in frames
 * @count: Number of frames to silence
 */
static int fusion_aes67_pcm_silence(struct snd_pcm_substream *substream,
                                    int channel, snd_pcm_uframes_t pos,
                                    snd_pcm_uframes_t count)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;
    size_t buffer_size_per_channel = FUSION_AES67_RINGBUFFER_NUM_FRAMES * stream->stride;
    const unsigned char *silence = snd_pcm_format_silence_64(runtime->format);
    unsigned char *stream_buf;

    if (substream->stream != SNDRV_PCM_STREAM_PLAYBACK) {
        return 0; // Silence not applicable for capture
    }

    if (pos + count > FUSION_AES67_RINGBUFFER_NUM_FRAMES) {
        printk(KERN_WARNING "fusion_aes67_pcm_silence: pos %lu + count %lu exceeds %u\n",
               pos, count, FUSION_AES67_RINGBUFFER_NUM_FRAMES);
        count = FUSION_AES67_RINGBUFFER_NUM_FRAMES - pos;
    }
    if (count == 0) {
        return 0;
    }

    spin_lock_irq(&stream->lock);

    if (channel == -1) { // All channels
        for (int ch = 0; ch < stream->channels; ch++) {
            stream_buf = stream->buffer + ch * buffer_size_per_channel + pos * stream->stride;
            for (snd_pcm_uframes_t i = 0; i < count; i++) {
                memcpy(stream_buf + i * stream->stride, silence, stream->stride);
            }
        }
    } else { // Specific channel
        if (channel >= stream->channels) {
            printk(KERN_ERR "fusion_aes67_pcm_silence: invalid channel %d\n", channel);
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

/**
 * fusion_aes67_pcm_ack - Acknowledge processed data for MMAP transfers
 * @substream: ALSA PCM substream
 */
static int fusion_aes67_pcm_ack(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct snd_pcm_runtime *runtime = substream->runtime;

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
// snd_pcm_lib_alloc_vmalloc_buffer() is removed in kernel 6.12
int fusion_snd_pcm_lib_alloc_vmalloc_buffer(struct snd_pcm_substream *substream, size_t size)
{
    struct snd_pcm_runtime *runtime;

    runtime = substream->runtime;
    if (runtime->dma_area) {
        if (runtime->dma_bytes >= size)
            return 0; /* already large enough */
        vfree(runtime->dma_area);
    }
    runtime->dma_area = vzalloc(size);
    if (!runtime->dma_area)
        return -ENOMEM;
    runtime->dma_bytes = size;
    return 1;
}

// snd_pcm_lib_free_vmalloc_buffer() is removed in kernel 6.12
int fusion_snd_pcm_lib_free_vmalloc_buffer(struct snd_pcm_substream *substream)
{
    struct snd_pcm_runtime *runtime;

    runtime = substream->runtime;
    vfree(runtime->dma_area);
    runtime->dma_area = NULL;
    return 0;
}

// snd_pcm_lib_get_vmalloc_page() is removed in kernel 6.1
struct page *fusion_snd_pcm_lib_get_vmalloc_page(struct snd_pcm_substream *substream, unsigned long offset)
{
    return vmalloc_to_page(substream->runtime->dma_area + offset);
}
#endif

static int fusion_aes67_pcm_hw_free(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    int err;

    printk(KERN_DEBUG "fusion_aes67_pcm_hw_free: substream %s #%d\n",
           substream->name, substream->number);

    spin_lock_irq(&stream->lock);

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
    err = fusion_snd_pcm_lib_free_vmalloc_buffer(substream);
#else
    err = snd_pcm_lib_free_vmalloc_buffer(substream);
#endif
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_free: failed to free runtime buffer: %d\n", err);
    }

    spin_unlock_irq(&stream->lock);
    return err;
}

// PCM Operations (shared for playback and capture, with direction-specific logic)
static int fusion_aes67_pcm_open(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    struct snd_pcm_runtime *runtime = substream->runtime;
    struct fusion_aes67_substream *stream = NULL;
    unsigned long flags;
    int err, i;

    spin_lock_irqsave(&chip->lock, flags);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        if (chip->num_playback_streams >= MAX_STREAMS) {
            err = -EBUSY;
            goto error_unlock;
        }
        for (i = 0; i < MAX_STREAMS; i++) {
            if (!chip->playback_streams[i]->substream) {
                stream = chip->playback_streams[i];
                chip->num_playback_streams++;
                break;
            }
        }
    } else {
        if (chip->num_capture_streams >= MAX_STREAMS) {
            err = -EBUSY;
            goto error_unlock;
        }
        for (i = 0; i < MAX_STREAMS; i++) {
            if (!chip->capture_streams[i]->substream) {
                stream = chip->capture_streams[i];
                chip->num_capture_streams++;
                break;
            }
        }
    }

    if (!stream) {
        err = -EBUSY; // Shouldn’t happen with MAX_STREAMS check, but defensive
        goto error_unlock;
    }

    stream->substream = substream;
    stream->buffer = vmalloc(fusion_aes67_pcm_hw.buffer_bytes_max);
    if (!stream->buffer) {
        err = -ENOMEM;
        goto error_cleanup;
    }

    err = chip->alsa_ops->assign_stream_handle(chip->aes67_mgr, substream->stream,
                                                &stream->stream_handle);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_open: failed to assign stream handle: %d\n", err);
        goto error_cleanup_buffer;
    }

    err = chip->alsa_ops->get_rtp_frame_size_per_stream(chip->aes67_mgr, stream->stream_handle,
                                                        &stream->rtp_frame_size);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_open: failed to get RTP frame size: %d\n", err);
        goto error_cleanup_buffer;
    }

    runtime->hw = fusion_aes67_pcm_hw;
    runtime->private_data = stream;
    spin_unlock_irqrestore(&chip->lock, flags);
    return 0;

error_cleanup_buffer:
    vfree(stream->buffer);
error_cleanup:
    stream->substream = NULL;
    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
        chip->num_playback_streams--;
    else
        chip->num_capture_streams--;
error_unlock:
    spin_unlock_irqrestore(&chip->lock, flags);
    return err;
}

static int fusion_aes67_pcm_close(struct snd_pcm_substream *substream)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    unsigned long flags;

    printk(KERN_DEBUG "fusion_aes67_pcm_close: substream %s #%d\n",
           substream->name, substream->number);

    spin_lock_irqsave(&chip->lock, flags);

    if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
        int i;
        for (i = 0; i < chip->num_playback_streams; i++) {
            if (chip->playback_streams[i] == stream) {
                vfree(stream->buffer);
                stream->buffer = NULL;
                stream->substream = NULL;
                stream->stream_handle = 0;
                chip->num_playback_streams--;
                // Move last entry to fill gap
                if (i < chip->num_playback_streams) {
                    chip->playback_streams[i] = chip->playback_streams[chip->num_playback_streams];
                }
                chip->playback_streams[chip->num_playback_streams] = stream; // Keep preallocated
                break;
            }
        }
        if (i == chip->num_playback_streams) {
            printk(KERN_WARNING "fusion_aes67_pcm_close: playback stream not found\n");
        }
    } else {
        int i;
        for (i = 0; i < chip->num_capture_streams; i++) {
            if (chip->capture_streams[i] == stream) {
                vfree(stream->buffer);
                stream->buffer = NULL;
                stream->substream = NULL;
                stream->stream_handle = 0;
                chip->num_capture_streams--;
                if (i < chip->num_capture_streams) {
                    chip->capture_streams[i] = chip->capture_streams[chip->num_capture_streams];
                }
                chip->capture_streams[chip->num_capture_streams] = stream;
                break;
            }
        }
        if (i == chip->num_capture_streams) {
            printk(KERN_WARNING "fusion_aes67_pcm_close: capture stream not found\n");
        }
    }

    spin_unlock_irqsave(&chip->lock, flags);
    return 0;
}

static int fusion_aes67_pcm_hw_params(struct snd_pcm_substream *substream,
                                      struct snd_pcm_hw_params *params)
{
    struct fusion_aes67_substream *stream = substream->runtime->private_data;
    struct fusion_aes67_chip *chip = snd_pcm_substream_chip(substream);
    struct snd_pcm_runtime *runtime = substream->runtime;
    unsigned int rate = params_rate(params);
    snd_pcm_format_t format = params_format(params);
    unsigned int channels = params_channels(params);
    unsigned int period_size = params_period_size(params);
    unsigned int buffer_bytes = params_buffer_bytes(params);
    int err;

    printk(KERN_DEBUG "fusion_aes67_pcm_hw_params: substream %s #%d, rate=%u, format=%d, channels=%u, period_size=%u, buffer_bytes=%u\n",
           substream->name, substream->number, rate, format, channels, period_size, buffer_bytes);

    /* Enforce hardware constraints */
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_RATE, &g_constraints_rates);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: failed to set rate constraint: %d\n", err);
        return err;
    }
    err = snd_pcm_hw_constraint_list(runtime, 0, SNDRV_PCM_HW_PARAM_PERIOD_SIZE, &g_constraints_period_sizes);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: failed to set period size constraint: %d\n", err);
        return err;
    }
    err = snd_pcm_hw_constraint_integer(runtime, SNDRV_PCM_HW_PARAM_PERIODS);
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: failed to set integer periods constraint: %d\n", err);
        return err;
    }

    /* Validate parameters against hardware constraints */
    if (rate < fusion_aes67_pcm_hw.rate_min || rate > fusion_aes67_pcm_hw.rate_max ||
        !(fusion_aes67_pcm_hw.rates & snd_pcm_rate_to_rate_bit(rate))) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: unsupported rate %u\n", rate);
        return -EINVAL;
    }
    if (!(fusion_aes67_pcm_hw.formats & (1ULL << format))) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: unsupported format %d\n", format);
        return -EINVAL;
    }
    if (channels < fusion_aes67_pcm_hw.channels_min || channels > fusion_aes67_pcm_hw.channels_max) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: invalid channel count %u\n", channels);
        return -EINVAL;
    }
    if (buffer_bytes > fusion_aes67_pcm_hw.buffer_bytes_max ||
        period_size < fusion_aes67_pcm_hw.period_bytes_min / (channels * snd_pcm_format_physical_width(format) >> 3) ||
        period_size > fusion_aes67_pcm_hw.period_bytes_max / (channels * snd_pcm_format_physical_width(format) >> 3)) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: invalid buffer/period size: buffer=%u, period=%u\n",
               buffer_bytes, period_size);
        return -EINVAL;
    }

    spin_lock_irq(&stream->lock);

    /* Configure stream parameters */
    stream->rate = rate;
    stream->format = format;
    stream->stride = snd_pcm_format_physical_width(format) >> 3;
    stream->channels = channels;

    /* Allocate ALSA runtime buffer for MMAP */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
    err = fusion_snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
#else
    err = snd_pcm_lib_alloc_vmalloc_buffer(substream, buffer_bytes);
#endif
    if (err < 0) {
        printk(KERN_ERR "fusion_aes67_pcm_hw_params: failed to allocate runtime buffer: %d\n", err);
        spin_unlock_irq(&stream->lock);
        return err;
    }

    /* Update runtime fields */
    runtime->buffer_size = buffer_bytes / (stream->stride * stream->channels);
    runtime->period_size = period_size;
    runtime->periods = buffer_bytes / (period_size * stream->stride * stream->channels);
    stream->pcm_indirect.hw_buffer_size = buffer_bytes;
    stream->pcm_indirect.sw_buffer_size = buffer_bytes;
    atomic_set(&stream->dma_offset, 0);

    /* Notify manager of stream-specific parameters (per-stream callback) */
    if (chip->alsa_ops->set_stream_params) {
        err = chip->alsa_ops->set_stream_params(chip->aes67_mgr, stream->stream_handle, rate, channels, format);
        if (err < 0) {
            printk(KERN_ERR "fusion_aes67_pcm_hw_params: set_stream_params failed for handle %llu: %d\n",
                   stream->stream_handle, err);
            goto error_free;
        }
    } else if (chip->alsa_ops->set_sample_rate) {
        /* Fallback to global rate if per-stream callback isn’t available */
        err = chip->alsa_ops->set_sample_rate(chip->aes67_mgr, rate);
        if (err < 0) {
            printk(KERN_ERR "fusion_aes67_pcm_hw_params: set_sample_rate failed: %d\n", err);
            goto error_free;
        }
    }

    spin_unlock_irq(&stream->lock);
    return 0;

error_free:
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,12,0)
    fusion_snd_pcm_lib_free_vmalloc_buffer(substream);
#else
    snd_pcm_lib_free_vmalloc_buffer(substream);
#endif
    spin_unlock_irq(&stream->lock);
    return err;
}

// Updated PCM ops structure
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
    int err, i;

    /* Create sound card with chip as private data */
    err = snd_card_new(&pdev->dev, SNDRV_DEFAULT_IDX1, "FusionAES67",
                       THIS_MODULE, sizeof(struct fusion_aes67_chip), &card);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to create FusionAES67 card: %d\n", err);
        return err;
    }

    chip = card->private_data;
    chip->card = card;
    chip->pdev = pdev;
    chip->aes67_mgr = g_aes67_mgr;  /* Set from global, passed via fusion_aes67_card_init */
    chip->alsa_ops = g_alsa_ops;

    /* Initialize chip structure */
    spin_lock_init(&chip->lock);
    chip->num_playback_streams = 0;
    chip->num_capture_streams = 0;

    /* Create PCM device with multiple substreams */
    err = snd_pcm_new(card, "FusionAES67", 0, MAX_STREAMS, MAX_STREAMS, &chip->pcm);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to create PCM device: %d\n", err);
        goto error_free_card;
    }

    chip->pcm->private_data = chip;
    strscpy(chip->pcm->name, "Fusion AES67 PCM", SNDRV_PCM_NAME_MAX);
    snd_pcm_set_ops(chip->pcm, SNDRV_PCM_STREAM_PLAYBACK, &fusion_aes67_pcm_ops);
    snd_pcm_set_ops(chip->pcm, SNDRV_PCM_STREAM_CAPTURE, &fusion_aes67_pcm_ops);

    /* Preallocate substream structures */
    for (i = 0; i < MAX_STREAMS; i++) {
        chip->playback_streams[i] = kzalloc(sizeof(struct fusion_aes67_substream), GFP_KERNEL);
        if (!chip->playback_streams[i]) {
            dev_err(&pdev->dev, "Failed to allocate playback stream %d\n", i);
            err = -ENOMEM;
            goto error_free_substreams;
        }
        spin_lock_init(&chip->playback_streams[i]->lock);

        chip->capture_streams[i] = kzalloc(sizeof(struct fusion_aes67_substream), GFP_KERNEL);
        if (!chip->capture_streams[i]) {
            dev_err(&pdev->dev, "Failed to allocate capture stream %d\n", i);
            err = -ENOMEM;
            goto error_free_substreams;
        }
        spin_lock_init(&chip->capture_streams[i]->lock);
    }

    /* Register manager ops */
    if (chip->alsa_ops && chip->alsa_ops->set_mgr_ops) {
        err = chip->alsa_ops->set_mgr_ops(chip->aes67_mgr, &g_mgr_ops);
        if (err < 0) {
            dev_err(&pdev->dev, "Failed to register manager ops: %d\n", err);
            goto error_free_substreams;
        }
    } else {
        dev_warn(&pdev->dev, "Manager ops not fully initialized (mgr=%p, ops=%p)\n",
                 chip->aes67_mgr, chip->alsa_ops);
    }

    /* Update period size constraints from manager */
    if (chip->alsa_ops && chip->alsa_ops->get_min_interrupts_frame_size) {
        uint32_t rtp_frame_size_min;
        err = chip->alsa_ops->get_min_interrupts_frame_size(chip->aes67_mgr, &rtp_frame_size_min);
        if (err == 0) {
            for (i = 0; i < ARRAY_SIZE(g_supported_period_sizes); i++) {
                g_supported_period_sizes[i] = min(rtp_frame_size_min << i, FUSION_AES67_RINGBUFFER_NUM_FRAMES);
            }
        } else {
            dev_warn(&pdev->dev, "Failed to get min RTP frame size: %d, using defaults\n", err);
        }
    }

    /* Set card identification */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,6,0)
    strscpy(card->driver, "FusionAES67", sizeof(card->driver));
    strscpy(card->shortname, "FusionAES67", sizeof(card->shortname));
#else
    strlcpy(card->driver, "FusionAES67", sizeof(card->driver));
    strlcpy(card->shortname, "FusionAES67", sizeof(card->shortname));
#endif
    strlcat(card->longname, "Fusion AES67 Audio-over-IP", sizeof(card->longname));
    snd_card_set_dev(card, &pdev->dev);

    /* Register card */
    err = snd_card_register(card);
    if (err < 0) {
        dev_err(&pdev->dev, "Failed to register card: %d\n", err);
        goto error_free_substreams;
    }

    platform_set_drvdata(pdev, card);
    dev_info(&pdev->dev, "FusionAES67 card registered successfully\n");
    return 0;

error_free_substreams:
    for (i = 0; i < MAX_STREAMS; i++) {
        kfree(chip->playback_streams[i]);
        kfree(chip->capture_streams[i]);
    }
error_free_card:
    snd_card_free(card);
    return err;
}

static int fusion_aes67_chip_remove(struct platform_device *pdev)
{
    struct snd_card *card = platform_get_drvdata(pdev);
    struct fusion_aes67_chip *chip = card->private_data;
    int i;

    if (chip) {
        for (i = 0; i < MAX_STREAMS; i++) {
            kfree(chip->playback_streams[i]);
            kfree(chip->capture_streams[i]);
        }
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
    .probe      = fusion_aes67_chip_probe,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
    .remove     = fusion_aes67_chip_remove_void,
#else
    .remove     = fusion_aes67_chip_remove,
#endif
    .driver     = {
        .name   = "snd_fusion_aes67"
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

static void fusion_aes67_unregister_all(void)
{
	// platform device unregister
	platform_device_unregister(g_pdev);
    platform_driver_unregister(&fusion_aes67_driver);
}

// exit point: should be called by module exit
void fusion_aes67_card_exit(void)
{
    printk(KERN_INFO "entering fusion_aes67_card_exit..\n" );
    fusion_aes67_unregister_all();

    printk(KERN_INFO "leaving fusion_aes67_card_exit..\n");
}

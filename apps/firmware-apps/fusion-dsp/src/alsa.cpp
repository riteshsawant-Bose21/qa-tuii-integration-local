
#include "asrc.h"
#include "servo.h"

#include <bosepro/algorithm.h>
#include <bosepro/audio_task.h>
#include <bosepro/dspmemory.h>

#include <alsa/asoundlib.h>
#include <pthread.h>
#include <samplerate.h>
#include <spdlog/spdlog.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>
#include <vector>


namespace {

class AlsaDevice {
public:
    /// Constructor for the ALSA device.
    ///
    /// @param  device_name  The name of the ALSA device to open.
    /// @param  channels     The number of channels to use.
    /// @param  sample_rate  The sample rate of the device.
    /// @param  period_size  The size of the period in samples.
    /// @param  max_transfer_size  The maximum number of samples to transfer.
    /// @param  is_input     True for an input device, false for an output.
    AlsaDevice(const std::string &device_name, int channels,
               int_fast32_t sample_rate, int period_size,
               int max_transfer_size, bool is_input);

    ~AlsaDevice();


    /// Get the buffer depth of this device, in samples.
    ///
    /// @return  The buffer depth.
    int get_buffer_depth();


    int get_buffer_size();


    /// Adjust the buffer depth of this device by the given number of samples.
    /// This can be used to increase or decrease the buffer depth to match the
    /// desired target depth.
    ///
    /// @param  samples  The number of samples to adjust the buffer depth by.
    /// @return  The new buffer depth.
    int adjust_buffer_depth(int samples);


    /// Read the given number of samples from the ALSA device into the given
    /// buffer.  The buffer should be large enough to hold the requested number
    /// of samples, and should be interleaved with the number of channels
    /// specified in the constructor.
    ///
    /// @param  buffer  Pointer to the buffer to read into.
    /// @param  samples  The number of samples to read.
    /// @return  The number of samples actually read.
    int read(float *buffer, int samples);


    /// Write the given number of samples to the ALSA device from the given
    /// buffer.  The buffer should be large enough to hold the requested number
    /// of samples, and should be interleaved with the number of channels
    /// specified in the constructor.
    ///
    /// @param  buffer  Pointer to the buffer to write from.
    /// @param  samples  The number of samples to write.
    void write(const float *buffer, int samples);


    /// Called by the deferred_open_task to open the ALSA device if it is not
    /// immediately available when the block is initialized.
    static void deferred_open(void *obj);

private:
    typedef struct {
        snd_pcm_format_t format;
        int bytes_per_sample;
        void (*convert_read)(const uint8_t *src, float *dst,
                             int channels, int samples);
        void (*convert_write)(const float *src, uint8_t *dst,
                              int channels, int samples);
    } AlsaFormat;

    typedef enum {
        DEVICE_STATE_CLOSED,
        DEVICE_STATE_IDLE,
        DEVICE_STATE_STREAMING,
        DEVICE_STATE_UNKNOWN,
    } State;

    static void convert_read_float_le(const uint8_t *src, float *dst,
                                      int channels, int samples);
    static void convert_write_float_le(const float *src, uint8_t *dst,
                                       int channels, int samples);
    static void convert_read_float_be(const uint8_t *src, float *dst,
                                      int channels, int samples);
    static void convert_write_float_be(const float *src, uint8_t *dst,
                                       int channels, int samples);
    static void convert_read_s32_le(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s32_le(const float *src, uint8_t *dst,
                                     int channels, int samples);
    static void convert_read_s32_be(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s32_be(const float *src, uint8_t *dst,
                                     int channels, int samples);
    static void convert_read_s24_le(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s24_le(const float *src, uint8_t *dst,
                                     int channels, int samples);
    static void convert_read_s24_be(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s24_be(const float *src, uint8_t *dst,
                                     int channels, int samples);
    static void convert_read_s24_3le(const uint8_t *src, float *dst,
                                     int channels, int samples);
    static void convert_write_s24_3le(const float *src, uint8_t *dst,
                                      int channels, int samples);
    static void convert_read_s24_3be(const uint8_t *src, float *dst,
                                     int channels, int samples);
    static void convert_write_s24_3be(const float *src, uint8_t *dst,
                                      int channels, int samples);
    static void convert_read_s16_le(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s16_le(const float *src, uint8_t *dst,
                                     int channels, int samples);
    static void convert_read_s16_be(const uint8_t *src, float *dst,
                                    int channels, int samples);
    static void convert_write_s16_be(const float *src, uint8_t *dst,
                                     int channels, int samples);

    snd_pcm_t *alsa;
    int channels;
    int_fast32_t sample_rate;
    int period_size;
    int max_transfer_size;
    snd_pcm_hw_params_t *hw_params;
    snd_pcm_sw_params_t *sw_params;
    bosepro::DspTempMemory<uint8_t []> sample_buffer;
    static std::vector<AlsaFormat> alsa_formats;
    std::string device_name;
    bool is_input;
    int playback_start_threshold_frames;
    State current_state = DEVICE_STATE_CLOSED;
    snd_pcm_uframes_t negotiated_buffer_size = 0;
    bosepro::AudioSubtask deferred_open_task;
    static pthread_mutex_t open_mutex;

    void (*convert_read)(const uint8_t *src, float *dst,
                         int channels, int samples) = nullptr;
    void (*convert_write)(const float *src, uint8_t *dst,
                          int channels, int samples) = nullptr;

    void open_device();
    void close_device();
    bool is_open();
    void set_hw_params();
    void set_sw_params();
    int get_device_number(const std::string &name);
};


#define ALSA_DEVICE_SET_STATE(new_state, fmt, ...) \
    do { \
        if ((new_state) != current_state) \
        { \
            current_state = (new_state); \
            SPDLOG_DEBUG(fmt, ##__VA_ARGS__); \
        } \
    } while (0)

std::vector<AlsaDevice::AlsaFormat> AlsaDevice::alsa_formats = {
        {SND_PCM_FORMAT_FLOAT_LE, 4, convert_read_float_le, convert_write_float_le},
        {SND_PCM_FORMAT_FLOAT_BE, 4, convert_read_float_be, convert_write_float_be},
        {SND_PCM_FORMAT_S32_LE, 4, convert_read_s32_le, convert_write_s32_le},
        {SND_PCM_FORMAT_S32_BE, 4, convert_read_s32_be, convert_write_s32_be},
        {SND_PCM_FORMAT_S24_LE, 4, convert_read_s24_le, convert_write_s24_le},
        {SND_PCM_FORMAT_S24_BE, 4, convert_read_s24_be, convert_write_s24_be},
        {SND_PCM_FORMAT_S24_3LE, 3, convert_read_s24_3le, convert_write_s24_3le},
        {SND_PCM_FORMAT_S24_3BE, 3, convert_read_s24_3be, convert_write_s24_3be},
        {SND_PCM_FORMAT_S16_LE, 2, convert_read_s16_le, convert_write_s16_le},
        {SND_PCM_FORMAT_S16_BE, 2, convert_read_s16_be, convert_write_s16_be},
        // Add more formats as needed
};

pthread_mutex_t AlsaDevice::open_mutex = PTHREAD_MUTEX_INITIALIZER;

class AlsaIn : public bosepro::Algorithm {
public:
    AlsaIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspStateMemory<AlsaDevice> device;
    bosepro::DspStateMemory<asrc::Asrc> asrc;
    bosepro::DspStateMemory<servo::Servo> servo;
    bosepro::DspTempMemory<float []> asrc_in_buf;
    bosepro::DspTempMemory<float []> asrc_out_buf;
    bool use_asrc;
    int channels;
    int read_samples;
    int_fast32_t target_depth;
    int_fast32_t max_depth;
    int_fast32_t min_depth;
    double min_ratio;
    double max_ratio;
    double base_ratio;
    static const int_fast32_t MIN_DEPTH = 1024;

    ALGORITHM_DECLARE(AlsaIn);
};

ALGORITHM_REGISTER(AlsaIn, "alsa_in");


class AlsaOut : public bosepro::Algorithm {
public:
    AlsaOut(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspStateMemory<AlsaDevice> device;
    bosepro::DspStateMemory<asrc::Asrc> asrc;
    bosepro::DspStateMemory<servo::Servo> servo;
    bosepro::DspTempMemory<float []> asrc_in_buf;
    bosepro::DspTempMemory<float []> asrc_out_buf;
    bool use_asrc;
    int channels;
    int max_write_samples;
    int_fast32_t target_depth;
    int_fast32_t max_depth;
    int_fast32_t min_depth;
    double min_ratio;
    double max_ratio;
    static const int_fast32_t MIN_DEPTH = 1024;

    ALGORITHM_DECLARE(AlsaOut);
};

ALGORITHM_REGISTER(AlsaOut, "alsa_out");


AlsaDevice::AlsaDevice(const std::string &device_name, int channels,
                       int_fast32_t sample_rate, int period_size,
                       int max_transfer_size, bool is_input)
    : alsa(nullptr), channels(channels), sample_rate(sample_rate),
      period_size(period_size), max_transfer_size(max_transfer_size),
      hw_params(nullptr), sw_params(nullptr), device_name(device_name),
      is_input(is_input),
      playback_start_threshold_frames(period_size),
      deferred_open_task(deferred_open, this, sample_rate, 500 * period_size,
                         period_size)
{
    sample_buffer.resize(channels * max_transfer_size * sizeof(float));
    open_device();
}


AlsaDevice::~AlsaDevice()
{
    close_device();
}


void AlsaDevice::open_device()
{
    pthread_mutex_lock(&open_mutex);

    std::string full_device_name = device_name;

    // If the device name starts with "hw:", it's a full device name that we
    // can open immediately.  If it doesn't, it's the name of a fusion connect
    // stream, and we need to look up its device number first.
    if ((device_name.compare(0, 3, "hw:") != 0)
        && (device_name.compare(0, 9, "bluealsa:") != 0))
    {
        SPDLOG_DEBUG("Getting device number for: {}", device_name);
        int device_number = get_device_number(device_name);

        if (device_number < 0)
        {
            SPDLOG_DEBUG("ALSA device {} not found", device_name);
            pthread_mutex_unlock(&open_mutex);
            return;
        }

        full_device_name = "hw:FusionConnect," + std::to_string(device_number);
    }

    SPDLOG_DEBUG("Opening: {}", full_device_name);
    int error = snd_pcm_open(&alsa, full_device_name.c_str(),
                             is_input ? SND_PCM_STREAM_CAPTURE
                                      : SND_PCM_STREAM_PLAYBACK,
                             SND_PCM_NONBLOCK);

    if (error < 0)
    {
        SPDLOG_DEBUG("Failed to open ALSA device: {}", snd_strerror(error));
        pthread_mutex_unlock(&open_mutex);
        return;
    }

    set_hw_params();
    set_sw_params();

    error = snd_pcm_prepare(alsa);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to prepare ALSA device: {}", snd_strerror(error));
    }

    pthread_mutex_unlock(&open_mutex);

    ALSA_DEVICE_SET_STATE(DEVICE_STATE_STREAMING, "Opened device {}",
                          device_name.c_str());
}


void AlsaDevice::close_device()
{
    if (alsa != nullptr)
    {
        snd_pcm_close(alsa);
    }

    if (hw_params != nullptr)
    {
        snd_pcm_hw_params_free(hw_params);
    }

    if (sw_params != nullptr)
    {
        snd_pcm_sw_params_free(sw_params);
    }

    ALSA_DEVICE_SET_STATE(DEVICE_STATE_CLOSED, "Closed device {}",
                          device_name.c_str());
}


void AlsaDevice::deferred_open(void *obj)
{
    AlsaDevice *device = static_cast<AlsaDevice *>(obj);
    device->open_device();
}


bool AlsaDevice::is_open()
{
    return current_state != DEVICE_STATE_CLOSED;
}


int AlsaDevice::get_buffer_depth()
{
    if (!is_open())
    {
        return -1;
    }

    int depth = snd_pcm_avail(alsa);

    if (depth < 0)
    {
        ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                              "Failed to get {} buffer depth: {}",
                              device_name.c_str(), snd_strerror(depth));
        return 0;
    }

    return depth;
}


int AlsaDevice::get_buffer_size()
{
    return static_cast<int>(negotiated_buffer_size);
}


int AlsaDevice::adjust_buffer_depth(int samples)
{
    if (!is_open())
    {
        return 0;
    }

    SPDLOG_TRACE("Adjusting ALSA buffer depth by {} samples", samples);

    if (samples < 0)
    {
        snd_pcm_sframes_t forwarded = snd_pcm_forward(alsa, -samples);

        if (forwarded < 0)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Failed to forward {} buffer depth: {}",
                                  device_name.c_str(), snd_strerror(forwarded));
            return 0;
        }

        if (forwarded != -samples)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Unexpected samples forwarded for {}: {} vs {}",
                                  device_name.c_str(), forwarded, -samples);
        }
    }
    else
    {
        snd_pcm_sframes_t rewound = snd_pcm_rewind(alsa, samples);

        if (rewound < 0)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Failed to rewind {} buffer depth: {}",
                                  device_name.c_str(), snd_strerror(rewound));
            return 0;
        }

        if (rewound != samples)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Unexpected samples rewound for {}: {} vs {}",
                                  device_name.c_str(), rewound, samples);
        }
    }

    return get_buffer_depth();
}


int AlsaDevice::read(float *buffer, int samples)
{
    if (!is_open())
    {
        deferred_open_task.tick();
        std::memset(buffer, 0, samples * channels * sizeof(float));
        return samples;
    }

    if (samples > max_transfer_size)
    {
        SPDLOG_ERROR("Requested read size {} exceeds maximum {}",
                     samples, max_transfer_size);
        std::memset(buffer, 0, samples * channels * sizeof(float));
        return samples;
    }

    int res = snd_pcm_readi(alsa, sample_buffer.get(), samples);

    if (res == -EAGAIN)
    {
        std::memset(buffer, 0, samples * channels * sizeof(float));
        return samples;
    }

    if (res < 0)
    {
        if (res == -EPIPE)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Capture xrun on {}: {}",
                                  device_name.c_str(), snd_strerror(res));

            if (snd_pcm_prepare(alsa) < 0)
            {
                close_device();
            }

            std::memset(buffer, 0, samples * channels * sizeof(float));
            return samples;
        }

        if (res == -EBADFD || res == -ENODEV)
        {
            close_device();
            std::memset(buffer, 0, samples * channels * sizeof(float));
            return samples;
        }

        ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                              "Unable to read from {}: {}",
                              device_name.c_str(), snd_strerror(res));
        std::memset(buffer, 0, samples * channels * sizeof(float));
        return samples;
    }

    if (res != samples)
    {
        ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                              "Unexpected samples read from {}: {} vs {}",
                              device_name.c_str(), res, samples);

        std::memset(buffer, 0, samples * channels * sizeof(float));
        if (res > 0)
        {
            convert_read(sample_buffer.get(), buffer, channels, res);
        }
        return res;
    }

    ALSA_DEVICE_SET_STATE(DEVICE_STATE_STREAMING,
                          "Device {} resumed reading", device_name.c_str());

    convert_read(sample_buffer.get(), buffer, channels, samples);

    return res;
}


void AlsaDevice::write(const float *buffer, int samples)
{
    if (!is_open())
    {
        deferred_open_task.tick();
        return;
    }

    if (samples > max_transfer_size)
    {
        SPDLOG_ERROR("Requested write size {} exceeds maximum {}",
                     samples, max_transfer_size);
        return;
    }

    convert_write(buffer, sample_buffer.get(), channels, samples);

    int res = snd_pcm_writei(alsa, sample_buffer.get(), samples);

    if (res == -EAGAIN)
    {
        return;
    }

    if (res < 0)
    {
        if (res == -EPIPE)
        {
            ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                                  "Playback xrun on {}: {}",
                                  device_name.c_str(), snd_strerror(res));

            if (snd_pcm_prepare(alsa) < 0)
            {
                close_device();
            }

            return;
        }

        if (res == -EBADFD || res == -ENODEV)
        {
            close_device();
            return;
        }

        ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                              "Unable to write {}: {}",
                              device_name.c_str(), snd_strerror(res));
        return;
    }

    if (res != samples)
    {
        ALSA_DEVICE_SET_STATE(DEVICE_STATE_UNKNOWN,
                              "Unexpected samples written to {}: {} vs {}",
                              device_name.c_str(), res, samples);
        return;
    }

    ALSA_DEVICE_SET_STATE(DEVICE_STATE_STREAMING,
                          "Device {} resumed writing", device_name.c_str());
}


void AlsaDevice::set_hw_params()
{
    int error;

    snd_pcm_hw_params_malloc(&hw_params);

    error = snd_pcm_hw_params_any(alsa, hw_params);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to get ALSA hardware parameters: {}",
                     snd_strerror(error));
    }

    // Choose between non-/interleaved and read/write vs. mmap.
    error = snd_pcm_hw_params_set_access(alsa, hw_params,
            SND_PCM_ACCESS_RW_INTERLEAVED);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA access type: {}",
                    snd_strerror(error));
    }

    // Choose between float, s32, s24, s16, etc.
    for (auto &format : alsa_formats)
    {
        error = snd_pcm_hw_params_set_format(alsa, hw_params, format.format);
        if (error == 0)
        {
            SPDLOG_DEBUG("Using ALSA format: {}",
                         snd_pcm_format_name(format.format));

            convert_read = format.convert_read;
            convert_write = format.convert_write;
            break;
        }
    }

    if (convert_read == nullptr)
    {
        SPDLOG_ERROR("Failed to find ALSA format.");
    }

    // `snd_pcm_hw_params_set_subformat()` can set up to use 20 or 24 bits
    // instead of the full wordlength.  The default is probably fine.

    // Set the exact number of channels to use.
    error = snd_pcm_hw_params_set_channels(alsa, hw_params, channels);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA channels: {}",
                     snd_strerror(error));
    }

    // Set the exact sample rate to use.
    error = snd_pcm_hw_params_set_rate(alsa, hw_params, sample_rate, 0);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA sample rate: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_hw_params_set_rate_resample()` can disable resampling
    // (enabled by default). It may be useful for allowing 44.1 kHz
    // Bluetooth A2DP inputs, but we may want to disable it and use our
    // own resampler, depending on the quality of the ALSA resampler.
    error = snd_pcm_hw_params_set_rate_resample(alsa, hw_params, 0);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to disable ALSA resampling: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_hw_params_set_export_buffer()` allows the buffer to be
    // accessible from "outside".  It's enabled by default (probably fine).

    // `snd_pcm_hw_params_set_period_wakeup()` disables period wakeups,
    // which can only be used with non-blocking access.  They are enabled
    // by default.  Maybe turning them off would reduce CPU load.

    // `snd_pcm_hw_params_set_drain_silence()` causes the output buffer to
    // be filled with zeroes when the stream is drained.  It's enabled by
    // default, which is probably what we want if we ever drain the stream.

    // `snd_pcm_hw_params_set_period_time()` sets the period time in µs.
    // Let's use `snd_pcm_hw_params_set_period_size()` instead.

    // Set the period size in samples.
    error = snd_pcm_hw_params_set_period_size(alsa, hw_params, period_size, 0);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA period size: {}",
                     snd_strerror(error));
    }

    // Set the number of periods in the buffer.
    error = snd_pcm_hw_params_set_periods(alsa, hw_params, 64, 0);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA number of periods: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_hw_params_set_buffer_time()` is redundant given we have set
    // both period_size and num_periods.

    // `snd_pcm_hw_params_set_buffer_size()` is redundant given we have set
    // both period_size and num_periods.

    // Now we apply all of the hardware parameters.
    error = snd_pcm_hw_params(alsa, hw_params);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA hardware parameters: {}",
                     snd_strerror(error));
    }
    else
    {
        snd_pcm_uframes_t actual_buffer_size = 0;
        snd_pcm_uframes_t actual_period_size = 0;
        int dir = 0;

        error = snd_pcm_hw_params_get_buffer_size(hw_params, &actual_buffer_size);
        if (error < 0)
        {
            SPDLOG_ERROR("Failed to get negotiated ALSA buffer size: {}",
                         snd_strerror(error));
        }
        else
        {
            negotiated_buffer_size = actual_buffer_size;
            SPDLOG_DEBUG("Negotiated ALSA buffer size for {}: {} frames",
                         device_name.c_str(), negotiated_buffer_size);
        }

        error = snd_pcm_hw_params_get_period_size(hw_params, &actual_period_size, &dir);
        if (error < 0)
        {
            SPDLOG_ERROR("Failed to get negotiated ALSA period size: {}",
                         snd_strerror(error));
        }
        else
        {
            SPDLOG_DEBUG("Negotiated ALSA period size for {}: {} frames",
                         device_name.c_str(), actual_period_size);
        }
    }
}


void AlsaDevice::set_sw_params()
{
    int error;

    snd_pcm_sw_params_malloc(&sw_params);

    error = snd_pcm_sw_params_current(alsa, sw_params);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to get ALSA software parameters: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_sw_params_set_tstamp_mode()` turns timestamps on or off.
    // For now, we are not using timestamps.

    // `snd_pcm_sw_params_set_tstamp_type()` chooses whether the timestamps
    // reflect time of day, monotonic, or monotonic raw.  For now, we are
    // not using timestamps.

    // Set the minimum available before considered ready to read/write,
    // usually must be a power of two periods.
    error = snd_pcm_sw_params_set_avail_min(alsa, sw_params, 1 * period_size);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA avail min: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_sw_params_set_period_event()` sets a poll/select wakeup
    // event when a period is complete.  We don't use poll or select.

    // Automatically start when buffer fills by at least one period on
    // the capture size, or at least one period is available to write on
    // the playback side.
    error = snd_pcm_sw_params_set_start_threshold(alsa, sw_params,
                                                is_input ? 1 : playback_start_threshold_frames);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA start threshold: {}",
                    snd_strerror(error));
    }

    // Set the threshold above which we enter xrun state.  The -1 setting
    // (really a large positive value since it's unsigned) means to never
    // stop on an xrun?
    error = snd_pcm_sw_params_set_stop_threshold(alsa, sw_params, -1);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA stop threshold: {}",
                     snd_strerror(error));
    }

    // `snd_pcm_sw_params_set_silence_thershold()` when the playback buffer
    // is below the silence threshold, silence is written.

    // `snd_pcm_sw_params_set_silence_size()` sets the amount of silence to
    // write when the playback buffer is below the silence threshold.

    // The JACK tools set `snd_pcm_sw_params_set_xfer_align()` to 1, but
    // that is deprecated.

    error = snd_pcm_sw_params(alsa, sw_params);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA software parameters: {}",
                     snd_strerror(error));
    }
}


int AlsaDevice::get_device_number(const std::string &name)
{
    snd_ctl_t *ctl;

    if (snd_ctl_open(&ctl, "hw:FusionConnect", 0) < 0)
    {
        SPDLOG_DEBUG("Failed to open ALSA control device");
        return -1;
    }

    int device = -1;

    SPDLOG_DEBUG("checking device numbers for: {}", name);
    while (snd_ctl_pcm_next_device(ctl, &device) >= 0 && device >= 0)
    {
        SPDLOG_DEBUG("checking device number {} for: {}", device, name);
        snd_pcm_info_t *info;
        snd_pcm_info_alloca(&info);
        snd_pcm_info_set_device(info, device);
        snd_pcm_info_set_subdevice(info, 0);
        snd_pcm_info_set_stream(info, is_input ? SND_PCM_STREAM_CAPTURE
                : SND_PCM_STREAM_PLAYBACK);

        SPDLOG_DEBUG("getting pcm info for: {}", device);
        if (snd_ctl_pcm_info(ctl, info) < 0)
        {
            SPDLOG_DEBUG("Failed to get ALSA PCM info for device {}", device);
            continue;
        }

        SPDLOG_DEBUG("getting pcm info name for: {}", device);
        if (snd_pcm_info_get_name(info) == name)
        {
            SPDLOG_DEBUG("Found ALSA device: {} {}",
                    snd_pcm_info_get_name(info), device);
            snd_ctl_close(ctl);
            return device;
        }
    }

    SPDLOG_DEBUG("closing control");
    snd_ctl_close(ctl);
    SPDLOG_DEBUG("didn't find device {}", name);
    return -1;
}


void AlsaDevice::convert_read_float_le(const uint8_t *src, float *dst,
                                       int channels, int samples)
{
    const float *src32 = reinterpret_cast<const float *>(src);

    for (int i = 0; i < samples * channels; i++)
    {
        dst[i] = src32[i];
    }
}


void AlsaDevice::convert_write_float_le(const float *src, uint8_t *dst,
                                        int channels, int samples)
{
    float *dst32 = reinterpret_cast<float *>(dst);

    for (int i = 0; i < samples * channels; i++)
    {
        dst32[i] = src[i];
    }
}


void AlsaDevice::convert_read_float_be(const uint8_t *src, float *dst,
                                       int channels, int samples)
{
    union {
        float f;
        uint8_t b[4];
    } src32;

    for (int i = 0; i < samples * channels; i++)
    {
        src32.b[0] = src[i * 4 + 3];
        src32.b[1] = src[i * 4 + 2];
        src32.b[2] = src[i * 4 + 1];
        src32.b[3] = src[i * 4 + 0];
        dst[i] = src32.f;
    }
}


void AlsaDevice::convert_write_float_be(const float *src, uint8_t *dst,
                                        int channels, int samples)
{
    union {
        float f;
        uint8_t b[4];
    } dst32;

    for (int i = 0; i < samples * channels; i++)
    {
        dst32.f = src[i];
        dst[i * 4 + 3] = dst32.b[0];
        dst[i * 4 + 2] = dst32.b[1];
        dst[i * 4 + 1] = dst32.b[2];
        dst[i * 4 + 0] = dst32.b[3];
    }
}


void AlsaDevice::convert_read_s32_le(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    const int32_t *src32 = reinterpret_cast<const int32_t *>(src);

    for (int i = 0; i < samples * channels; i++)
    {
        dst[i] = static_cast<float>(src32[i]) / 2147483648.0f;
    }
}


void AlsaDevice::convert_write_s32_le(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    int32_t *dst32 = reinterpret_cast<int32_t *>(dst);

    for (int i = 0; i < samples * channels; i++)
    {
        dst32[i] = static_cast<int32_t>(src[i] * 2147483648.0f);
    }
}


void AlsaDevice::convert_read_s32_be(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } src32;

    for (int i = 0; i < samples * channels; i++)
    {
        src32.b[0] = src[i * 4 + 3];
        src32.b[1] = src[i * 4 + 2];
        src32.b[2] = src[i * 4 + 1];
        src32.b[3] = src[i * 4 + 0];
        dst[i] = static_cast<float>(src32.i) / 2147483648.0f;
    }
}


void AlsaDevice::convert_write_s32_be(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } dst32;

    for (int i = 0; i < samples * channels; i++)
    {
        dst32.i = static_cast<int32_t>(src[i] * 2147483648.0f);
        dst[i * 4 + 3] = dst32.b[0];
        dst[i * 4 + 2] = dst32.b[1];
        dst[i * 4 + 1] = dst32.b[2];
        dst[i * 4 + 0] = dst32.b[3];
    }
}


void AlsaDevice::convert_read_s24_le(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    const int32_t *src32 = reinterpret_cast<const int32_t *>(src);

    for (int i = 0; i < samples * channels; i++)
    {
        dst[i] = static_cast<float>(src32[i]) / 8388608.0f;
    }
}


void AlsaDevice::convert_write_s24_le(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    int32_t *dst32 = reinterpret_cast<int32_t *>(dst);

    for (int i = 0; i < samples * channels; i++)
    {
        dst32[i] = static_cast<int32_t>(src[i] * 8388608.0f);
    }
}


void AlsaDevice::convert_read_s24_be(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } src32;

    for (int i = 0; i < samples * channels; i++)
    {
        src32.b[0] = src[i * 4 + 3];
        src32.b[1] = src[i * 4 + 2];
        src32.b[2] = src[i * 4 + 1];
        src32.b[3] = src[i * 4 + 0];
        dst[i] = static_cast<float>(src32.i) / 8388608.0f;
    }
}


void AlsaDevice::convert_write_s24_be(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } dst32;

    for (int i = 0; i < samples * channels; i++)
    {
        dst32.i = static_cast<int32_t>(src[i] * 8388608.0f);
        dst[i * 4 + 3] = dst32.b[0];
        dst[i * 4 + 2] = dst32.b[1];
        dst[i * 4 + 1] = dst32.b[2];
        dst[i * 4 + 0] = dst32.b[3];
    }
}


void AlsaDevice::convert_read_s24_3le(const uint8_t *src, float *dst,
                                      int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } src32;

    for (int i = 0; i < samples * channels; i++)
    {
        src32.b[0] = src[i * 3 + 0];
        src32.b[1] = src[i * 3 + 1];
        src32.b[2] = src[i * 3 + 2];
        src32.b[3] = 0;
        dst[i] = static_cast<float>(src32.i) / 2147483648.0f;
    }
}


void AlsaDevice::convert_write_s24_3le(const float *src, uint8_t *dst,
                                       int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } dst32;

    for (int i = 0; i < samples * channels; i++)
    {
        dst32.i = static_cast<int32_t>(src[i] * 2147483648.0f);
        dst[i * 3 + 2] = dst32.b[3];
        dst[i * 3 + 1] = dst32.b[2];
        dst[i * 3 + 0] = dst32.b[1];
    }
}


void AlsaDevice::convert_read_s24_3be(const uint8_t *src, float *dst,
                                      int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } src32;

    for (int i = 0; i < samples * channels; i++)
    {
        src32.b[0] = 0;
        src32.b[1] = src[i * 3 + 2];
        src32.b[2] = src[i * 3 + 1];
        src32.b[3] = src[i * 3 + 0];
        dst[i] = static_cast<float>(src32.i) / 2147483648.0f;
    }
}


void AlsaDevice::convert_write_s24_3be(const float *src, uint8_t *dst,
                                       int channels, int samples)
{
    union {
        int32_t i;
        uint8_t b[4];
    } dst32;

    for (int i = 0; i < samples * channels; i++)
    {
        dst32.i = static_cast<int32_t>(src[i] * 2147483648.0f);
        dst[i * 3 + 2] = dst32.b[1];
        dst[i * 3 + 1] = dst32.b[2];
        dst[i * 3 + 0] = dst32.b[3];
    }
}


void AlsaDevice::convert_read_s16_le(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    const int16_t *src16 = reinterpret_cast<const int16_t *>(src);

    for (int i = 0; i < samples * channels; i++)
    {
        dst[i] = static_cast<float>(src16[i]) / 32768.0f;
    }
}


void AlsaDevice::convert_write_s16_le(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    int16_t *dst16 = reinterpret_cast<int16_t *>(dst);

    for (int i = 0; i < samples * channels; i++)
    {
        dst16[i] = static_cast<int16_t>(src[i] * 32768.0f);
    }
}


void AlsaDevice::convert_read_s16_be(const uint8_t *src, float *dst,
                                     int channels, int samples)
{
    union {
        int16_t i;
        uint8_t b[2];
    } src16;

    for (int i = 0; i < samples * channels; i++)
    {
        src16.b[0] = src[i * 2 + 1];
        src16.b[1] = src[i * 2 + 0];
        dst[i] = static_cast<float>(src16.i) / 32768.0f;
    }
}

void AlsaDevice::convert_write_s16_be(const float *src, uint8_t *dst,
                                      int channels, int samples)
{
    union {
        int16_t i;
        uint8_t b[2];
    } dst16;

    for (int i = 0; i < samples * channels; i++)
    {
        dst16.i = static_cast<int16_t>(src[i] * 32768.0f);
        dst[i * 2 + 1] = dst16.b[0];
        dst[i * 2 + 0] = dst16.b[1];
    }
}


AlsaIn::AlsaIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    std::string device_name;
    int_fast32_t period_size;
    int_fast32_t device_sample_rate;

    get_property("use_asrc", use_asrc);
    get_property("device_name", device_name);
    get_property("period_size", period_size);
    get_property("device_sample_rate", device_sample_rate);

    if (device_sample_rate == 0)
    {
        device_sample_rate = get_sample_rate();
    }

    assign_terminal("out", out);

    get_terminal_num_channels("out", channels);

    if (use_asrc)
    {
        base_ratio = static_cast<double>(get_sample_rate())
            / device_sample_rate;

        read_samples = static_cast<int>(std::ceil(get_frame_size() / base_ratio))
            + 1;

        min_depth = std::max(2 * get_frame_size(), MIN_DEPTH);
        min_depth = std::max(min_depth, 2 * period_size);
        if (min_depth % period_size != 0)
        {
            min_depth += period_size - (min_depth % period_size);
        }

        max_depth = std::max(6 * get_frame_size(), 3 * MIN_DEPTH);
        max_depth = std::max(max_depth, 6 * period_size);
        if (max_depth % period_size != 0)
        {
            max_depth += period_size - (max_depth % period_size);
        }

        target_depth = std::max(4 * get_frame_size(), 2 * MIN_DEPTH);
        target_depth = std::max(target_depth, 4 * period_size);
        if (target_depth % period_size != 0)
        {
            target_depth += period_size - (target_depth % period_size);
        }
    }
    else
    {
        base_ratio = 1.0;
        read_samples = get_frame_size();
        min_depth = std::max(get_frame_size(), period_size);
        max_depth = 3 * min_depth;
        target_depth = 2 * min_depth;
    }

    // The JND for pitch is about 0.6% (or about 10 cents).  We can limit the
    // ratio to be smaller than this to avoid pitch artifacts, while still
    // allowing the servo to correct for reasonable jitter and clock mismatch.
    min_ratio = base_ratio * 0.998;
    max_ratio = base_ratio * 1.002;

    if (use_asrc)
    {
        asrc_in_buf.resize(channels * read_samples);
    }

    asrc_out_buf.resize(channels * get_frame_size());

    new (device.get()) AlsaDevice(device_name, channels, device_sample_rate,
                                  period_size, read_samples, true);

    if (use_asrc)
    {
        new (asrc.get()) asrc::Asrc(channels, get_frame_size(), true);
        new (servo.get()) servo::Servo();
    }
}


void AlsaIn::process()
{
    // Measure the current buffer depth
    int depth = device->get_buffer_depth();

    if (depth <= 0)
    {
        // Pretend everything is operating nominally if the device isn't open
        depth = target_depth;
    }

    // Handle the cases where the buffer depth is way too high or low
    // Perhaps we want to do packet loss concealment here
    if (depth > max_depth || depth < min_depth)
    {
        depth = device->adjust_buffer_depth(target_depth - depth);

        if (use_asrc)
        {
            servo->reset();
        }
    }

    if (use_asrc)
    {
        // Run the servo loop to adjust the sample rate
        double ratio = 1.0 - servo->update(depth - target_depth);
        ratio *= base_ratio;

        ratio = (ratio < min_ratio) ? min_ratio : ratio;
        ratio = (ratio > max_ratio) ? max_ratio : ratio;

        device->read(asrc_in_buf.get(), read_samples);

        // Perform ASRC
        int consumed = asrc->process(asrc_out_buf.get(), asrc_in_buf.get(),
                                     read_samples, ratio);

        // Put back any samples we didn't need for ASRC
        device->adjust_buffer_depth(read_samples - consumed);
    }
    else
    {
        device->read(asrc_out_buf.get(), get_frame_size());
    }

    // Deinterleave to the output buffer
    for (int channel = 0; channel < channels; channel++)
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            out[channel][sample] = asrc_out_buf[sample * channels + channel];
        }
    }
}


AlsaOut::AlsaOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    std::string device_name;
    int_fast32_t period_size;

    get_property("use_asrc", use_asrc);
    get_property("device_name", device_name);
    get_property("period_size", period_size);

    assign_terminal("in", in);

    get_terminal_num_channels("in", channels);

    if (use_asrc)
    {
        max_write_samples = get_frame_size() + 1;

        min_depth = std::max(2 * get_frame_size(), MIN_DEPTH);
        if (min_depth % period_size != 0)
        {
            min_depth += period_size - (min_depth % period_size);
        }

        max_depth = std::max(6 * get_frame_size(), 3 * MIN_DEPTH);
        if (max_depth % period_size != 0)
        {
            max_depth += period_size - (max_depth % period_size);
        }

        target_depth = std::max(4 * get_frame_size(), 2 * MIN_DEPTH);
        if (target_depth % period_size != 0)
        {
            target_depth += period_size - (target_depth % period_size);
        }
    }
    else
    {
        max_write_samples = get_frame_size();
        min_depth = std::max(get_frame_size(), period_size);
        max_depth = 3 * min_depth;
        target_depth = 2 * min_depth;
    }

    // The JND for pitch is about 0.6% (or about 10 cents).  We can limit the
    // ratio to be smaller than this to avoid pitch artifacts, while still
    // allowing the servo to correct for reasonable jitter and clock mismatch.
    min_ratio = 0.998;
    max_ratio = 1.002;

    asrc_in_buf.resize(channels * get_frame_size());

    if (use_asrc)
    {
        asrc_out_buf.resize(channels * max_write_samples);
    }

    new (device.get()) AlsaDevice(device_name, channels, get_sample_rate(),
                                  period_size, max_write_samples, false);

    if (use_asrc)
    {
        new (asrc.get()) asrc::Asrc(channels, get_frame_size(), false);
        new (servo.get()) servo::Servo();
    }
}


void AlsaOut::process()
{
    int avail = device->get_buffer_depth();
    int buffer_size = device->get_buffer_size();
    int depth = buffer_size - avail;
    double ratio;

    if (avail < 0 || buffer_size <= 0)
    {
        depth = target_depth;
    }

    // Handle the cases where the buffer depth is way too high or low
    // Perhaps we want to do packet loss concealment here
    if (depth > max_depth)
    {
        depth = device->adjust_buffer_depth(depth - target_depth);

        if (use_asrc)
        {
            servo->reset();
        }
    }
    else if (depth < min_depth)
    {
        int_fast32_t fill_amount = target_depth - depth;

        while (fill_amount > 0)
        {

            memset(asrc_in_buf.get(), 0,
                   get_frame_size() * channels * sizeof(float));

            device->write(asrc_in_buf.get(),
                          std::min(fill_amount, get_frame_size()));

            fill_amount -= get_frame_size();
        }

        if (use_asrc)
        {
            servo->reset();
        }
    }

    if (use_asrc)
    {
        // Run the servo loop to adjust the sample rate
        ratio = 1.0 - servo->update(target_depth - depth);

        ratio = (ratio < min_ratio) ? min_ratio : ratio;
        ratio = (ratio > max_ratio) ? max_ratio : ratio;
    }

    // Interleave into the ASRC buffer
    for (int channel = 0; channel < channels; channel++)
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            asrc_in_buf[sample * channels + channel] = in[channel][sample];
        }
    }

    if (use_asrc)
    {
        // Perform ASRC
        int produced = asrc->process(asrc_out_buf.get(), asrc_in_buf.get(),
                                     max_write_samples, ratio);

        device->write(asrc_out_buf.get(), produced);
    }
    else
    {
        device->write(asrc_in_buf.get(), get_frame_size());
    }
}


} // namespace


#include "asrc.h"
#include "servo.h"

#include <bosepro/algorithm.h>
#include <bosepro/dspmemory.h>

#include <alsa/asoundlib.h>
#include <samplerate.h>
#include <spdlog/spdlog.h>

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


private:
    snd_pcm_t *alsa;
    int channels;
    int_fast32_t sample_rate;
    int period_size;
    int max_transfer_size;
    snd_pcm_hw_params_t *hw_params;
    snd_pcm_sw_params_t *sw_params;
    bosepro::DspTempMemory<int32_t []> sample_buffer;

    void set_hw_params();
    void set_sw_params();
};


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
    int channels;
    int read_samples;
    int target_depth;
    int max_depth;
    int min_depth;
    double min_ratio;
    double max_ratio;

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
    int channels;
    int max_write_samples;
    int target_depth;
    int max_depth;
    int min_depth;
    double min_ratio;
    double max_ratio;

    ALGORITHM_DECLARE(AlsaOut);
};

ALGORITHM_REGISTER(AlsaOut, "alsa_out");


AlsaDevice::AlsaDevice(const std::string &device_name, int channels,
                       int_fast32_t sample_rate, int period_size,
                       int max_transfer_size, bool is_input)
    : alsa(nullptr), channels(channels), sample_rate(sample_rate),
      period_size(period_size), max_transfer_size(max_transfer_size),
      hw_params(nullptr), sw_params(nullptr)
{
    int error = snd_pcm_open(&alsa, device_name.c_str(),
                             is_input ? SND_PCM_STREAM_CAPTURE
                                      : SND_PCM_STREAM_PLAYBACK,
                             0);

    if (error < 0)
    {
        SPDLOG_ERROR("Failed to open ALSA device: {}", snd_strerror(error));
        throw std::runtime_error("Failed to open ALSA device: "
                + std::string(snd_strerror(error)));
    }

    set_hw_params();
    set_sw_params();

    sample_buffer.resize(channels * max_transfer_size);

    error = snd_pcm_prepare(alsa);
    if (error < 0)
    {
        throw std::runtime_error("Failed to prepare ALSA device: "
                + std::string(snd_strerror(error)));
    }
}


AlsaDevice::~AlsaDevice()
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
}


int AlsaDevice::get_buffer_depth()
{
    int depth = snd_pcm_avail(alsa);

    if (depth < 0)
    {
        SPDLOG_ERROR("Failed to get ALSA buffer depth: {}",
                snd_strerror(depth));
        return 0;
    }

    return depth;
}


int AlsaDevice::adjust_buffer_depth(int samples)
{
    SPDLOG_TRACE("Adjusting ALSA buffer depth by {} samples", samples);

    if (samples < 0)
    {
        snd_pcm_sframes_t forwarded = snd_pcm_forward(alsa, -samples);

        if (forwarded < 0)
        {
            SPDLOG_ERROR("Failed to adjust ALSA buffer depth: {}",
                    snd_strerror(forwarded));
            return 0;
        }

        if (forwarded != -samples)
        {
            SPDLOG_ERROR("Unexpected number of samples forwarded: {}",
                    forwarded);
        }
    }
    else
    {
        snd_pcm_sframes_t rewound = snd_pcm_rewind(alsa, samples);

        if (rewound < 0)
        {
            SPDLOG_ERROR("Failed to adjust ALSA buffer depth: {}",
                    snd_strerror(rewound));
            return 0;
        }

        if (rewound != samples)
        {
            SPDLOG_ERROR("Unexpected number of samples rewound: {}",
                    rewound);
        }
    }

    return get_buffer_depth();
}


int AlsaDevice::read(float *buffer, int samples)
{
    if (samples > max_transfer_size)
    {
        SPDLOG_ERROR("Requested read size {} exceeds maximum {}",
                     samples, max_transfer_size);
        return 0;
    }

    int res = snd_pcm_readi(alsa, sample_buffer.get(), samples);

    if (res < 0)
    {
        SPDLOG_ERROR("Failed to read from ALSA device: {}",
                snd_strerror(res));
        return 0;
    }

    if (res != samples)
    {
        SPDLOG_ERROR("Unexpected number of samples read: {}",
                res);
    }

    for (int i = 0; i < samples * channels; i++)
    {
        buffer[i] = (float)sample_buffer[i] / 2147483648.0f;
    }

    return res;
}


void AlsaDevice::write(const float *buffer, int samples)
{
    if (samples > max_transfer_size)
    {
        SPDLOG_ERROR("Requested write size {} exceeds maximum {}",
                     samples, max_transfer_size);
        return;
    }

    for (int i = 0; i < samples * channels; i++)
    {
        sample_buffer[i] = (int32_t)(buffer[i] * 2147483648.0f);
    }

    int res = snd_pcm_writei(alsa, sample_buffer.get(), samples);

    if (res < 0)
    {
        SPDLOG_ERROR("Failed to write to ALSA device: {}", snd_strerror(res));
    }
    else if (res != samples)
    {
        SPDLOG_ERROR("Unexpected number of samples written: {}", res);
    }
}


void AlsaDevice::set_hw_params()
{
    int error;

    snd_pcm_hw_params_alloca(&hw_params);

    error = snd_pcm_hw_params_any(alsa, hw_params);
    if (error < 0)
    {
        throw std::runtime_error("Failed to get ALSA hardware parameters: "
                + std::string(snd_strerror(error)));
    }

    // Choose between non-/interleaved and read/write vs. mmap.
    error = snd_pcm_hw_params_set_access(alsa, hw_params,
            SND_PCM_ACCESS_RW_INTERLEAVED);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set ALSA access type: "
                + std::string(snd_strerror(error)));
    }

    // Choose between float, s32, s24, s16, etc.
    error = snd_pcm_hw_params_set_format(alsa, hw_params,
            SND_PCM_FORMAT_S32_LE);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA format: {}",
                snd_strerror(error));
        throw std::runtime_error("Failed to set ALSA format: "
                + std::string(snd_strerror(error)));
    }

    // `snd_pcm_hw_params_set_subformat()` can set up to use 20 or 24 bits
    // instead of the full wordlength.  The default is probably fine.

    // Set the exact number of channels to use.
    error = snd_pcm_hw_params_set_channels(alsa, hw_params, channels);
    if (error < 0)
    {
        SPDLOG_ERROR("Failed to set ALSA channels: {}",
                snd_strerror(error));
        throw std::runtime_error("Failed to set ALSA channels: "
                + std::string(snd_strerror(error)));
    }

    // Set the exact sample rate to use.
    error = snd_pcm_hw_params_set_rate(alsa, hw_params, sample_rate, 0);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set ALSA sample rate: "
                + std::string(snd_strerror(error)));
    }

    // `snd_pcm_hw_params_set_rate_resample()` can disable resampling
    // (enabled by default). It may be useful for allowing 44.1 kHz
    // Bluetooth A2DP inputs, but we may want to disable it and use our
    // own resampler, depending on the quality of the ALSA resampler.

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
        throw std::runtime_error("Failed to set ALSA period size: "
                + std::string(snd_strerror(error)));
    }

    // Set the number of periods in the buffer.
    error = snd_pcm_hw_params_set_periods(alsa, hw_params, 8, 0);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set ALSA number of periods: "
                + std::string(snd_strerror(error)));
    }

    // `snd_pcm_hw_params_set_buffer_time()` is redundant given we have set
    // both period_size and num_periods.

    // `snd_pcm_hw_params_set_buffer_size()` is redundant given we have set
    // both period_size and num_periods.

    // Now we apply all of the hardware parameters.
    error = snd_pcm_hw_params(alsa, hw_params);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set ALSA hardware parameters: "
                + std::string(snd_strerror(error)));
    }
}


void AlsaDevice::set_sw_params()
{
    int error;

    snd_pcm_sw_params_alloca(&sw_params);

    error = snd_pcm_sw_params_current(alsa, sw_params);
    if (error < 0)
    {
        throw std::runtime_error("Failed to get software parameters: "
                + std::string(snd_strerror(error)));
    }

    // `snd_pcm_sw_params_set_tstamp_mode()` turns timestamps on or off.
    // For now, we are not using timestamps.

    // `snd_pcm_sw_params_set_tstamp_type()` chooses whether the timestamps
    // reflect time of day, monotonic, or monotonic raw.  For now, we are
    // not using timestamps.

    // Set the minimum available before considered ready to read/write,
    // usually must be a power of two periods.
    error = snd_pcm_sw_params_set_avail_min(alsa, sw_params, 2 * period_size);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set avail min: "
                + std::string(snd_strerror(error)));
    }

    // `snd_pcm_sw_params_set_period_event()` sets a poll/select wakeup
    // event when a period is complete.  We don't use poll or select.

    // Automatically start when buffer fills by at least one period on
    // the capture size, or at least one period is available to write on
    // the playback side.
    error = snd_pcm_sw_params_set_start_threshold(alsa, sw_params, period_size);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set start threshold: "
                + std::string(snd_strerror(error)));
    }

    // Set the threshold above which we enter xrun state.  The -1 setting
    // (really a large positive value since it's unsigned) means to never
    // stop on an xrun?
    error = snd_pcm_sw_params_set_stop_threshold(alsa, sw_params, -1);
    if (error < 0)
    {
        throw std::runtime_error("Failed to set stop threshold: "
                + std::string(snd_strerror(error)));
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
        throw std::runtime_error("Failed to set software parameters: "
                + std::string(snd_strerror(error)));
    }
}


AlsaIn::AlsaIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    std::string device_name;
    int_fast32_t period_size;

    get_property("device_name", device_name);
    get_property("period_size", period_size);

    assign_terminal("out", out);

    get_terminal_num_channels("out", channels);

    read_samples = get_frame_size() + 1;

    min_depth = 2 * period_size;
    max_depth = 6 * period_size;
    target_depth = 4 * period_size;

    // The JND for pitch is about 0.6% (or about 10 cents).  We can limit the
    // ratio to be smaller than this to avoid pitch artifacts, while still
    // allowing the servo to correct for reasonable jitter and clock mismatch.
    min_ratio = 0.999;
    max_ratio = 1.001;

    asrc_in_buf.resize(channels * read_samples);
    asrc_out_buf.resize(channels * get_frame_size());

    new (device.get()) AlsaDevice(device_name, channels, get_sample_rate(),
                                  period_size, read_samples, true);
    new (asrc.get()) asrc::Asrc(channels, get_frame_size(), true);
    new (servo.get()) servo::Servo();
}


void AlsaIn::process()
{
    // Measure the current buffer depth
    int depth = device->get_buffer_depth();

    // Handle the cases where the buffer depth is way too high or low
    // Perhaps we want to do packet loss concealment here
    if (depth > max_depth)
    {
        SPDLOG_WARN("Buffer depth too high: {}", depth);
        depth = device->adjust_buffer_depth(target_depth - depth);

        servo->reset();
    }
    else if (depth < min_depth)
    {
        SPDLOG_WARN("Buffer depth too low: {}", depth);
        depth = device->adjust_buffer_depth(target_depth - depth);

        servo->reset();
    }

    // Run the servo loop to adjust the sample rate
    double ratio = 1.0 - servo->update(depth - target_depth);

    ratio = (ratio < min_ratio) ? min_ratio : ratio;
    ratio = (ratio > max_ratio) ? max_ratio : ratio;

    int actually_read = device->read(asrc_in_buf.get(), read_samples);

    if (actually_read < read_samples)
    {
        SPDLOG_WARN("Only read {} samples, expected {}", actually_read,
                    read_samples);
    }

    // Perform ASRC
    int consumed = asrc->process(asrc_out_buf.get(), asrc_in_buf.get(),
                                 read_samples, ratio);

    // Put back any samples we didn't need for ASRC
    device->adjust_buffer_depth(read_samples - consumed);

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

    get_property("device_name", device_name);
    get_property("period_size", period_size);

    assign_terminal("in", in);

    get_terminal_num_channels("in", channels);

    max_write_samples = get_frame_size() + 1;

    min_depth = 2 * period_size;
    max_depth = 6 * period_size;
    target_depth = 4 * period_size;

    // The JND for pitch is about 0.6% (or about 10 cents).  We can limit the
    // ratio to be smaller than this to avoid pitch artifacts, while still
    // allowing the servo to correct for reasonable jitter and clock mismatch.
    min_ratio = 0.999;
    max_ratio = 1.001;

    asrc_in_buf.resize(channels * get_frame_size());
    asrc_out_buf.resize(channels * max_write_samples);

    new (device.get()) AlsaDevice(device_name, channels, get_sample_rate(),
                                  period_size, max_write_samples, false);
    new (asrc.get()) asrc::Asrc(channels, get_frame_size(), false);
    new (servo.get()) servo::Servo();
}


void AlsaOut::process()
{
    // Measure the current buffer depth
    int depth = device->get_buffer_depth();

    // Handle the cases where the buffer depth is way too high or low
    // Perhaps we want to do packet loss concealment here
    if (depth > max_depth)
    {
        SPDLOG_WARN("Buffer depth too high: {}", depth);
        depth = device->adjust_buffer_depth(target_depth - depth);

        servo->reset();
    }
    else if (depth < min_depth)
    {
        SPDLOG_WARN("Buffer depth too low: {}", depth);
        depth = device->adjust_buffer_depth(target_depth - depth);

        servo->reset();
    }

    // Run the servo loop to adjust the sample rate
    double ratio = 1.0 - servo->update(depth - target_depth);

    ratio = (ratio < min_ratio) ? min_ratio : ratio;
    ratio = (ratio > max_ratio) ? max_ratio : ratio;

    // Interleave into the ASRC buffer
    for (int channel = 0; channel < channels; channel++)
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            asrc_in_buf[sample * channels + channel] = in[channel][sample];
        }
    }

    // Perform ASRC
    int produced = asrc->process(asrc_out_buf.get(), asrc_in_buf.get(),
                                 max_write_samples, ratio);

    device->write(asrc_out_buf.get(), produced);
}


} // namespace

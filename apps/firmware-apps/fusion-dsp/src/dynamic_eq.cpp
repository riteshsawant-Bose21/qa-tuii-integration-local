// Dynamic EQ ported from Raphael

#include "iir.h"

#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>
#include <spdlog/spdlog.h>

#include <cstdint>
#include <cmath>
#include <cstring>
#include <vector>
#include <limits>

namespace {


const float RMS_AVERAGING_TIME_SECONDS = 50.0e-3f;  // 50 msec
const float LOG2_10 = 1.0f / std::log10(2.0f);      // log2(10) == 1/log10(2)


class DynamicEq : public bosepro::Algorithm
{
public:
    DynamicEq(const bosepro::BlockConfiguration &configuration);
    virtual ~DynamicEq() = default;

    virtual void process() override;

private:
    int_fast32_t channels;

    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    bosepro::DspTelemetryMemory<float[]> out_meter;
    bosepro::DspTelemetryMemory<float[]> calibration_spl;

    bosepro::DspCoeffMemory<float[]> input_gain;

    bool calibration_mode;
    bool calibration_hold;
    

    bosepro::DspStateMemory<filter::IirFilter> hpf_filter;
    bosepro::DspStateMemory<filter::IirFilter> lf_filter;
    bosepro::DspStateMemory<filter::IirFilter> hf_filter;
    
    // Temporary signal buffers for filter outputs
    bosepro::DspTempMemory<float*[]> hpf_out;
    bosepro::DspTempMemory<float*[]> lf_out;
    bosepro::DspTempMemory<float*[]> hf_out;
    
    bosepro::DspStateMemory<float[]> input_level;
    bosepro::DspStateMemory<float[]> input_mean_square;
    bosepro::DspStateMemory<float[]> lf_deq_gain;
    bosepro::DspStateMemory<float[]> hf_deq_gain;
    
    bosepro::DspStateMemory<float[]> calibration_accumulator;
    bosepro::DspStateMemory<int[]> calibration_samples;

    float calibration_gain_db;
    float calibration_gain_linear;
    float level_attack;
    float level_release;  
    float gain_attack;
    float gain_release;
    float hpf_frequency;
    float rms_time_constant;

    void update_calibration_gain();
    void update_detect_attack();
    void update_detect_release(); 
    void update_smooth_attack();
    void update_smooth_release();
    void update_hpf_frequency();

    ALGORITHM_DECLARE(DynamicEq);
};

ALGORITHM_REGISTER(DynamicEq, "dynamic_eq");


DynamicEq::DynamicEq(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_telemetry("out_meter", out_meter, bosepro::linear_to_db);
    assign_telemetry("calibration_spl", calibration_spl);

    // input_gain is expressed as dB
    assign_parameter("input_gain", input_gain, bosepro::db_to_linear);

    // Calibration controls
    assign_parameter("calibration_mode", &calibration_mode);
    assign_parameter("calibration_hold", &calibration_hold);

    // Dynamic EQ parameters from Raphael
    assign_parameter("calibration_gain", &calibration_gain_db,
                     POST_FUNCTION_SCALAR(update_calibration_gain));
    assign_parameter("detect_attack", &level_attack,
                     POST_FUNCTION_SCALAR(update_detect_attack));
    assign_parameter("detect_release", &level_release,
                     POST_FUNCTION_SCALAR(update_detect_release));
    assign_parameter("smooth_attack", &gain_attack,
                     POST_FUNCTION_SCALAR(update_smooth_attack));
    assign_parameter("smooth_release", &gain_release,
                     POST_FUNCTION_SCALAR(update_smooth_release));
    assign_parameter("hpf_frequency", &hpf_frequency,
                     POST_FUNCTION_SCALAR(update_hpf_frequency));

    const float sample_rate = get_sample_rate();

    rms_time_constant = 1.0f / (sample_rate * RMS_AVERAGING_TIME_SECONDS);
    
    new (hpf_filter.get()) filter::IirFilter(1, channels);
    
    new (lf_filter.get()) filter::IirFilter(1, channels);
    lf_filter->design_band("lf_bpf", 0, 30.0f, 1.0f, 0.0f, sample_rate);
    
    new (hf_filter.get()) filter::IirFilter(1, channels);
    hf_filter->design_band("hf_bpf", 0, 3400.0f, 1.1f, 0.0f, sample_rate);

    // Initialize temporary signal buffers
    hpf_out.resize(channels, get_frame_size());
    lf_out.resize(channels, get_frame_size());
    hf_out.resize(channels, get_frame_size());

    input_level.resize(channels);
    input_mean_square.resize(channels);
    lf_deq_gain.resize(channels);
    hf_deq_gain.resize(channels);
    calibration_accumulator.resize(channels);
    calibration_samples.resize(channels);

}


void DynamicEq::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        const float gain = input_gain[channel];
        for (int i = 0; i < get_frame_size(); ++i)
        {
            out[channel][i] = in[channel][i] * gain;
        }
    }
    
    if (calibration_mode && calibration_hold)
    {
        hpf_filter->process(hpf_out.get(), (const float**)out.get(), get_frame_size());
    }
    else
    {
        for (int ch = 0; ch < channels; ch++)
        {
            std::memcpy(hpf_out[ch], out[ch], get_frame_size() * sizeof(float));
        }
    }
    
    lf_filter->process(lf_out.get(), (const float**)out.get(), get_frame_size());
    hf_filter->process(hf_out.get(), (const float**)out.get(), get_frame_size());
    
    float lf_global_target = std::numeric_limits<float>::max();
    float hf_global_target = std::numeric_limits<float>::max();

    // per-channel level analysis
    for (int channel = 0; channel < channels; channel++)
    {
        const float *source = out[channel];
        const float *trigger = (calibration_mode && calibration_hold) ? 
                              hpf_out[channel] : source;
        
        float detect;
        float input_ms = input_mean_square[channel];
        float trigger_state = input_level[channel];
        
        // Calibration mode accumulation
        // 
        // The calibration process measures the RMS level of the high-pass filtered signal
        // when calibration_mode and calibration_hold are both enabled. This allows
        // measurement of the mobile device's frequency response characteristics.
        //
        // Process:
        // 1. Accumulate signal energy for at least 1 second (sample_rate samples)
        // 2. Calculate RMS level from accumulated energy
        // 3. Convert to dBFS and suggest calibration_gain adjustment
        // 4. Target is -95 dBFS + 70 dB = -25 dBFS (accounting for 70dB reference level)
        // 5. Update calibration_spl telemetry for monitoring (dBFS + 70dB reference)
        //
        // Usage: Enable calibration_mode and calibration_hold, play pink noise through
        // the device, then adjust calibration_gain based on the suggested value.
        if (calibration_mode && calibration_hold)
        {
            float sum = 0.0f;
            for (int i = 0; i < get_frame_size(); ++i)
            {
                float sample = trigger[i];
                sum += sample * sample;
            }
            calibration_accumulator[channel] += sum;
            calibration_samples[channel] += get_frame_size();
            
            if (calibration_samples[channel] >= get_sample_rate())
            {
                float cal_rms = std::sqrt(calibration_accumulator[channel] / calibration_samples[channel]);
                float cal_db = 20.0f * std::log10(cal_rms + 1e-10f);
                float new_cal_gain = -cal_db - (95.0f - 70.0f);
                
                SPDLOG_INFO("DynamicEQ Cal: Channel {} level: {:.2f} dBFS, suggested cal_gain: {:.2f} dB", 
                            channel, cal_db, new_cal_gain);
                
                // Update telemetry for potential mobile device SPL monitoring
                calibration_spl[channel] = cal_db + 70.0f;  // Convert to SPL (assuming 70dB reference)
                
                calibration_accumulator[channel] = 0.0f;
                calibration_samples[channel] = 0;
            }
        }
        
        // RMS level detection
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            detect = trigger[sample] * calibration_gain_linear;
            detect *= detect;
            
            input_ms = input_ms + (detect - input_ms) * rms_time_constant;
            trigger_state = trigger_state + (input_ms - trigger_state) * 
                          ((input_ms < trigger_state) ? level_release : level_attack);
        }
        
        // Log2(level) calculation
        if (trigger_state <= 0.000000001f)
        {
            trigger_state = 0.000000001f;
            detect = -29.89735285f;
        }
        else if (trigger_state >= 1.0f)
        {
            detect = 0.0f;
        }
        else
        {
            detect = std::log10(trigger_state) * LOG2_10;
        }
        
        input_level[channel] = trigger_state;
        input_mean_square[channel] = input_ms;
        
        // Calculate LF gain using Raphael formula
        float lf_target_gain = (detect > -0.001f) ? 0.001f : detect * (-1.0f);
        lf_target_gain = std::log10(lf_target_gain) * LOG2_10;
        lf_target_gain += -3.354021725f;
        lf_target_gain *= 3.12f;
        lf_target_gain = std::pow(2.0f, lf_target_gain);
        lf_target_gain += detect * (-0.0785f);
        
        // Calculate HF gain using Raphael formula
        float hf_target_gain = detect * 0.0295f;
        hf_target_gain += 0.826f;
        hf_target_gain *= hf_target_gain;
        hf_target_gain = 0.683f - hf_target_gain;
        
        if (calibration_mode)
        {
            lf_target_gain = 0.0f;
            hf_target_gain = 0.0f;
        }
        
        lf_global_target = std::min(lf_global_target, lf_target_gain);
        hf_global_target = std::min(hf_global_target, hf_target_gain);
    }

    if (lf_global_target == std::numeric_limits<float>::max())
    {
        lf_global_target = 0.0f;
    }

    if (hf_global_target == std::numeric_limits<float>::max())
    {
        hf_global_target = 0.0f;
    }

    // Apply shared gains with smoothing
    for (int channel = 0; channel < channels; channel++)
    {
        const float *source = out[channel];
        const float *lf_band = lf_out[channel];
        const float *hf_band = hf_out[channel];
        float *output = out[channel];

        float lf_gain = lf_deq_gain[channel];
        float hf_gain = hf_deq_gain[channel];

        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            lf_gain = lf_gain + (lf_global_target - lf_gain) * 
                     ((lf_global_target < lf_gain) ? gain_release : gain_attack);
            hf_gain = hf_gain + (hf_global_target - hf_gain) * 
                     ((hf_global_target < hf_gain) ? gain_release : gain_attack);
            
            output[sample] = source[sample] + lf_gain * lf_band[sample] + hf_gain * hf_band[sample];
            
            out_meter[channel] = std::max(out_meter[channel], std::fabs(output[sample]));
        }

        lf_deq_gain[channel] = lf_gain;
        hf_deq_gain[channel] = hf_gain;
    }
}


void DynamicEq::update_calibration_gain()
{
    calibration_gain_linear = std::pow(10.0f, calibration_gain_db / 20.0f);
}

void DynamicEq::update_detect_attack()
{
    const float sample_rate = get_sample_rate();
    // Convert time parameter (in seconds) to coefficient
    level_attack = 1.0f - std::exp(-1.0f / (sample_rate * 0.1f));  // Fixed 0.1s attack
}

void DynamicEq::update_detect_release()
{
    const float sample_rate = get_sample_rate();
    // Convert time parameter (in seconds) to coefficient 
    level_release = 1.0f - std::exp(-1.0f / (sample_rate * 2.0f));  // Fixed 2.0s release
}

void DynamicEq::update_smooth_attack()
{
    const float sample_rate = get_sample_rate();
    // Convert time parameter (in seconds) to coefficient
    gain_attack = 1.0f - std::exp(-1.0f / (sample_rate * 0.001f));  // Fixed 1ms attack
}

void DynamicEq::update_smooth_release()
{
    const float sample_rate = get_sample_rate();
    // Convert time parameter (in seconds) to coefficient
    gain_release = 1.0f - std::exp(-1.0f / (sample_rate * 0.001f));  // Fixed 1ms release
}

void DynamicEq::update_hpf_frequency()
{
    hpf_filter->design_band("hpf_cs", 0, hpf_frequency, 0.707f, 0.0f, get_sample_rate());
}

} // namespace

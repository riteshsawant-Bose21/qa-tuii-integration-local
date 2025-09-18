//
// crossover.cpp
// Implementation of audio crossover filters with parameter validation and 
// real-time processing using configurable IIR filter designs.
//

#include "crossover.h"

#include "iir.h"
#include <spdlog/spdlog.h>

#include <cstring>

namespace filter {


Crossover::Crossover(int frame_size)
    : frame_size(frame_size)
{
    lpf = std::make_unique<IirFilter>(MAX_SOS);
    hpf = std::make_unique<IirFilter>(MAX_SOS);
}

void Crossover::design()
{
    // early exit if disabled
    if (!params.enabled)
    {
        SPDLOG_DEBUG("Crossover::design() called while disabled");
        return;
    }

    // Clamp orders to our supported range (1..8).
    int l_order = params.lowpass_order;
    int h_order = params.highpass_order;

    if (l_order < 1) l_order = 1;
    if (h_order < 1) h_order = 1;

    if (l_order > 8) l_order = 8;
    if (h_order > 8) h_order = 8;

    // For Bessel, minimum order is 2
    if (params.type == CrossoverType::BESSEL || params.type == CrossoverType::LINKWITZ_RILEY) {
        if (l_order < 2) {
            l_order = 2;
            SPDLOG_WARN("{} filters require minimum order 2, clamping lowpass from {} to 2", 
                       (params.type == CrossoverType::BESSEL) ? "Bessel" : "Linkwitz-Riley", 
                       params.lowpass_order);
        }
        if (h_order < 2) {
            h_order = 2;
            SPDLOG_WARN("{} filters require minimum order 2, clamping highpass from {} to 2",
                       (params.type == CrossoverType::BESSEL) ? "Bessel" : "Linkwitz-Riley", 
                       params.highpass_order);
        }
    }

    // For Linkwitz-Riley crossovers, the order must be even
    if (params.type == CrossoverType::LINKWITZ_RILEY)
    {
        if ((l_order & 1) != 0)
        {
            ++l_order;
            SPDLOG_WARN("Crossover::design() rounded LPF order up to even {} for LR", l_order);
        }
        if ((h_order & 1) != 0)
        {
            ++h_order;
            SPDLOG_WARN("Crossover::design() rounded HPF order up to even {} for LR", h_order);
        }
    }

    int l_sections = (l_order + 1) / 2;
    int h_sections = (h_order + 1) / 2;

    float fs = params.sample_rate;

    // validation of sample rate and frequencies
    if (fs <= 0.0f)
    {
        SPDLOG_ERROR("Crossover::design() invalid sample rate {}", fs);
        return;
    }

    const float nyq = fs * 0.5f;
    if (!(params.lowpass_freq > 0.0f && params.lowpass_freq < nyq))
    {
        SPDLOG_WARN("Crossover::design() lowpass_freq {} out of (0, fs/2). Clamping.", params.lowpass_freq);
        if (params.lowpass_freq <= 0.0f) params.lowpass_freq = 20.0f;
        if (params.lowpass_freq >= nyq) params.lowpass_freq = nyq - 1.0f;
    }
    if (!(params.highpass_freq > 0.0f && params.highpass_freq < nyq))
    {
        SPDLOG_WARN("Crossover::design() highpass_freq {} out of (0, fs/2). Clamping.", params.highpass_freq);
        if (params.highpass_freq <= 0.0f) params.highpass_freq = 20.0f;
        if (params.highpass_freq >= nyq) params.highpass_freq = nyq - 1.0f;
    }

    if (params.type == CrossoverType::BUTTERWORTH)
    {
        lpf->design("iir_crossover_butterworth_lpf", 0, params.lowpass_freq, l_order, fs, MAX_SOS);
        hpf->design("iir_crossover_butterworth_hpf", 0, params.highpass_freq, h_order, fs, MAX_SOS);
    }
    else if (params.type == CrossoverType::LINKWITZ_RILEY)
    {
        lpf->design("iir_crossover_linkwitz_riley_lpf", 0, params.lowpass_freq, l_order, fs, MAX_SOS);
        hpf->design("iir_crossover_linkwitz_riley_hpf", 0, params.highpass_freq, h_order, fs, MAX_SOS);
    }
    else if (params.type == CrossoverType::BESSEL)
    {
        lpf->design("iir_crossover_bessel_lpf", 0, params.lowpass_freq, l_order, fs, MAX_SOS);
        hpf->design("iir_crossover_bessel_hpf", 0, params.highpass_freq, h_order, fs, MAX_SOS);
    }

    // unused sections are unity pass-through.
    for (int s = l_sections; s < MAX_SOS; ++s)
    {
        lpf->set_section_coeffs(s, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }

    for (int s = h_sections; s < MAX_SOS; ++s)
    {
        hpf->set_section_coeffs(s, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }

    SPDLOG_DEBUG("Crossover::design() placeholder configured: l_sec={} h_sec={} fs={}",
                 l_sections, h_sections, fs);
}


void Crossover::process(float *out_low, float *out_high, const float *in)
{
    if (!params.enabled)
    {
        std::memcpy(out_low, in, sizeof(float) * frame_size);
        std::memcpy(out_high, in, sizeof(float) * frame_size);
        return;
    }

    lpf->process(out_low, in, frame_size);
    hpf->process(out_high, in, frame_size);
}


void Crossover::reset()
{
    lpf = std::make_unique<IirFilter>(MAX_SOS);
    hpf = std::make_unique<IirFilter>(MAX_SOS);
}

} // namespace filter
//
// crossover.h
// Implements a Crossover class that owns two multi-section IIR filters
// (one high-pass and one low-pass).
//

#pragma once

#include "filter.h"

#include <memory>
#include <string>

namespace filter {

enum class CrossoverType {
    LINKWITZ_RILEY,
    BUTTERWORTH,
    BESSEL
};

struct CrossoverParams {
    float sample_rate{48000.0f};
    float lowpass_freq{200.0f};
    float highpass_freq{200.0f};
    int lowpass_order{4};   // up to 8 supported via multiple sos
    int highpass_order{4};
    CrossoverType type{CrossoverType::LINKWITZ_RILEY};
    bool enabled{true};
};


class IirFilter;

class Crossover
{
public:
    Crossover(int frame_size = 64);

    ~Crossover() = default;

    void set_params(const CrossoverParams &p)
    {
        params = p;
    }

    const CrossoverParams &get_params() const
    {
        return params;
    }

    void design();

    void process(float *out_low, float *out_high, const float *in);

    void reset();

    void set_enable(bool enable)
    {
        params.enabled = enable;
    }

private:
    CrossoverParams params;
    int frame_size;

    static const int MAX_SOS = 4;

    std::unique_ptr<IirFilter> lpf;
    std::unique_ptr<IirFilter> hpf;
};

} // namespace filter

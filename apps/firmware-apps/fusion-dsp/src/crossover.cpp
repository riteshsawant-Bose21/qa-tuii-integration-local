//
// crossover.cpp
// Implementation of audio crossover filters with parameter validation and 
// real-time processing using configurable IIR filter designs.
//

#include "iir.h"

#include <bosepro/algorithm.h>
#include <spdlog/spdlog.h>
#include <cstdint>

namespace {

enum class FilterType {
    LINKWITZ_RILEY,
    BUTTERWORTH,
    BESSEL
};

class Crossover : public bosepro::Algorithm
{
public:
    Crossover(const bosepro::BlockConfiguration &configuration);
    virtual ~Crossover() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    
    bosepro::DspStateMemory<filter::IirFilter> hpf;
    bosepro::DspStateMemory<filter::IirFilter> lpf;
    
    float hpf_freq{20.0f};
    float lpf_freq{20000.0f};
    int_fast32_t hpf_order{4};
    int_fast32_t lpf_order{4};
    std::string hpf_type_str{"linkwitz_riley"};
    std::string lpf_type_str{"linkwitz_riley"};
    
    FilterType hpf_type{FilterType::LINKWITZ_RILEY};
    FilterType lpf_type{FilterType::LINKWITZ_RILEY};
    static const int MAX_SOS = 4;
    
    void update_hpf();
    void update_lpf();
    void update_hpf_type();
    void update_lpf_type();
    void design_filter(filter::IirFilter* filter, FilterType type, bool is_highpass,
                      float freq, int order);
    
    ALGORITHM_DECLARE(Crossover);
};

ALGORITHM_REGISTER(Crossover, "crossover");

Crossover::Crossover(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);
    
    assign_terminal("in", in);
    assign_terminal("out", out);
    
    assign_parameter("hpf_freq", &hpf_freq, 
                     POST_FUNCTION_SCALAR(update_hpf));
    assign_parameter("lpf_freq", &lpf_freq, 
                     POST_FUNCTION_SCALAR(update_lpf));
    assign_parameter("hpf_order", &hpf_order, 
                     POST_FUNCTION_SCALAR(update_hpf));
    assign_parameter("lpf_order", &lpf_order, 
                     POST_FUNCTION_SCALAR(update_lpf));
    assign_parameter("hpf_type", &hpf_type_str, 
                     POST_FUNCTION_SCALAR(update_hpf_type));
    assign_parameter("lpf_type", &lpf_type_str, 
                     POST_FUNCTION_SCALAR(update_lpf_type));
    
    new (hpf.get()) filter::IirFilter(MAX_SOS, channels);
    new (lpf.get()) filter::IirFilter(MAX_SOS, channels);
}

void Crossover::process()
{
    hpf->process(out.get(), in.get(), get_frame_size());
    lpf->process(out.get(), const_cast<const float**>(out.get()), get_frame_size());
}

void Crossover::update_hpf()
{
    design_filter(hpf.get(), hpf_type, true, hpf_freq, hpf_order);
}

void Crossover::update_lpf()
{
    design_filter(lpf.get(), lpf_type, false, lpf_freq, lpf_order);
}

// Convert string parameter to enum
void Crossover::update_hpf_type()
{
    if (hpf_type_str == "butterworth")
    {
        hpf_type = FilterType::BUTTERWORTH;
    }
    else if (hpf_type_str == "bessel")
    {
        hpf_type = FilterType::BESSEL;
    }
    else
    {
        hpf_type = FilterType::LINKWITZ_RILEY;
    }
    
    update_hpf();
}

void Crossover::update_lpf_type()
{
    if (lpf_type_str == "butterworth")
    {
        lpf_type = FilterType::BUTTERWORTH;
    }
    else if (lpf_type_str == "bessel")
    {
        lpf_type = FilterType::BESSEL;
    }
    else
    {
        lpf_type = FilterType::LINKWITZ_RILEY;
    }
    
    update_lpf();
}

void Crossover::design_filter(filter::IirFilter* filter, FilterType type, 
                              bool is_highpass, float freq, int order)
{
    int actual_order = order;
    
    // For Bessel and Linkwitz-Riley, minimum order is 2
    if (type == FilterType::BESSEL || type == FilterType::LINKWITZ_RILEY)
    {
        if (actual_order < 2)
        {
            actual_order = 2;
            SPDLOG_WARN("{} filters require minimum order 2, clamping {} from {} to 2", 
                       (type == FilterType::BESSEL) ? "Bessel" : "Linkwitz-Riley",
                       is_highpass ? "HPF" : "LPF", order);
        }
    }
    
    // For Linkwitz-Riley, order must be even
    if (type == FilterType::LINKWITZ_RILEY)
    {
        if ((actual_order & 1) != 0)
        {
            ++actual_order;
            SPDLOG_WARN("Crossover: rounded {} order up to even {} for LR", 
                       is_highpass ? "HPF" : "LPF", actual_order);
        }
    }
    
    int sections = (actual_order + 1) / 2;
    float fs = get_sample_rate();
    
    // validation of sample rate and frequencies
    if (fs <= 0.0f)
    {
        SPDLOG_ERROR("Crossover: invalid sample rate {}", fs);
        return;
    }
    
    const float nyq = fs * 0.5f;
    float actual_freq = freq;
    
    if (!(actual_freq > 0.0f && actual_freq < nyq))
    {
        SPDLOG_WARN("Crossover: {} freq {} out of (0, fs/2). Clamping.", 
                   is_highpass ? "HPF" : "LPF", actual_freq);
        if (actual_freq <= 0.0f) actual_freq = 20.0f;
        if (actual_freq >= nyq) actual_freq = nyq - 1.0f;
    }
    
    const char* design_name = nullptr;
    
    if (type == FilterType::BUTTERWORTH)
    {
        design_name = is_highpass ? "iir_crossover_butterworth_hpf" 
                                  : "iir_crossover_butterworth_lpf";
    }
    else if (type == FilterType::LINKWITZ_RILEY)
    {
        design_name = is_highpass ? "iir_crossover_linkwitz_riley_hpf"
                                  : "iir_crossover_linkwitz_riley_lpf";
    }
    else if (type == FilterType::BESSEL)
    {
        design_name = is_highpass ? "iir_crossover_bessel_hpf"
                                  : "iir_crossover_bessel_lpf";
    }
    
    filter->design(design_name, 0, actual_freq, actual_order, fs, MAX_SOS);
    
    // unused sections are unity pass-through.
    for (int s = sections; s < MAX_SOS; ++s)
    {
        filter->set_section_coeffs(s, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
    }
    
    SPDLOG_DEBUG("Crossover: designed {} {} order={} freq={} fs={}",
                is_highpass ? "HPF" : "LPF", design_name, 
                actual_order, actual_freq, fs);
}

} // namespace
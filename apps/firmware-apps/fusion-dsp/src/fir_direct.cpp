//
// fir_direct.cpp
// Simple direct-form FIR filter
//

#include <bosepro/algorithm.h>
#include "fir.h"

#include <cmath>
#include <cstring>
#include <memory>
#include <vector>

namespace {

class FirDirect : public bosepro::Algorithm
{
public:
    FirDirect(const bosepro::BlockConfiguration &configuration);
    virtual ~FirDirect() = default;

    virtual void process() override;

private:
    void initialize_coefficients();
    bool check_coefficients_changed();

    int_fast32_t channels;
    int_fast32_t num_taps;
    int frame_size;
    int sample_rate;
    
    bosepro::DspSignalMemory<const float*[]> in;
    bosepro::DspSignalMemory<float*[]> out;
    
    bosepro::DspCoeffMemory<float[]> coefficients;
    bosepro::DspStateMemory<float[]> previous_coefficients;
    
    std::vector<std::unique_ptr<filter::FirFilter>> filters;
    bool coefficients_changed;
    
    ALGORITHM_DECLARE(FirDirect);
};

ALGORITHM_REGISTER(FirDirect, "fir_direct");

FirDirect::FirDirect(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
    , coefficients_changed(true)
{
    get_property("channels", channels);
    get_property("num_taps", num_taps);
    
    frame_size = get_frame_size();
    sample_rate = get_sample_rate();
    
    assign_terminal("in", in);
    assign_terminal("out", out);
    
    assign_parameter("coefficients", coefficients);
    
    previous_coefficients.resize(num_taps);
    
    filters.reserve(channels);
    for (int ch = 0; ch < channels; ch++) {
        filters.push_back(std::make_unique<filter::FirFilter>(num_taps, frame_size, sample_rate));
    }
    
    initialize_coefficients();
}

void FirDirect::initialize_coefficients()
{
    for (int ch = 0; ch < channels; ch++) {
        filters[ch]->with_coefficients(&coefficients[0]);
    }
    std::memcpy(&previous_coefficients[0], &coefficients[0],
                num_taps * sizeof(float));
    
    coefficients_changed = false;
}

bool FirDirect::check_coefficients_changed()
{
    for (int i = 0; i < num_taps; ++i) {
        if (std::abs(coefficients[i] - previous_coefficients[i]) > 1e-9f) {
            std::memcpy(&previous_coefficients[0], &coefficients[0], 
                       num_taps * sizeof(float));
            return true;
        }
    }
    return false;
}

void FirDirect::process()
{
    if (coefficients_changed || check_coefficients_changed()) {
        initialize_coefficients();
        coefficients_changed = false;
    }
    for (int ch = 0; ch < channels; ch++) {
        filters[ch]->process(out[ch], in[ch]);
    }
    
}

} // namespace


#include "iir.h"

#include <bosepro/algorithm.h>

#include <cstdint>
#include <memory>

namespace {


class Tone : public bosepro::Algorithm
{
public:
    Tone(const bosepro::BlockConfiguration &configuration);
    virtual ~Tone() = default;

    virtual void process() override;


private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    std::unique_ptr<filter::IirFilter> iir;

    float low_gain;
    float mid_gain;
    float high_gain;
    bool low_bypass;
    bool mid_bypass;
    bool high_bypass;

    void update_low();
    void update_mid();
    void update_high();

    ALGORITHM_DECLARE(Tone);
};

ALGORITHM_REGISTER(Tone, "tone");


Tone::Tone(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_control("low_gain", &low_gain, POST_FUNCTION_SCALAR(update_low));
    assign_control("mid_gain", &mid_gain, POST_FUNCTION_SCALAR(update_mid));
    assign_control("high_gain", &high_gain, POST_FUNCTION_SCALAR(update_high));
    assign_control("low_bypass", &low_bypass, POST_FUNCTION_SCALAR(update_low));
    assign_control("mid_bypass", &mid_bypass, POST_FUNCTION_SCALAR(update_mid));
    assign_control("high_bypass", &high_bypass,
                   POST_FUNCTION_SCALAR(update_high));

    iir = std::unique_ptr<filter::IirFilter>(new filter::IirFilter(3, channels));
}


void Tone::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}


void Tone::update_low()
{
    if (!low_bypass)
    {
        iir->design_band("low_shelf_cs", 0, 200.0f, 1.0f, low_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 0, 0.0, 0.0, 0.0, get_sample_rate());
    }
}


void Tone::update_mid()
{
    if (!mid_bypass)
    {
        iir->design_band("peq_cs", 1, 1000.0f, 1.414f, mid_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 1, 0.0, 0.0, 0.0, get_sample_rate());
    }
}


void Tone::update_high()
{
    if (!high_bypass)
    {
        iir->design_band("high_shelf_cs", 2, 5000.0f, 1.0f, high_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 2, 0.0, 0.0, 0.0, get_sample_rate());
    }
}

} // namespace

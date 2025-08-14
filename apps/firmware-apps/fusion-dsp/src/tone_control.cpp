
#include "iir.h"

#include <bosepro/algorithm.h>

#include <cstdint>

namespace {


class ToneControl : public bosepro::Algorithm
{
public:
    ToneControl(const bosepro::BlockConfiguration &configuration);
    virtual ~ToneControl() = default;

    virtual void process() override;


private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspStateMemory<filter::IirFilter> iir;

    float low_gain;
    float mid_gain;
    float high_gain;
    bool low_bypass;
    bool mid_bypass;
    bool high_bypass;

    void update_low();
    void update_mid();
    void update_high();

    ALGORITHM_DECLARE(ToneControl);
};

ALGORITHM_REGISTER(ToneControl, "tone_control");


ToneControl::ToneControl(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("low_gain", &low_gain, POST_FUNCTION_SCALAR(update_low));
    assign_parameter("mid_gain", &mid_gain, POST_FUNCTION_SCALAR(update_mid));
    assign_parameter("high_gain", &high_gain,
                     POST_FUNCTION_SCALAR(update_high));
    assign_parameter("low_bypass", &low_bypass,
                     POST_FUNCTION_SCALAR(update_low));
    assign_parameter("mid_bypass", &mid_bypass,
                     POST_FUNCTION_SCALAR(update_mid));
    assign_parameter("high_bypass", &high_bypass,
                     POST_FUNCTION_SCALAR(update_high));

    new (iir.get()) filter::IirFilter(3, channels);
}


void ToneControl::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}


void ToneControl::update_low()
{
    if (!low_bypass)
    {
        iir->design_band("low_shelf_cs", 0, 200.0f, 1.0f, low_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 0, 0.0f, 0.0f, 0.0f, get_sample_rate());
    }
}


void ToneControl::update_mid()
{
    if (!mid_bypass)
    {
        iir->design_band("peq_cs", 1, 1000.0f, 1.414f, mid_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 1, 0.0f, 0.0f, 0.0f, get_sample_rate());
    }
}


void ToneControl::update_high()
{
    if (!high_bypass)
    {
        iir->design_band("high_shelf_cs", 2, 5000.0f, 1.0f, high_gain,
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", 2, 0.0f, 0.0f, 0.0f, get_sample_rate());
    }
}

} // namespace

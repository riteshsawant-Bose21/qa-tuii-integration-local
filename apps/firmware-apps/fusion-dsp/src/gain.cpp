
#include <bosepro/algorithm.h>

#include <cstdint>


namespace {


class Gain : public bosepro::Algorithm
{
public:
    Gain(const bosepro::BlockConfiguration &configuration);
    virtual ~Gain() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    float gain;
    bool mute;

    float smoothed_gain;
    float smooth_coeff;

    ALGORITHM_DECLARE(Gain);
};

ALGORITHM_REGISTER(Gain, "gain");


Gain::Gain(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_control("gain", &gain);
    assign_control("mute", &mute);

    smooth_coeff = 0.999f;
    smoothed_gain = 1.0f;
}


void Gain::process()
{
    float target_gain = mute ? 0.0f : gain;
    float g = smoothed_gain;

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            out[channel][sample] = in[channel][sample] * g;

            g = smooth_coeff * g + (1.0f - smooth_coeff) * target_gain;
        }
    }

    smoothed_gain = g;
}


} // namespace

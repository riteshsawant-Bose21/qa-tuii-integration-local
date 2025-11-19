
#include <bosepro/algorithm.h>

#include <cstdint>


namespace {


class Unshifter : public bosepro::Algorithm
{
public:
    Unshifter(const bosepro::BlockConfiguration &configuration);
    virtual ~Unshifter() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    static const float scale_up;
    static const float scale_down;

    ALGORITHM_DECLARE(Unshifter);
};

ALGORITHM_REGISTER(Unshifter, "unshifter");

const float Unshifter::scale_up = 2147483648.0f;
const float Unshifter::scale_down = 1.0f / 2147483648.0f;


Unshifter::Unshifter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);
}


void Unshifter::process()
{
    int_fast32_t pcm;

    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            pcm = static_cast<int_fast32_t>(in[channel][sample] * scale_up);
            pcm <<= 1;
            out[channel][sample] = static_cast<float>(pcm) * scale_down;
        }
    }
}


} // namespace

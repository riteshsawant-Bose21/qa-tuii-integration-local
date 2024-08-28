
#include <bosepro/algorithm.h>
#include <bosepro/jack.h>

#include <cstring>
#include <string>


namespace {


class JackIn : public bosepro::Jack {
public:
    JackIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<float *[]> out;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, true)
{
    assign_terminal("out", out);
}


void JackIn::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        float *in = ports[channel].get_buffer(get_frame_size());

        std::memcpy(out[channel], in, get_frame_size() * sizeof(float));
    }
}


} // namespace

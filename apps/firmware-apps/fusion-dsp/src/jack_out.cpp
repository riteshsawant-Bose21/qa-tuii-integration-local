
#include <bosepro/algorithm.h>
#include <bosepro/jack.h>

#include <cstring>
#include <string>


namespace {


class JackOut : public bosepro::Jack {
public:
    JackOut(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<const float *[]> in;

    ALGORITHM_DECLARE(JackOut);
};

ALGORITHM_REGISTER(JackOut, "jack_out");


JackOut::JackOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, false)
{
    assign_terminal("in", in);
}


void JackOut::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        float *out = ports[channel].get_buffer(get_frame_size());

        std::memcpy(out, in[channel], get_frame_size() * sizeof(float));
    }
}


} // namespace

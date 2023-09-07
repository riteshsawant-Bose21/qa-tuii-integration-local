
#include "jack.h"

#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <cstring>
#include <string>
#include <vector>


namespace {


class JackOut : public bosepro::Jack {
public:
    JackOut(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    std::vector<const float *> in;

    ALGORITHM_DECLARE(JackOut);
};

ALGORITHM_REGISTER(JackOut, "jack_out");


JackOut::JackOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, false)
{
    assign_terminal("in", &in);
}


void JackOut::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        jack_default_audio_sample_t *out = (jack_default_audio_sample_t *)
            jack_port_get_buffer(ports[channel], get_frame_size());

        std::memcpy(out, in[channel], get_frame_size() * sizeof(float));
    }
}


} // namespace

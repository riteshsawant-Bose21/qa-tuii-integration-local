
#include "jack.h"

#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <cstring>
#include <string>
#include <vector>


namespace {


class JackIn : public bosepro::Jack {
public:
    JackIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    std::vector<float *> out;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, true)
{
    assign_terminal("out", &out);
}


void JackIn::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        jack_default_audio_sample_t *in = (jack_default_audio_sample_t *)
            jack_port_get_buffer(ports[channel], get_frame_size());

        std::memcpy(out[channel], in, get_frame_size() * sizeof(float));
    }
}


} // namespace

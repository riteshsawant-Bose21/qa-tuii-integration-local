
#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <cstring>
#include <string>
#include <vector>


extern jack_client_t *jack_client;


namespace {


class JackOut : public bosepro::Algorithm {
public:
    JackOut(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    int channels;
    std::vector<const float *> in;
    std::vector<jack_port_t *> output_port;

    ALGORITHM_DECLARE(JackOut);
};

ALGORITHM_REGISTER(JackOut, "jack_out");


JackOut::JackOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", channels);

    output_port.resize(channels);

    for (int channel = 0; channel < channels; channel++)
    {
        std::string port_name = "output_" + std::to_string(channel + 1);
        output_port[channel] = jack_port_register(jack_client, port_name.c_str(),
                                                  JACK_DEFAULT_AUDIO_TYPE,
                                                  JackPortIsOutput, 0);
    }

    assign_terminal("in", &in);
}


void JackOut::process()
{
    if (jack_port_connected(output_port[0]) == 0)
    {
        const char **ports =
            jack_get_ports(jack_client, NULL, JACK_DEFAULT_AUDIO_TYPE,
                           JackPortIsPhysical | JackPortIsInput);

        for (int channel = 0; channel < channels; channel++)
        {
            jack_connect(jack_client, jack_port_name(output_port[channel]),
                         ports[channel]);
        }

        free(ports);
    }

    for (int channel = 0; channel < channels; channel++)
    {
        jack_default_audio_sample_t *out = (jack_default_audio_sample_t *)
            jack_port_get_buffer(output_port[channel], get_frame_size());

        std::memcpy(out, in[channel], get_frame_size() * sizeof(float));
    }
}


} // namespace

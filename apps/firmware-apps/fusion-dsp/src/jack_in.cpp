
#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <cstring>
#include <string>
#include <vector>


extern jack_client_t *jack_client;


namespace {


class JackIn : public bosepro::Algorithm {
public:
    JackIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    int channels;
    std::vector<float *> out;
    std::vector<jack_port_t *> input_port;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("out", channels);

    input_port.resize(channels);

    for (int channel = 0; channel < channels; channel++)
    {
        std::string port_name = "input_" + std::to_string(channel + 1);
        input_port[channel] = jack_port_register(jack_client, port_name.c_str(),
                                                 JACK_DEFAULT_AUDIO_TYPE,
                                                 JackPortIsInput, 0);
    }

    assign_terminal("out", &out);
}


void JackIn::process()
{
    if (jack_port_connected(input_port[0]) == 0)
    {
        const char **ports =
            jack_get_ports(jack_client, NULL, JACK_DEFAULT_AUDIO_TYPE,
                           JackPortIsPhysical | JackPortIsOutput);

        for (int channel = 0; channel < channels; channel++)
        {
            jack_connect(jack_client, ports[channel],
                         jack_port_name(input_port[channel]));
        }

        free(ports);
    }

    for (int channel = 0; channel < channels; channel++)
    {
        jack_default_audio_sample_t *in = (jack_default_audio_sample_t *)
            jack_port_get_buffer(input_port[channel], get_frame_size());

        std::memcpy(out[channel], in, get_frame_size() * sizeof(float));
    }
}


} // namespace

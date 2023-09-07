
#include "jack.h"

#include <bosepro/algorithm.h>

#include <jack/jack.h>
#include <spdlog/spdlog.h>


namespace bosepro {


jack_client_t *Jack::client = nullptr;
std::list<Jack *> Jack::instances;


Jack::Jack(const BlockConfiguration &configuration, bool is_input)
    : bosepro::Algorithm(configuration), is_input(is_input)
{
    if (client == nullptr)
    {
        std::string client_name;
        jack_status_t jack_status;

        get_constant("client_name", client_name);

        client = jack_client_open(client_name.c_str(), JackNullOption,
                                  &jack_status, NULL);

        if (client == nullptr)
        {
            SPDLOG_CRITICAL("jack_client_open() failed, status: {}",
                         (int)jack_status);
            return;
        }
    }

    if ((int)jack_get_sample_rate(client) != get_sample_rate())
    {
        SPDLOG_CRITICAL("JACK sample rate does not match");
        return;
    }

    if ((int)jack_get_buffer_size(client) != get_frame_size())
    {
        SPDLOG_CRITICAL("JACK frame size does not match");
        return;
    }

    std::string port_name_prefix;
    get_constant("port_name_prefix", port_name_prefix);

    if (is_input)
    {
        get_terminal_num_channels("out", channels);
    }
    else
    {
        get_terminal_num_channels("in", channels);
    }

    ports.resize(channels);

    for (int channel = 0; channel < channels; channel++)
    {
        std::string port_name = port_name_prefix + std::to_string(channel + 1);
        SPDLOG_DEBUG("Port name: {}", port_name);
        ports[channel] = jack_port_register(client, port_name.c_str(),
                                            JACK_DEFAULT_AUDIO_TYPE,
                                            is_input ? JackPortIsInput
                                                     :JackPortIsOutput,
                                            0);
    }

    port_connections.resize(channels);

    assign_control("port_connection", &port_connections,
                   POST_FUNCTION_VECTOR(post_port_connection));

    instances.push_back(this);
}


bool Jack::has_client()
{
    return client != nullptr;
}


bool Jack::set_process_callback(JackProcessCallback callback, void *arg,
                                bool make_default_connections)
{
    int err;

    if (client == nullptr)
    {
        SPDLOG_CRITICAL("JACK client is not initialized");
        return false;
    }

    if (jack_set_process_callback(client, callback, arg) != 0)
    {
        return false;
    }

    err = jack_activate(client);

    if (err != 0)
    {
        SPDLOG_CRITICAL("jack_set_process_callback() failed, err: {}", err);
        return false;
    }

    if (make_default_connections)
    {
        for (Jack *instance : instances)
        {
            if (!instance->connect_default_ports())
            {
                return false;
            }
        }
    }

    return true;
}


bool Jack::connect_default_ports()
{
    const char **server_ports =
        jack_get_ports(client, NULL, JACK_DEFAULT_AUDIO_TYPE,
                       JackPortIsPhysical | (is_input ? JackPortIsOutput
                                                      : JackPortIsInput));

    if (server_ports == nullptr)
    {
        SPDLOG_CRITICAL("jack_get_ports() failed");
        return false;
    }

    for (int channel = 0; channel < channels; channel++)
    {
        int err;

        SPDLOG_INFO("Server port: {}", server_ports[channel]);

        err = jack_connect(client,
                           is_input ? server_ports[channel]
                                    : jack_port_name(ports[channel]),
                           is_input ? jack_port_name(ports[channel])
                                    : server_ports[channel]);

        if (err != 0)
        {
            SPDLOG_ERROR("jack_connect() failed, err: {}", err);
            free(server_ports);
            return false;
        }

        port_connections[channel] = server_ports[channel];
    }

    free(server_ports);
    return true;
}


void Jack::post_port_connection(int channel)
{
    int err;

    if (port_connections[channel].empty())
    {
        return;
    }

    err = jack_connect(client,
                       is_input ? port_connections[channel].c_str()
                                : jack_port_name(ports[channel]),
                       is_input ? jack_port_name(ports[channel])
                                : port_connections[channel].c_str());

    if (err != 0)
    {
        SPDLOG_ERROR("jack_connect() failed, err: {}", err);
    }

}


} // namespace bosepro

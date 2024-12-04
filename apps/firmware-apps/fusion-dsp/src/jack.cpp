
#include <bosepro/algorithm.h>
#include <bosepro/jack.h>
#include <bosepro/task.h>

#include <jack/jack.h>
#include <spdlog/spdlog.h>


namespace bosepro {


std::map<std::string, JackClient> Jack::clients;
JackClient *Jack::current_client = nullptr;


void JackPort::create(JackClient *client, const char *name, bool is_input)
{
    port = jack_port_register(client->get_jack_client(),
                              name,
                              JACK_DEFAULT_AUDIO_TYPE,
                              is_input ? JackPortIsInput :JackPortIsOutput,
                              0);
}


void JackPort::connect(JackClient *client, const char *connection_name,
                       bool is_input)
{
    int err = jack_connect(client->get_jack_client(),
                           is_input ? connection_name : get_name(),
                           is_input ? get_name() : connection_name);

    if (err != 0 && err != EEXIST)
    {
        SPDLOG_ERROR("Unable to connect port {} {}.",
                     get_name(), connection_name);
    }
}


void JackPort::disconnect(JackClient *client)
{
    int err = jack_port_disconnect(client->get_jack_client(), port);

    if (err != 0)
    {
        SPDLOG_ERROR("Unable to disconnect port.");
    }
}


bool JackClient::set_process_thread(JackThreadCallback callback, void *arg)
{
    int err;

    if (client == nullptr)
    {
        SPDLOG_CRITICAL("JACK client {} not found");
        return false;
    }

    if (jack_set_process_thread(client, callback, arg) != 0)
    {
        return false;
    }

    err = jack_activate(client);

    if (err != 0)
    {
        SPDLOG_CRITICAL("jack_set_process_thread() failed, err: {}", err);
        return false;
    }

    return true;
}


void JackClient::jack_thread()
{
#ifndef USE_MAC_THREADS
    // JACK takes care of making this a real-time thread, but we have to
    // manage core affinity ourselves.
    int_fast32_t thread_affinity = task->get_cpu_affinity();

    if (thread_affinity >= 0)
    {
        cpu_set_t cpuset;
        CPU_ZERO(&cpuset);
        CPU_SET(thread_affinity, &cpuset);

        if (pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset)
            != 0)
        {
            SPDLOG_ERROR("Couldn't set thread affinity.");
        }
    }
#endif

    while (!task->finished_running())
    {
        jack_cycle_wait(client);
        task->process();
        jack_cycle_signal(client, 0);
    }

    jack_cycle_wait(client);
    jack_cycle_signal(client, 1); // Tell JACK we are done with this thread.
}


void JackClient::start()
{
    int err = jack_activate(client);

    if (err != 0)
    {
        SPDLOG_ERROR("Couldn't activate. {}", err);
    }

    for (auto &block : jack_blocks)
    {
        block->connect_all();
    }
}


void JackClient::stop()
{
    int err = jack_deactivate(client);

    if (err != 0)
    {
        SPDLOG_ERROR("Couldn't deactivate. {}", err);
    }
}


Jack::Jack(const BlockConfiguration &configuration, bool is_input)
    : bosepro::Algorithm(configuration), is_input(is_input)
{
    std::string client_name;

    get_property("client_name", client_name);

    client = get_client(client_name);

    if (client == nullptr)
    {
        SPDLOG_CRITICAL("JACK client not found: {}", client_name);
        return;
    }

    if (client->get_sample_rate() != get_sample_rate())
    {
        SPDLOG_CRITICAL("JACK sample rate does not match");
        return;
    }

    if (client->get_frame_size() != get_frame_size())
    {
        SPDLOG_CRITICAL("JACK frame size does not match");
        return;
    }

    client->attach_block(this);

    std::string port_name_prefix;
    get_property("port_name_prefix", port_name_prefix);

    if (port_name_prefix.empty())
    {
        port_name_prefix = configuration.get_name() + "_";
    }

    if (is_input)
    {
        get_terminal_num_channels("out", channels);
    }
    else
    {
        get_terminal_num_channels("in", channels);
    }

    ports.resize(channels);
    port_connections.resize(channels);

    for (int channel = 0; channel < channels; channel++)
    {
        std::string port_name = port_name_prefix + std::to_string(channel + 1);
        ports[channel].create(client, port_name.c_str(), is_input);
    }
}


JackClient *Jack::create_client(const std::string &name, Task *task)
{
    if (clients.count(name) != 0)
    {
        SPDLOG_CRITICAL("Multiple JACK clients named {}", name);
        return nullptr;
    }

    clients.try_emplace(name, name, task);

    current_client = &clients.at(name);

    return current_client;
}


void Jack::destroy_client(const std::string &name)
{
    if (clients.count(name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find client named {}", name);
    }

    clients.erase(name);
    current_client = nullptr;
}


bool Jack::has_client()
{
    return !clients.empty();
}


JackClient *Jack::get_client(const std::string &name)
{
    if (name.empty())
    {
        return current_client;
    }

    if (clients.count(name) == 0)
    {
        SPDLOG_CRITICAL("Unable to find client {}!", name);
        return nullptr;
    }

    return &clients.at(name);
}


void Jack::connect_port(int_fast32_t channel, const std::string &connection)
{
    port_connections[channel] = connection;
    make_port_connection(channel);
}


void Jack::make_port_connection(int channel)
{
    if (port_connections[channel].empty())
    {
        ports[channel].disconnect(client);
    }
    else
    {
        ports[channel].connect(client, port_connections[channel].c_str(),
                               is_input);
    }
}


void Jack::connect_all()
{
    for (int channel = 0; channel < channels; channel++)
    {
        make_port_connection(channel);
    }
}


} // namespace bosepro


#pragma once

#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <list>
#include <map>
#include <set>
#include <string>
#include <vector>


namespace bosepro {

class Task;
class JackClient;
class Jack;

/// A JACK port within a JACK client.
class JackPort {
public:
    /// Get the name of the port, as registered with JACK.
    ///
    /// @return  A C string containing the name of the port.
    const char *get_name()
    {
        return jack_port_name(port);
    }


    /// Get the current audio buffer associated with this port.
    ///
    /// @param  frame_size  The number of samples to be read from or written to
    ///     the buffer.
    /// @return  A pointer to the buffer.
    float *get_buffer(int_fast32_t frame_size)
    {
        return static_cast<float *>(jack_port_get_buffer(port, frame_size));
    }


    /// Create this JACK port and register it with JACK.
    ///
    /// @param  client  The JACK client this port is associated with.
    /// @param  name  The name of the port.
    /// @param  is_input  `true` if this is an input port to the client.
    void create(JackClient *client, const char *name, bool is_input);


    /// Connect this port to another JACK port.
    ///
    /// @param  client  The JACK client this port is associated with.
    /// @param  connection_name  The name of the port to connect to.
    /// @param  is_input  `true` if this is an input port to the client.
    void connect(JackClient *client, const char *connection_name, bool is_input);


    /// Disconnect this port from any/all ports it is connected to.
    ///
    /// @param  client  The JACK client this port is associated with.
    void disconnect(JackClient *client);

private:
    jack_port_t *port;
};


/// A JACK client.
class JackClient {
public:
    /// Create the JACK client with a given name, and associate it with the
    /// task that will perform signal processing for that client.
    ///
    /// @param  name  The name of the client.
    /// @param  task  The task that will perform processing for the client.
    JackClient(const std::string &name, Task *task)
        : name(name), task(task)
    {
        jack_status_t jack_status;
        client = jack_client_open(name.c_str(), JackNullOption, &jack_status,
                                  NULL);

        if (client == nullptr)
        {
            SPDLOG_ERROR("Couldn't open JACK client.");
        }

        set_process_thread(jack_thread_helper, this);
    }


    ~JackClient()
    {
        jack_client_close(client);
    }


    /// Start processing with this JACK client.  This will activate the client,
    /// and (re-)make connections for the ports associated with this client.
    void start();


    /// Stop processing with this JACK client.  This will not destroy the
    /// client, but just deactivate it for processing.  Any ports associated
    /// with this client will automatically be disconnected by JACK.
    void stop();


    /// Get the sample rate used by the JACK server.
    ///
    /// @return  The JACK sample rate, in Hz.
    int_fast32_t get_sample_rate()
    {
        return jack_get_sample_rate(client);
    }


    /// Get the frame size used by the JACK server.
    ///
    /// @return  The JACK frame size, in samples.
    int_fast32_t get_frame_size()
    {
        return jack_get_buffer_size(client);
    }


    /// Get the actual JACK client object associated with this client.
    ///
    /// @return  A pointer to the JACK client object.
    jack_client_t *get_jack_client()
    {
        return client;
    }


    /// Attach a "jack_in" or "jack_out" signal processing block to this
    /// client.  This is needed primarily to automatically connect JACK ports
    /// after the client is activated.
    ///
    /// @param  jack_block  A pointer to the "jack_in" or "jack_out" block.
    void attach_block(Jack *jack_block)
    {
        jack_blocks.insert(jack_block);
    }


    /// Get the name of this JACK client.
    ///
    /// @return  The name of the client.
    const std::string &get_name() const
    {
        return name;
    }

private:
    jack_client_t *client;
    std::string name;
    Task *task;
    std::set<Jack *> jack_blocks;

    bool set_process_thread(JackThreadCallback callback, void *arg);

    static void *jack_thread_helper(void *arg)
    {
        JackClient *jack_client = (JackClient *)arg;
        jack_client->jack_thread();
        return arg;
    }

    void jack_thread();
};


/// A parent class for the "jack_in" and "jack_out" algorithms, which handles
/// some of the common JACK behavior.
class Jack : public Algorithm {
public:
    /// Configure the JACK client according to the block's configuration.
    ///
    /// @param  configuration  The configuration for the block.
    /// @param  is_input  `true` if this is a "jack_in" block.
    Jack(const BlockConfiguration &configuration, bool is_input);


    /// Specify a port connection for one of the JACK ports associated with
    /// this "jack_in" or "jack_out" block.  This does not immediately
    /// connect the port if the client has not yet been activated: the
    /// connection is deferred until `connect_all()` has been called.
    void connect_port(int_fast32_t channel, const std::string &connection);


    /// Connect all of the JACK ports associated with this "jack_in" or
    /// "jack_out" block.  This can only be done after the JACK client has
    /// been activated.
    void connect_all();


    /// Create a JACK client and associate it with a task.
    ///
    /// @param  name  The name of the JACK client.
    /// @param  task  The task that will do processing for the client.
    /// @return  A pointer to the JACK client.
    static JackClient *create_client(const std::string &name, Task *task);


    /// Destroy the JACK client with the given name.
    ///
    /// @param  name  The name of the JACK client to destroy.
    static void destroy_client(const std::string &name);


    /// Test whether any JACK clients are configured in the system.
    ///
    /// @return  `true` if any JACK clients exist.
    static bool has_client();


    /// Get a pointer to the JACK client with the given name.
    ///
    /// @param  name  The name of the JACK client.
    /// @return  A pointer to the client.
    static JackClient *get_client(const std::string &name);

protected:
    /// The number of channels in this "jack_in" or "jack_out" block.
    int channels;


    /// The JACK ports associated with this "jack_in" or "jack_out" block.
    bosepro::DspStateMemory<JackPort[]> ports;

private:
    static std::map<std::string, JackClient> clients;
    static JackClient *current_client;
    JackClient *client;

    bool is_input;
    bosepro::DspParamMemory<std::string[]> port_connections;

    void make_port_connection(int channel);
};


}

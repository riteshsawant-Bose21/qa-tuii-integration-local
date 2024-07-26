
#pragma once

#include <bosepro/algorithm.h>

#include <jack/jack.h>

#include <list>
#include <string>
#include <vector>


namespace bosepro {


class Jack : public Algorithm {

public:
    Jack(const BlockConfiguration &configuration, bool is_input);

    static bool has_client();

    static jack_client_t *get_client();

    static bool set_process_callback(JackProcessCallback callback, void *arg,
                                     bool make_default_connections);

    static bool set_process_thread(JackThreadCallback callback, void *arg,
                                   bool make_default_connections);

protected:
    int channels;
    std::vector<jack_port_t *> ports;


private:
    static jack_client_t *client;
    static std::list<Jack *> instances;

    bool is_input;
    bosepro::DspParamMemory<std::string[]> port_connections;

    bool connect_default_ports();

    void post_port_connection(int channel);
};


}

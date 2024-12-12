#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/profile.h>
#include <bosepro/session.h>

#include <boost/program_options.hpp>
#include <spdlog/spdlog.h>

#include <pthread.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <iostream>

#define CMD_PORT 53509

int connection_fd;

std::mutex socket_mutex;


/// Callback to send telemetry over a socket
///
/// @param message the message to send
void send_telemetry_sock_cb(const std::string &message)
{
    std::lock_guard<std::mutex> guard(socket_mutex);
    
    int size = send(connection_fd, message.c_str(), message.size(), 0);

    if (size < 0)
    {
        SPDLOG_WARN("Couldn't send telemetry to socket.");
    }
}


/// Callback to update telemetry in shared memory
///
/// @param message the message to send
// void update_telemetry_smem_cb(const std::string &message)
// {
    
// }


int main(int argc, char *argv[])
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("fusion_system_monitor");

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/configuration.json"), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value("config/module-definitions.json"), "module definition file")
        ("time,t", boost::program_options::value<int>(), "time to run (seconds)")
        ("help,h", "print this message and exit")
    ;

    boost::program_options::variables_map vm;
    boost::program_options::store(
            boost::program_options::parse_command_line(argc, argv, desc), vm);
    boost::program_options::notify(vm);

    if (vm.count("help"))
    {
        std::cout << desc << std::endl;
        return 0;
    }

    bosepro::Configuration configuration(vm["configuration"].as<std::string>());
    bosepro::Definition definitions(vm["definitions"].as<std::string>());
    bosepro::Session session(configuration.get_session(), definitions);

    if (configuration.has_tasks())
    {
        session.create_tasks(configuration);
    }

    if (configuration.has_na_tasks())
    {
        session.create_na_tasks(configuration);
    }

    if (configuration.has_parameter_settings())
    {
        for (auto &ps : configuration.get_parameter_settings())
        {
            session.process_parameter_setting((const bosepro::ParameterSetting &)ps.second);
        }
    }

    if (vm.count("time"))
    {
        session.set_seconds_to_run(vm["time"].as<int>());
    }

    session.set_telemetry_callbacks(send_telemetry_sock_cb, send_telemetry_sock_cb);

    session.start();

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in address;

    if (server_fd < 0)
    {
        SPDLOG_ERROR("Couldn't open socket");
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(CMD_PORT);

    if (bind(server_fd, (const struct sockaddr *)&address, sizeof(address)) != 0)
    {
        SPDLOG_ERROR("Couldn't bind socket");
    }

    SPDLOG_INFO("Listening");

    if (listen(server_fd, 5) != 0)
    {
        SPDLOG_ERROR("Couldn't listen to socket");
    }

    while (1)
    {
        if (connection_fd <= 0) 
        {
            struct sockaddr_in client;
            socklen_t len = sizeof(client);
            connection_fd = accept(server_fd, (struct sockaddr *)&client, &len);

            if (connection_fd < 0) {
                SPDLOG_ERROR("Couldn't accept client");
                continue;
            }
        }

        char buf[1024];
        memset(buf, 0, sizeof(buf));

        int result = read(connection_fd, buf, sizeof(buf) - 1);

        if (result <= 0)
        {
            SPDLOG_ERROR("Couldn't read from socket / Invalid socket.");
            close(connection_fd); // Close the invalid socket
            connection_fd = -1;   // Mark the connection as closed
            continue;
        }

        buf[result] = '\0';

        SPDLOG_INFO("Got parameter setting: '{}'", buf);

        try
        {
            std::stringstream ss(buf);
            bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
            session.process_parameter_setting(ps);
        }
        catch (const std::exception &e)
        {
            SPDLOG_ERROR("Error processing ps: {}", e.what());
        }

        usleep(100);
    }

    return 0;
}

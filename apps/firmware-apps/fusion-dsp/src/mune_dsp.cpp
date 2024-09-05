#include "wav_read.h"

#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/profile.h>
#include <bosepro/session.h>

#include <boost/program_options.hpp>
#include <spdlog/spdlog.h>

#include <pthread.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <iostream>

int connection_fd;

void send_meter(const std::string &message)
{
    int size = send(connection_fd, message.c_str(), message.size(), 0);

    if (size < 0)
    {
        SPDLOG_WARN("Couldn't send meter to socket.");
    }
}

int main(int argc, char *argv[])
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("mune_dsp");

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/configuration.json"), "configuration file")
        ("parameters,p", boost::program_options::value<std::string>()->default_value("config/parameters.json"), "parameter definition file")
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

    SPDLOG_INFO("Profile resolution {} ns", bosepro::Profile::get_resolution());
    bosepro::Profile::set_cpu_mips(1800.0);

    bosepro::Configuration configuration(vm["configuration"].as<std::string>());
    bosepro::Parameters parameters(vm["parameters"].as<std::string>());
    bosepro::Session session(configuration.get_session(), parameters);

    // Try to be psychic and run the way the user wants:
    //
    //     1.  If any "jack_in" or "jack_out" blocks are defined,
    //         run using JACK indefinitely.
    //     2.  Otherwise, if any "wav_read" blocks are defined, run
    //         enough frames to process the longest input WAV file and exit.
    //     3.  Finally, run for a specified amount of time and exit.

    if (bosepro::Jack::has_client())
    {
        if (vm.count("time"))
        {
            session.set_seconds_to_run(vm["time"].as<int>());
        }

        session.set_meter_callback(send_meter);

        session.start();


        int server_fd = socket(AF_INET, SOCK_STREAM, 0);
        struct sockaddr_in address;

        if (server_fd < 0)
        {
            SPDLOG_ERROR("Couldn't open socket");
        }

        address.sin_family = AF_INET;
        address.sin_addr.s_addr = htonl(INADDR_ANY);
        address.sin_port = htons(53508);

        if (bind(server_fd, (const struct sockaddr *)&address, sizeof(address)) != 0)
        {
            SPDLOG_ERROR("Couldn't bind socket");
        }

        SPDLOG_INFO("Listening");

        if (listen(server_fd, 5) != 0)
        {
            SPDLOG_ERROR("Couldn't listen to socket");
        }

        struct sockaddr_in client;
        socklen_t len = sizeof(client);

        connection_fd = accept(server_fd, (struct sockaddr *)&client, &len);

        if (connection_fd < 0)
        {
            SPDLOG_ERROR("Couldn't accept client");
        }

        SPDLOG_INFO("Socket connected");

        while(1)
        {
            char buf[1024];
            memset(buf, 0, sizeof(buf));

            int result = read(connection_fd, buf, sizeof(buf) - 1);

            if (result < 0)
            {
                SPDLOG_ERROR("Couldn't read from socket.");
            }

            if (buf[0] != '\0')
            {
                SPDLOG_INFO("Got command: {}", buf);
            }

            std::stringstream ss;
            ss << buf;
            bosepro::Command command = bosepro::Command(ss);
            session.process_command(command);
            usleep(100);
        }
    }
    else
    {
        if (bosepro::WavRead::longest_file_seconds() > 0.0)
        {
            session.set_seconds_to_run(bosepro::WavRead::longest_file_seconds());
        }
        else if (vm.count("time"))
        {
            session.set_seconds_to_run(vm["time"].as<int>());
        }

        while (!session.finished_running())
        {
            session.process();
        }

        SPDLOG_INFO("Finished running.");
    }

    return 0;
}

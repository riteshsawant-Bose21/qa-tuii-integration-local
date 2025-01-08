#include "wav_read.h"

#include <bosepro/observer.h>

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


bosepro::Session *psession;
int connection_fd;

void send_meter(const std::string &message)
{
    int size = send(connection_fd, message.c_str(), message.size(), 0);

    if (size < 0)
    {
        SPDLOG_WARN("Couldn't send meter to socket.");
    }
}


void handle_update(const std::string &update_setting)
{
    std::stringstream ss;
    ss << update_setting;
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    psession->process_parameter_setting(ps);
    SPDLOG_INFO("server update: {}", update_setting);
}


// Boost needs this structure and the corresponding `validate()` function to
// allow the same option to repeated multiple times and counted (-vv, -qq).
struct OptionCounter
{
    int count = 0;
};

void validate(boost::any &v, std::vector<std::string> const &, OptionCounter *, long)
{
    if (v.empty()) v = OptionCounter{1};
    else ++boost::any_cast<OptionCounter &>(v).count;
}

int main(int argc, char *argv[])
{
    OptionCounter verbosity;
    OptionCounter quietness;

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/configuration.json"), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value("config/algorithm-definitions.json"), "algorithm definition file")
        ("time,t", boost::program_options::value<int>(), "time to run (seconds)")
        ("serverip,s", boost::program_options::value<std::string>(), "IP address of fusion-server")
        ("verbose,v", boost::program_options::value(&verbosity)->zero_tokens(), "make logs more verbose")
        ("quiet,q", boost::program_options::value(&quietness)->zero_tokens(), "make logs more quiet")
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

    if (verbosity.count == 1)
    {
        spdlog::set_level(spdlog::level::debug);
    }
    else if (verbosity.count >= 2)
    {
        spdlog::set_level(spdlog::level::trace);
    }
    else if (quietness.count == 1)
    {
        spdlog::set_level(spdlog::level::warn);
    }
    else if (quietness.count >= 2)
    {
        spdlog::set_level(spdlog::level::off);
    }
    else
    {
        spdlog::set_level(spdlog::level::info);
    }

    SPDLOG_INFO("mune_dsp");

    SPDLOG_INFO("Profile resolution {} ns", bosepro::Profile::get_resolution());
    bosepro::Profile::set_cpu_mips(1800.0);

    bosepro::Configuration configuration(vm["configuration"].as<std::string>());
    bosepro::Definition definitions(vm["definitions"].as<std::string>());
    bosepro::Session session(configuration.get_session(), definitions);

    if (configuration.has_tasks())
    {
        session.create_tasks(configuration);
    }

    if (configuration.has_parameter_settings())
    {
        for (auto &ps : configuration.get_parameter_settings())
        {
            session.process_parameter_setting((const bosepro::ParameterSetting &)ps.second);
        }
    }

    if (configuration.has_task_connections())
    {
        for (auto &tc : configuration.get_task_connections())
        {
            session.connect_tasks((const bosepro::TaskConnectionConfiguration &)tc.second);
        }
    }

    // Try to be psychic and run the way the user wants:
    //
    //     1.  If any "jack_in" or "jack_out" blocks are defined,
    //         run using JACK indefinitely.
    //     2.  Otherwise, if any "wav_read" blocks are defined, run
    //         enough frames to process the longest input WAV file and exit.
    //     3.  Finally, run for a specified amount of time and exit.

    if (bosepro::Jack::has_client())
    {
        UDPValueMonitor *client = nullptr;
        psession = &session;

        if (vm.count("time"))
        {
            session.set_seconds_to_run(vm["time"].as<int>());
        }

        std::vector<std::string> target_paths;

        target_paths.push_back("settings.audio.*.*");

        if (vm.count("serverip"))
        {
            SPDLOG_INFO("server ip {}", vm["serverip"].as<std::string>());
            client = new UDPValueMonitor(vm["serverip"].as<std::string>(), 7947,
                                         target_paths, handle_update);
        }

        session.set_meter_callback(send_meter);

        session.start();

        while(1)
        {
            usleep(1000);
        }

        if (client != nullptr)
        {
            client->stop();
            delete client;
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

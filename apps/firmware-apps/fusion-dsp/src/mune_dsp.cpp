#include "wav_read.h"

#include <bosepro/observer.h>

#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/profile.h>
#include <bosepro/session.h>
#include <bosepro/telemetry_monitor.h>

#include <boost/program_options.hpp>
#include <spdlog/spdlog.h>

#include <pthread.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <signal.h>
#include <atomic>
#include <iostream>
#include <filesystem>


std::atomic<bool> g_running{true};

void signal_handler(int signum)
{
    if (signum == SIGINT || signum == SIGTERM) {
        g_running = false;
    }
}


bosepro::Session *psession;

void handle_update(const std::string &update_setting)
{
    std::stringstream ss;
    ss << update_setting;
    bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
    SPDLOG_INFO("server update: {}", update_setting);
    psession->process_parameter_setting(ps);
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
    // Register signal handler
    struct sigaction sa;
    sa.sa_handler = signal_handler;
    sa.sa_flags = 0;
    sigemptyset(&sa.sa_mask);

    sigaction(SIGINT, &sa, nullptr);
    sigaction(SIGTERM, &sa, nullptr);


    OptionCounter verbosity;
    OptionCounter quietness;

    // Get the root application directory for default paths.
    std::string app_path(std::filesystem::path(argv[0]).parent_path());
    
    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value(app_path + "/config/configuration.json"), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value(app_path + "/config/algorithm-definitions.json"), "algorithm definition file")
        ("time,t", boost::program_options::value<int>(), "time to run (seconds)")
        ("telemetry-messages,m", boost::program_options::value<std::string>()->default_value(app_path + "/config/telemetry-messages.json"), "telemetry commands file")
        ("telemetry-configuration,p", boost::program_options::value<std::string>()->default_value(app_path + "/config/telemetry-configuration.json"), "telemetry configuration file")
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
    bosepro::TelemetryConfiguration telem_configuration(vm["telemetry-configuration"].as<std::string>());
    bosepro::Definition definitions(vm["definitions"].as<std::string>());
    bosepro::Session session(configuration.get_session(), definitions);

    auto& telemetry_monitor = bosepro::TelemetryMonitor::get_instance();
    
    if (configuration.has_audio_tasks())
    {
        session.create_audio_tasks(configuration);
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
    //     1.  If any tasks are specified with corresponding JACK clients,
    //         run using JACK indefinitely.
    //     2.  If the "serverip" address is specified, but no JACK clients
    //         currently exist, connect to the server and wait for further
    //         instruction.
    //     3.  Otherwise, if any "wav_read" blocks are defined, run
    //         enough frames to process the longest input WAV file and exit.
    //     4.  Finally, run for a specified amount of time and exit, or 10
    //         seconds if no time is specified.

    if (bosepro::Jack::has_client() || vm.count("serverip"))
    {
        UDPValueMonitor *client = nullptr;
        psession = &session;

        if (vm.count("time"))
        {
            session.set_seconds_to_run(vm["time"].as<int>());
        }

        std::vector<std::string> target_paths;

        // Path for the static configuration
        target_paths.push_back("dsp_static_config");
        // Path for dynamic parameter setttings with vector indices
        target_paths.push_back("settings.audio.*.*[*]");
        // Path for dynamic parameter setttings
        target_paths.push_back("settings.audio.*.*");

        if (vm.count("serverip"))
        {
            SPDLOG_INFO("server ip {}", vm["serverip"].as<std::string>());
            client = new UDPValueMonitor(vm["serverip"].as<std::string>(), 7947,
                                         target_paths, handle_update);
        }

        // if we boot up on empty config, no need to start up telemetry
        if (configuration.has_audio_tasks())
        {
            session.start();
        }
        
        while(g_running)
        {
            if (!telemetry_monitor.is_running()) 
            {
                if (session.is_ready())
                {
                    telemetry_monitor.initialize(vm["telemetry-messages"].as<std::string>(), 
                                     telem_configuration.get_socket_path(),
                                     configuration.get_session().get_name());
                    telemetry_monitor.start();
                }
            }
            usleep(1000);
        }

        if (client != nullptr)
        {
            client->stop();
            delete client;
        }

        telemetry_monitor.stop();
        session.stop();
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
        else
        {
            session.set_seconds_to_run(10);
        }

        while (!session.finished_running())
        {
            session.process();
        }

        SPDLOG_INFO("Finished running.");
    }

    SPDLOG_INFO("mune_dsp exiting...");
    return 0;
}

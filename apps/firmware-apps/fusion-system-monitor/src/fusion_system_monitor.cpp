#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/profile.h>
#include <bosepro/session.h>

#include <boost/program_options.hpp>
#include <spdlog/spdlog.h>

#include <pthread.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h> 
#include <iostream>


int main(int argc, char *argv[])
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("fusion_system_monitor");

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/configuration.json"), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value("config/module-definitions.json"), "module definition file")
        ("telemetry,d", boost::program_options::value<std::string>()->default_value("config/telemetry-messages.json"), "telemetry commands file")
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
    
    // Get TelemetryMonitor instance
    auto& telemetry_monitor = bosepro::TelemetryMonitor::get_instance();

    if (configuration.has_audio_tasks())
    {
        session.create_audio_tasks(configuration);
    }

    if (configuration.has_periodic_tasks())
    {
        session.create_periodic_tasks(configuration);
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

    telemetry_monitor.initialize(vm["telemetry"].as<std::string>());
    telemetry_monitor.start();
    session.start();

    return 0;
}

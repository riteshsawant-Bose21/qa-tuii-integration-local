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
#include <fstream>


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
    psession->process_parameter_setting(ps);
    SPDLOG_INFO("server update: {}", update_setting);
}

static void handle_amp_control_update(const std::string &path,
                                      const Json::Value &old_val,
                                      const Json::Value &new_val)
{
    (void)path;

    if (old_val == new_val) {
        return;
    }

    if (!new_val.isObject() || !new_val.isMember("endpoint") || !new_val.isMember("payload") ||
        !new_val["endpoint"].isString() || !new_val["payload"].isString()) {
        Json::StreamWriterBuilder writer;
        writer["indentation"] = "";
        SPDLOG_WARN("Ignoring amp_control update at {} with unexpected payload {}",
                    path, Json::writeString(writer, new_val));
        return;
    }

    Json::Value message_json;
    message_json["target"] = "amp_control";
    message_json["name"] = new_val["endpoint"].asString();
    message_json["value"] = new_val["payload"].asString();

    Json::StreamWriterBuilder writer;
    writer["indentation"] = "";
    handle_update(Json::writeString(writer, message_json));
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

static std::string read_bootargs_device_id()
{
    constexpr const char *bootargs_path = "/proc/device-tree/chosen/bootargs";
    const std::string key = "device_id=";

    std::ifstream file(bootargs_path, std::ios::binary);
    if (!file.is_open()) {
        return {};
    }

    std::string bootargs((std::istreambuf_iterator<char>(file)),
                         std::istreambuf_iterator<char>());

    const auto pos = bootargs.find(key);
    if (pos == std::string::npos) {
        return {};
    }

    const auto start = pos + key.size();
    auto end = start;
    while (end < bootargs.size() && bootargs[end] != ' ' && bootargs[end] != '\0') {
        ++end;
    }

    if (end == start) {
        return {};
    }

    return bootargs.substr(start, end - start);
}

static std::string resolve_configuration_path(const std::string &config_dir)
{
    namespace fs = std::filesystem;
    const std::string base_name = "configuration.json";
    const std::string device_id = read_bootargs_device_id();

    std::string candidate = config_dir + "/";
    candidate += device_id.empty() ? base_name : device_id + "-" + base_name;

    if (!fs::exists(candidate)) {
        candidate = config_dir + "/som-" + base_name;
    }

    return candidate;
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

    std::string config_path = "/etc/fusion/system-monitor";
    std::string default_configuration = resolve_configuration_path(config_path);

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value(default_configuration), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value(config_path + "/module-definitions.json"), "module definition file")
        ("telemetry-messages,m", boost::program_options::value<std::string>()->default_value(config_path + "/telemetry-messages.json"), "telemetry commands file")
        ("telemetry-configuration,p", boost::program_options::value<std::string>()->default_value(config_path + "/telemetry-configuration.json"), "telemetry configuration file")
        ("serverip,s", boost::program_options::value<std::string>(), "127.0.0.1")
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


    SPDLOG_INFO("fusion_system_monitor--configuration file: {}", vm["configuration"].as<std::string>());

    bosepro::Configuration configuration(vm["configuration"].as<std::string>());
    bosepro::TelemetryConfiguration telem_configuration(vm["telemetry-configuration"].as<std::string>());
    bosepro::Definition definitions(vm["definitions"].as<std::string>());
    bosepro::Session session(configuration.get_session(), definitions);
    

    auto& telemetry_monitor = bosepro::TelemetryMonitor::get_instance();

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


    UDPValueMonitor *client = nullptr;
    psession = &session;

    std::vector<std::string> target_paths;

    // Path for networked audio streams
    target_paths.push_back("audio_streams");
    // Path for dynamic parameter setttings
    target_paths.push_back("settings.fw.*.*[*]");
    target_paths.push_back("settings.fw.*.*");
    
    if (vm.count("serverip"))
    {
        SPDLOG_INFO("server ip {}", vm["serverip"].as<std::string>());
        client = new UDPValueMonitor(vm["serverip"].as<std::string>(), 7947,
                                        target_paths, handle_update);
        client->watch("settings.firmware.amp_control",
                      [](const std::string &path, const Json::Value &old_val,
                         const Json::Value &new_val) {
                          handle_amp_control_update(path, old_val, new_val);
                      });
    }

    // if we boot up on empty config, no need to start up telemetry
    if (configuration.has_periodic_tasks())
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
                                    configuration.get_session().has_name()
                                     ? configuration.get_session().get_name()
                                     : "fusion_system_monitor");
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

    SPDLOG_INFO("fusion_system_monitor exiting...");
    return 0;
}

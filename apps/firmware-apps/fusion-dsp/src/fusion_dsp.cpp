#include "wav_read.h"
#include "message_player.h"

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

void handle_update(const std::string &update_setting);

class UDPListener {
public:
    UDPListener()
    {
        sockfd = socket(AF_INET, SOCK_DGRAM, 0);

        if (sockfd < 0)
        {
            SPDLOG_ERROR("Error opening socket");
            return;
        }

        sockaddr_in address;
        std::memset(&address, 0, sizeof(address));
        address.sin_family = AF_INET;
        address.sin_addr.s_addr = INADDR_ANY;
        address.sin_port = htons(3508);
        if (bind(sockfd, (struct sockaddr *)&address, sizeof(address)) < 0)
        {
            SPDLOG_ERROR("Error binding socket");
            close(sockfd);
            sockfd = -1;
            return;
        }

        int flags = fcntl(sockfd, F_GETFL, 0);
        if (flags == -1)
        {
            throw std::runtime_error(std::string("fcntl(F_GETFL) failed: ") +
                    strerror(errno));
        }
        if (fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) == -1)
        {
            throw std::runtime_error(std::string("fcntl(F_SETFL) failed: ") +
                    strerror(errno));
        }

        listener_thread = std::thread(&UDPListener::run, this);
    }


    ~UDPListener()
    {
        stop();
        if (sockfd >= 0)
        {
            close(sockfd);
        }
    }


    void stop()
    {
        running = false;
        if (listener_thread.joinable()) {
            listener_thread.join();
        }
    }


private:
    static std::string escape_quotes(const std::string& input)
    {
        std::string output;
        output.reserve(input.size());
        for (char c : input)
        {
            if (c == '"')
            {
                output += "\\\"";
            }
            else if (std::isprint(c))
            {
                output += c;
            }
        }
        return output;
    }

    void run()
    {
        pollfd pfd;
        pfd.fd = sockfd;
        pfd.events = POLLIN;
        constexpr size_t BUFFER_SIZE = 65535;
        char buffer[BUFFER_SIZE];
        sockaddr_in sender_addr;
        socklen_t sender_len = sizeof(sender_addr);

        while (running)
        {
            const int poll_result = poll(&pfd, 1, 1000);

            if (poll_result < 0)
            {
                if (errno == EINTR)
                {
                    continue;
                }
                SPDLOG_ERROR("Poll error: {}", strerror(errno));
                break;
            }
            else if (poll_result == 0)
            {
                continue;
            }

            if (pfd.revents & POLLIN)
            {
                sender_len = sizeof(sender_addr);
                const ssize_t received =
                    recvfrom(sockfd, buffer, BUFFER_SIZE - 1, 0,
                             reinterpret_cast<sockaddr *>(&sender_addr),
                             &sender_len);

                if (received < 0)
                {
                    if (errno == EWOULDBLOCK || errno == EAGAIN)
                    {
                        continue;
                    }
                    SPDLOG_ERROR("Error receiving data: {}", strerror(errno));
                    continue;
                }

                buffer[received] = '\0';

                Json::Value response;
                Json::CharReaderBuilder reader_builder;
                std::istringstream iss(buffer);
                std::string errs;


                if (Json::parseFromStream(reader_builder, iss, &response, &errs))
                {
                    if (response.isMember("message_type") &&
                        response["message_type"].asString() == "play_message")
                    {
                        Json::FastWriter fast_writer;
                        std::string response_str = fast_writer.write(response);

                        for (auto &mp : MessagePlayer::get_player_names())
                        {
                            std::string command = "{ \"target\": \"" + mp +
                                "\", \"name\": \"play_message\", \"value\": \""
                                + escape_quotes(response_str) + "\" }";
                            handle_update(command);
                        }
                    }
                }
                else
                {
                    SPDLOG_DEBUG("Failed to parse JSON: {}", errs);
                }
            }
        }
    }

    int sockfd;
    std::atomic<bool> running{true};
    std::thread listener_thread;
};


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
    static std::mutex mtx;
    std::lock_guard<std::mutex> lock(mtx);

    std::stringstream ss;
    ss << update_setting;
    SPDLOG_DEBUG("Server update: {}", update_setting);

    try
    {
        bosepro::ParameterSetting ps = bosepro::ParameterSetting(ss);
        psession->process_parameter_setting(ps);
    }
    catch (const std::exception &e)
    {
        SPDLOG_ERROR("Error processing parameter setting: {} - {}",
                     update_setting, e.what());
    }
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

    bool no_telemetry = false;
    OptionCounter verbosity;
    OptionCounter quietness;

    // Note: on actual devices CONFIG_PATH will be set appropriately. And shared configuration 
    // like telemetry-configuration.json will have symlinks to the "real" file.
    std::string config_path = "config"; // Default config path for local testing, etc.
    auto envConfigPath = getenv("CONFIG_PATH");
    if (envConfigPath) {
        config_path = envConfigPath;
    }

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value(config_path + "/configuration.json"), "configuration file")
        ("definitions,d", boost::program_options::value<std::string>()->default_value(config_path + "/algorithm-definitions.json"), "algorithm definition file")
        ("time,t", boost::program_options::value<int>(), "time to run (seconds)")
        ("telemetry-messages,m", boost::program_options::value<std::string>()->default_value(config_path + "/telemetry-messages.json"), "telemetry commands file")
        ("telemetry-configuration,p", boost::program_options::value<std::string>()->default_value(config_path + "/telemetry-configuration.json"), "telemetry configuration file")
        ("serverip,s", boost::program_options::value<std::string>(), "IP address of fusion-server")
        ("no-telemetry,n", boost::program_options::bool_switch(&no_telemetry), "disable telemetry")
        ("device-id,i", boost::program_options::value<std::string>(), "device ID to use")
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

    SPDLOG_INFO("fusion_dsp");

    SPDLOG_INFO("Profile resolution {} ns", bosepro::Profile::get_resolution());
    bosepro::Profile::set_cpu_mips(1800.0);

    bosepro::Configuration configuration(vm["configuration"].as<std::string>());
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
        UDPListener udp_listener;

        if (vm.count("time"))
        {
            session.set_seconds_to_run(vm["time"].as<int>());
        }

        std::vector<std::string> target_paths;

        // Path for the static configuration
        target_paths.push_back("devices[*]");
        // Path for dynamic parameter setttings with matrix indices
        target_paths.push_back("settings.audio.*.*[*][*]");
        // Path for dynamic parameter setttings with vector indices
        target_paths.push_back("settings.audio.*.*[*]");
        // Path for dynamic parameter setttings
        target_paths.push_back("settings.audio.*.*");

        if (vm.count("serverip"))
        {
            SPDLOG_INFO("server ip {}", vm["serverip"].as<std::string>());
            client = new UDPValueMonitor(vm["serverip"].as<std::string>(), 7947,
                                         target_paths, handle_update);

            if (vm.count("device-id"))
            {
                client->setDeviceID(vm["device-id"].as<std::string>());
            }
        }

        // if we boot up on empty config, no need to start up telemetry
        if (configuration.has_audio_tasks())
        {
            session.start();
        }

        while(g_running)
        {
            if (!telemetry_monitor.is_running() && !no_telemetry)
            {
                if (session.is_ready())
                {
                    bosepro::TelemetryConfiguration telem_configuration(vm["telemetry-configuration"].as<std::string>());

                    telemetry_monitor.initialize(vm["telemetry-messages"].as<std::string>(),
                                     telem_configuration.get_socket_path(),
                                     configuration.get_session().has_name()
                                     ? configuration.get_session().get_name()
                                     : "fusion_dsp");
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
        udp_listener.stop();
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

    SPDLOG_INFO("fusion_dsp exiting...");
    return 0;
}

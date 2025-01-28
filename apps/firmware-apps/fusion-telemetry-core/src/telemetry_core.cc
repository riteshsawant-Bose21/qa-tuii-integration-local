#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <signal.h>
#include <iostream>
#include <variant>
#include <vector>
#include <list>
#include <csignal>
#include <algorithm>
#include <boost/program_options.hpp>
#include <poll.h>
#include <spdlog/spdlog.h>
#include <spdlog/fmt/ostr.h>
#include "telemetry_core.h"
#include "telemetry_msg_handler.h"
#include "telemetry_utils.h"

#define POLL_HI_TIME_NSEC(time) time * 1000000

#define RX_BUFFER_SIZE   1024

#define CORE_SOCKET_PATH  "/tmp/telmery-core"

sig_atomic_t volatile telm_running = 1;

void sig_handler(int signum)
{
    SPDLOG_CRITICAL("Caught Signal ({})", strsignal(signum));
    telm_running = 0;
}

int register_message_handlers(bosepro::telemetryManager& telm_mgr)
{
    int ret_val;

    // Register all message req/rsp handlers here

    // Message: sub_register_req
    ret_val = telm_mgr.register_message_handler("sub_register_req",
                                       process_sub_register_req,
                                       process_sub_register_rsp);
    if (ret_val != 0)
    {
        return ret_val;
    }

    // Message: sub_deregister_req
    ret_val = telm_mgr.register_message_handler("sub_deregister_req",
                                      process_sub_deregister_req,
                                      process_sub_deregister_rsp);
    if (ret_val != 0)
    {
        return ret_val;
    }

    // Message: pub_register_req
    ret_val = telm_mgr.register_message_handler("pub_register_req",
                                      process_pub_register_req,
                                      process_pub_register_rsp);

    if (ret_val != 0)
    {
        return ret_val;
    }

    // Message: pub_deregister_req
    ret_val = telm_mgr.register_message_handler("pub_deregister_req",
                                      process_pub_deregister_req,
                                      process_pub_deregister_rsp);

    if (ret_val != 0)
    {
        return ret_val;
    }

    // When a response to update_meter_req is received the meter_data
    // is sent back when it is time.
    ret_val = telm_mgr.register_message_handler("update_meters_rsp",
                                       process_update_meters_rsp,
                                       process_meter_data);

    // Message: send_meter_req
    ret_val = telm_mgr.register_message_handler("send_meter_req",
                                       process_send_meter_req,
                                       process_send_meter_rsp);

    if (ret_val != 0)
    {
        return ret_val;
    }

    // Message: event
    ret_val = telm_mgr.register_message_handler("event",
                                       process_event,
                                       process_event_rsp);

    if (ret_val != 0)
    {
        return ret_val;
    }

    // Message: update_report_period_req
    ret_val = telm_mgr.register_message_handler("update_report_period_req",
                                       process_update_report_period_req,
                                       process_update_report_period_rsp);
    return ret_val;

}

#define HI_METERS_UPDATE_PERIOD_NS  550000.0  // 2/3 ms (approx. )

int main(int argc, char* argv[])
{
    std::vector<uint32_t> update_periods = {0, 0, 0};
    std::vector<uint32_t> report_periods = {0, 0, 0};
    std::string core_path;
    std::string core_ip;
    uint64_t start_tstamp_ns;

    signal(SIGINT, &sig_handler);
    signal(SIGTERM, &sig_handler);
    signal(SIGKILL, &sig_handler);

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/telemetry-configuration.json"), "configuration file")
        ("socket-path,p", boost::program_options::value<std::string>(&core_path), "Core UNIX Domain Socket Path")
        ("system-ip,i", boost::program_options::value<std::string>(&core_ip)->required(), "System IP Address")
        ("update-period,u", boost::program_options::value<std::vector<uint32_t>>(&update_periods)->multitoken(), "HI Freq., MED Freq. & LO Freq. update periods (Frames)")
        ("report-period,r", boost::program_options::value<std::vector<uint32_t>>(&report_periods)->multitoken(), "HI Freq., MED Freq. & LO Freq. report periods (Frames)")
        ("debug-log-enable,d", boost::program_options::bool_switch(), "Set logging level to DEBUG")
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

    // Check if DEBUG log level is enabled
    bool debug_flag = vm["debug-log-enable"].as<bool>();
    if (debug_flag)
    {
        spdlog::set_level(spdlog::level::debug);
    }
    else
    {
        spdlog::set_level(spdlog::level::info);
    }

    bosepro::Telemetry_configuration configuration(vm["configuration"].as<std::string>());
    bosepro::Telemetry_configuration telm_config( configuration.get_telemetry_configuration());

    for (auto& cfg : telm_config)
    {
        bosepro::Telemetry_configuration *temp =
            static_cast<bosepro::Telemetry_configuration *> (&cfg.second);
        std::string temp_str;

        temp->get_value("name", temp_str);

        if (temp_str.compare("socket_path") == 0)
        {
            // Use socket path from file if not provided in command line
            if (core_path.size() == 0)
            {
                temp->get_value("property", core_path);
            }
            SPDLOG_INFO("Socket path - '{}'", core_path);
        }
        else if (temp_str.compare("meter_update_period_frames") == 0)
        {
            // Use periods from file if not provided in command line
            if ( (update_periods[0] == 0) && (update_periods[1] == 0) && (update_periods[2] == 0))
            {
                update_periods.clear();
                temp->get_config_value_vector("property", update_periods);
            }
            SPDLOG_INFO("Period: [ {}, {}, {}]",
                    update_periods[0], update_periods[1], update_periods[2]);
        }
        else if (temp_str.compare("meter_report_period_frames") == 0)
        {
            // Use periods from file if not provided in command line
            if ( (report_periods[0] == 0) && (report_periods[1] == 0) && (report_periods[2] == 0))
            {
                report_periods.clear();
                temp->get_config_value_vector("property", report_periods);
            }
            SPDLOG_INFO("Period: [ {}, {}, {}]",
                    report_periods[0], report_periods[1], report_periods[2]);
        }
    }

    // Check for IP format error
    if (core_ip.find(' ') != std::string::npos)
    {
        //Report error

        SPDLOG_ERROR("Bad IP address");
        exit(1);
    }

    if ( ( (update_periods.size() > 0) && (update_periods.size() != 3)) ||
         ( (report_periods.size() > 0) && (report_periods.size() != 3)) )
    {
        //Report error

        SPDLOG_ERROR("HI, MED & LO  period values must be specified");
        exit(1);
    }

    // Check for values are sorted
    if ( (update_periods[0] >= update_periods[1]) ||
         (update_periods[0] >= update_periods[2]) ||
         (update_periods[1] >= update_periods[2]) )
    {
        //Report error
        SPDLOG_ERROR("Invalid Update period values!");

        exit(1);
    }

    if ( (report_periods[0] >= report_periods[1]) ||
         (report_periods[0] >= report_periods[2]) ||
         (report_periods[1] >= report_periods[2]) )
    {
        //Report error
        SPDLOG_ERROR("Invalid Report period values!");

        exit(1);
    }

    // ***** Cmd-line argument processing complete ******

    // Instantiate telmetry manager
    std::unique_ptr<bosepro::telemetryManager> telmMgr =
                              std::make_unique<bosepro::telemetryManager>();

    struct pollfd telmPollFds[TELM_CONN_TYPE_MAX];
    uint32_t core_hi_period_frms;
    uint32_t core_med_period_frms;
    uint32_t core_lo_period_frms;
    int poll_ret;
    int ux_sock_fd;
    int inet_sock_fd;
    uint32_t calibrated_period_ns = HI_METERS_UPDATE_PERIOD_NS;

    std::string ux_path;
    std::string inet_ip;
    uint32_t inet_port;

    // Calibrate timeout value (~2/3 ms)
    {
        struct timespec poll_timeout;
        struct pollfd tempPollFds;
        uint64_t start, end;

        tempPollFds.fd = -1;

        poll_timeout.tv_sec  = 0;
        poll_timeout.tv_nsec = calibrated_period_ns;

        while (1)
        {
            start = get_realtime_ns();
            poll_ret = ppoll(&tempPollFds, 1, &poll_timeout, NULL);
            end = get_realtime_ns() - start;

            if (end > 620000)
            {
                calibrated_period_ns -= 10;
            }
            else if (end < 615000)
            {
                calibrated_period_ns += 10;
            }
            else
            {
                break;
            }
            poll_timeout.tv_nsec = calibrated_period_ns;
        }

        SPDLOG_INFO("Calibration Complete (Ref time: {}({}))",
                     calibrated_period_ns, end);
    }

    // Initialize manager
    if (telmMgr->init(core_ip, core_path, update_periods, report_periods) != 0)
    {
        SPDLOG_ERROR("Failed initialization");
        exit(1);
    }

    if (register_message_handlers(*telmMgr) != 0)
    {
        exit(1);
    }

    telmMgr->get_ux_sock_path(ux_path);
    telmMgr->get_inet_ip(inet_ip);
    telmMgr->get_inet_port(inet_port);

    ux_sock_fd = open_unix_udp_socket(ux_path);
    inet_sock_fd = open_inet_udp_socket(inet_ip, inet_port);

    telmMgr->set_socket_descriptors(ux_sock_fd, inet_sock_fd);

    telmMgr->get_meter_report_periods(
            core_hi_period_frms, core_med_period_frms, core_lo_period_frms);

    // Setup poll FD
    telmPollFds[TELM_CONN_TYPE_UNIX_SOCK].fd =
                telmMgr->get_socket_descriptor(TELM_CONN_TYPE_UNIX_SOCK);
    telmPollFds[TELM_CONN_TYPE_UNIX_SOCK].events = POLLIN;

    telmPollFds[TELM_CONN_TYPE_INTERNET_SOCK].fd =
                telmMgr->get_socket_descriptor(TELM_CONN_TYPE_INTERNET_SOCK);
    telmPollFds[TELM_CONN_TYPE_INTERNET_SOCK].events = POLLIN;

    struct timespec poll_timeout;

    // Prepare signal mask
    sigset_t sigmask, oldmask;
    sigemptyset(&sigmask);

    // Block during ppoll()
    sigaddset(&sigmask, SIGINT);
    sigaddset(&sigmask, SIGTERM);
    sigaddset(&sigmask, SIGKILL);

    poll_timeout.tv_sec  = 0;
    poll_timeout.tv_nsec = calibrated_period_ns;

    SPDLOG_INFO("Telemetry Core startring ...");
    while(telm_running)
    {
        char        recv_data[RX_BUFFER_SIZE];
        std::string rx_string;
        uint32_t    recv_size;

        start_tstamp_ns = get_realtime_ns();

        // Block signals and call ppoll()
        if (sigprocmask(SIG_BLOCK, &sigmask, &oldmask) == -1) {
            perror("sigprocmask");
            return 1;
        }

        memset(recv_data, 0, RX_BUFFER_SIZE);

        poll_ret = ppoll(telmPollFds, TELM_CONN_TYPE_MAX,
                         &poll_timeout, &sigmask);

        // Restore the old signal mask
        if (sigprocmask(SIG_SETMASK, &oldmask, NULL) == -1) {
            perror("sigprocmask");
            return 1;
        }

        if (!telm_running)
        {
            break;
        }

        if (poll_ret < 0)
        {
            //Report Error
            SPDLOG_ERROR("Received external signal");
        }
        else if (poll_ret == 0)
        {
            // Timeout
            // - Send meter update message(type(s)) to all pubs
            telmMgr->send_update_request();

            // Responses to update request are handled by the message handler

            // Incase periods were updated in previous message
            telmMgr->get_meter_report_periods(core_hi_period_frms,
                                              core_med_period_frms,
                                              core_lo_period_frms);

            poll_timeout.tv_nsec = calibrated_period_ns;
        }
        else
        {
            if (telmPollFds[TELM_CONN_TYPE_UNIX_SOCK].revents & POLLIN)
            {
                telmMgr->receive_data(TELM_CONN_TYPE_UNIX_SOCK, recv_data,
                                      RX_BUFFER_SIZE, recv_size);
            }
            else if (telmPollFds[TELM_CONN_TYPE_INTERNET_SOCK].revents & POLLIN)
            {
                telmMgr->receive_data(TELM_CONN_TYPE_INTERNET_SOCK, recv_data,
                                      RX_BUFFER_SIZE, recv_size);
            }
            else
            {
                // Should not get here
                continue;
            }

            rx_string.assign(recv_data);

            if (rx_string.size() > 0)
            {
                telmMgr->process_rx_packet(rx_string);
            }
            else
            {
                if (recv_size < 0)
                {
                    //Report ERROR
                    SPDLOG_ERROR("Receive Data Error");
                }
            }

            // Compute remaining time before next meter_update_message
            poll_timeout.tv_nsec -= (get_realtime_ns() - start_tstamp_ns);

            if (poll_timeout.tv_nsec < 0)
                poll_timeout.tv_nsec = 0;
        }

        telmMgr->cleanup_dead_endpoints();

    }  // while(1)

    close(ux_sock_fd);
    close(inet_sock_fd);
    unlink(core_path.c_str());
    remove(core_path.c_str());
}


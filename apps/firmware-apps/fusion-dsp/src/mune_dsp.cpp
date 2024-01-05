#include "jack.h"
#include "wav_read.h"

#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/profile.h>
#include <bosepro/session.h>

#include <boost/program_options.hpp>
#include <jack/jack.h>
#include <spdlog/spdlog.h>

#include <pthread.h>
#include <unistd.h>

#include <iostream>


int rt_process(jack_nframes_t /* unused */, void *arg)
{
    bosepro::Session *session = (bosepro::Session *)arg;

    if (session == nullptr)
    {
        return 0;
    }

    if (session->finished_running())
    {
        SPDLOG_INFO("Finished running.");
        delete session;
        SPDLOG_INFO("Session terminated.");
        return 0;
    }

    session->process();
    return 0;
}

typedef struct {
    jack_client_t *client;
    bosepro::Session *session;
} ThreadData;

void *rt_thread(void *arg)
{
    ThreadData *thread_data = (ThreadData *)arg;
    sched_param param;
    int policy;
    SPDLOG_INFO("Starting thread.");
    pthread_getschedparam(pthread_self(), &policy, &param);
    SPDLOG_INFO("Thread priority: {} {} {}", SCHED_FIFO, policy, param.sched_priority);


#ifndef USE_MAC_THREADS
    cpu_set_t cpuset;

    pthread_getaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);
    SPDLOG_INFO("CPU affinity: {} {} {} {} {}", CPU_COUNT(&cpuset),
            CPU_ISSET(0, &cpuset), CPU_ISSET(1, &cpuset), CPU_ISSET(2, &cpuset), CPU_ISSET(3, &cpuset));

    CPU_ZERO(&cpuset);
    CPU_SET(1, &cpuset);
    if (pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset) != 0)
    {
        SPDLOG_ERROR("pthread_setaffinity_np() failed");
    }

    pthread_getaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);
    SPDLOG_INFO("CPU affinity: {} {} {} {} {}", CPU_COUNT(&cpuset),
            CPU_ISSET(0, &cpuset), CPU_ISSET(1, &cpuset), CPU_ISSET(2, &cpuset), CPU_ISSET(3, &cpuset));
#endif

    while (!thread_data->session->finished_running())
    {
        jack_cycle_wait(thread_data->client);
        thread_data->session->process();
        jack_cycle_signal(thread_data->client, 0);
    }

    jack_cycle_wait(thread_data->client);
    SPDLOG_INFO("Finished running.");
    delete thread_data->session;
    SPDLOG_INFO("Session terminated.");
    jack_cycle_signal(thread_data->client, 1);

    SPDLOG_INFO("exiting thread.");
    return arg;
}


int main(int argc, char *argv[])
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("mune_dsp");

    boost::program_options::options_description desc("Allowed options");
    desc.add_options()
        ("configuration,c", boost::program_options::value<std::string>()->default_value("config/configuration.json"), "configuration file")
        ("parameters,p", boost::program_options::value<std::string>()->default_value("config/parameters.json"), "parameter definition file")
        ("threads,T", "use JACK threads interface")
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

        if (vm.count("threads"))
        {
            SPDLOG_INFO("Using JACK threads interface");

            static ThreadData thread_data;
            thread_data.client = bosepro::Jack::get_client();
            thread_data.session = &session;

            if (!bosepro::Jack::set_process_thread(rt_thread, &thread_data, false))
            {
                SPDLOG_CRITICAL("bosepro::Jack::set_process_thread() failed");
                return 1;
            }
        }
        else if (!bosepro::Jack::set_process_callback(rt_process, &session, false))
        {
            SPDLOG_CRITICAL("bosepro::Jack::set_process_callback() failed");
            return 1;
        }

        sleep(-1);
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

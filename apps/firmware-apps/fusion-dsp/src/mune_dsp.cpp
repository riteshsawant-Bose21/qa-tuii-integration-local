#include "jack.h"
#include "wav_read.h"

#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/session.h>

#include <boost/program_options.hpp>
#include <jack/jack.h>
#include <spdlog/spdlog.h>

#include <unistd.h>

#include <iostream>


int rt_process(jack_nframes_t /* unused */, void *arg)
{
    bosepro::Session *session = (bosepro::Session *)arg;

    session->process();
    return 0;
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
        if (!bosepro::Jack::set_process_callback(rt_process, &session, false))
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

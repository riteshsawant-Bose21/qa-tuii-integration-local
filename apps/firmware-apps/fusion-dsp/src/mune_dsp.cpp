#include "jack.h"

#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/session.h>

#include <jack/jack.h>
#include <spdlog/spdlog.h>

#include <unistd.h>


int rt_process(jack_nframes_t /* unused */, void *arg)
{
    bosepro::Session *session = (bosepro::Session *)arg;

    session->process();
    return 0;
}


int main()
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("mune_dsp");

    bosepro::Configuration configuration("config/vb1.json");
    bosepro::Parameters parameters("config/parameters.json");
    bosepro::Session session(configuration.get_session(), parameters);

    if (!bosepro::Jack::has_client())
    {
        SPDLOG_CRITICAL("JACK not initialized. File-only is not implemented.");
        return 1;
    }

    if (!bosepro::Jack::set_process_callback(rt_process, &session, false))
    {
        SPDLOG_CRITICAL("bosepro::Jack::set_process_callback() failed");
        return 1;
    }

    sleep(-1);
    return 0;
}

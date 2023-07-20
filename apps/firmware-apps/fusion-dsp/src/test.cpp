
#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/session.h>

#include <jack/jack.h>
#include <spdlog/spdlog.h>

#include <unistd.h>


jack_client_t *jack_client;


typedef struct {
    jack_client_t *jack_client;
    bosepro::Session *session;
    int total_frames;
} Stuff;


int rt_process(jack_nframes_t nframes, void *arg)
{
    Stuff *stuff = (Stuff *)arg;
    stuff->total_frames += nframes;

    stuff->session->process();
    return 0;
}


int main()
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("bosepro test");
    Stuff stuff;
    int err;
    jack_status_t jack_status;
    stuff.jack_client = jack_client_open("bosepro", JackNullOption,
                                         &jack_status, NULL);
    jack_client = stuff.jack_client;

    if (stuff.jack_client == NULL) {
        SPDLOG_CRITICAL("jack_client_open() failed, status: {}", (int)jack_status);
        return 1;
    }

    bosepro::Configuration configuration("config/test.json");
    bosepro::Parameters parameters("config/parameters.json");
    bosepro::Session session(configuration.get_session(), parameters);

    stuff.session = &session;

    err = jack_set_process_callback(stuff.jack_client, rt_process, &stuff);

    if (err != 0)
    {
        SPDLOG_CRITICAL("jack_set_process_callback() failed, err: {}", err);
        return 1;
    }

    err = jack_activate(stuff.jack_client);

    if (err != 0)
    {
        SPDLOG_CRITICAL("jack_activate() failed, err: {}", err);
        return 1;
    }

    sleep(-1);
    return 0;
}
